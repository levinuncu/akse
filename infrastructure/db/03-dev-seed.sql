-- Seed script for development environment
-- This creates a test user, campaigns, campaign members, and a character sheet

-- ── Dev User ─────────────────────────────────────────────────────────────────
INSERT INTO users (id, keycloak_id, username, email, display_name)
VALUES ('00000000-0000-0000-0000-000000000001', 'dev-user-123', 'DevWizard', 'dev@example.com', 'The Master Dev')
ON CONFLICT (keycloak_id) DO NOTHING;

-- ── Campaigns ────────────────────────────────────────────────────────────────
INSERT INTO campaigns (id, owner_id, name, description, setting, status, max_players, invite_code)
VALUES
  ('c0000000-0000-0000-0000-000000000001',
   '00000000-0000-0000-0000-000000000001',
   'The Frozen Tundra',
   'A cold adventure in the far north filled with ancient secrets.',
   'Forgotten Realms', 'active', 4, 'TUNDRA01'),
  ('c0000000-0000-0000-0000-000000000002',
   '00000000-0000-0000-0000-000000000001',
   'Trial of the Gods',
   'Epic level 20 one-shot at the gates of Olympus.',
   'Mount Olympus', 'active', 6, 'GODTRL01')
ON CONFLICT (id) DO NOTHING;

-- ── Campaign Members (owner is always DM) ────────────────────────────────────
INSERT INTO campaign_members (campaign_id, user_id, role)
VALUES
  ('c0000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'dm'),
  ('c0000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', 'dm')
ON CONFLICT DO NOTHING;

-- ── Sample Character: Grog Strongjaw ─────────────────────────────────────────
INSERT INTO character_sheets (
    id, campaign_id, player_id, character_name, race, class, level,
    current_hp, max_hp, temp_hp, armor_class, speed, initiative_bonus,
    proficiency_bonus, experience_points,
    ability_scores, saving_throws, skills,
    hit_dice, death_saves, spell_slots,
    personality, attacks, features, inventory, spells_known,
    has_inspiration, spellcasting_info
)
VALUES (
    'd0000000-0000-0000-0000-000000000001',
    'c0000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000001',
    'Grog Strongjaw',
    'Goliath',
    '[{"name": "Barbarian", "level": 5}]',
    5,
    55, 65, 0, 16, 30, 1,
    3, 6500,
    '{"strength": 20, "dexterity": 12, "constitution": 18, "intelligence": 6, "wisdom": 10, "charisma": 8}',
    '{"STR": true, "DEX": false, "CON": true, "INT": false, "WIS": false, "CHA": false}',
    '{"Athletics": true, "Intimidation": true}',
    '{"total": 5, "remaining": 5, "die": "d12"}',
    '{"successes": 0, "failures": 0}',
    '{}',
    '{"traits": "I would rather make a new friend than a new enemy.", "ideals": "Responsibility. I do what I must.", "bonds": "I will one day get revenge on the Herd of Storms.", "flaws": "I am too fond of ale and intoxicants."}',
    '[{"name": "Greatsword", "bonus": "+8", "damage": "2d6+5 S"}, {"name": "Javelin", "bonus": "+8", "damage": "1d6+5 P"}]',
    '[{"name": "Rage", "description": "3/day. Advantage on STR checks and saves. +2 damage."}, {"name": "Unarmored Defense", "description": "AC = 10 + DEX mod + CON mod when not wearing armor."}, {"name": "Reckless Attack", "description": "Advantage on attack rolls, enemies have advantage on you."}, {"name": "Danger Sense", "description": "Advantage on DEX saves against effects you can see."}, {"name": "Frenzy", "description": "Extra attack while raging (Frenzied Rage subclass)."}]',
    '[{"name": "Greataxe", "quantity": 1}, {"name": "Javelin", "quantity": 5}, {"name": "Explorer''s Pack", "quantity": 1}, {"name": "Belt of Dwarvenkind", "quantity": 1}]',
    '[]',
    false,
    '{"ability": "STR", "dc": 10, "bonus": 0, "class": ""}'
)
ON CONFLICT (id) DO UPDATE SET
    ability_scores = EXCLUDED.ability_scores,
    personality = EXCLUDED.personality,
    attacks = EXCLUDED.attacks,
    features = EXCLUDED.features,
    current_hp = EXCLUDED.current_hp,
    max_hp = EXCLUDED.max_hp;
