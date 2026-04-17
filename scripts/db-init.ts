#!/usr/bin/env node
/**
 * Database Initialization and DnD Data Seeding Script
 * 
 * This script:
 * 1. Ensures all database tables exist (runs migrations from infrastructure/db/*.sql)
 * 2. Checks if DnD data is already loaded
 * 3. If not, loads all JSON files from dnd_data_bundle into the database
 * 
 * Usage:
 *   npm run db:init          # Load with status output
 *   npm run db:init:force    # Force re-load (truncates tables)
 */

import fs from 'fs';
import path from 'path';
import * as pg from 'pg';
import { fileURLToPath } from 'url';

const { Client } = pg.default;

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Configuration from environment or defaults
const DB_CONFIG = {
  host: process.env.POSTGRES_HOST || 'localhost',
  port: parseInt(process.env.POSTGRES_PORT || '5432', 10),
  database: process.env.POSTGRES_DB || 'dnd_campaigns',
  user: process.env.POSTGRES_USER || 'dnd_admin',
  password: process.env.POSTGRES_PASSWORD || 'localdev_secret',
};

const FORCE_RELOAD = process.argv.includes('--force');
const DATA_BUNDLE_PATH = path.join(__dirname, '../dnd_data_bundle');
const MIGRATIONS_PATH = path.join(__dirname, '../infrastructure/db');

function parseChallengeRating(value: any): number | null {
  if (value === null || value === undefined) {
    return null;
  }

  if (typeof value === 'number') {
    return value;
  }

  if (typeof value === 'string') {
    const trimmed = value.trim();
    if (trimmed.includes('/')) {
      const [num, den] = trimmed.split('/');
      const numerator = Number(num);
      const denominator = Number(den);
      if (!Number.isNaN(numerator) && !Number.isNaN(denominator) && denominator !== 0) {
        return numerator / denominator;
      }
      return null;
    }

    const direct = Number(trimmed);
    return Number.isNaN(direct) ? null : direct;
  }

  if (typeof value === 'object' && value.cr !== undefined) {
    return parseChallengeRating(value.cr);
  }

  return null;
}

function parseArmorClass(value: any): number | null {
  if (typeof value === 'number') {
    return value;
  }

  if (Array.isArray(value) && value.length > 0) {
    const first = value[0];
    if (typeof first === 'number') {
      return first;
    }
    if (first && typeof first.ac === 'number') {
      return first.ac;
    }
  }

  return null;
}

function normalizeCreatureType(value: any): string | null {
  if (typeof value === 'string') {
    return value;
  }

  if (value && typeof value.type === 'string') {
    return value.type;
  }

  return null;
}

// ─────────────────────────────────────────────────────────────────────────────
// Utility Functions
// ─────────────────────────────────────────────────────────────────────────────

async function log(message: string, type: 'info' | 'success' | 'error' | 'warning' = 'info') {
  const timestamp = new Date().toISOString();
  const prefix = {
    info: '📋',
    success: '✅',
    error: '❌',
    warning: '⚠️',
  }[type];
  console.log(`${prefix} [${timestamp}] ${message}`);
}

async function connectToDatabase(): Promise<pg.Client> {
  try {
    const client = new Client(DB_CONFIG);
    await client.connect();
    await log(`Connected to database: ${DB_CONFIG.database}@${DB_CONFIG.host}`, 'success');
    return client;
  } catch (error) {
    await log(`Failed to connect to database: ${error.message}`, 'error');
    throw error;
  }
}

async function runMigrations(client: pg.Client): Promise<void> {
  await log('Running database migrations...', 'info');

  // Read all SQL migration files in order
  const migrationFiles = fs.readdirSync(MIGRATIONS_PATH)
    .filter(f => f.endsWith('.sql'))
    .sort();

  if (migrationFiles.length === 0) {
    await log('No migration files found', 'warning');
    return;
  }

  for (const file of migrationFiles) {
    const filePath = path.join(MIGRATIONS_PATH, file);
    const sql = fs.readFileSync(filePath, 'utf8');

    try {
      await client.query(sql);
      await log(`Executed migration: ${file}`, 'success');
    } catch (error) {
      await log(`Error executing migration ${file}: ${error.message}`, 'error');
      throw error;
    }
  }
}

async function getDataStatus(client: pg.Client): Promise<Record<string, any>> {
  try {
    const result = await client.query('SELECT data_type, item_count, loaded_at FROM dnd_data_status');
    const status: Record<string, any> = {};
    result.rows.forEach(row => {
      status[row.data_type] = { itemCount: row.item_count, loadedAt: row.loaded_at };
    });
    return status;
  } catch (error) {
    await log(`Could not fetch data status: ${error.message}`, 'warning');
    return {};
  }
}

async function shouldLoadData(client: pg.Client): Promise<boolean> {
  if (FORCE_RELOAD) {
    await log('Force reload flag detected, will truncate and reload all data', 'warning');
    return true;
  }

  const status = await getDataStatus(client);
  const totalLoaded = Object.values(status as any).reduce((sum, item: any) => sum + (item.itemCount || 0), 0);

  if (totalLoaded === 0) {
    await log('No DnD data found in database, will load', 'info');
    return true;
  }

  await log(`Existing data found (${totalLoaded} items loaded). Use --force flag to reload`, 'info');
  return false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Data Loading Functions
// ─────────────────────────────────────────────────────────────────────────────

async function truncateTables(client: pg.Client): Promise<void> {
  const tables = [
    'dnd_races',
    'dnd_backgrounds',
    'dnd_classes',
    'dnd_feats',
    'dnd_spells',
    'dnd_items',
    'dnd_bestiary',
    'dnd_conditions',
  ];

  await log('Truncating DnD data tables...', 'info');
  for (const table of tables) {
    await client.query(`TRUNCATE TABLE ${table}`);
  }
  await log('Tables truncated', 'success');
}

async function loadRaces(client: pg.Client): Promise<number> {
  const filePath = path.join(DATA_BUNDLE_PATH, 'races.json');
  if (!fs.existsSync(filePath)) {
    await log('Races file not found, skipping', 'warning');
    return 0;
  }

  const data = JSON.parse(fs.readFileSync(filePath, 'utf8'));
  const races = data.race || [];
  let loaded = 0;

  for (const race of races) {
    try {
      await client.query(
        `INSERT INTO dnd_races (name, source, edition, description, ability_bonuses, data)
         VALUES ($1, $2, $3, $4, $5, $6)
         ON CONFLICT (name) DO UPDATE SET updated_at = NOW()`,
        [
          race.name,
          race.source || null,
          race.edition || null,
          race.description?.[0] || null,
          JSON.stringify(race.ability || {}),
          JSON.stringify(race),
        ]
      );
      loaded++;
    } catch (error) {
      await log(`Error loading race "${race.name}": ${error.message}`, 'warning');
    }
  }

  await client.query(`UPDATE dnd_data_status SET item_count = $1, updated_at = NOW() WHERE data_type = 'races'`, [loaded]);
  await log(`Loaded ${loaded} races`, 'success');
  return loaded;
}

async function loadBackgrounds(client: pg.Client): Promise<number> {
  const filePath = path.join(DATA_BUNDLE_PATH, 'backgrounds.json');
  if (!fs.existsSync(filePath)) {
    await log('Backgrounds file not found, skipping', 'warning');
    return 0;
  }

  const data = JSON.parse(fs.readFileSync(filePath, 'utf8'));
  const backgrounds = data.background || [];
  let loaded = 0;

  for (const bg of backgrounds) {
    try {
      await client.query(
        `INSERT INTO dnd_backgrounds (name, source, edition, description, ability_bonuses, data)
         VALUES ($1, $2, $3, $4, $5, $6)
         ON CONFLICT (name) DO UPDATE SET updated_at = NOW()`,
        [
          bg.name,
          bg.source || null,
          bg.edition || null,
          null,
          JSON.stringify(bg.ability || {}),
          JSON.stringify(bg),
        ]
      );
      loaded++;
    } catch (error) {
      await log(`Error loading background "${bg.name}": ${error.message}`, 'warning');
    }
  }

  await client.query(`UPDATE dnd_data_status SET item_count = $1, updated_at = NOW() WHERE data_type = 'backgrounds'`, [loaded]);
  await log(`Loaded ${loaded} backgrounds`, 'success');
  return loaded;
}

async function loadClasses(client: pg.Client): Promise<number> {
  const classDir = path.join(DATA_BUNDLE_PATH, 'class');
  if (!fs.existsSync(classDir)) {
    await log('Classes directory not found, skipping', 'warning');
    return 0;
  }

  const files = fs.readdirSync(classDir).filter(f => f.endsWith('.json'));
  let loaded = 0;

  for (const file of files) {
    const filePath = path.join(classDir, file);
    const data = JSON.parse(fs.readFileSync(filePath, 'utf8'));
    const classes = data.class || [];

    for (const cls of classes) {
      try {
        await client.query(
          `INSERT INTO dnd_classes (name, source, edition, description, hit_die, data)
           VALUES ($1, $2, $3, $4, $5, $6)
           ON CONFLICT (name) DO UPDATE SET updated_at = NOW()`,
          [
            cls.name,
            cls.source || null,
            cls.edition || null,
            cls.description?.[0] || null,
            cls.hd?.faces || null,
            JSON.stringify(cls),
          ]
        );
        loaded++;
      } catch (error) {
        await log(`Error loading class "${cls.name}": ${error.message}`, 'warning');
      }
    }
  }

  await client.query(`UPDATE dnd_data_status SET item_count = $1, updated_at = NOW() WHERE data_type = 'classes'`, [loaded]);
  await log(`Loaded ${loaded} classes`, 'success');
  return loaded;
}

async function loadFeats(client: pg.Client): Promise<number> {
  const filePath = path.join(DATA_BUNDLE_PATH, 'feats.json');
  if (!fs.existsSync(filePath)) {
    await log('Feats file not found, skipping', 'warning');
    return 0;
  }

  const data = JSON.parse(fs.readFileSync(filePath, 'utf8'));
  const feats = data.feat || [];
  let loaded = 0;

  for (const feat of feats) {
    try {
      await client.query(
        `INSERT INTO dnd_feats (name, source, edition, description, prerequisite, data)
         VALUES ($1, $2, $3, $4, $5, $6)
         ON CONFLICT (name) DO UPDATE SET updated_at = NOW()`,
        [
          feat.name,
          feat.source || null,
          feat.edition || null,
          feat.description?.[0] || null,
          feat.prerequisite?.[0]?.text || null,
          JSON.stringify(feat),
        ]
      );
      loaded++;
    } catch (error) {
      await log(`Error loading feat "${feat.name}": ${error.message}`, 'warning');
    }
  }

  await client.query(`UPDATE dnd_data_status SET item_count = $1, updated_at = NOW() WHERE data_type = 'feats'`, [loaded]);
  await log(`Loaded ${loaded} feats`, 'success');
  return loaded;
}

async function loadSpells(client: pg.Client): Promise<number> {
  const spellsDir = path.join(DATA_BUNDLE_PATH, 'spells');
  if (!fs.existsSync(spellsDir)) {
    await log('Spells directory not found, skipping', 'warning');
    return 0;
  }

  const files = fs.readdirSync(spellsDir).filter(f => f.endsWith('.json'));
  let loaded = 0;

  for (const file of files) {
    const filePath = path.join(spellsDir, file);
    const data = JSON.parse(fs.readFileSync(filePath, 'utf8'));
    const spells = data.spell || [];

    for (const spell of spells) {
      try {
        await client.query(
          `INSERT INTO dnd_spells (name, source, edition, level, school, casting_time, duration, range_text, components, description, data)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
           ON CONFLICT (name) DO UPDATE SET updated_at = NOW()`,
          [
            spell.name,
            spell.source || null,
            spell.edition || null,
            spell.level || 0,
            spell.school || null,
            spell.time?.[0]?.number + ' ' + spell.time?.[0]?.unit || null,
            spell.duration?.[0]?.type || null,
            spell.range?.distance?.type || spell.range?.type || null,
            JSON.stringify(spell.components || {}),
            spell.description?.[0] || null,
            JSON.stringify(spell),
          ]
        );
        loaded++;
      } catch (error) {
        await log(`Error loading spell "${spell.name}": ${error.message}`, 'warning');
      }
    }
  }

  await client.query(`UPDATE dnd_data_status SET item_count = $1, updated_at = NOW() WHERE data_type = 'spells'`, [loaded]);
  await log(`Loaded ${loaded} spells`, 'success');
  return loaded;
}

async function loadItems(client: pg.Client): Promise<number> {
  const itemsDir = path.join(DATA_BUNDLE_PATH, 'items');
  if (!fs.existsSync(itemsDir)) {
    await log('Items directory not found, skipping', 'warning');
    return 0;
  }

  const files = fs.readdirSync(itemsDir).filter(f => f.endsWith('.json'));
  let loaded = 0;

  for (const file of files) {
    const filePath = path.join(itemsDir, file);
    const data = JSON.parse(fs.readFileSync(filePath, 'utf8'));
    const items = data.item || [];

    for (const item of items) {
      try {
        await client.query(
          `INSERT INTO dnd_items (name, source, edition, item_type, rarity, description, data)
           VALUES ($1, $2, $3, $4, $5, $6, $7)
           ON CONFLICT (name) DO UPDATE SET updated_at = NOW()`,
          [
            item.name,
            item.source || null,
            item.edition || null,
            item.type || null,
            item.rarity || null,
            item.description?.[0] || null,
            JSON.stringify(item),
          ]
        );
        loaded++;
      } catch (error) {
        await log(`Error loading item "${item.name}": ${error.message}`, 'warning');
      }
    }
  }

  await client.query(`UPDATE dnd_data_status SET item_count = $1, updated_at = NOW() WHERE data_type = 'items'`, [loaded]);
  await log(`Loaded ${loaded} items`, 'success');
  return loaded;
}

async function loadBestiary(client: pg.Client): Promise<number> {
  const bestiaryDir = path.join(DATA_BUNDLE_PATH, 'bestiary');
  if (!fs.existsSync(bestiaryDir)) {
    await log('Bestiary directory not found, skipping', 'warning');
    return 0;
  }

  const files = fs.readdirSync(bestiaryDir).filter(f => f.endsWith('.json'));
  let loaded = 0;

  for (const file of files) {
    const filePath = path.join(bestiaryDir, file);
    const data = JSON.parse(fs.readFileSync(filePath, 'utf8'));
    const creatures = data.monster || [];

    for (const creature of creatures) {
      try {
        const challengeRating = parseChallengeRating(creature.cr);
        const creatureType = normalizeCreatureType(creature.type);
        const armorClass = parseArmorClass(creature.ac);

        await client.query(
          `INSERT INTO dnd_bestiary (name, source, edition, creature_type, description, challenge_rating, armor_class, hit_points, ability_scores, data)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
           ON CONFLICT (name, source) DO UPDATE SET updated_at = NOW()`,
          [
            creature.name,
            creature.source || null,
            creature.edition || null,
            creatureType,
            creature.description?.[0] || null,
            challengeRating,
            armorClass,
            creature.hp?.average || null,
            JSON.stringify(creature.ability || {}),
            JSON.stringify(creature),
          ]
        );
        loaded++;
      } catch (error) {
        await log(`Error loading creature "${creature.name}": ${error.message}`, 'warning');
      }
    }
  }

  await client.query(`UPDATE dnd_data_status SET item_count = $1, updated_at = NOW() WHERE data_type = 'bestiary'`, [loaded]);
  await log(`Loaded ${loaded} bestiary creatures`, 'success');
  return loaded;
}

async function loadConditions(client: pg.Client): Promise<number> {
  const filePath = path.join(DATA_BUNDLE_PATH, 'conditionsdiseases.json');
  if (!fs.existsSync(filePath)) {
    await log('Conditions file not found, skipping', 'warning');
    return 0;
  }

  const data = JSON.parse(fs.readFileSync(filePath, 'utf8'));
  const conditions = data.condition || [];
  let loaded = 0;

  for (const condition of conditions) {
    try {
      await client.query(
        `INSERT INTO dnd_conditions (name, source, edition, description, data)
         VALUES ($1, $2, $3, $4, $5)
         ON CONFLICT (name) DO UPDATE SET updated_at = NOW()`,
        [
          condition.name,
          condition.source || null,
          condition.edition || null,
          condition.description?.[0] || null,
          JSON.stringify(condition),
        ]
      );
      loaded++;
    } catch (error) {
      await log(`Error loading condition "${condition.name}": ${error.message}`, 'warning');
    }
  }

  await client.query(`UPDATE dnd_data_status SET item_count = $1, updated_at = NOW() WHERE data_type = 'conditions'`, [loaded]);
  await log(`Loaded ${loaded} conditions`, 'success');
  return loaded;
}

// ─────────────────────────────────────────────────────────────────────────────
// Main Function
// ─────────────────────────────────────────────────────────────────────────────

async function main(): Promise<void> {
  console.log('\n🚀 DnD Campaign Manager - Database Initialization\n');

  let client: pg.Client | null = null;

  try {
    // 1. Connect to database
    client = await connectToDatabase();

    // 2. Run migrations (create tables if needed)
    await runMigrations(client);

    // 3. Check if we should load data
    const shouldLoad = await shouldLoadData(client);

    if (shouldLoad) {
      if (FORCE_RELOAD) {
        await truncateTables(client);
      }

      // 4. Load all DnD data
      await log('\nLoading DnD data...', 'info');
      const stats = {
        races: await loadRaces(client),
        backgrounds: await loadBackgrounds(client),
        classes: await loadClasses(client),
        feats: await loadFeats(client),
        spells: await loadSpells(client),
        items: await loadItems(client),
        bestiary: await loadBestiary(client),
        conditions: await loadConditions(client),
      };

      const totalLoaded = Object.values(stats).reduce((a, b) => a + b, 0);
      await log(`\n✨ Successfully loaded ${totalLoaded} total items!`, 'success');
    }

    await log('\n✅ Database initialization complete!\n', 'success');
  } catch (error) {
    await log(`\n❌ Fatal error: ${error.message}`, 'error');
    process.exit(1);
  } finally {
    if (client) {
      await client.end();
    }
  }
}

main();
