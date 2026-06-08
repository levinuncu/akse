import { Client } from 'pg';

const DB_HOST = process.env.POSTGRES_HOST || 'localhost';
const DB_PORT = parseInt(process.env.POSTGRES_PORT || '5432', 10);
const DB_NAME = process.env.POSTGRES_DB || 'dnd_campaigns';
const DB_USER = process.env.POSTGRES_USER || 'dnd_admin';
const DB_PASS = process.env.POSTGRES_PASSWORD || 'localdev_secret';

const client = new Client({ host: DB_HOST, port: DB_PORT, database: DB_NAME, user: DB_USER, password: DB_PASS });

const XPHB_FEATS = [
  { name: 'Actor', source: 'XPHB' },
  { name: 'Athlete', source: 'XPHB' },
  { name: 'Charger', source: 'XPHB' },
  { name: 'Chef', source: 'XPHB' },
  { name: 'Crossbow Expert', source: 'XPHB' },
  { name: 'Crusher', source: 'XPHB' },
  { name: 'Defensive Duelist', source: 'XPHB' },
  { name: 'Dual Wielder', source: 'XPHB' },
  { name: 'Durable', source: 'XPHB' },
  { name: 'Elemental Adept', source: 'XPHB' },
  { name: 'Grappler', source: 'XPHB' },
  { name: 'Great Weapon Master', source: 'XPHB' },
  { name: 'Heavily Armored', source: 'XPHB' },
  { name: 'Heavy Armor Master', source: 'XPHB' },
  { name: 'Inspiring Leader', source: 'XPHB' },
  { name: 'Keen Mind', source: 'XPHB' },
  { name: 'Lightly Armored', source: 'XPHB' },
  { name: 'Mage Slayer', source: 'XPHB' },
  { name: 'Medium Armor Master', source: 'XPHB' },
  { name: 'Moderately Armored', source: 'XPHB' },
  { name: 'Mounted Combatant', source: 'XPHB' },
  { name: 'Observant', source: 'XPHB' },
  { name: 'Piercer', source: 'XPHB' },
  { name: 'Poisoner', source: 'XPHB' },
  { name: 'Polearm Master', source: 'XPHB' },
  { name: 'Resilient', source: 'XPHB' },
  { name: 'Ritual Caster', source: 'XPHB' },
  { name: 'Sentinel', source: 'XPHB' },
  { name: 'Sharpshooter', source: 'XPHB' },
  { name: 'Shield Master', source: 'XPHB' },
  { name: 'Skill Expert', source: 'XPHB' },
  { name: 'Skulker', source: 'XPHB' },
  { name: 'Slasher', source: 'XPHB' },
  { name: 'Spell Sniper', source: 'XPHB' },
  { name: 'Telekinetic', source: 'XPHB' },
  { name: 'Telepathic', source: 'XPHB' },
  { name: 'War Caster', source: 'XPHB' },
  { name: 'Weapon Master', source: 'XPHB' },
];

async function main() {
  await client.connect();
  console.log('Connected to', DB_HOST);

  const existing = await client.query('SELECT name, source FROM dnd_feats WHERE source = $1', ['XPHB']);
  const existingSet = new Set(existing.rows.map(r => r.name));

  let inserted = 0;
  for (const feat of XPHB_FEATS) {
    if (existingSet.has(feat.name)) {
      console.log(`Skipping ${feat.name} (${feat.source}) — already exists`);
      continue;
    }
    await client.query(
      `INSERT INTO dnd_feats (name, source, edition, description)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (name) DO NOTHING`,
      [feat.name, feat.source, '2024', JSON.stringify([{ type: 'entries', name: feat.name, entries: ['See 5e.tools for details.'] }])]
    );
    console.log(`Inserted ${feat.name} (${feat.source})`);
    inserted++;
  }

  console.log(`Done. Inserted: ${inserted}`);
  await client.end();
}

main().catch(err => { console.error(err); process.exit(1); });
