# Database Table Snapshots

Here is a snapshot of one record from each of the 5e data tables to show the structure.

## `dnd_races`

| Column | Value |
|--------|-------|
| **id** | `1` |
| **name** | `Aarakocra` |
| **source** | `DMG` |
| **edition** | `NULL` |
| **description** | `[{"name":"Dive Attack","type":"entries","entries":["If you are flying and dive at least 30 ft. st...` |
| **ability_bonuses** | `[{"dex":2,"wis":2}]` |
| **size** | `M` |
| **speed** | `20` |
| **darkvision** | `NULL` |
| **languages** | `[{"auran":true}]` |
| **traits** | `[{"name":"Dive Attack","type":"entries","entries":["If you are flying and dive at least 30 ft. st...` |
| **subraces** | `[]` |

## `dnd_backgrounds`

| Column | Value |
|--------|-------|
| **id** | `1` |
| **name** | `Aberrant Heir` |
| **source** | `EFA` |
| **edition** | `one` |
| **description** | `[{"type":"list","items":[{"name":"Ability Scores:","type":"item","entry":"Strength, Constitution,...` |
| **ability_bonuses** | `[{"choose":{"weighted":{"from":["str","con","cha"],"weights":[2,1]}}},{"choose":{"weighted":{"fro...` |
| **skills** | `[{"history":true,"intimidation":true}]` |
| **tools** | `[{"disguise kit":true}]` |
| **languages** | `{}` |
| **feats** | `[{"aberrant dragonmark\|efa":true}]` |
| **traits** | `[{"type":"list","items":[{"name":"Ability Scores:","type":"item","entry":"Strength, Constitution,...` |

## `dnd_classes`

| Column | Value |
|--------|-------|
| **id** | `1` |
| **name** | `Artificer` |
| **source** | `TCE` |
| **edition** | `classic` |
| **description** | `[]` |
| **hit_die** | `8` |
| **proficiencies** | `{}` |
| **saving_throws** | `["con","int"]` |
| **starting_equipment** | `{"default":["any two {@filter simple weapons\|items\|source=phb\|category=basic\|type=simple weapon} ...` |
| **class_features** | `["Optional Rule: Firearm Proficiency\|Artificer\|TCE\|1","Magical Tinkering\|Artificer\|TCE\|1","Spellc...` |
| **subclasses** | `[]` |
| **spellcasting** | `{}` |

## `dnd_feats`

| Column | Value |
|--------|-------|
| **id** | `1` |
| **name** | `Aberrant Dragonmark` |
| **source** | `EFA` |
| **edition** | `NULL` |
| **description** | `["You gain the following benefits.",{"name":"Aberrant Fortitude","type":"entries","entries":["Whe...` |
| **prerequisite** | `NULL` |
| **ability_prerequisite** | `[]` |
| **ability_bonuses** | `[]` |

## `dnd_spells`

| Column | Value |
|--------|-------|
| **id** | `1` |
| **name** | `Acid Splash` |
| **source** | `PHB` |
| **edition** | `NULL` |
| **level** | `0` |
| **school** | `C` |
| **casting_time** | `1 action` |
| **duration** | `instant` |
| **range_text** | `feet` |
| **components** | `{"s":true,"v":true}` |
| **description** | `["You hurl a bubble of acid. Choose one creature you can see within range, or choose two creature...` |
| **higher_levels** | `[]` |
| **classes** | `{}` |
| **subclasses** | `{}` |
| **ritual** | `false` |
| **concentration** | `false` |

## `dnd_items`

| Column | Value |
|--------|-------|
| **id** | `1` |
| **name** | `+1 All-Purpose Tool` |
| **source** | `TCE` |
| **edition** | `NULL` |
| **item_type** | `SCF` |
| **rarity** | `uncommon` |
| **description** | `["This simple screwdriver can transform into a variety of tools; as an action, you can touch the ...` |
| **weight** | `NULL` |
| **cost** | `NULL` |
| **properties** | `[]` |
| **damage** | `{}` |
| **ac_bonus** | `NULL` |
| **requires_attunement** | `true` |
| **curse** | `NULL` |

## `dnd_bestiary`

| Column | Value |
|--------|-------|
| **id** | `1` |
| **name** | `Aarakocra` |
| **source** | `MM` |
| **edition** | `NULL` |
| **creature_type** | `humanoid` |
| **description** | `[]` |
| **challenge_rating** | `0.25` |
| **experience** | `NULL` |
| **armor_class** | `12` |
| **hit_points** | `13` |
| **hit_dice** | `3d8` |
| **ability_scores** | `{"cha":11,"con":10,"dex":14,"int":11,"str":10,"wis":12}` |
| **saving_throws** | `{}` |
| **skills** | `{"perception":"+5"}` |
| **damage_immunities** | `[]` |
| **condition_immunities** | `[]` |
| **senses** | `[]` |
| **languages** | `["Auran","Aarakocra"]` |
| **traits** | `[{"name":"Dive Attack","entries":["If the aarakocra is flying and dives at least 30 feet straight...` |
| **actions** | `[{"name":"Talon","entries":["{@atk mw} {@hit 4} to hit, reach 5 ft., one target. {@h}4 ({@damage ...` |
| **reactions** | `[]` |
| **legendary_actions** | `[]` |
| **spells** | `[]` |

## `dnd_conditions`

| Column | Value |
|--------|-------|
| **id** | `1` |
| **name** | `Blinded` |
| **source** | `PHB` |
| **edition** | `NULL` |
| **description** | `[{"type":"list","items":["A blinded creature can't see and automatically fails any ability check ...` |
| **save_dc** | `NULL` |
| **save_ability** | `NULL` |

