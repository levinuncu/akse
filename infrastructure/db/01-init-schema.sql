-- ══════════════════════════════════════════════════════════════════
-- DnD Campaign Manager - PostgreSQL Initialization Schema
-- ══════════════════════════════════════════════════════════════════

-- ── Extensions ─────────────────────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- for fuzzy search on 5e data

-- ── Users ──────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  keycloak_id   VARCHAR(36) UNIQUE NOT NULL,
  username      VARCHAR(100) NOT NULL,
  email         VARCHAR(255) UNIQUE NOT NULL,
  display_name  VARCHAR(255),
  avatar_url    TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_users_keycloak_id ON users(keycloak_id);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- ── Campaigns ──────────────────────────────────────────────────────────────
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'campaign_status') THEN
    CREATE TYPE campaign_status AS ENUM ('draft', 'active', 'paused', 'completed', 'archived');
  END IF;
END
$$;

CREATE TABLE IF NOT EXISTS campaigns (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  owner_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name          VARCHAR(255) NOT NULL,
  description   TEXT,
  setting       VARCHAR(255),
  invite_code   VARCHAR(20) UNIQUE NOT NULL DEFAULT UPPER(SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 8)),
  status        campaign_status NOT NULL DEFAULT 'draft',
  max_players   INT NOT NULL DEFAULT 6,
  banner_url    TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_campaigns_owner_id ON campaigns(owner_id);
CREATE INDEX IF NOT EXISTS idx_campaigns_invite_code ON campaigns(invite_code);
CREATE INDEX IF NOT EXISTS idx_campaigns_status ON campaigns(status);

-- ── Campaign Members ────────────────────────────────────────────────────────
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'member_role') THEN
    CREATE TYPE member_role AS ENUM ('dm', 'player', 'spectator');
  END IF;
END
$$;

CREATE TABLE IF NOT EXISTS campaign_members (
  campaign_id   UUID NOT NULL REFERENCES campaigns(id) ON DELETE CASCADE,
  user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role          member_role NOT NULL DEFAULT 'player',
  joined_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (campaign_id, user_id)
);
CREATE INDEX IF NOT EXISTS idx_campaign_members_user_id ON campaign_members(user_id);

-- ── Sessions ───────────────────────────────────────────────────────────────
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'session_status') THEN
    CREATE TYPE session_status AS ENUM ('active', 'ended');
  END IF;
END
$$;

CREATE TABLE IF NOT EXISTS sessions (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  campaign_id   UUID NOT NULL REFERENCES campaigns(id) ON DELETE CASCADE,
  name          VARCHAR(255),
  status        session_status NOT NULL DEFAULT 'active',
  notes         TEXT,
  started_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ended_at      TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_sessions_campaign_id ON sessions(campaign_id);

-- ── Character Sheets ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS character_sheets (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  campaign_id     UUID NOT NULL REFERENCES campaigns(id) ON DELETE CASCADE,
  player_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  character_name  VARCHAR(255) NOT NULL,
  -- Core stats stored as structured JSONB for flexibility
  ability_scores  JSONB NOT NULL DEFAULT '{"strength": 10, "dexterity": 10, "constitution": 10, "intelligence": 10, "wisdom": 10, "charisma": 10}',
  saving_throws   JSONB NOT NULL DEFAULT '{}',
  skills          JSONB NOT NULL DEFAULT '{}',
  -- Combat
  current_hp      INT NOT NULL DEFAULT 1,
  max_hp          INT NOT NULL DEFAULT 1,
  temp_hp         INT NOT NULL DEFAULT 0,
  armor_class     INT NOT NULL DEFAULT 10,
  initiative_bonus INT NOT NULL DEFAULT 0,
  speed           INT NOT NULL DEFAULT 30,
  -- Character info
  level           INT NOT NULL DEFAULT 1 CHECK (level BETWEEN 1 AND 20),
  experience_points BIGINT NOT NULL DEFAULT 0,
  class           JSONB NOT NULL DEFAULT '[]', -- supports multiclass
  race            VARCHAR(100),
  subrace         VARCHAR(100),
  background      VARCHAR(100),
  alignment       VARCHAR(50),
  backstory       TEXT,
  -- Resources
  hit_dice        JSONB NOT NULL DEFAULT '{}',
  death_saves     JSONB NOT NULL DEFAULT '{"successes": 0, "failures": 0}',
  spell_slots     JSONB NOT NULL DEFAULT '{}',
  -- Inventory & spells
  inventory       JSONB NOT NULL DEFAULT '[]',
  spells_known    JSONB NOT NULL DEFAULT '[]',
  features        JSONB NOT NULL DEFAULT '[]',
  -- Conditions
  conditions      JSONB NOT NULL DEFAULT '[]',
  -- Proficiencies
  proficiency_bonus INT NOT NULL DEFAULT 2,
  proficiencies   JSONB NOT NULL DEFAULT '{}',
  -- Inspiration
  has_inspiration BOOLEAN NOT NULL DEFAULT FALSE,
  -- Meta
  avatar_url      TEXT,
  notes           TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (campaign_id, player_id)
);
CREATE INDEX IF NOT EXISTS idx_character_sheets_campaign_id ON character_sheets(campaign_id);
CREATE INDEX IF NOT EXISTS idx_character_sheets_player_id ON character_sheets(player_id);

-- ── Roll History ────────────────────────────────────────────────────────────
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'roll_type') THEN
    CREATE TYPE roll_type AS ENUM (
      'attackRoll', 'skillCheck', 'savingThrow', 'initiative',
      'damageRoll', 'deathSave', 'custom'
    );
  END IF;
END
$$;

CREATE TABLE IF NOT EXISTS roll_history (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  campaign_id     UUID NOT NULL REFERENCES campaigns(id) ON DELETE CASCADE,
  session_id      UUID REFERENCES sessions(id),
  character_id    UUID REFERENCES character_sheets(id),
  rolled_by       UUID NOT NULL REFERENCES users(id),
  expression      VARCHAR(100) NOT NULL,
  individual_dice JSONB NOT NULL,
  modifier        INT NOT NULL DEFAULT 0,
  total           INT NOT NULL,
  roll_type       roll_type NOT NULL DEFAULT 'custom',
  context_note    VARCHAR(255),
  is_critical_hit   BOOLEAN,
  is_critical_fail  BOOLEAN,
  rolled_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_roll_history_campaign_id ON roll_history(campaign_id);
CREATE INDEX IF NOT EXISTS idx_roll_history_session_id ON roll_history(session_id);

-- ── Initiative Tracker ──────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS initiative_tracker (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  session_id    UUID NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
  campaign_id   UUID NOT NULL REFERENCES campaigns(id) ON DELETE CASCADE,
  character_id  UUID REFERENCES character_sheets(id),
  name          VARCHAR(255) NOT NULL,
  initiative    INT NOT NULL,
  is_player     BOOLEAN NOT NULL DEFAULT TRUE,
  current_hp    INT,
  max_hp        INT,
  conditions    JSONB NOT NULL DEFAULT '[]',
  sort_order    INT NOT NULL DEFAULT 0,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_initiative_session_id ON initiative_tracker(session_id);
