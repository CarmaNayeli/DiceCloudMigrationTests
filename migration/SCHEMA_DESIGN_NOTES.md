# PostgreSQL Schema Design Notes

## Overview

This document explains key design decisions for the MongoDB → PostgreSQL migration.

## Design Philosophy

**Goal**: Minimize code changes while leveraging PostgreSQL strengths for cost optimization.

**Strategy**:
1. Keep structure similar to MongoDB
2. Use JSONB for flexible schemas (gradual normalization later)
3. Maintain proven patterns (nested sets, soft deletes)
4. Optimize for 300GB mostly-historical dataset
5. Index strategically (active data only where possible)

---

## Key Design Decisions

### 1. Property Type Storage: Single Table + JSONB

**MongoDB**: One collection with type-based schema selectors
```javascript
CreatureProperties.attachSchema(schema, { selector: { type: 'action' } })
```

**PostgreSQL**: Single table with `type` discriminator + JSONB `data` field
```sql
CREATE TABLE creature_properties (
  type TEXT NOT NULL,  -- 'action', 'spell', 'item', etc.
  data JSONB NOT NULL  -- Type-specific fields
)
```

**Why JSONB?**
- ✅ Minimal code changes (similar to MongoDB documents)
- ✅ Handles 35 property types without 35 tables or complex inheritance
- ✅ PostgreSQL JSONB is fast and indexable
- ✅ Can gradually normalize hot fields later
- ✅ Supabase supports JSONB queries well

**Alternative considered**: Separate tables per type
- ❌ 35+ tables to manage
- ❌ Complex joins
- ❌ Major code refactoring required

**Migration path**: Extract common fields to columns, keep rest in JSONB

---

### 2. Tree Structure: Keep Nested Sets

**Current MongoDB**: Nested set model with `left`/`right` bounds

**PostgreSQL**: Maintain nested sets + add recursive CTE capability

**Why keep nested sets?**
- ✅ Already computed in MongoDB - no recalculation needed
- ✅ Efficient for "get all descendants" queries
- ✅ `left` value provides canonical ordering
- ✅ PostgreSQL supports both nested sets AND recursive CTEs

**Usage patterns**:
```sql
-- Descendants using nested sets (fast)
SELECT * FROM creature_properties
WHERE root_id = $1
  AND tree_left > $2
  AND tree_right < $3;

-- Ancestors using recursive CTE (when needed)
WITH RECURSIVE ancestors AS (
  SELECT * FROM creature_properties WHERE id = $1
  UNION ALL
  SELECT cp.* FROM creature_properties cp
  JOIN ancestors a ON cp.id = a.parent_id
)
SELECT * FROM ancestors;
```

**Migration**: Copy `left`/`right` values directly from MongoDB

---

### 3. Historical Data: Partitioning by Date

**Problem**: 300GB dataset, mostly historical logs

**Solution**: Partition `creature_logs` by year
```sql
CREATE TABLE creature_logs (...) PARTITION BY RANGE (date);
CREATE TABLE creature_logs_2025 PARTITION OF creature_logs
  FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');
```

**Benefits**:
- ✅ Query only relevant partitions (faster)
- ✅ Index recent partitions heavily, old ones lightly
- ✅ Easy to archive old partitions to cold storage
- ✅ Reduces active index size = lower costs

**Cost optimization**:
- Heavy indexes: 2025, 2026 (current/recent)
- Light indexes: 2023, 2024 (moderate access)
- Minimal/none: 2020-2022 (archive candidates)

**Archive strategy** (future):
```sql
-- Detach old partition
ALTER TABLE creature_logs DETACH PARTITION creature_logs_2020;

-- Export to S3/cold storage
pg_dump -t creature_logs_2020 | gzip > s3://archive/logs_2020.sql.gz

-- Drop from PostgreSQL
DROP TABLE creature_logs_2020;
```

---

### 4. Soft Deletes: Keep Pattern

**MongoDB pattern**: `removed`, `removedAt`, `removedWith` fields

**PostgreSQL**: Same pattern with optimized indexes
```sql
removed BOOLEAN DEFAULT FALSE,
removed_at TIMESTAMPTZ,
removed_with UUID,

-- Index only active data
CREATE INDEX ON creatures(owner_id) WHERE removed = FALSE;
```

**Benefits**:
- ✅ No code changes required
- ✅ Partial indexes reduce size/cost
- ✅ Easy to purge old soft-deleted data
- ✅ Maintains audit trail

**Cost optimization**: Partial indexes (`WHERE removed = FALSE`) mean inactive data doesn't bloat indexes.

---

### 5. Sharing Model: Array Columns

**MongoDB**: Arrays of user IDs for `readers`, `writers`

**PostgreSQL**: Same, using PostgreSQL arrays
```sql
readers UUID[],  -- Max 100
writers UUID[],

-- GIN index for array containment
CREATE INDEX ON creatures USING GIN(readers);
```

**Query pattern**:
```sql
-- Check if user can read
SELECT * FROM creatures
WHERE owner_id = $user_id
   OR $user_id = ANY(readers)
   OR $user_id = ANY(writers)
   OR public = TRUE;
```

**Alternative considered**: Junction table
- ❌ More complex queries
- ❌ Max 100 readers/writers makes arrays fine
- ❌ Additional table to manage

---

### 6. Denormalization: Triggers

**MongoDB**: Application-level denormalization
```javascript
Creatures.update(id, { $inc: { propCount: 1 } })
```

**PostgreSQL**: Database triggers
```sql
CREATE TRIGGER trigger_update_creature_prop_count
AFTER INSERT ON creature_properties
EXECUTE FUNCTION update_creature_prop_count();
```

**Why triggers?**
- ✅ Guaranteed consistency (can't forget to update)
- ✅ Works with any client (not just application code)
- ✅ Reduces code complexity
- ❌ Slight performance overhead (acceptable)

**Alternative**: Keep application-level
- ❌ Easy to miss updates
- ❌ Inconsistent state risk

---

### 7. User Authentication: Supabase Auth

**MongoDB**: Meteor accounts system

**PostgreSQL**: Supabase provides `auth.users` table

**Integration**:
```sql
CREATE TABLE user_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  -- DiceCloud-specific fields
)
```

**Migration path**:
1. Export Meteor users
2. Create Supabase auth accounts
3. Link profiles via UUID

---

### 8. Row Level Security (RLS)

**Supabase feature**: Database-level permissions

**Example**:
```sql
ALTER TABLE creatures ENABLE ROW LEVEL SECURITY;

CREATE POLICY creatures_select_own ON creatures
  FOR SELECT
  USING (
    owner_id = auth.uid() OR
    auth.uid() = ANY(readers) OR
    auth.uid() = ANY(writers) OR
    public = TRUE
  );
```

**Benefits**:
- ✅ Security enforced at database level
- ✅ Works with Supabase client automatically
- ✅ No need to check permissions in every query

**Migration**: Add RLS policies after schema creation

---

## Field Mapping Reference

### Common Mappings

| MongoDB Type | PostgreSQL Type | Notes |
|--------------|----------------|-------|
| `String` | `TEXT` | VARCHAR if max length known |
| `Number` | `NUMERIC` / `INTEGER` | INTEGER for whole numbers |
| `Boolean` | `BOOLEAN` | Direct mapping |
| `Date` | `TIMESTAMPTZ` | With timezone |
| `Array` | `ARRAY` / `JSONB` | Arrays for simple types, JSONB for complex |
| `Object` (flexible) | `JSONB` | For dynamic schemas |
| `ObjectId` | `UUID` | Use uuid-ossp extension |

### Creature Schema Mapping

| MongoDB Field | PostgreSQL Column | Type | Notes |
|--------------|-------------------|------|-------|
| `_id` | `id` | `UUID` | Primary key |
| `name` | `name` | `TEXT` | |
| `owner` | `owner_id` | `UUID` | FK to user_profiles |
| `readers` | `readers` | `UUID[]` | Array column |
| `denormalizedStats.xp` | `denormalized_xp` | `INTEGER` | Flattened |
| `settings` | `settings` | `JSONB` | Keep as JSONB |
| `computeErrors` | `compute_errors` | `JSONB` | Array of objects |

### CreatureProperty Schema Mapping

| MongoDB Field | PostgreSQL Column | Type | Notes |
|--------------|-------------------|------|-------|
| `type` | `type` | `TEXT` | Discriminator |
| `tags` | `tags` | `TEXT[]` | Array |
| `icon` | `icon` | `JSONB` | Complex object |
| (type-specific) | `data` | `JSONB` | All custom fields |
| `root.id` | `root_id` | `UUID` | Flattened |
| `root.collection` | `root_collection` | `TEXT` | Flattened |
| `left` | `tree_left` | `INTEGER` | Nested set |
| `right` | `tree_right` | `INTEGER` | Nested set |

---

## Index Strategy

### Principle: Index Active Data Only

Use partial indexes to exclude soft-deleted and historical data:

```sql
-- Bad: Indexes everything
CREATE INDEX idx_creatures_owner ON creatures(owner_id);

-- Good: Indexes only active records
CREATE INDEX idx_creatures_owner ON creatures(owner_id) WHERE removed = FALSE;
```

**Cost impact**: 10% active, 90% deleted → **90% smaller index** → lower storage cost & faster queries

### Index Priority Levels

**Priority 1: Always Index** (hot path queries)
- `creatures`: `owner_id`, `readers`, `writers`, `public`
- `creature_properties`: `creature_id`, `root_id + left + right`
- Foreign keys

**Priority 2: Index Recent Data Only**
- `creature_logs`: Recent partitions (2025-2026)
- Time-series queries

**Priority 3: Optional/Sparse** (use sparingly)
- JSONB fields (GIN indexes are large)
- Full-text search (if needed)

---

## Migration Pipeline Design

### Phase 1: Historical Data (Weeks 1-2)

```
┌─────────────────────┐
│  MongoDB (live)     │
│  Keep running       │
└──────┬──────────────┘
       │ mongodump --query '{ "date": { "$lt": "2025-01-01" } }'
       │
       ▼
┌─────────────────────┐
│  Transform Script   │
│  - Batch: 10k docs  │
│  - Map fields       │
│  - Generate UUIDs   │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│  PostgreSQL (new)   │
│  Old partitions     │
└─────────────────────┘
```

**Priority**: Logs, old experiences, archived creatures

**Why first**: Low risk, reduces active migration size

### Phase 2: Active Data (Week 3)

Migrate current/active data:
- Active creatures
- Recent logs (last 3 months)
- Current sessions

### Phase 3: Code Migration (Weeks 4-12)

Port API files while V2 stays live:
- Convert MongoDB queries → PostgreSQL
- Deploy V3 to separate subdomain
- Sync incremental changes

### Phase 4: Cutover (Week 13+)

Gradual traffic shift:
- Migrate select users to V3
- Monitor & fix issues
- Full switch when stable

---

## Common Query Conversions

### Find Documents

**MongoDB**:
```javascript
Creatures.find({ owner: userId })
```

**PostgreSQL** (Meteor + pg):
```javascript
db.query('SELECT * FROM creatures WHERE owner_id = $1', [userId])
```

**PostgreSQL** (Supabase):
```javascript
supabase.from('creatures').select('*').eq('owner_id', userId)
```

### Array Contains

**MongoDB**:
```javascript
Creatures.find({ readers: userId })
```

**PostgreSQL**:
```sql
SELECT * FROM creatures WHERE $1 = ANY(readers)
```

**Supabase**:
```javascript
supabase.from('creatures').select('*').contains('readers', [userId])
```

### Nested Field Update

**MongoDB**:
```javascript
Creatures.update(id, { $set: { 'settings.hideSpellcasting': true } })
```

**PostgreSQL**:
```sql
UPDATE creatures
SET settings = jsonb_set(settings, '{hideSpellcasting}', 'true'::jsonb)
WHERE id = $1
```

### Increment Counter

**MongoDB**:
```javascript
Creatures.update(id, { $inc: { 'denormalizedStats.xp': 100 } })
```

**PostgreSQL**:
```sql
UPDATE creatures
SET denormalized_xp = denormalized_xp + 100
WHERE id = $1
```

### Tree Descendants

**MongoDB**:
```javascript
CreatureProperties.find({
  'root.id': creatureId,
  left: { $gt: parentLeft },
  right: { $lt: parentRight }
})
```

**PostgreSQL**:
```sql
SELECT * FROM creature_properties
WHERE root_id = $1
  AND tree_left > $2
  AND tree_right < $3
  AND removed = FALSE
```

---

## Cost Optimization Checklist

- [x] Partition historical data (logs by year)
- [x] Use partial indexes (`WHERE removed = FALSE`)
- [x] Index recent partitions only
- [x] Use JSONB for flexible schemas (avoid over-normalization)
- [x] Array columns for bounded lists (readers/writers)
- [ ] Consider archiving logs older than 2 years
- [ ] Review Supabase tier after migration (may fit smaller tier)
- [ ] Set up automated partition management
- [ ] Monitor query performance with `pg_stat_statements`

---

## Performance Considerations

### JSONB Query Performance

**Fast** (indexed):
```sql
-- Existence check
WHERE data ? 'fieldName'

-- Equality
WHERE data->>'fieldName' = 'value'
```

**Slower** (full scan):
```sql
-- Nested path without index
WHERE data->'nested'->'deep'->>'field' = 'value'
```

**Solution**: Extract frequently-queried fields to columns

### Tree Query Performance

**Fast** (nested sets):
```sql
-- Descendants: Index scan on (root_id, tree_left, tree_right)
WHERE root_id = $1 AND tree_left > $2 AND tree_right < $3
```

**Moderate** (recursive CTE):
```sql
-- Ancestors: Sequential scan + recursion
WITH RECURSIVE ... parent_id chain
```

**Guideline**: Use nested sets for descendants, CTEs for ancestors

---

## Testing Strategy

### 1. Schema Validation
- [ ] Create schema on test Supabase instance
- [ ] Test all triggers fire correctly
- [ ] Verify RLS policies work as expected

### 2. Data Migration Testing
- [ ] Migrate 1000 sample documents
- [ ] Verify field mapping accuracy
- [ ] Check tree structure integrity
- [ ] Validate UUID consistency

### 3. Query Performance Testing
- [ ] Run common queries against PostgreSQL
- [ ] Compare execution time to MongoDB
- [ ] Identify slow queries, optimize indexes

### 4. Integration Testing
- [ ] Port one API file completely
- [ ] Run tests against PostgreSQL version
- [ ] Verify Meteor methods work correctly

---

## Migration Tools Needed

### 1. Field Mapper
- Map MongoDB `_id` → PostgreSQL UUID
- Flatten nested objects
- Convert ObjectIds to UUIDs

### 2. Batch Loader
- Read MongoDB in batches (10k docs)
- Transform to PostgreSQL format
- Load with `COPY` command (fast)
- Checkpoint progress

### 3. Validation Tool
- Count records (MongoDB vs PostgreSQL)
- Sample random documents, compare
- Check referential integrity
- Verify tree structure

### 4. Incremental Sync
- Track changes during migration
- Apply deltas to PostgreSQL
- Final sync before cutover

---

## Rollback Plan

If migration fails or issues arise:

1. **During testing**: Just drop PostgreSQL database, restart
2. **During dual-run**: Keep MongoDB running, V2 unaffected
3. **After cutover**:
   - Keep MongoDB read-only for 30 days
   - Can restore from backup
   - Migrate users back to V2 if needed

**Key**: Don't cancel MongoDB hosting until V3 is proven stable (30+ days)

---

## Next Steps

1. **Review this schema** with team
2. **Test on small dataset** (1000 creatures)
3. **Build migration pipeline** (see `migration-pipeline/` docs)
4. **Port one API file** as proof of concept
5. **Create detailed migration plan** with timeline

---

## Questions to Resolve

- [ ] What's the current breakdown of data volume per collection?
- [ ] Which collections are queried most frequently?
- [ ] Are there specific performance bottlenecks in MongoDB to address?
- [ ] What's the acceptable query response time for V3?
- [ ] Should we archive logs older than X years immediately?
- [ ] Which Supabase tier to target?

---

## References

- PostgreSQL JSONB: https://www.postgresql.org/docs/current/datatype-json.html
- Supabase RLS: https://supabase.com/docs/guides/auth/row-level-security
- Partitioning: https://www.postgresql.org/docs/current/ddl-partitioning.html
- Nested Sets: https://www.postgresql.org/docs/current/queries-with.html
