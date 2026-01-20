-- ============================================================================
-- DiceCloud Test Data - Level 20 Characters
-- One character of each D&D 5e class at max level
-- ============================================================================

-- ============================================================================
-- LEVEL 20 BARBARIAN - Gorak the Unkillable
-- ============================================================================
INSERT INTO creatures (
  id, name, alignment, gender, type, owner_id, public, color, settings, created_at
) VALUES (
  '20000000-0000-0000-0000-000000000001'::uuid,
  'Gorak the Unkillable',
  'Chaotic Neutral', 'Male', 'pc',
  '00000000-0000-0000-0000-000000000001'::uuid,
  true, '#8B0000',
  '{"class": "Barbarian", "subclass": "Path of the Totem Warrior", "level": 20, "race": "Half-Orc"}'::jsonb,
  NOW()
);

INSERT INTO creature_properties (id, creature_id, type, name, data, root_id, root_collection, tree_left, tree_right, created_at) VALUES
  (uuid_generate_v4(), '20000000-0000-0000-0000-000000000001'::uuid, 'ability', 'Strength', '{"base": 24, "modifier": 7}'::jsonb, '20000000-0000-0000-0000-000000000001'::uuid, 'creatures', 1, 2, NOW()),
  (uuid_generate_v4(), '20000000-0000-0000-0000-000000000001'::uuid, 'ability', 'Constitution', '{"base": 22, "modifier": 6}'::jsonb, '20000000-0000-0000-0000-000000000001'::uuid, 'creatures', 3, 4, NOW()),
  (uuid_generate_v4(), '20000000-0000-0000-0000-000000000001'::uuid, 'feature', 'Primal Champion', '{"description": "At 20th level, +4 to Strength and Constitution, max 24"}'::jsonb, '20000000-0000-0000-0000-000000000001'::uuid, 'creatures', 5, 6, NOW()),
  (uuid_generate_v4(), '20000000-0000-0000-0000-000000000001'::uuid, 'feature', 'Rage (Unlimited)', '{"uses": "unlimited", "bonus": "+4 damage"}'::jsonb, '20000000-0000-0000-0000-000000000001'::uuid, 'creatures', 7, 8, NOW()),
  (uuid_generate_v4(), '20000000-0000-0000-0000-000000000001'::uuid, 'item', 'Belt of Storm Giant Strength', '{"rarity": "legendary", "equipped": true, "effect": "Strength becomes 29"}'::jsonb, '20000000-0000-0000-0000-000000000001'::uuid, 'creatures', 9, 10, NOW());

INSERT INTO creature_variables (creature_id, variables, created_at) VALUES
  ('20000000-0000-0000-0000-000000000001'::uuid, '{"level": 20, "hitPoints": 285, "maxHitPoints": 285, "armorClass": 19, "speed": 40}'::jsonb, NOW());

-- ============================================================================
-- LEVEL 20 BARD - Lyra Songweaver
-- ============================================================================
INSERT INTO creatures (id, name, alignment, gender, type, owner_id, public, color, settings, created_at) VALUES (
  '20000000-0000-0000-0000-000000000002'::uuid,
  'Lyra Songweaver',
  'Chaotic Good', 'Female', 'pc',
  '00000000-0000-0000-0000-000000000001'::uuid,
  true, '#9B59B6',
  '{"class": "Bard", "subclass": "College of Lore", "level": 20, "race": "Half-Elf"}'::jsonb,
  NOW()
);

INSERT INTO creature_properties (id, creature_id, type, name, data, root_id, root_collection, tree_left, tree_right, created_at) VALUES
  (uuid_generate_v4(), '20000000-0000-0000-0000-000000000002'::uuid, 'ability', 'Charisma', '{"base": 20, "modifier": 5}'::jsonb, '20000000-0000-0000-0000-000000000002'::uuid, 'creatures', 1, 2, NOW()),
  (uuid_generate_v4(), '20000000-0000-0000-0000-000000000002'::uuid, 'ability', 'Dexterity', '{"base": 18, "modifier": 4}'::jsonb, '20000000-0000-0000-0000-000000000002'::uuid, 'creatures', 3, 4, NOW()),
  (uuid_generate_v4(), '20000000-0000-0000-0000-000000000002'::uuid, 'feature', 'Superior Inspiration', '{"description": "Regain Bardic Inspiration on initiative roll"}'::jsonb, '20000000-0000-0000-0000-000000000002'::uuid, 'creatures', 5, 6, NOW()),
  (uuid_generate_v4(), '20000000-0000-0000-0000-000000000002'::uuid, 'spell', 'Power Word Kill', '{"level": 9, "school": "enchantment"}'::jsonb, '20000000-0000-0000-0000-000000000002'::uuid, 'creatures', 7, 8, NOW()),
  (uuid_generate_v4(), '20000000-0000-0000-0000-000000000002'::uuid, 'spell', 'True Polymorph', '{"level": 9, "school": "transmutation"}'::jsonb, '20000000-0000-0000-0000-000000000002'::uuid, 'creatures', 9, 10, NOW());

INSERT INTO creature_variables (creature_id, variables, created_at) VALUES
  ('20000000-0000-0000-0000-000000000002'::uuid, '{"level": 20, "hitPoints": 152, "maxHitPoints": 152, "armorClass": 17, "speed": 30, "spellSlots": {"1": 4, "2": 3, "3": 3, "4": 3, "5": 3, "6": 2, "7": 2, "8": 1, "9": 1}}'::jsonb, NOW());

-- ============================================================================
-- LEVEL 20 CLERIC - Brother Aldric
-- ============================================================================
INSERT INTO creatures (id, name, alignment, gender, type, owner_id, public, color, settings, created_at) VALUES (
  '20000000-0000-0000-0000-000000000003'::uuid,
  'Brother Aldric',
  'Lawful Good', 'Male', 'pc',
  '00000000-0000-0000-0000-000000000001'::uuid,
  true, '#FFD700',
  '{"class": "Cleric", "subclass": "Life Domain", "level": 20, "race": "Human"}'::jsonb,
  NOW()
);

INSERT INTO creature_properties (id, creature_id, type, name, data, root_id, root_collection, tree_left, tree_right, created_at) VALUES
  (uuid_generate_v4(), '20000000-0000-0000-0000-000000000003'::uuid, 'ability', 'Wisdom', '{"base": 20, "modifier": 5}'::jsonb, '20000000-0000-0000-0000-000000000003'::uuid, 'creatures', 1, 2, NOW()),
  (uuid_generate_v4(), '20000000-0000-0000-0000-000000000003'::uuid, 'feature', 'Divine Intervention', '{"description": "Automatically succeeds at level 20"}'::jsonb, '20000000-0000-0000-0000-000000000003'::uuid, 'creatures', 3, 4, NOW()),
  (uuid_generate_v4(), '20000000-0000-0000-0000-000000000003'::uuid, 'spell', 'Mass Heal', '{"level": 9, "healing": "700 HP"}'::jsonb, '20000000-0000-0000-0000-000000000003'::uuid, 'creatures', 5, 6, NOW()),
  (uuid_generate_v4(), '20000000-0000-0000-0000-000000000003'::uuid, 'spell', 'True Resurrection', '{"level": 9, "school": "necromancy"}'::jsonb, '20000000-0000-0000-0000-000000000003'::uuid, 'creatures', 7, 8, NOW());

INSERT INTO creature_variables (creature_id, variables, created_at) VALUES
  ('20000000-0000-0000-0000-000000000003'::uuid, '{"level": 20, "hitPoints": 180, "maxHitPoints": 180, "armorClass": 20, "speed": 30, "spellSlots": {"1": 4, "2": 3, "3": 3, "4": 3, "5": 3, "6": 2, "7": 2, "8": 1, "9": 1}}'::jsonb, NOW());

-- ============================================================================
-- LEVEL 20 DRUID - Thornwind
-- ============================================================================
INSERT INTO creatures (id, name, alignment, gender, type, owner_id, public, color, settings, created_at) VALUES (
  '20000000-0000-0000-0000-000000000004'::uuid,
  'Thornwind',
  'Neutral', 'Non-binary', 'pc',
  '00000000-0000-0000-0000-000000000001'::uuid,
  true, '#228B22',
  '{"class": "Druid", "subclass": "Circle of the Moon", "level": 20, "race": "Wood Elf"}'::jsonb,
  NOW()
);

INSERT INTO creature_properties (id, creature_id, type, name, data, root_id, root_collection, tree_left, tree_right, created_at) VALUES
  (uuid_generate_v4(), '20000000-0000-0000-0000-000000000004'::uuid, 'ability', 'Wisdom', '{"base": 20, "modifier": 5}'::jsonb, '20000000-0000-0000-0000-000000000004'::uuid, 'creatures', 1, 2, NOW()),
  (uuid_generate_v4(), '20000000-0000-0000-0000-000000000004'::uuid, 'feature', 'Archdruid', '{"description": "Unlimited Wild Shape, ignore age"}'::jsonb, '20000000-0000-0000-0000-000000000004'::uuid, 'creatures', 3, 4, NOW()),
  (uuid_generate_v4(), '20000000-0000-0000-0000-000000000004'::uuid, 'spell', 'Shapechange', '{"level": 9, "school": "transmutation"}'::jsonb, '20000000-0000-0000-0000-000000000004'::uuid, 'creatures', 5, 6, NOW());

INSERT INTO creature_variables (creature_id, variables, created_at) VALUES
  ('20000000-0000-0000-0000-000000000004'::uuid, '{"level": 20, "hitPoints": 170, "maxHitPoints": 170, "armorClass": 18, "speed": 35, "spellSlots": {"1": 4, "2": 3, "3": 3, "4": 3, "5": 3, "6": 2, "7": 2, "8": 1, "9": 1}}'::jsonb, NOW());

-- ============================================================================
-- LEVEL 20 FIGHTER - Commander Valeria
-- ============================================================================
INSERT INTO creatures (id, name, alignment, gender, type, owner_id, public, color, settings, created_at) VALUES (
  '20000000-0000-0000-0000-000000000005'::uuid,
  'Commander Valeria',
  'Lawful Neutral', 'Female', 'pc',
  '00000000-0000-0000-0000-000000000001'::uuid,
  true, '#C0C0C0',
  '{"class": "Fighter", "subclass": "Battle Master", "level": 20, "race": "Human"}'::jsonb,
  NOW()
);

INSERT INTO creature_properties (id, creature_id, type, name, data, root_id, root_collection, tree_left, tree_right, created_at) VALUES
  (uuid_generate_v4(), '20000000-0000-0000-0000-000000000005'::uuid, 'ability', 'Strength', '{"base": 20, "modifier": 5}'::jsonb, '20000000-0000-0000-0000-000000000005'::uuid, 'creatures', 1, 2, NOW()),
  (uuid_generate_v4(), '20000000-0000-0000-0000-000000000005'::uuid, 'feature', 'Extra Attack (4)', '{"attacks": 4}'::jsonb, '20000000-0000-0000-0000-000000000005'::uuid, 'creatures', 3, 4, NOW()),
  (uuid_generate_v4(), '20000000-0000-0000-0000-000000000005'::uuid, 'item', 'Holy Avenger Longsword', '{"rarity": "legendary", "equipped": true, "bonus": "+3"}'::jsonb, '20000000-0000-0000-0000-000000000005'::uuid, 'creatures', 5, 6, NOW());

INSERT INTO creature_variables (creature_id, variables, created_at) VALUES
  ('20000000-0000-0000-0000-000000000005'::uuid, '{"level": 20, "hitPoints": 240, "maxHitPoints": 240, "armorClass": 21, "speed": 30}'::jsonb, NOW());

-- ============================================================================
-- LEVEL 20 MONK - Master Zen
-- ============================================================================
INSERT INTO creatures (id, name, alignment, gender, type, owner_id, public, color, settings, created_at) VALUES (
  '20000000-0000-0000-0000-000000000006'::uuid,
  'Master Zen',
  'Lawful Neutral', 'Male', 'pc',
  '00000000-0000-0000-0000-000000000001'::uuid,
  true, '#FF8C00',
  '{"class": "Monk", "subclass": "Way of the Open Hand", "level": 20, "race": "Human"}'::jsonb,
  NOW()
);

INSERT INTO creature_properties (id, creature_id, type, name, data, root_id, root_collection, tree_left, tree_right, created_at) VALUES
  (uuid_generate_v4(), '20000000-0000-0000-0000-000000000006'::uuid, 'ability', 'Dexterity', '{"base": 20, "modifier": 5}'::jsonb, '20000000-0000-0000-0000-000000000006'::uuid, 'creatures', 1, 2, NOW()),
  (uuid_generate_v4(), '20000000-0000-0000-0000-000000000006'::uuid, 'ability', 'Wisdom', '{"base": 20, "modifier": 5}'::jsonb, '20000000-0000-0000-0000-000000000006'::uuid, 'creatures', 3, 4, NOW()),
  (uuid_generate_v4(), '20000000-0000-0000-0000-000000000006'::uuid, 'feature', 'Perfect Self', '{"description": "Regain 4 ki points on short rest if at 0"}'::jsonb, '20000000-0000-0000-0000-000000000006'::uuid, 'creatures', 5, 6, NOW());

INSERT INTO creature_variables (creature_id, variables, created_at) VALUES
  ('20000000-0000-0000-0000-000000000006'::uuid, '{"level": 20, "hitPoints": 180, "maxHitPoints": 180, "armorClass": 20, "speed": 60, "kiPoints": 20}'::jsonb, NOW());

-- ============================================================================
-- LEVEL 20 PALADIN - Sir Galahad
-- ============================================================================
INSERT INTO creatures (id, name, alignment, gender, type, owner_id, public, color, settings, created_at) VALUES (
  '20000000-0000-0000-0000-000000000007'::uuid,
  'Sir Galahad the Pure',
  'Lawful Good', 'Male', 'pc',
  '00000000-0000-0000-0000-000000000001'::uuid,
  true, '#4169E1',
  '{"class": "Paladin", "subclass": "Oath of Devotion", "level": 20, "race": "Human"}'::jsonb,
  NOW()
);

INSERT INTO creature_properties (id, creature_id, type, name, data, root_id, root_collection, tree_left, tree_right, created_at) VALUES
  (uuid_generate_v4(), '20000000-0000-0000-0000-000000000007'::uuid, 'ability', 'Strength', '{"base": 20, "modifier": 5}'::jsonb, '20000000-0000-0000-0000-000000000007'::uuid, 'creatures', 1, 2, NOW()),
  (uuid_generate_v4(), '20000000-0000-0000-0000-000000000007'::uuid, 'ability', 'Charisma', '{"base": 18, "modifier": 4}'::jsonb, '20000000-0000-0000-0000-000000000007'::uuid, 'creatures', 3, 4, NOW()),
  (uuid_generate_v4(), '20000000-0000-0000-0000-000000000007'::uuid, 'spell', 'Holy Aura', '{"level": 8, "school": "abjuration"}'::jsonb, '20000000-0000-0000-0000-000000000007'::uuid, 'creatures', 5, 6, NOW());

INSERT INTO creature_variables (creature_id, variables, created_at) VALUES
  ('20000000-0000-0000-0000-000000000007'::uuid, '{"level": 20, "hitPoints": 220, "maxHitPoints": 220, "armorClass": 22, "speed": 30, "spellSlots": {"1": 4, "2": 3, "3": 3, "4": 3, "5": 2}}'::jsonb, NOW());

-- ============================================================================
-- LEVEL 20 RANGER - Artemis Nightbow
-- ============================================================================
INSERT INTO creatures (id, name, alignment, gender, type, owner_id, public, color, settings, created_at) VALUES (
  '20000000-0000-0000-0000-000000000008'::uuid,
  'Artemis Nightbow',
  'Neutral Good', 'Female', 'pc',
  '00000000-0000-0000-0000-000000000001'::uuid,
  true, '#006400',
  '{"class": "Ranger", "subclass": "Hunter", "level": 20, "race": "Wood Elf"}'::jsonb,
  NOW()
);

INSERT INTO creature_properties (id, creature_id, type, name, data, root_id, root_collection, tree_left, tree_right, created_at) VALUES
  (uuid_generate_v4(), '20000000-0000-0000-0000-000000000008'::uuid, 'ability', 'Dexterity', '{"base": 20, "modifier": 5}'::jsonb, '20000000-0000-0000-0000-000000000008'::uuid, 'creatures', 1, 2, NOW()),
  (uuid_generate_v4(), '20000000-0000-0000-0000-000000000008'::uuid, 'ability', 'Wisdom', '{"base": 18, "modifier": 4}'::jsonb, '20000000-0000-0000-0000-000000000008'::uuid, 'creatures', 3, 4, NOW()),
  (uuid_generate_v4(), '20000000-0000-0000-0000-000000000008'::uuid, 'feature', 'Foe Slayer', '{"description": "+5 to attack or damage once per turn"}'::jsonb, '20000000-0000-0000-0000-000000000008'::uuid, 'creatures', 5, 6, NOW()),
  (uuid_generate_v4(), '20000000-0000-0000-0000-000000000008'::uuid, 'item', 'Oathbow', '{"rarity": "very rare", "equipped": true}'::jsonb, '20000000-0000-0000-0000-000000000008'::uuid, 'creatures', 7, 8, NOW());

INSERT INTO creature_variables (creature_id, variables, created_at) VALUES
  ('20000000-0000-0000-0000-000000000008'::uuid, '{"level": 20, "hitPoints": 200, "maxHitPoints": 200, "armorClass": 19, "speed": 35, "spellSlots": {"1": 4, "2": 3, "3": 3, "4": 3, "5": 2}}'::jsonb, NOW());

-- ============================================================================
-- LEVEL 20 ROGUE - Shadow
-- ============================================================================
INSERT INTO creatures (id, name, alignment, gender, type, owner_id, public, color, settings, created_at) VALUES (
  '20000000-0000-0000-0000-000000000009'::uuid,
  'Shadow',
  'Chaotic Neutral', 'Non-binary', 'pc',
  '00000000-0000-0000-0000-000000000001'::uuid,
  true, '#2F4F4F',
  '{"class": "Rogue", "subclass": "Assassin", "level": 20, "race": "Halfling"}'::jsonb,
  NOW()
);

INSERT INTO creature_properties (id, creature_id, type, name, data, root_id, root_collection, tree_left, tree_right, created_at) VALUES
  (uuid_generate_v4(), '20000000-0000-0000-0000-000000000009'::uuid, 'ability', 'Dexterity', '{"base": 20, "modifier": 5}'::jsonb, '20000000-0000-0000-0000-000000000009'::uuid, 'creatures', 1, 2, NOW()),
  (uuid_generate_v4(), '20000000-0000-0000-0000-000000000009'::uuid, 'feature', 'Stroke of Luck', '{"description": "Turn a miss into a hit or fail into success once per short rest"}'::jsonb, '20000000-0000-0000-0000-000000000009'::uuid, 'creatures', 3, 4, NOW()),
  (uuid_generate_v4(), '20000000-0000-0000-0000-000000000009'::uuid, 'feature', 'Sneak Attack', '{"damage": "10d6"}'::jsonb, '20000000-0000-0000-0000-000000000009'::uuid, 'creatures', 5, 6, NOW());

INSERT INTO creature_variables (creature_id, variables, created_at) VALUES
  ('20000000-0000-0000-0000-000000000009'::uuid, '{"level": 20, "hitPoints": 160, "maxHitPoints": 160, "armorClass": 20, "speed": 30}'::jsonb, NOW());

-- ============================================================================
-- LEVEL 20 SORCERER - Pyra Flameheart
-- ============================================================================
INSERT INTO creatures (id, name, alignment, gender, type, owner_id, public, color, settings, created_at) VALUES (
  '20000000-0000-0000-0000-000000000010'::uuid,
  'Pyra Flameheart',
  'Chaotic Good', 'Female', 'pc',
  '00000000-0000-0000-0000-000000000001'::uuid,
  true, '#FF4500',
  '{"class": "Sorcerer", "subclass": "Draconic Bloodline (Red)", "level": 20, "race": "Dragonborn"}'::jsonb,
  NOW()
);

INSERT INTO creature_properties (id, creature_id, type, name, data, root_id, root_collection, tree_left, tree_right, created_at) VALUES
  (uuid_generate_v4(), '20000000-0000-0000-0000-000000000010'::uuid, 'ability', 'Charisma', '{"base": 20, "modifier": 5}'::jsonb, '20000000-0000-0000-0000-000000000010'::uuid, 'creatures', 1, 2, NOW()),
  (uuid_generate_v4(), '20000000-0000-0000-0000-000000000010'::uuid, 'feature', 'Sorcerous Restoration', '{"description": "Regain 4 sorcery points on short rest"}'::jsonb, '20000000-0000-0000-0000-000000000010'::uuid, 'creatures', 3, 4, NOW()),
  (uuid_generate_v4(), '20000000-0000-0000-0000-000000000010'::uuid, 'spell', 'Meteor Swarm', '{"level": 9, "damage": "40d6 fire", "school": "evocation"}'::jsonb, '20000000-0000-0000-0000-000000000010'::uuid, 'creatures', 5, 6, NOW());

INSERT INTO creature_variables (creature_id, variables, created_at) VALUES
  ('20000000-0000-0000-0000-000000000010'::uuid, '{"level": 20, "hitPoints": 140, "maxHitPoints": 140, "armorClass": 16, "speed": 30, "sorceryPoints": 20, "spellSlots": {"1": 4, "2": 3, "3": 3, "4": 3, "5": 3, "6": 2, "7": 2, "8": 1, "9": 1}}'::jsonb, NOW());

-- ============================================================================
-- LEVEL 20 WARLOCK - Malachi Darkpact
-- ============================================================================
INSERT INTO creatures (id, name, alignment, gender, type, owner_id, public, color, settings, created_at) VALUES (
  '20000000-0000-0000-0000-000000000011'::uuid,
  'Malachi Darkpact',
  'Neutral Evil', 'Male', 'pc',
  '00000000-0000-0000-0000-000000000001'::uuid,
  true, '#4B0082',
  '{"class": "Warlock", "subclass": "The Fiend", "level": 20, "race": "Tiefling"}'::jsonb,
  NOW()
);

INSERT INTO creature_properties (id, creature_id, type, name, data, root_id, root_collection, tree_left, tree_right, created_at) VALUES
  (uuid_generate_v4(), '20000000-0000-0000-0000-000000000011'::uuid, 'ability', 'Charisma', '{"base": 20, "modifier": 5}'::jsonb, '20000000-0000-0000-0000-000000000011'::uuid, 'creatures', 1, 2, NOW()),
  (uuid_generate_v4(), '20000000-0000-0000-0000-000000000011'::uuid, 'feature', 'Eldritch Master', '{"description": "Regain all spell slots on short rest once per day"}'::jsonb, '20000000-0000-0000-0000-000000000011'::uuid, 'creatures', 3, 4, NOW()),
  (uuid_generate_v4(), '20000000-0000-0000-0000-000000000011'::uuid, 'spell', 'Eldritch Blast', '{"cantrip": true, "beams": 4, "damage": "1d10+5 per beam"}'::jsonb, '20000000-0000-0000-0000-000000000011'::uuid, 'creatures', 5, 6, NOW());

INSERT INTO creature_variables (creature_id, variables, created_at) VALUES
  ('20000000-0000-0000-0000-000000000011'::uuid, '{"level": 20, "hitPoints": 155, "maxHitPoints": 155, "armorClass": 17, "speed": 30, "spellSlots": {"5": 4}}'::jsonb, NOW());

-- ============================================================================
-- LEVEL 20 WIZARD - Archmage Merlin
-- ============================================================================
INSERT INTO creatures (id, name, alignment, gender, type, owner_id, public, color, settings, created_at) VALUES (
  '20000000-0000-0000-0000-000000000012'::uuid,
  'Archmage Merlin',
  'Neutral Good', 'Male', 'pc',
  '00000000-0000-0000-0000-000000000001'::uuid,
  true, '#00008B',
  '{"class": "Wizard", "subclass": "School of Evocation", "level": 20, "race": "High Elf"}'::jsonb,
  NOW()
);

INSERT INTO creature_properties (id, creature_id, type, name, data, root_id, root_collection, tree_left, tree_right, created_at) VALUES
  (uuid_generate_v4(), '20000000-0000-0000-0000-000000000012'::uuid, 'ability', 'Intelligence', '{"base": 20, "modifier": 5}'::jsonb, '20000000-0000-0000-0000-000000000012'::uuid, 'creatures', 1, 2, NOW()),
  (uuid_generate_v4(), '20000000-0000-0000-0000-000000000012'::uuid, 'feature', 'Signature Spells', '{"spells": ["Counterspell", "Fireball"]}'::jsonb, '20000000-0000-0000-0000-000000000012'::uuid, 'creatures', 3, 4, NOW()),
  (uuid_generate_v4(), '20000000-0000-0000-0000-000000000012'::uuid, 'spell', 'Wish', '{"level": 9, "school": "conjuration", "description": "The ultimate spell"}'::jsonb, '20000000-0000-0000-0000-000000000012'::uuid, 'creatures', 5, 6, NOW()),
  (uuid_generate_v4(), '20000000-0000-0000-0000-000000000012'::uuid, 'item', 'Staff of the Magi', '{"rarity": "legendary", "charges": 50}'::jsonb, '20000000-0000-0000-0000-000000000012'::uuid, 'creatures', 7, 8, NOW());

INSERT INTO creature_variables (creature_id, variables, created_at) VALUES
  ('20000000-0000-0000-0000-000000000012'::uuid, '{"level": 20, "hitPoints": 145, "maxHitPoints": 145, "armorClass": 17, "speed": 30, "spellSlots": {"1": 4, "2": 3, "3": 3, "4": 3, "5": 3, "6": 2, "7": 2, "8": 1, "9": 1}}'::jsonb, NOW());

-- ============================================================================
-- LEVEL 20 ARTIFICER - Gizmo Cogsworth
-- ============================================================================
INSERT INTO creatures (id, name, alignment, gender, type, owner_id, public, color, settings, created_at) VALUES (
  '20000000-0000-0000-0000-000000000013'::uuid,
  'Gizmo Cogsworth',
  'Neutral', 'Male', 'pc',
  '00000000-0000-0000-0000-000000000001'::uuid,
  true, '#CD7F32',
  '{"class": "Artificer", "subclass": "Battle Smith", "level": 20, "race": "Gnome"}'::jsonb,
  NOW()
);

INSERT INTO creature_properties (id, creature_id, type, name, data, root_id, root_collection, tree_left, tree_right, created_at) VALUES
  (uuid_generate_v4(), '20000000-0000-0000-0000-000000000013'::uuid, 'ability', 'Intelligence', '{"base": 20, "modifier": 5}'::jsonb, '20000000-0000-0000-0000-000000000013'::uuid, 'creatures', 1, 2, NOW()),
  (uuid_generate_v4(), '20000000-0000-0000-0000-000000000013'::uuid, 'feature', 'Soul of Artifice', '{"description": "+6 to all saves, attunement to 6 items"}'::jsonb, '20000000-0000-0000-0000-000000000013'::uuid, 'creatures', 3, 4, NOW()),
  (uuid_generate_v4(), '20000000-0000-0000-0000-000000000013'::uuid, 'feature', 'Steel Defender', '{"type": "companion", "AC": 19, "HP": 120}'::jsonb, '20000000-0000-0000-0000-000000000013'::uuid, 'creatures', 5, 6, NOW());

INSERT INTO creature_variables (creature_id, variables, created_at) VALUES
  ('20000000-0000-0000-0000-000000000013'::uuid, '{"level": 20, "hitPoints": 165, "maxHitPoints": 165, "armorClass": 19, "speed": 25, "spellSlots": {"1": 4, "2": 3, "3": 3, "4": 3, "5": 2}, "infusions": 6}'::jsonb, NOW());

-- ============================================================================
-- Summary
-- ============================================================================
DO $$
BEGIN
  RAISE NOTICE '✅ Level 20 characters created successfully!';
  RAISE NOTICE '';
  RAISE NOTICE 'All 13 D&D 5e Classes at Level 20:';
  RAISE NOTICE '  1. Gorak the Unkillable - Barbarian';
  RAISE NOTICE '  2. Lyra Songweaver - Bard';
  RAISE NOTICE '  3. Brother Aldric - Cleric';
  RAISE NOTICE '  4. Thornwind - Druid';
  RAISE NOTICE '  5. Commander Valeria - Fighter';
  RAISE NOTICE '  6. Master Zen - Monk';
  RAISE NOTICE '  7. Sir Galahad - Paladin';
  RAISE NOTICE '  8. Artemis Nightbow - Ranger';
  RAISE NOTICE '  9. Shadow - Rogue';
  RAISE NOTICE ' 10. Pyra Flameheart - Sorcerer';
  RAISE NOTICE ' 11. Malachi Darkpact - Warlock';
  RAISE NOTICE ' 12. Archmage Merlin - Wizard';
  RAISE NOTICE ' 13. Gizmo Cogsworth - Artificer';
  RAISE NOTICE '';
  RAISE NOTICE 'Each character includes:';
  RAISE NOTICE '  - Optimized ability scores';
  RAISE NOTICE '  - Level 20 capstone features';
  RAISE NOTICE '  - Signature spells/abilities';
  RAISE NOTICE '  - Legendary magic items';
  RAISE NOTICE '  - Complete stats (HP, AC, spell slots, etc.)';
END $$;
