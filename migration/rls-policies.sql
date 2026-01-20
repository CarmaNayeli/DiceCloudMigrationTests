-- ============================================================================
-- DiceCloud Row Level Security (RLS) Policies
-- Supabase PostgreSQL Security Configuration
-- ============================================================================

-- ============================================================================
-- IMPORTANT NOTES
-- ============================================================================
-- 1. The app uses service_role key, which BYPASSES all RLS policies
-- 2. These policies are for direct database access and future API features
-- 3. For development/testing, you can leave RLS disabled
-- 4. For production, enable RLS and use these policies
-- ============================================================================

-- ============================================================================
-- ENABLE RLS ON ALL TABLES
-- ============================================================================
-- Uncomment these when you're ready to enable RLS (not needed for testing)

-- ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE creatures ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE creature_properties ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE creature_variables ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE creature_logs ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE experiences ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE libraries ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE library_nodes ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE library_collections ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE tabletops ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- USER PROFILES
-- ============================================================================

-- Users can read their own profile
CREATE POLICY "Users can read own profile"
  ON user_profiles FOR SELECT
  USING (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
  ON user_profiles FOR UPDATE
  USING (auth.uid() = id);

-- ============================================================================
-- CREATURES (Characters)
-- ============================================================================

-- Users can read their own creatures
CREATE POLICY "Users can read own creatures"
  ON creatures FOR SELECT
  USING (
    auth.uid() = owner_id
    OR auth.uid() = ANY(readers)
    OR auth.uid() = ANY(writers)
    OR public = true
  );

-- Users can insert their own creatures
CREATE POLICY "Users can create creatures"
  ON creatures FOR INSERT
  WITH CHECK (auth.uid() = owner_id);

-- Users can update their own creatures or creatures they have write access to
CREATE POLICY "Users can update creatures"
  ON creatures FOR UPDATE
  USING (
    auth.uid() = owner_id
    OR auth.uid() = ANY(writers)
  );

-- Users can delete their own creatures
CREATE POLICY "Users can delete own creatures"
  ON creatures FOR DELETE
  USING (auth.uid() = owner_id);

-- ============================================================================
-- CREATURE PROPERTIES
-- ============================================================================

-- Users can read properties of creatures they have access to
CREATE POLICY "Users can read creature properties"
  ON creature_properties FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM creatures
      WHERE creatures.id = creature_properties.creature_id
      AND (
        creatures.owner_id = auth.uid()
        OR auth.uid() = ANY(creatures.readers)
        OR auth.uid() = ANY(creatures.writers)
        OR creatures.public = true
      )
    )
  );

-- Users can insert properties to creatures they own or can write to
CREATE POLICY "Users can create creature properties"
  ON creature_properties FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM creatures
      WHERE creatures.id = creature_properties.creature_id
      AND (
        creatures.owner_id = auth.uid()
        OR auth.uid() = ANY(creatures.writers)
      )
    )
  );

-- Users can update properties of creatures they own or can write to
CREATE POLICY "Users can update creature properties"
  ON creature_properties FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM creatures
      WHERE creatures.id = creature_properties.creature_id
      AND (
        creatures.owner_id = auth.uid()
        OR auth.uid() = ANY(creatures.writers)
      )
    )
  );

-- Users can delete properties of creatures they own
CREATE POLICY "Users can delete creature properties"
  ON creature_properties FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM creatures
      WHERE creatures.id = creature_properties.creature_id
      AND creatures.owner_id = auth.uid()
    )
  );

-- ============================================================================
-- CREATURE VARIABLES
-- ============================================================================

CREATE POLICY "Users can read creature variables"
  ON creature_variables FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM creatures
      WHERE creatures.id = creature_variables.creature_id
      AND (
        creatures.owner_id = auth.uid()
        OR auth.uid() = ANY(creatures.readers)
        OR auth.uid() = ANY(creatures.writers)
        OR creatures.public = true
      )
    )
  );

CREATE POLICY "Users can manage creature variables"
  ON creature_variables FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM creatures
      WHERE creatures.id = creature_variables.creature_id
      AND (
        creatures.owner_id = auth.uid()
        OR auth.uid() = ANY(creatures.writers)
      )
    )
  );

-- ============================================================================
-- CREATURE LOGS
-- ============================================================================

CREATE POLICY "Users can read creature logs"
  ON creature_logs FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM creatures
      WHERE creatures.id = creature_logs.creature_id
      AND (
        creatures.owner_id = auth.uid()
        OR auth.uid() = ANY(creatures.readers)
        OR auth.uid() = ANY(creatures.writers)
        OR creatures.public = true
      )
    )
  );

CREATE POLICY "Users can create creature logs"
  ON creature_logs FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM creatures
      WHERE creatures.id = creature_logs.creature_id
      AND (
        creatures.owner_id = auth.uid()
        OR auth.uid() = ANY(creatures.writers)
      )
    )
  );

-- ============================================================================
-- EXPERIENCES
-- ============================================================================

CREATE POLICY "Users can read experiences"
  ON experiences FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM creatures
      WHERE creatures.id = experiences.creature_id
      AND (
        creatures.owner_id = auth.uid()
        OR auth.uid() = ANY(creatures.readers)
        OR auth.uid() = ANY(creatures.writers)
        OR creatures.public = true
      )
    )
  );

CREATE POLICY "Users can manage experiences"
  ON experiences FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM creatures
      WHERE creatures.id = experiences.creature_id
      AND (
        creatures.owner_id = auth.uid()
        OR auth.uid() = ANY(creatures.writers)
      )
    )
  );

-- ============================================================================
-- LIBRARIES
-- ============================================================================

-- Anyone can read public libraries
CREATE POLICY "Users can read libraries"
  ON libraries FOR SELECT
  USING (
    auth.uid() = owner_id
    OR public = true
  );

-- Users can create their own libraries
CREATE POLICY "Users can create libraries"
  ON libraries FOR INSERT
  WITH CHECK (auth.uid() = owner_id);

-- Users can update their own libraries
CREATE POLICY "Users can update libraries"
  ON libraries FOR UPDATE
  USING (auth.uid() = owner_id);

-- Users can delete their own libraries
CREATE POLICY "Users can delete libraries"
  ON libraries FOR DELETE
  USING (auth.uid() = owner_id);

-- ============================================================================
-- LIBRARY NODES
-- ============================================================================

CREATE POLICY "Users can read library nodes"
  ON library_nodes FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM libraries
      WHERE libraries.id = library_nodes.library_id
      AND (
        libraries.owner_id = auth.uid()
        OR libraries.public = true
      )
    )
  );

CREATE POLICY "Users can manage library nodes"
  ON library_nodes FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM libraries
      WHERE libraries.id = library_nodes.library_id
      AND libraries.owner_id = auth.uid()
    )
  );

-- ============================================================================
-- LIBRARY COLLECTIONS
-- ============================================================================

CREATE POLICY "Users can read library collections"
  ON library_collections FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM libraries
      WHERE libraries.id = library_collections.library_id
      AND (
        libraries.owner_id = auth.uid()
        OR libraries.public = true
      )
    )
  );

CREATE POLICY "Users can manage library collections"
  ON library_collections FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM libraries
      WHERE libraries.id = library_collections.library_id
      AND libraries.owner_id = auth.uid()
    )
  );

-- ============================================================================
-- TABLETOPS
-- ============================================================================

CREATE POLICY "Users can read tabletops"
  ON tabletops FOR SELECT
  USING (
    auth.uid() = owner_id
    OR auth.uid() = ANY(readers)
    OR auth.uid() = ANY(writers)
  );

CREATE POLICY "Users can create tabletops"
  ON tabletops FOR INSERT
  WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Users can update tabletops"
  ON tabletops FOR UPDATE
  USING (
    auth.uid() = owner_id
    OR auth.uid() = ANY(writers)
  );

CREATE POLICY "Users can delete tabletops"
  ON tabletops FOR DELETE
  USING (auth.uid() = owner_id);

-- ============================================================================
-- MESSAGES
-- ============================================================================

CREATE POLICY "Users can read messages in their tabletops"
  ON messages FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM tabletops
      WHERE tabletops.id = messages.tabletop_id
      AND (
        tabletops.owner_id = auth.uid()
        OR auth.uid() = ANY(tabletops.readers)
        OR auth.uid() = ANY(tabletops.writers)
      )
    )
  );

CREATE POLICY "Users can create messages in accessible tabletops"
  ON messages FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM tabletops
      WHERE tabletops.id = messages.tabletop_id
      AND (
        tabletops.owner_id = auth.uid()
        OR auth.uid() = ANY(tabletops.writers)
      )
    )
  );

-- ============================================================================
-- SUMMARY
-- ============================================================================

DO $$
BEGIN
  RAISE NOTICE '✅ RLS policies created successfully!';
  RAISE NOTICE '';
  RAISE NOTICE 'NOTE: RLS is currently DISABLED for testing.';
  RAISE NOTICE '';
  RAISE NOTICE 'To enable RLS in production:';
  RAISE NOTICE '  1. Uncomment the ALTER TABLE ... ENABLE ROW LEVEL SECURITY statements';
  RAISE NOTICE '  2. Run this script again';
  RAISE NOTICE '  3. Test thoroughly before deploying';
  RAISE NOTICE '';
  RAISE NOTICE 'The app uses service_role key which BYPASSES RLS.';
  RAISE NOTICE 'These policies protect direct database access and future API features.';
END $$;
