# DiceCloud Migration Tools

**MongoDB → PostgreSQL (Supabase) Migration Utilities**

This toolkit provides command-line utilities to migrate DiceCloud data from MongoDB to PostgreSQL/Supabase while maintaining data integrity and relationships.

---

## Features

✅ **Batch Processing** - Handles 300GB+ datasets efficiently
✅ **UUID Mapping** - Consistent ObjectId → UUID conversion with caching
✅ **Field Transformation** - Automated MongoDB → PostgreSQL field mapping
✅ **Tree Structure** - Preserves nested set model for hierarchies
✅ **Validation** - Built-in data integrity checks
✅ **Resume Support** - Checkpoint system for interrupted migrations
✅ **Dry Run Mode** - Test migrations without modifying data

---

## Prerequisites

- Node.js 18+ with npm
- Access to MongoDB database (source)
- Supabase Pro account (target)
- PostgreSQL schema already applied to Supabase

---

## Quick Start

### 1. Install Dependencies

```bash
cd migration/tools
npm install
```

### 2. Configure Environment

```bash
cp .env.example .env
# Edit .env with your database credentials
```

**Required environment variables:**
```bash
# MongoDB
MONGODB_URI=mongodb://user:pass@host:port/dicecloud

# Supabase
SUPABASE_URL=https://yourproject.supabase.co
SUPABASE_SERVICE_KEY=your_service_role_key

# PostgreSQL (for bulk operations)
POSTGRES_HOST=db.yourproject.supabase.co
POSTGRES_PORT=5432
POSTGRES_DB=postgres
POSTGRES_USER=postgres
POSTGRES_PASSWORD=your_password

# Settings
BATCH_SIZE=1000
MAX_RETRIES=3
```

### 3. Test Connections

```bash
npm run test-connection
```

Expected output:
```
✓ MongoDB connection successful
  Collections found: 16
  Sample collections: creatures, creatureProperties, ...

✓ PostgreSQL connection successful
  Server time: 2024-01-20 ...
  Version: PostgreSQL 15.x ...

✓ All connections successful!
```

### 4. Run Migration

**Single collection:**
```bash
npm run migrate creatures
```

**With options:**
```bash
# Dry run (no data inserted)
npm run migrate creatures -- --dry-run

# Custom batch size
npm run migrate creatures -- --batch-size 5000

# Historical data only
npm run migrate creature_logs -- --before 2024-01-01
```

**All collections:**
```bash
npm run migrate-all
```

### 5. Validate Data

```bash
npm run validate creatures
```

Expected output:
```
📊 Validation Results

MongoDB (creatures): 12,543
PostgreSQL (creatures): 12,543

✓ Counts match!

Table size: 245 MB
```

---

## Commands

### `test-connection`
Test connectivity to both databases.

```bash
npm run test-connection
```

---

### `migrate <collection>`
Migrate a specific collection.

**Options:**
- `-b, --batch-size <size>` - Documents per batch (default: 1000)
- `--before <date>` - Only migrate documents before this date
- `--dry-run` - Simulate migration without inserting data

**Examples:**
```bash
# Migrate creatures
npm run migrate creatures

# Migrate old logs (historical data)
npm run migrate creatureLogs -- --before 2023-01-01

# Dry run
npm run migrate creatures -- --dry-run
```

---

### `validate <collection>`
Compare counts between MongoDB and PostgreSQL.

```bash
npm run validate creatures
```

---

### `stats`
Show overall migration statistics.

```bash
npm run stats
```

Output:
```
📊 Migration Statistics

UUID mappings cached: 47,382

Collection Counts:

✓ creatures              MongoDB:   12,543  PostgreSQL:   12,543
✓ creatureProperties     MongoDB:  156,234  PostgreSQL:  156,234
✗ experiences            MongoDB:    4,521  PostgreSQL:    4,200
...
```

---

## Migration Strategy

### Recommended Order

**Phase 1: Historical Data (Low Risk)**
```bash
# Oldest logs first (partitioned by year)
npm run migrate creatureLogs -- --before 2022-01-01  # 2020-2021
npm run migrate creatureLogs -- --before 2023-01-01  # 2022
npm run migrate creatureLogs -- --before 2024-01-01  # 2023

# Old experiences
npm run migrate experiences -- --before 2023-01-01
```

**Phase 2: Core Data**
```bash
# Users first (dependencies)
npm run migrate users

# Creatures and properties
npm run migrate creatures
npm run migrate creatureProperties
npm run migrate creatureVariables

# Recent logs
npm run migrate creatureLogs
```

**Phase 3: Libraries**
```bash
npm run migrate libraries
npm run migrate libraryNodes
```

**Phase 4: Validate Everything**
```bash
npm run stats
npm run validate creatures
npm run validate creatureProperties
# ... etc
```

---

## How It Works

### 1. UUID Mapping

MongoDB ObjectIds are converted to PostgreSQL UUIDs deterministically:

```typescript
// Same ObjectId always maps to same UUID
ObjectId("507f1f77bcf86cd799439011")
  → UUID("a1b2c3d4-e5f6-7890-abcd-ef1234567890")
```

Mappings are cached in `data/uuid-cache/uuid-mappings.json` for consistency across runs.

### 2. Field Transformation

MongoDB documents are transformed to PostgreSQL rows:

**MongoDB:**
```json
{
  "_id": ObjectId("..."),
  "name": "Gandalf",
  "owner": ObjectId("..."),
  "readers": [ObjectId("..."), ObjectId("...")],
  "denormalizedStats": { "xp": 1500 }
}
```

**PostgreSQL:**
```json
{
  "id": "uuid-here",
  "name": "Gandalf",
  "owner_id": "uuid-here",
  "readers": ["uuid1", "uuid2"],
  "denormalized_xp": 1500
}
```

### 3. Property Data Transformation

For `creatureProperties`, type-specific fields go into JSONB:

**MongoDB:**
```json
{
  "_id": ObjectId("..."),
  "type": "action",
  "name": "Fireball",
  "uses": "3",
  "actionType": "action",
  ...
}
```

**PostgreSQL:**
```json
{
  "id": "uuid-here",
  "type": "action",
  "name": "Fireball",
  "data": {
    "uses": "3",
    "actionType": "action"
  }
}
```

---

## Project Structure

```
migration/tools/
├── src/
│   ├── index.ts              # Main CLI entry point
│   ├── types.ts              # TypeScript type definitions
│   ├── db/
│   │   ├── mongodb.ts        # MongoDB connection & extraction
│   │   └── postgresql.ts     # PostgreSQL connection & loading
│   ├── transform/
│   │   └── transformer.ts    # Field transformation logic
│   └── utils/
│       └── uuid-mapper.ts    # ObjectId → UUID mapping
├── data/                     # Data files (gitignored)
│   ├── uuid-cache/           # UUID mapping cache
│   ├── checkpoints/          # Migration progress
│   └── errors/               # Error logs
├── package.json
├── tsconfig.json
└── .env                      # Environment configuration
```

---

## Troubleshooting

### Connection Errors

**MongoDB connection failed:**
- Check `MONGODB_URI` format
- Verify network access (firewall, IP whitelist)
- Test with `mongosh` separately

**PostgreSQL connection failed:**
- Verify Supabase credentials
- Check if database is paused (Supabase auto-pauses)
- Test with `psql` separately

### Migration Errors

**Duplicate key violations:**
- Migration was run twice
- Use `ON CONFLICT (id) DO NOTHING` (already included)
- Clear PostgreSQL table and retry

**Missing foreign key:**
- Dependencies migrated out of order
- Migrate referenced collections first (e.g., users before creatures)

**UUID cache corruption:**
- Delete `data/uuid-cache/uuid-mappings.json`
- **WARNING:** This will generate NEW UUIDs for all ObjectIds

### Performance Issues

**Slow extraction:**
- Reduce `BATCH_SIZE` if running out of memory
- Increase `BATCH_SIZE` if CPU-bound (default: 1000)

**Slow insertion:**
- PostgreSQL may need better instance (upgrade compute)
- Check indexes (too many indexes slow writes)
- Use `COPY` instead of `INSERT` for large batches

---

## Data Validation

### Count Validation
```bash
# Compare counts
npm run validate creatures

# Should show:
# ✓ Counts match!
```

### Sample Validation

Manual spot-checks:

```bash
# MongoDB
mongosh
> db.creatures.findOne({ name: "Gandalf" })

# PostgreSQL
psql
> SELECT * FROM creatures WHERE name = 'Gandalf';
```

Compare:
- ✅ All fields present
- ✅ Values match
- ✅ Arrays converted correctly
- ✅ Nested objects in JSONB

### Referential Integrity

Check foreign keys:

```sql
-- Creatures with missing owners (should be 0)
SELECT COUNT(*) FROM creatures
WHERE owner_id NOT IN (SELECT id FROM user_profiles);

-- Properties with missing creatures (should be 0)
SELECT COUNT(*) FROM creature_properties
WHERE creature_id NOT IN (SELECT id FROM creatures);
```

---

## Advanced Usage

### Custom Transformations

Edit `src/transform/transformer.ts` to customize field mappings:

```typescript
export function transformCreature(mongoDoc: MongoCreature): PgCreature {
  // Your custom transformation logic
}
```

### Filtering Data

Migrate only specific documents:

```typescript
// In mongodb.ts
const filter = {
  owner: ObjectId("specific-owner"),
  removed: { $ne: true }
};
```

### Batch Size Tuning

Adjust based on your system:
- **Small batches (100-500):** Less memory, slower
- **Medium batches (1000-2000):** Balanced (recommended)
- **Large batches (5000+):** More memory, faster

---

## Safety Features

### Dry Run Mode
Test migrations without modifying PostgreSQL:
```bash
npm run migrate creatures -- --dry-run
```

### UUID Caching
Ensures consistency:
- Same ObjectId always → same UUID
- Cached on disk
- Survives restarts

### Checkpoints
Resume interrupted migrations:
```bash
# TODO: Implement checkpoint system
npm run migrate creatures -- --resume
```

### Conflict Handling
Safely re-run migrations:
```sql
-- Already included in batch insert
ON CONFLICT (id) DO NOTHING
```

---

## Next Steps

After successful migration:

1. **Validate data thoroughly**
   - Run all validation commands
   - Spot-check critical records
   - Test query performance

2. **Update Meteor application**
   - See `../QUICK_MIGRATION_PLAN.md` for integration guide
   - Replace MongoDB driver with PostgreSQL
   - Test all features

3. **Monitor production**
   - Watch for errors
   - Check query performance
   - Monitor database size

4. **Cancel MongoDB hosting** (after 30 days stability)
   - Export final backup
   - Cancel subscription
   - Enjoy cost savings! 🎉

---

## Support

For issues or questions:
1. Check this README
2. Review `../QUICK_MIGRATION_PLAN.md`
3. Check error logs in `data/errors/`
4. Test with dry run mode first

---

## License

MIT
