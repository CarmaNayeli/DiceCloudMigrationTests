-- ============================================================================
-- DiceCloud Test Data
-- Sample data for testing PostgreSQL/Supabase migration
-- ============================================================================

-- Note: This creates test users in the auth schema.
-- In production, users would sign up through the app.

-- ============================================================================
-- TEST USER
-- ============================================================================

-- Create a test user in Supabase auth
-- Password: testpassword123
INSERT INTO auth.users (
  id,
  instance_id,
  email,
  encrypted_password,
  email_confirmed_at,
  created_at,
  updated_at,
  raw_app_meta_data,
  raw_user_meta_data,
  is_super_admin,
  role
) VALUES (
  '00000000-0000-0000-0000-000000000001'::uuid,
  '00000000-0000-0000-0000-000000000000'::uuid,
  'testuser@example.com',
  '$2a$10$rMYKMvVGXYZ5zN5z5N5z5N5z5N5z5N5z5N5z5N5z5N5z5N5z5N5z5',  -- hashed "testpassword123"
  NOW(),
  NOW(),
  NOW(),
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"username":"testuser"}'::jsonb,
  false,
  'authenticated'
) ON CONFLICT (id) DO NOTHING;

-- Create user profile
INSERT INTO user_profiles (
  id,
  username,
  display_name,
  picture,
  patreon_tier,
  paid_benefits,
  created_at,
  updated_at
) VALUES (
  '00000000-0000-0000-0000-000000000001'::uuid,
  'testuser',
  'Test User',
  'https://api.dicebear.com/7.x/avataaars/svg?seed=testuser',
  NULL,
  true, -- Give them paid features for testing
  NOW(),
  NOW()
) ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- TEST CREATURES (Characters)
-- ============================================================================

-- Create a Fighter character
INSERT INTO creatures (
  id,
  name,
  alignment,
  gender,
  picture,
  type,
  owner_id,
  public,
  readers_can_copy,
  color,
  settings,
  created_at,
  updated_at
) VALUES (
  '10000000-0000-0000-0000-000000000001'::uuid,
  'Thorin Ironforge',
  'Lawful Good',
  'Male',
  'https://api.dicebear.com/7.x/adventurer/svg?seed=thorin',
  'pc',
  '00000000-0000-0000-0000-000000000001'::uuid,
  true,
  true,
  '#8B4513',
  '{"useStandardArray": true, "abilityScoreMethod": "pointBuy"}'::jsonb,
  NOW(),
  NOW()
);

-- Create a Wizard character
INSERT INTO creatures (
  id,
  name,
  alignment,
  gender,
  picture,
  type,
  owner_id,
  public,
  readers_can_copy,
  color,
  settings,
  created_at,
  updated_at
) VALUES (
  '10000000-0000-0000-0000-000000000002'::uuid,
  'Elara Moonwhisper',
  'Neutral Good',
  'Female',
  'https://api.dicebear.com/7.x/adventurer/svg?seed=elara',
  'pc',
  '00000000-0000-0000-0000-000000000001'::uuid,
  true,
  true,
  '#9B59B6',
  '{}'::jsonb,
  NOW(),
  NOW()
);

-- ============================================================================
-- CREATURE PROPERTIES
-- ============================================================================

-- Thorin's abilities
INSERT INTO creature_properties (
  id,
  creature_id,
  type,
  name,
  description,
  data,
  root_id,
  root_collection,
  tree_left,
  tree_right,
  created_at,
  updated_at
) VALUES
  -- Strength
  (
    '20000000-0000-0000-0000-000000000001'::uuid,
    '10000000-0000-0000-0000-000000000001'::uuid,
    'ability',
    'Strength',
    'Raw physical power',
    '{"base": 16, "modifier": 3}'::jsonb,
    '10000000-0000-0000-0000-000000000001'::uuid,
    'creatures',
    1,
    2,
    NOW(),
    NOW()
  ),
  -- Longsword
  (
    '20000000-0000-0000-0000-000000000002'::uuid,
    '10000000-0000-0000-0000-000000000001'::uuid,
    'item',
    'Longsword +1',
    'A masterwork longsword with a +1 enchantment',
    '{"equipped": true, "weight": 3, "attackBonus": 1, "damage": "1d8+1", "damageType": "slashing"}'::jsonb,
    '10000000-0000-0000-0000-000000000001'::uuid,
    'creatures',
    3,
    4,
    NOW(),
    NOW()
  ),
  -- Heavy Armor proficiency
  (
    '20000000-0000-0000-0000-000000000003'::uuid,
    '10000000-0000-0000-0000-000000000001'::uuid,
    'proficiency',
    'Heavy Armor',
    'Proficient with heavy armor',
    '{"proficiencyLevel": "proficient"}'::jsonb,
    '10000000-0000-0000-0000-000000000001'::uuid,
    'creatures',
    5,
    6,
    NOW(),
    NOW()
  );

-- Elara's abilities
INSERT INTO creature_properties (
  id,
  creature_id,
  type,
  name,
  description,
  data,
  root_id,
  root_collection,
  tree_left,
  tree_right,
  created_at,
  updated_at
) VALUES
  -- Intelligence
  (
    '20000000-0000-0000-0000-000000000010'::uuid,
    '10000000-0000-0000-0000-000000000002'::uuid,
    'ability',
    'Intelligence',
    'Mental acuity and recall',
    '{"base": 18, "modifier": 4}'::jsonb,
    '10000000-0000-0000-0000-000000000002'::uuid,
    'creatures',
    1,
    2,
    NOW(),
    NOW()
  ),
  -- Fireball spell
  (
    '20000000-0000-0000-0000-000000000011'::uuid,
    '10000000-0000-0000-0000-000000000002'::uuid,
    'spell',
    'Fireball',
    '3rd level evocation spell',
    '{"level": 3, "school": "evocation", "castingTime": "1 action", "range": "150 feet", "components": ["V", "S", "M"], "duration": "Instantaneous", "damage": "8d6", "damageType": "fire", "savingThrow": "Dexterity"}'::jsonb,
    '10000000-0000-0000-0000-000000000002'::uuid,
    'creatures',
    3,
    4,
    NOW(),
    NOW()
  ),
  -- Staff of Power
  (
    '20000000-0000-0000-0000-000000000012'::uuid,
    '10000000-0000-0000-0000-000000000002'::uuid,
    'item',
    'Staff of Power',
    'A legendary magical staff',
    '{"equipped": true, "rarity": "legendary", "requiresAttunement": true, "charges": 20}'::jsonb,
    '10000000-0000-0000-0000-000000000002'::uuid,
    'creatures',
    5,
    6,
    NOW(),
    NOW()
  );

-- ============================================================================
-- CREATURE VARIABLES
-- ============================================================================

INSERT INTO creature_variables (
  id,
  creature_id,
  variables,
  created_at,
  updated_at
) VALUES
  (
    uuid_generate_v4(),
    '10000000-0000-0000-0000-000000000001'::uuid,
    '{"level": 5, "hitPoints": 45, "maxHitPoints": 45, "armorClass": 18, "speed": 30}'::jsonb,
    NOW(),
    NOW()
  ),
  (
    uuid_generate_v4(),
    '10000000-0000-0000-0000-000000000002'::uuid,
    '{"level": 7, "hitPoints": 38, "maxHitPoints": 38, "armorClass": 14, "speed": 30, "spellSlots": {"1": 4, "2": 3, "3": 3, "4": 1}}'::jsonb,
    NOW(),
    NOW()
  );

-- ============================================================================
-- EXPERIENCE
-- ============================================================================

INSERT INTO experiences (
  id,
  name,
  xp,
  levels,
  creature_id,
  date,
  created_at
) VALUES
  (
    uuid_generate_v4(),
    'Defeated the Dragon',
    5000,
    0,
    '10000000-0000-0000-0000-000000000001'::uuid,
    NOW() - INTERVAL '7 days',
    NOW() - INTERVAL '7 days'
  ),
  (
    uuid_generate_v4(),
    'Completed Quest: Save the Village',
    2000,
    1,
    '10000000-0000-0000-0000-000000000001'::uuid,
    NOW() - INTERVAL '14 days',
    NOW() - INTERVAL '14 days'
  );

-- ============================================================================
-- CREATURE LOGS (Activity History)
-- ============================================================================

INSERT INTO creature_logs (
  id,
  creature_id,
  creature_name,
  content,
  date,
  created_at
) VALUES
  (
    uuid_generate_v4(),
    '10000000-0000-0000-0000-000000000001'::uuid,
    'Thorin Ironforge',
    '{"type": "damage", "amount": 15, "damageType": "slashing", "source": "Goblin"}'::jsonb,
    NOW() - INTERVAL '1 hour',
    NOW() - INTERVAL '1 hour'
  ),
  (
    uuid_generate_v4(),
    '10000000-0000-0000-0000-000000000002'::uuid,
    'Elara Moonwhisper',
    '{"type": "spellCast", "spell": "Fireball", "target": "Orc Warband", "damage": "8d6"}'::jsonb,
    NOW() - INTERVAL '30 minutes',
    NOW() - INTERVAL '30 minutes'
  );

-- ============================================================================
-- LIBRARIES
-- ============================================================================

INSERT INTO libraries (
  id,
  name,
  description,
  owner_id,
  public,
  show_in_market,
  created_at,
  updated_at
) VALUES
  (
    '30000000-0000-0000-0000-000000000001'::uuid,
    'Standard Fantasy Items',
    'Common weapons, armor, and adventuring gear for D&D 5e',
    '00000000-0000-0000-0000-000000000001'::uuid,
    true,
    true,
    NOW(),
    NOW()
  );

-- ============================================================================
-- LIBRARY NODES
-- ============================================================================

INSERT INTO library_nodes (
  id,
  library_id,
  type,
  name,
  description,
  data,
  root_id,
  root_collection,
  tree_left,
  tree_right,
  created_at,
  updated_at
) VALUES
  -- Sword
  (
    '40000000-0000-0000-0000-000000000001'::uuid,
    '30000000-0000-0000-0000-000000000001'::uuid,
    'item',
    'Longsword',
    'A versatile martial weapon',
    '{"cost": "15 gp", "weight": 3, "damage": "1d8", "damageType": "slashing", "properties": ["versatile (1d10)"]}'::jsonb,
    '30000000-0000-0000-0000-000000000001'::uuid,
    'libraries',
    1,
    2,
    NOW(),
    NOW()
  ),
  -- Armor
  (
    '40000000-0000-0000-0000-000000000002'::uuid,
    '30000000-0000-0000-0000-000000000001'::uuid,
    'item',
    'Plate Armor',
    'Heavy armor made of shaped metal plates',
    '{"cost": "1500 gp", "weight": 65, "armorClass": 18, "armorType": "heavy", "stealthDisadvantage": true}'::jsonb,
    '30000000-0000-0000-0000-000000000001'::uuid,
    'libraries',
    3,
    4,
    NOW(),
    NOW()
  );

-- ============================================================================
-- SUMMARY
-- ============================================================================

-- Print summary
DO $$
BEGIN
  RAISE NOTICE '✅ Test data created successfully!';
  RAISE NOTICE '';
  RAISE NOTICE 'Test User:';
  RAISE NOTICE '  Email: testuser@example.com';
  RAISE NOTICE '  Password: testpassword123';
  RAISE NOTICE '  (Note: Password is hashed, you''ll need to sign up through the app)';
  RAISE NOTICE '';
  RAISE NOTICE 'Created:';
  RAISE NOTICE '  - 1 user profile';
  RAISE NOTICE '  - 2 creatures (characters)';
  RAISE NOTICE '  - 6 creature properties';
  RAISE NOTICE '  - 2 creature variable records';
  RAISE NOTICE '  - 2 experience entries';
  RAISE NOTICE '  - 2 creature logs';
  RAISE NOTICE '  - 1 library';
  RAISE NOTICE '  - 2 library nodes';
  RAISE NOTICE '';
  RAISE NOTICE 'Characters:';
  RAISE NOTICE '  - Thorin Ironforge (Fighter, Level 5)';
  RAISE NOTICE '  - Elara Moonwhisper (Wizard, Level 7)';
END $$;
