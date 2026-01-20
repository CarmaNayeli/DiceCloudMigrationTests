-- ============================================================================
-- DiceCloud v3 PostgreSQL Schema
-- MongoDB to Supabase Migration
-- ============================================================================
-- Design Principles:
-- 1. Keep similar structure to MongoDB for easier code migration
-- 2. Use JSONB for flexible fields (35 property types)
-- 3. Maintain nested set model for tree structures
-- 4. Implement soft deletes with cascading
-- 5. Partition historical data for cost optimization
-- 6. Index only active data where possible
-- ============================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- USERS & AUTHENTICATION
-- ============================================================================
-- Note: Supabase provides auth.users table by default
-- We extend it with a profiles table for DiceCloud-specific data

CREATE TABLE user_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT,
  display_name TEXT,
  picture TEXT,

  -- Patreon/tier info
  patreon_tier TEXT,
  paid_benefits BOOLEAN DEFAULT FALSE,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_user_profiles_username ON user_profiles(username);

-- ============================================================================
-- CREATURES (Main Character/NPC/Monster collection)
-- ============================================================================
CREATE TABLE creatures (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  -- Basic info
  name TEXT DEFAULT '',
  alignment TEXT,
  gender TEXT,
  picture TEXT, -- URL
  avatar_picture TEXT, -- URL
  type TEXT DEFAULT 'pc' CHECK (type IN ('pc', 'npc', 'monster')),

  -- Libraries allowed for this creature
  allowed_libraries TEXT[], -- Array of library IDs
  allowed_library_collections TEXT[], -- Array of collection IDs

  -- Denormalized stats (cached from other tables)
  denormalized_xp INTEGER DEFAULT 0,
  denormalized_milestone_levels INTEGER DEFAULT 0,
  prop_count INTEGER DEFAULT 0, -- Count of properties

  -- Computation state
  dirty BOOLEAN DEFAULT FALSE, -- Needs recomputation
  compute_version TEXT, -- Version of engine used
  compute_errors JSONB, -- Array of error objects
  last_computed_at TIMESTAMPTZ,

  -- Tabletop integration
  tabletop_id UUID,
  initiative_roll INTEGER,

  -- Settings (flexible nested object)
  settings JSONB DEFAULT '{}'::jsonb,

  -- Color
  color TEXT, -- Hex color #A23F56

  -- Sharing/permissions
  owner_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  readers UUID[], -- Max 100 user IDs
  writers UUID[], -- Max 100 user IDs
  public BOOLEAN DEFAULT FALSE,
  readers_can_copy BOOLEAN DEFAULT FALSE,

  -- Soft delete
  removed BOOLEAN DEFAULT FALSE,
  removed_at TIMESTAMPTZ,
  removed_with UUID, -- ID that triggered cascade delete

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for creatures (only on non-removed by default)
CREATE INDEX idx_creatures_owner ON creatures(owner_id) WHERE removed = FALSE;
CREATE INDEX idx_creatures_readers ON creatures USING GIN(readers) WHERE removed = FALSE;
CREATE INDEX idx_creatures_writers ON creatures USING GIN(writers) WHERE removed = FALSE;
CREATE INDEX idx_creatures_public ON creatures(public) WHERE removed = FALSE AND public = TRUE;
CREATE INDEX idx_creatures_tabletop ON creatures(tabletop_id) WHERE removed = FALSE;
CREATE INDEX idx_creatures_dirty ON creatures(dirty) WHERE removed = FALSE AND dirty = TRUE;

-- Index for soft delete queries
CREATE INDEX idx_creatures_removed ON creatures(removed, removed_at);

COMMENT ON TABLE creatures IS 'Main character, NPC, and monster data';
COMMENT ON COLUMN creatures.prop_count IS 'Denormalized count of properties - updated via trigger';
COMMENT ON COLUMN creatures.dirty IS 'Flag indicating creature needs recomputation';
COMMENT ON COLUMN creatures.readers IS 'Array of user IDs with read permission (max 100)';

-- ============================================================================
-- CREATURE PROPERTIES (35 different property types)
-- ============================================================================
-- All property types stored in one table with type discriminator
-- Type-specific data stored in JSONB 'data' field
-- Property types: action, adjustment, attribute, buff, buffRemover, branch,
-- class, classLevel, constant, container, damage, damageMultiplier, effect,
-- feature, folder, item, note, pointBuy, proficiency, reference, roll,
-- savingThrow, skill, slot, spellList, spell, toggle, trigger, etc.

CREATE TABLE creature_properties (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  -- Core fields
  creature_id UUID NOT NULL REFERENCES creatures(id) ON DELETE CASCADE,
  type TEXT NOT NULL, -- One of 35 property types

  -- Common fields across all types
  name TEXT,
  description TEXT,
  tags TEXT[] DEFAULT '{}', -- Max 100 tags
  disabled BOOLEAN DEFAULT FALSE,

  -- Icon (stored as JSONB object)
  icon JSONB,

  -- Reference to library node this was copied from
  library_node_id UUID,

  -- Slot filling (for feats, ability score improvements)
  slot_quantity_filled INTEGER DEFAULT 1,

  -- Type-specific data (flexible JSONB field)
  -- This contains all the fields specific to each property type
  -- Examples: 'amount', 'target', 'uses', 'baseValue', etc.
  data JSONB NOT NULL DEFAULT '{}'::jsonb,

  -- Denormalized flags (set during computation)
  inactive BOOLEAN DEFAULT FALSE,
  deactivated_by_ancestor BOOLEAN DEFAULT FALSE,
  deactivated_by_self BOOLEAN DEFAULT FALSE,
  deactivated_by_toggle BOOLEAN DEFAULT FALSE,
  deactivating_toggle_id UUID,
  trigger_ids JSONB, -- {before: [], after: [], afterChildren: []}
  dirty BOOLEAN DEFAULT TRUE, -- New properties trigger recompute

  -- Color
  color TEXT,

  -- Tree structure (nested set model)
  root_id UUID NOT NULL, -- Always references creature_id for creature properties
  root_collection TEXT NOT NULL DEFAULT 'creatures',
  parent_id UUID, -- NULL means direct child of root
  tree_left INTEGER NOT NULL DEFAULT 2147483646, -- Use left for canonical ordering
  tree_right INTEGER NOT NULL DEFAULT 2147483647,

  -- Order within parent (for manual sorting)
  order_index INTEGER DEFAULT 0,

  -- Soft delete
  removed BOOLEAN DEFAULT FALSE,
  removed_at TIMESTAMPTZ,
  removed_with UUID,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for creature properties
CREATE INDEX idx_creature_props_creature ON creature_properties(creature_id) WHERE removed = FALSE;
CREATE INDEX idx_creature_props_type ON creature_properties(type) WHERE removed = FALSE;
CREATE INDEX idx_creature_props_root ON creature_properties(root_id, tree_left, tree_right);
CREATE INDEX idx_creature_props_parent ON creature_properties(parent_id) WHERE removed = FALSE;
CREATE INDEX idx_creature_props_dirty ON creature_properties(dirty) WHERE removed = FALSE AND dirty = TRUE;
CREATE INDEX idx_creature_props_library_ref ON creature_properties(library_node_id) WHERE removed = FALSE;

-- JSONB indexes for common queries in data field
CREATE INDEX idx_creature_props_data_gin ON creature_properties USING GIN(data);

-- Index for soft delete
CREATE INDEX idx_creature_props_removed ON creature_properties(removed, removed_at);

COMMENT ON TABLE creature_properties IS 'All 35 property types in one table with type discriminator';
COMMENT ON COLUMN creature_properties.data IS 'JSONB field containing type-specific properties';
COMMENT ON COLUMN creature_properties.tree_left IS 'Nested set left bound - use for canonical ordering';
COMMENT ON COLUMN creature_properties.tree_right IS 'Nested set right bound';

-- ============================================================================
-- CREATURE VARIABLES (Computed/cached variables)
-- ============================================================================
-- Dynamic schema - each creature has different variable names
-- Structure: { variableName: {value: 10, ...}, anotherVar: {...} }
CREATE TABLE creature_variables (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  creature_id UUID NOT NULL UNIQUE REFERENCES creatures(id) ON DELETE CASCADE,

  -- All variables stored as JSONB
  -- Top-level keys are variable names
  -- Values are complex objects with calculations, parse nodes, etc.
  variables JSONB NOT NULL DEFAULT '{}'::jsonb,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Unique index on creature_id (one variables doc per creature)
CREATE UNIQUE INDEX idx_creature_variables_creature ON creature_variables(creature_id);

-- GIN index for JSONB queries
CREATE INDEX idx_creature_variables_gin ON creature_variables USING GIN(variables);

COMMENT ON TABLE creature_variables IS 'Computed variables for each creature - one row per creature';
COMMENT ON COLUMN creature_variables.variables IS 'JSONB object where keys are variable names';

-- ============================================================================
-- CREATURE LOGS (Historical action logs - partition by date)
-- ============================================================================
-- This is a good candidate for partitioning due to 300GB mostly historical data
CREATE TABLE creature_logs (
  id UUID DEFAULT uuid_generate_v4(),

  -- Log content (array of field objects)
  content JSONB NOT NULL, -- Array of {name, value, inline} objects

  -- References
  creature_id UUID NOT NULL,
  tabletop_id UUID,
  action_id UUID,
  creature_name TEXT,

  -- Date (partition key)
  date TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  created_at TIMESTAMPTZ DEFAULT NOW(),

  -- Partition by date range
  PRIMARY KEY (id, date)
) PARTITION BY RANGE (date);

-- Create partitions for each year
-- Historical data (adjust years as needed)
CREATE TABLE creature_logs_2020 PARTITION OF creature_logs
  FOR VALUES FROM ('2020-01-01') TO ('2021-01-01');

CREATE TABLE creature_logs_2021 PARTITION OF creature_logs
  FOR VALUES FROM ('2021-01-01') TO ('2022-01-01');

CREATE TABLE creature_logs_2022 PARTITION OF creature_logs
  FOR VALUES FROM ('2022-01-01') TO ('2023-01-01');

CREATE TABLE creature_logs_2023 PARTITION OF creature_logs
  FOR VALUES FROM ('2023-01-01') TO ('2024-01-01');

CREATE TABLE creature_logs_2024 PARTITION OF creature_logs
  FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');

-- Current year (2025)
CREATE TABLE creature_logs_2025 PARTITION OF creature_logs
  FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');

-- Future year
CREATE TABLE creature_logs_2026 PARTITION OF creature_logs
  FOR VALUES FROM ('2026-01-01') TO ('2027-01-01');

CREATE TABLE creature_logs_future PARTITION OF creature_logs
  FOR VALUES FROM ('2027-01-01') TO (MAXVALUE);

-- Indexes on recent partitions only (for performance and cost)
CREATE INDEX idx_creature_logs_2025_creature ON creature_logs_2025(creature_id, date DESC);
CREATE INDEX idx_creature_logs_2025_tabletop ON creature_logs_2025(tabletop_id, date DESC);
CREATE INDEX idx_creature_logs_2026_creature ON creature_logs_2026(creature_id, date DESC);

-- Light indexes on older data
CREATE INDEX idx_creature_logs_2024_creature ON creature_logs_2024(creature_id);
CREATE INDEX idx_creature_logs_2023_creature ON creature_logs_2023(creature_id);

-- NOTE: For logs older than 2023, consider archiving to cold storage or no indexes

COMMENT ON TABLE creature_logs IS 'Historical action logs - partitioned by year for cost optimization';

-- ============================================================================
-- EXPERIENCES (XP tracking)
-- ============================================================================
CREATE TABLE experiences (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  name TEXT,
  xp INTEGER CHECK (xp >= 0), -- XP amount
  levels INTEGER CHECK (levels >= 0), -- Milestone levels

  creature_id UUID NOT NULL REFERENCES creatures(id) ON DELETE CASCADE,

  date TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_experiences_creature ON experiences(creature_id, date DESC);
CREATE INDEX idx_experiences_date ON experiences(date DESC);

COMMENT ON TABLE experiences IS 'XP and milestone level tracking for creatures';

-- ============================================================================
-- LIBRARIES (Reusable content collections)
-- ============================================================================
CREATE TABLE libraries (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  name TEXT NOT NULL,
  description TEXT,

  show_in_market BOOLEAN DEFAULT FALSE,
  subscriber_count INTEGER DEFAULT 0,

  -- Sharing/permissions
  owner_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  readers UUID[],
  writers UUID[],
  public BOOLEAN DEFAULT FALSE,
  readers_can_copy BOOLEAN DEFAULT FALSE,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_libraries_owner ON libraries(owner_id);
CREATE INDEX idx_libraries_market ON libraries(show_in_market, subscriber_count DESC) WHERE show_in_market = TRUE;
CREATE INDEX idx_libraries_readers ON libraries USING GIN(readers);
CREATE INDEX idx_libraries_writers ON libraries USING GIN(writers);

COMMENT ON TABLE libraries IS 'Reusable content libraries that can be shared and subscribed to';

-- ============================================================================
-- LIBRARY NODES (Tree structure of library content)
-- ============================================================================
-- Similar to creature_properties but for library content
CREATE TABLE library_nodes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  library_id UUID NOT NULL REFERENCES libraries(id) ON DELETE CASCADE,

  -- Node type (same as creature property types)
  type TEXT NOT NULL,

  -- Common fields
  name TEXT,
  description TEXT,
  tags TEXT[] DEFAULT '{}',

  -- Type-specific data
  data JSONB NOT NULL DEFAULT '{}'::jsonb,

  -- Color
  color TEXT,

  -- Tree structure
  root_id UUID NOT NULL, -- References library_id
  root_collection TEXT NOT NULL DEFAULT 'libraries',
  parent_id UUID, -- NULL means direct child of library
  tree_left INTEGER NOT NULL DEFAULT 2147483646,
  tree_right INTEGER NOT NULL DEFAULT 2147483647,

  -- Soft delete
  removed BOOLEAN DEFAULT FALSE,
  removed_at TIMESTAMPTZ,
  removed_with UUID,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_library_nodes_library ON library_nodes(library_id) WHERE removed = FALSE;
CREATE INDEX idx_library_nodes_root ON library_nodes(root_id, tree_left, tree_right);
CREATE INDEX idx_library_nodes_parent ON library_nodes(parent_id) WHERE removed = FALSE;
CREATE INDEX idx_library_nodes_type ON library_nodes(type) WHERE removed = FALSE;
CREATE INDEX idx_library_nodes_data_gin ON library_nodes USING GIN(data);

COMMENT ON TABLE library_nodes IS 'Tree structure of content within libraries';

-- ============================================================================
-- LIBRARY COLLECTIONS (Groups of libraries)
-- ============================================================================
CREATE TABLE library_collections (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  name TEXT NOT NULL,
  description TEXT,

  -- Libraries in this collection
  library_ids UUID[], -- Array of library IDs

  -- Sharing/permissions
  owner_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  readers UUID[],
  writers UUID[],
  public BOOLEAN DEFAULT FALSE,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_library_collections_owner ON library_collections(owner_id);

-- ============================================================================
-- TABLETOPS (Game sessions)
-- ============================================================================
CREATE TABLE tabletops (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  name TEXT NOT NULL,
  description TEXT,

  -- Sharing/permissions
  owner_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  readers UUID[],
  writers UUID[],

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_tabletops_owner ON tabletops(owner_id);

-- ============================================================================
-- TABLETOP MAPS
-- ============================================================================
CREATE TABLE tabletop_maps (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  tabletop_id UUID NOT NULL REFERENCES tabletops(id) ON DELETE CASCADE,

  name TEXT,
  image_url TEXT,

  -- Map dimensions and settings
  settings JSONB DEFAULT '{}'::jsonb,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_tabletop_maps_tabletop ON tabletop_maps(tabletop_id);

-- ============================================================================
-- TABLETOP OBJECTS (Objects on maps)
-- ============================================================================
CREATE TABLE tabletop_objects (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  map_id UUID NOT NULL REFERENCES tabletop_maps(id) ON DELETE CASCADE,
  creature_id UUID REFERENCES creatures(id) ON DELETE SET NULL,

  -- Position
  x NUMERIC,
  y NUMERIC,

  -- Visual properties
  settings JSONB DEFAULT '{}'::jsonb,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_tabletop_objects_map ON tabletop_objects(map_id);
CREATE INDEX idx_tabletop_objects_creature ON tabletop_objects(creature_id);

-- ============================================================================
-- MESSAGES (Chat/communication)
-- ============================================================================
CREATE TABLE messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  content TEXT NOT NULL,

  -- Context
  tabletop_id UUID REFERENCES tabletops(id) ON DELETE CASCADE,
  author_id UUID REFERENCES user_profiles(id) ON DELETE SET NULL,

  date TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_messages_tabletop ON messages(tabletop_id, date DESC);
CREATE INDEX idx_messages_author ON messages(author_id);

-- ============================================================================
-- INVITES (User invitations)
-- ============================================================================
CREATE TABLE invites (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  email TEXT NOT NULL,
  invited_by UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,

  accepted BOOLEAN DEFAULT FALSE,
  accepted_by UUID REFERENCES user_profiles(id) ON DELETE SET NULL,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ
);

CREATE INDEX idx_invites_email ON invites(email) WHERE accepted = FALSE;

-- ============================================================================
-- ICONS
-- ============================================================================
CREATE TABLE icons (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  name TEXT NOT NULL,
  shape TEXT,

  -- Icon data
  data JSONB NOT NULL,

  -- Sharing
  owner_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
  public BOOLEAN DEFAULT FALSE,

  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_icons_name ON icons(name);
CREATE INDEX idx_icons_owner ON icons(owner_id);

-- ============================================================================
-- TRIGGERS FOR DENORMALIZATION
-- ============================================================================

-- Trigger: Update prop_count when creature_properties change
CREATE OR REPLACE FUNCTION update_creature_prop_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' AND NEW.removed = FALSE THEN
    UPDATE creatures
    SET prop_count = prop_count + 1,
        dirty = TRUE,
        updated_at = NOW()
    WHERE id = NEW.creature_id;
  ELSIF TG_OP = 'DELETE' OR (TG_OP = 'UPDATE' AND NEW.removed = TRUE AND OLD.removed = FALSE) THEN
    UPDATE creatures
    SET prop_count = prop_count - 1,
        dirty = TRUE,
        updated_at = NOW()
    WHERE id = COALESCE(NEW.creature_id, OLD.creature_id);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_creature_prop_count
AFTER INSERT OR UPDATE OR DELETE ON creature_properties
FOR EACH ROW
EXECUTE FUNCTION update_creature_prop_count();

-- Trigger: Update creature dirty flag when properties change
CREATE OR REPLACE FUNCTION mark_creature_dirty()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE creatures
  SET dirty = TRUE, updated_at = NOW()
  WHERE id = NEW.creature_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_mark_creature_dirty_on_prop_change
AFTER UPDATE ON creature_properties
FOR EACH ROW
WHEN (OLD.data IS DISTINCT FROM NEW.data OR OLD.disabled IS DISTINCT FROM NEW.disabled)
EXECUTE FUNCTION mark_creature_dirty();

-- Trigger: Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to all tables with updated_at
CREATE TRIGGER trigger_creatures_updated_at BEFORE UPDATE ON creatures
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trigger_creature_properties_updated_at BEFORE UPDATE ON creature_properties
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trigger_libraries_updated_at BEFORE UPDATE ON libraries
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trigger_library_nodes_updated_at BEFORE UPDATE ON library_nodes
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) - Optional but recommended for Supabase
-- ============================================================================

-- Enable RLS on all tables (examples shown for creatures)
ALTER TABLE creatures ENABLE ROW LEVEL SECURITY;
ALTER TABLE creature_properties ENABLE ROW LEVEL SECURITY;
ALTER TABLE libraries ENABLE ROW LEVEL SECURITY;

-- Example policies for creatures (expand for all tables)
-- Users can read their own creatures
CREATE POLICY creatures_select_own ON creatures
  FOR SELECT
  USING (
    owner_id = auth.uid()
    OR auth.uid() = ANY(readers)
    OR auth.uid() = ANY(writers)
    OR public = TRUE
  );

-- Users can update creatures they own or can write to
CREATE POLICY creatures_update_own ON creatures
  FOR UPDATE
  USING (owner_id = auth.uid() OR auth.uid() = ANY(writers));

-- Users can insert their own creatures
CREATE POLICY creatures_insert_own ON creatures
  FOR INSERT
  WITH CHECK (owner_id = auth.uid());

-- Users can delete their own creatures
CREATE POLICY creatures_delete_own ON creatures
  FOR DELETE
  USING (owner_id = auth.uid());

-- Similar policies needed for creature_properties, libraries, etc.

-- ============================================================================
-- HELPER FUNCTIONS FOR TREE QUERIES
-- ============================================================================

-- Get all descendants of a node (using nested sets)
CREATE OR REPLACE FUNCTION get_descendants(
  p_root_id UUID,
  p_left INTEGER,
  p_right INTEGER,
  p_table TEXT DEFAULT 'creature_properties'
)
RETURNS TABLE (
  id UUID,
  name TEXT,
  type TEXT,
  tree_left INTEGER,
  tree_right INTEGER
) AS $$
BEGIN
  RETURN QUERY EXECUTE format(
    'SELECT id, name, type, tree_left, tree_right
     FROM %I
     WHERE root_id = $1
       AND tree_left > $2
       AND tree_right < $3
       AND removed = FALSE
     ORDER BY tree_left',
    p_table
  ) USING p_root_id, p_left, p_right;
END;
$$ LANGUAGE plpgsql;

-- Get ancestors of a node (using parent_id recursively)
CREATE OR REPLACE FUNCTION get_ancestors(
  p_node_id UUID,
  p_table TEXT DEFAULT 'creature_properties'
)
RETURNS TABLE (
  id UUID,
  name TEXT,
  parent_id UUID
) AS $$
BEGIN
  RETURN QUERY EXECUTE format(
    'WITH RECURSIVE ancestors AS (
      SELECT id, name, parent_id
      FROM %I
      WHERE id = $1

      UNION ALL

      SELECT n.id, n.name, n.parent_id
      FROM %I n
      INNER JOIN ancestors a ON n.id = a.parent_id
    )
    SELECT id, name, parent_id FROM ancestors',
    p_table, p_table
  ) USING p_node_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- MIGRATION METADATA
-- ============================================================================
CREATE TABLE migration_metadata (
  id SERIAL PRIMARY KEY,
  migration_name TEXT NOT NULL,
  started_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  status TEXT CHECK (status IN ('pending', 'in_progress', 'completed', 'failed')),
  records_migrated INTEGER DEFAULT 0,
  notes TEXT
);

COMMENT ON TABLE migration_metadata IS 'Track progress of MongoDB to PostgreSQL migration';

-- ============================================================================
-- INDEXES SUMMARY
-- ============================================================================
-- Total indexes created: ~50+
-- Focus on:
-- - Active data (WHERE removed = FALSE)
-- - Recent partitions only for logs
-- - Sharing queries (GIN indexes on arrays)
-- - Tree queries (root_id, left, right)
-- - Foreign key relationships

-- ============================================================================
-- NEXT STEPS
-- ============================================================================
-- 1. Review and adjust field types based on actual data
-- 2. Add more RLS policies for all tables
-- 3. Set up Supabase Realtime on key tables
-- 4. Create views for common queries
-- 5. Add more trigger functions for complex denormalization
-- 6. Test with sample data
-- 7. Build migration scripts
