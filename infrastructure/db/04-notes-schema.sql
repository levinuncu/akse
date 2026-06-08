-- ══════════════════════════════════════════════════════════════════
-- Character Notes Table
-- ══════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS character_notes (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  character_id  UUID NOT NULL REFERENCES character_sheets(id) ON DELETE CASCADE,
  title         VARCHAR(255) NOT NULL DEFAULT 'Untitled',
  content       TEXT NOT NULL DEFAULT '',
  sort_order    INT NOT NULL DEFAULT 0,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_character_notes_character_id ON character_notes(character_id);
CREATE INDEX IF NOT EXISTS idx_character_notes_sort_order ON character_notes(sort_order);
