import fs from 'fs';
import path from 'path';
import { Client } from 'pg';

const PGHOST = process.env.PGHOST || process.env.POSTGRES_HOST || 'localhost';
const PGPORT = parseInt(process.env.PGPORT || process.env.POSTGRES_PORT || '5432', 10);
const PGDB = process.env.PGDATABASE || process.env.POSTGRES_DB || 'dnd_campaigns';
const PGUSER = process.env.PGUSER || process.env.POSTGRES_USER || 'dnd_admin';
const PGPASS = process.env.PGPASSWORD || process.env.POSTGRES_PASSWORD || 'localdev_secret';
const BUNDLE = process.env.BUNDLE_PATH || '/tmp/dnd_data_bundle/items/items-base.json';

const client = new Client({ host: PGHOST, port: PGPORT, database: PGDB, user: PGUSER, password: PGPASS });

async function main() {
  await client.connect();
  console.log('Connecting to', PGHOST, PGPORT, PGDB);
  const raw = fs.readFileSync(BUNDLE, 'utf-8');
  const data = JSON.parse(raw);
  const items = data.item || data.baseitem || [];
  console.log('Baseitems to check:', items.length);
  let inserted = 0;
  for (const it of items) {
    const name = it.name;
    if (!name) continue;
    const res = await client.query('SELECT id FROM dnd_items WHERE name = $1', [name]);
    if (res.rowCount) continue;
    const source = it.source;
    const edition = it.edition;
    const item_type = it.type || it.item_type;
    const rarity = it.rarity;
    const description = it.entries || it.additionalEntries || [];
    const weight = it.weight;
    const value = it.value;
    let cost: string | null = null;
    if (value != null) { try { cost = `${Number(value) / 100} gp`; } catch { cost = String(value); } }
    const properties = it.property || it.properties || [];
    let damage = null;
    if (it.dmg1 || it.dmgType) damage = { damage1: it.dmg1, damageType: it.dmgType };
    const ac = it.ac;
    const req_att = Boolean(it.reqAttune || it.requires_attunement);
    const curse = it.curse;
    try {
      await client.query(
        `INSERT INTO dnd_items (name, source, edition, item_type, rarity, description, weight, cost, properties, damage, ac_bonus, requires_attunement, curse)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13)`,
        [name, source, edition, item_type, rarity, JSON.stringify(description), weight, cost, JSON.stringify(properties), JSON.stringify(damage), ac, req_att, curse]
      );
      inserted += 1;
    } catch (e) {
      console.error('Insert error for', name, e);
    }
  }
  console.log('Inserted baseitems:', inserted);
  await client.end();
}

main().catch(err => { console.error(err); process.exit(1); });
