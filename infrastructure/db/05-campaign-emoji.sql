-- Add banner_emoji column to campaigns for user-selectable emoji
ALTER TABLE campaigns ADD COLUMN IF NOT EXISTS banner_emoji VARCHAR(10) NOT NULL DEFAULT '🏔';
