import fs from 'fs';
import path from 'path';
import glob from 'glob';
import { Client } from 'pg';

const DB_HOST = process.env.POSTGRES_HOST || 'localhost';
const DB_PORT = parseInt(process.env.POSTGRES_PORT || '5432', 10);
const DB_NAME = process.env.POSTGRES_DB || 'dnd_campaigns';
const DB_USER = process.env.POSTGRES_USER || 'dnd_admin';
const DB_PASS = process.env.POSTGRES_PASSWORD || 'localdev_secret';
const DATA_PATH = process.env.DND_BUNDLE_PATH || '/tmp/dnd_data_bundle';

const client = new Client({ host: DB_HOST, port: DB_PORT, database: DB_NAME, user: DB_USER, password: DB_PASS });

async function loadItems() {
  const itemsDir = path.join(DATA_PATH, 'items');
  if (!fs.existsSync(itemsDir)) {
    console.log('Items directory not found, skipping');
    return 0;
  }
  const files = glob.sync(path.join(itemsDir, '*.json'));
  let loaded = 0;
  for (const f of files) {
    console.log('Loading', f);
    const raw = fs.readFileSync(f, 'utf-8');
    const data = JSON.parse(raw);
    const items = data.item || data.baseitem || [];
    for (const item of items) {
      try {
        const name = item.name;
        const source = item.source;
        const edition = item.edition;
        const item_type = item.type || item.item_type;
        const rarity = item.rarity;
        const description = item.entries || item.entry || [];
        const weight = item.weight;
        const value = item.value;
        let cost: string | null = null;
        if (value != null) {
          try { cost = `${Number(value) / 100} gp`; } catch { cost = String(value); }
        }
        const properties = item.property || item.properties || [];
        const damage: any = {};
        if (item.dmg1 || item.dmgType) damage.damage1 = item.dmg1, damage.damageType = item.dmgType;
        const ac = item.ac;
        const req_att = Boolean(item.reqAttune || item.requires_attunement);
        const curse = item.curse ? 'Cursed' : null;
        await client.query(
          `INSERT INTO dnd_items (name, source, edition, item_type, rarity, description, weight, cost, properties, damage, ac_bonus, requires_attunement, curse)
           VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13)
           ON CONFLICT (name) DO UPDATE SET source=EXCLUDED.source, edition=EXCLUDED.edition, item_type=EXCLUDED.item_type, rarity=EXCLUDED.rarity, description=EXCLUDED.description, weight=EXCLUDED.weight, cost=EXCLUDED.cost, properties=EXCLUDED.properties, damage=EXCLUDED.damage, ac_bonus=EXCLUDED.ac_bonus, requires_attunement=EXCLUDED.requires_attunement, curse=EXCLUDED.curse`,
          [name, source, edition, item_type, rarity, JSON.stringify(description), weight, cost, JSON.stringify(properties), JSON.stringify(damage), ac, req_att, curse]
        );
        loaded += 1;
      } catch (err) {
        console.error('Error inserting item', item?.name, err);
      }
    }
  }
  await client.query("UPDATE dnd_data_status SET item_count = $1, updated_at = NOW() WHERE data_type = 'items'", [loaded]);
  console.log('Loaded items:', loaded);
  return loaded;
}

async function loadSpells() {
  const spellsDir = path.join(DATA_PATH, 'spells');
  if (!fs.existsSync(spellsDir)) {
    console.log('Spells directory not found, skipping');
    return 0;
  }
  const files = glob.sync(path.join(spellsDir, '*.json'));
  let loaded = 0;
  for (const f of files) {
    console.log('Loading', f);
    const raw = fs.readFileSync(f, 'utf-8');
    const data = JSON.parse(raw);
    const spells = data.spell || data.spells || [];
    for (const spell of spells) {
      try {
        const name = spell.name;
        const source = spell.source;
        const edition = spell.edition;
        const level = spell.level || 0;
        const school = spell.school;
        const casting_time = (Array.isArray(spell.time) && spell.time[0]) ? `${spell.time[0].number || ''}${spell.time[0].unit || ''}` : null;
        const duration = (Array.isArray(spell.duration) && spell.duration[0]) ? (spell.duration[0].type || null) : null;
        let range_text = null;
        if (spell.range) {
          const rng = spell.range;
          if (typeof rng === 'object' && rng.distance) {
            const distance = rng.distance; range_text = `${distance.amount || ''} ${distance.type || ''}`;
          } else if (typeof rng === 'object') range_text = rng.type || null;
        }
        const components = spell.components || {};
        const concentration = false;
        const ritual = false;
        const classes = spell.classes || [];
        const description = spell.entries || spell.entry || [];
        await client.query(
          `INSERT INTO dnd_spells (name, source, edition, level, school, casting_time, duration, range_text, components, concentration, ritual, classes, description)
           VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13)
           ON CONFLICT (name) DO UPDATE SET source=EXCLUDED.source, edition=EXCLUDED.edition, level=EXCLUDED.level, school=EXCLUDED.school, casting_time=EXCLUDED.casting_time, duration=EXCLUDED.duration, range_text=EXCLUDED.range_text, components=EXCLUDED.components, concentration=EXCLUDED.concentration, ritual=EXCLUDED.ritual, classes=EXCLUDED.classes, description=EXCLUDED.description`,
          [name, source, edition, level, school, casting_time, duration, range_text, JSON.stringify(components), concentration, ritual, JSON.stringify(classes), JSON.stringify(description)]
        );
        loaded += 1;
      } catch (err) {
        console.error('Error inserting spell', spell?.name, err);
      }
    }
  }
  await client.query("UPDATE dnd_data_status SET item_count = $1, updated_at = NOW() WHERE data_type = 'spells'", [loaded]);
  console.log('Loaded spells:', loaded);
  return loaded;
}

async function loadFeats() {
  const featsFile = path.join(DATA_PATH, 'feats.json');
  let files: string[] = [];
  if (fs.existsSync(featsFile)) files = [featsFile];
  else {
    const featsDir = path.join(DATA_PATH, 'feats');
    if (!fs.existsSync(featsDir)) { console.log('Feats not found, skipping'); return 0; }
    files = glob.sync(path.join(featsDir, '*.json'));
  }
  let loaded = 0;
  for (const f of files) {
    console.log('Loading feats from', f);
    const raw = fs.readFileSync(f, 'utf-8');
    const data = JSON.parse(raw);
    const feats = data.feat || data.feats || [];
    for (const feat of feats) {
      try {
        const name = feat.name;
        const source = feat.source;
        const edition = feat.edition;
        const description = feat.entries || [];
        const prerequisite = feat.prerequisite || null;
        const ability_prereq = feat.abilityPrerequisite || feat.ability_prerequisite || null;
        const ability_bonuses = feat.ability_bonuses || null;
        await client.query(
          `INSERT INTO dnd_feats (name, source, edition, description, prerequisite, ability_prerequisite, ability_bonuses)
           VALUES ($1,$2,$3,$4,$5,$6,$7)
           ON CONFLICT (name) DO UPDATE SET source=EXCLUDED.source, edition=EXCLUDED.edition, description=EXCLUDED.description, prerequisite=EXCLUDED.prerequisite, ability_prerequisite=EXCLUDED.ability_prerequisite, ability_bonuses=EXCLUDED.ability_bonuses`,
          [name, source, edition, JSON.stringify(description), prerequisite, ability_prereq ? JSON.stringify(ability_prereq) : null, ability_bonuses ? JSON.stringify(ability_bonuses) : null]
        );
        loaded += 1;
      } catch (err) {
        console.error('Error inserting feat', feat?.name, err);
      }
    }
  }
  await client.query("UPDATE dnd_data_status SET item_count = $1, updated_at = NOW() WHERE data_type = 'feats'", [loaded]);
  console.log('Loaded feats:', loaded);
  return loaded;
}

async function main() {
  await client.connect();
  console.log('Connected to', DB_HOST);
  const items = await loadItems();
  const spells = await loadSpells();
  const feats = await loadFeats();
  console.log('Done. Items:', items, 'Spells:', spells, 'Feats:', feats);
  await client.end();
}

main().catch(err => { console.error(err); process.exit(1); });
