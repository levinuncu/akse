-- ══════════════════════════════════════════════════════════════════
-- DnD Data - PostgreSQL Schema (Backgrounds, Races, Classes, etc.)
-- ══════════════════════════════════════════════════════════════════

-- ── Races ────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS dnd_races (
  id              SERIAL PRIMARY KEY,
  name            VARCHAR(255) NOT NULL UNIQUE,
  source          VARCHAR(50),
  edition         VARCHAR(10),
  description     TEXT,
  ability_bonuses JSONB,
  speed           INT DEFAULT 30,
  languages       JSONB,
  traits          JSONB,
  subraces        JSONB,
  data            JSONB,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_dnd_races_name ON dnd_races(name);

-- ── Backgrounds ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS dnd_backgrounds (
  id              SERIAL PRIMARY KEY,
  name            VARCHAR(255) NOT NULL UNIQUE,
  source          VARCHAR(50),
  edition         VARCHAR(10),
  description     TEXT,
  ability_bonuses JSONB,
  skills          JSONB,
  tools           JSONB,
  languages       JSONB,
  feats           JSONB,
  traits          JSONB,
  data            JSONB,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_dnd_backgrounds_name ON dnd_backgrounds(name);

-- ── Classes ──────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS dnd_classes (
  id              SERIAL PRIMARY KEY,
  name            VARCHAR(255) NOT NULL UNIQUE,
  source          VARCHAR(50),
  edition         VARCHAR(10),
  description     TEXT,
  hit_die         INT,
  proficiencies   JSONB,
  saving_throws   JSONB,
  starting_equipment JSONB,
  class_features  JSONB,
  subclasses      JSONB,
  spellcasting    JSONB,
  data            JSONB,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_dnd_classes_name ON dnd_classes(name);

-- ── Feats ────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS dnd_feats (
  id              SERIAL PRIMARY KEY,
  name            VARCHAR(255) NOT NULL UNIQUE,
  source          VARCHAR(50),
  edition         VARCHAR(10),
  description     TEXT,
  prerequisite    VARCHAR(255),
  ability_prerequisite JSONB,
  benefits        JSONB,
  data            JSONB,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_dnd_feats_name ON dnd_feats(name);

-- ── Spells ──────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS dnd_spells (
  id              SERIAL PRIMARY KEY,
  name            VARCHAR(255) NOT NULL UNIQUE,
  source          VARCHAR(50),
  edition         VARCHAR(10),
  level           INT,
  school          VARCHAR(50),
  casting_time    VARCHAR(100),
  duration        VARCHAR(100),
  range_text      VARCHAR(100),
  components      JSONB,
  description     TEXT,
  higher_levels   TEXT,
  classes         JSONB,
  subclasses      JSONB,
  ritual           BOOLEAN DEFAULT FALSE,
  concentration   BOOLEAN DEFAULT FALSE,
  data            JSONB,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_dnd_spells_name ON dnd_spells(name);
CREATE INDEX IF NOT EXISTS idx_dnd_spells_level ON dnd_spells(level);
CREATE INDEX IF NOT EXISTS idx_dnd_spells_school ON dnd_spells(school);

-- ── Items ────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS dnd_items (
  id              SERIAL PRIMARY KEY,
  name            VARCHAR(255) NOT NULL UNIQUE,
  source          VARCHAR(50),
  edition         VARCHAR(10),
  item_type       VARCHAR(100),
  rarity          VARCHAR(50),
  description     TEXT,
  weight          DECIMAL(10, 2),
  cost            VARCHAR(100),
  properties      JSONB,
  damage          JSONB,
  ac_bonus        INT,
  requires_attunement BOOLEAN DEFAULT FALSE,
  curse           VARCHAR(255),
  data            JSONB,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_dnd_items_name ON dnd_items(name);
CREATE INDEX IF NOT EXISTS idx_dnd_items_type ON dnd_items(item_type);
CREATE INDEX IF NOT EXISTS idx_dnd_items_rarity ON dnd_items(rarity);

-- ── Bestiary (Monsters/NPCs) ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS dnd_bestiary (
  id              SERIAL PRIMARY KEY,
  name            VARCHAR(255) NOT NULL,
  source          VARCHAR(50),
  edition         VARCHAR(10),
  creature_type   VARCHAR(100),
  description     TEXT,
  challenge_rating DECIMAL(5, 2),
  experience      INT,
  armor_class     INT,
  hit_points      INT,
  hit_dice        VARCHAR(50),
  ability_scores  JSONB,
  saving_throws   JSONB,
  skills          JSONB,
  damage_immunities JSONB,
  condition_immunities JSONB,
  senses          JSONB,
  languages       VARCHAR(255),
  traits          JSONB,
  actions         JSONB,
  reactions       JSONB,
  legendary_actions JSONB,
  spells          JSONB,
  data            JSONB,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (name, source)
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_dnd_bestiary_name_source ON dnd_bestiary(name, source);
CREATE INDEX IF NOT EXISTS idx_dnd_bestiary_name ON dnd_bestiary(name);
CREATE INDEX IF NOT EXISTS idx_dnd_bestiary_cr ON dnd_bestiary(challenge_rating);
CREATE INDEX IF NOT EXISTS idx_dnd_bestiary_type ON dnd_bestiary(creature_type);

-- ── Conditions/Diseases ──────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS dnd_conditions (
  id              SERIAL PRIMARY KEY,
  name            VARCHAR(255) NOT NULL UNIQUE,
  source          VARCHAR(50),
  edition         VARCHAR(10),
  description     TEXT,
  effects         JSONB,
  save_dc         INT,
  save_ability    VARCHAR(10),
  data            JSONB,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_dnd_conditions_name ON dnd_conditions(name);

-- ── Data Load Status (tracks which bundles have been loaded) ──────────────────
CREATE TABLE IF NOT EXISTS dnd_data_status (
  id              SERIAL PRIMARY KEY,
  data_type       VARCHAR(50) NOT NULL UNIQUE,
  loaded_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  item_count      INT DEFAULT 0,
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Seed initial status (these will be updated when data is loaded)
INSERT INTO dnd_data_status (data_type, item_count) VALUES
  ('races', 0),
  ('backgrounds', 0),
  ('classes', 0),
  ('feats', 0),
  ('spells', 0),
  ('items', 0),
  ('bestiary', 0),
  ('conditions', 0)
ON CONFLICT (data_type) DO NOTHING;
