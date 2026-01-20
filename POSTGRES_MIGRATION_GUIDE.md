# PostgreSQL Migration Guide for DiceCloud

This guide explains how to migrate your DiceCloud application from MongoDB to PostgreSQL (Supabase).

## Overview

The application has been updated to support both MongoDB and PostgreSQL databases. You can switch between them using feature flags, allowing for a gradual, low-risk migration.

## What's Been Changed

### 1. Database Abstraction Layer (`app/imports/api/db/`)

New files created:
- `PostgresCollection.ts` - MongoDB-compatible API wrapper for PostgreSQL
- `dbConfig.ts` - Database configuration and feature flags
- `createCollection.ts` - Collection factory that creates either MongoDB or PostgreSQL collections
- `index.ts` - Module exports

### 2. Updated Collections

The following collections have been updated to support PostgreSQL:
- **Creatures** (`creatures` → `creatures`)
- **CreatureProperties** (`creatureProperties` → `creature_properties`)
- **CreatureVariables** (`creatureVariables` → `creature_variables`)
- **CreatureLogs** (`creatureLogs` → `creature_logs`)
- **Experiences** (`experiences` → `experiences`)
- **Libraries** (`libraries` → `libraries`)
- **LibraryNodes** (`libraryNodes` → `library_nodes`)

### 3. Dependencies Added

New npm packages in `app/package.json`:
- `@supabase/supabase-js@^2.39.0` - Supabase client
- `pg@^8.11.3` - PostgreSQL driver
- `@types/pg@^8.10.9` - TypeScript definitions (dev)

## Prerequisites

Before migrating:

1. **Set up Supabase account**
   - Create a project at https://supabase.com
   - Upgrade to Pro plan for production use
   - Note your connection credentials

2. **Run the PostgreSQL schema**
   ```bash
   # In Supabase SQL Editor, run:
   cat migration/postgres-schema.sql
   ```

3. **Migrate your data** (using migration tools)
   ```bash
   cd migration/tools
   npm install
   cp .env.example .env
   # Edit .env with your credentials
   npm run test-connection
   npm run migrate creatures
   # ... migrate other collections
   ```

## Configuration

### Step 1: Install Dependencies

```bash
cd app
meteor npm install
```

### Step 2: Configure Meteor Settings

Create a new settings file or update your existing one:

```bash
cp settings-postgres.example.json settings-postgres.json
```

Edit `settings-postgres.json`:

```json
{
  "public": {
    "usePostgres": {
      "creatures": false,
      "creatureProperties": false,
      "creatureVariables": false,
      "creatureLogs": false,
      "experiences": false,
      "libraries": false,
      "libraryNodes": false,
      "users": false
    }
  },
  "postgres": {
    "host": "db.yourproject.supabase.co",
    "port": 5432,
    "database": "postgres",
    "user": "postgres",
    "password": "your_database_password",
    "poolSize": 20,
    "supabaseUrl": "https://yourproject.supabase.co",
    "supabaseKey": "your_supabase_service_role_key"
  }
}
```

### Step 3: Start the Application

```bash
meteor run --settings settings-postgres.json
```

At this point, the application is still using MongoDB for all collections (all flags are `false`).

## Gradual Migration Strategy

Enable PostgreSQL for collections one at a time to minimize risk.

### Phase 1: Test with Low-Risk Collection

Start with a non-critical collection like `experiences`:

```json
{
  "public": {
    "usePostgres": {
      "experiences": true,
      "creatures": false,
      // ... others false
    }
  }
}
```

Restart the application and test:
- Creating experiences
- Viewing experiences
- Deleting experiences
- All related functionality

### Phase 2: Enable Core Collections

Once confident, enable core collections:

```json
{
  "public": {
    "usePostgres": {
      "creatures": true,
      "creatureProperties": true,
      "creatureVariables": true,
      "experiences": true,
      // ... others as needed
    }
  }
}
```

### Phase 3: Full Migration

Enable all remaining collections:

```json
{
  "public": {
    "usePostgres": {
      "creatures": true,
      "creatureProperties": true,
      "creatureVariables": true,
      "creatureLogs": true,
      "experiences": true,
      "libraries": true,
      "libraryNodes": true,
      "users": true
    }
  }
}
```

## Rollback Plan

If issues occur, you can immediately roll back by:

1. **Disable PostgreSQL flags**
   ```json
   {
     "public": {
       "usePostgres": {
         "creatures": false,
         // ... set all to false
       }
     }
   }
   ```

2. **Restart the application**
   ```bash
   # Application will use MongoDB again
   meteor run --settings settings.json
   ```

3. **Data is still in MongoDB** (not deleted)

## Testing Checklist

Before going live with PostgreSQL:

### Functionality Tests
- [ ] User login/logout
- [ ] Create new creature
- [ ] Edit creature properties
- [ ] Add/remove properties
- [ ] Calculate stats
- [ ] Roll dice/actions
- [ ] View logs
- [ ] Add/remove XP
- [ ] Create/edit libraries
- [ ] Copy library nodes to creatures
- [ ] Share creatures
- [ ] Tabletop integration

### Performance Tests
- [ ] Load time for creature sheet
- [ ] Query performance (profile slow queries)
- [ ] Bulk operations (e.g., copying large libraries)
- [ ] Concurrent users (stress test)

### Data Integrity Tests
- [ ] Count matches (MongoDB vs PostgreSQL)
- [ ] Spot-check critical records
- [ ] Referential integrity (no orphaned records)
- [ ] Tree structure validity (left/right indices)

## Known Limitations & Considerations

### 1. MongoDB Operators

Some MongoDB-specific query operators may need special handling:
- `$inc` - Implemented with SQL `field = field + value`
- `$push` / `$pull` - Array operations need custom SQL
- `$addToSet` - Requires array containment checks

### 2. Indexes

PostgreSQL indexes are defined in the schema, but may need optimization:
- Check query plans: `EXPLAIN ANALYZE SELECT ...`
- Add indexes for slow queries
- Consider partial indexes for filtered queries

### 3. Transactions

PostgreSQL supports ACID transactions, MongoDB's are limited:
- Take advantage of transactions for multi-step operations
- Use `BEGIN` / `COMMIT` / `ROLLBACK` as needed

### 4. Full-Text Search

MongoDB's text search differs from PostgreSQL:
- PostgreSQL uses `tsvector` and `tsquery`
- Update search implementations if needed

## Monitoring

### Application Logs

Watch for:
```
[DB] Creating PostgreSQL collection: creatures → creatures
[DB] Creating MongoDB collection: libraries
```

This shows which database each collection is using.

### PostgreSQL Query Performance

In Supabase dashboard:
1. Go to Database → Query Performance
2. Monitor slow queries
3. Add indexes as needed

### Error Handling

If you see errors like:
```
Error: PostgreSQL pool not initialized
```

Check:
- `settings-postgres.json` is loaded
- PostgreSQL credentials are correct
- Supabase database is not paused

## Production Deployment

### Before Deployment

1. **Full data migration complete**
   - All collections migrated
   - Validation passed
   - No discrepancies

2. **Staging environment tested**
   - All features working
   - Performance acceptable
   - No critical bugs

3. **Rollback plan ready**
   - MongoDB still available
   - Quick switch back possible
   - Team trained on rollback

### Deployment Steps

1. **Schedule maintenance window** (1-2 hours recommended)

2. **Deploy updated application**
   ```bash
   meteor build ../build --architecture os.linux.x86_64
   # Deploy bundle to server
   ```

3. **Start with PostgreSQL disabled**
   ```bash
   # All flags false initially
   node main.js
   ```

4. **Final data sync** (if needed)
   ```bash
   cd migration/tools
   npm run migrate creatures -- --batch-size 5000
   ```

5. **Enable PostgreSQL collections**
   ```bash
   # Update settings, restart server
   ```

6. **Monitor closely**
   - Watch error logs
   - Check response times
   - Monitor database connections

7. **Celebrate!** 🎉

### Post-Deployment

1. **Monitor for 30 days**
   - Keep MongoDB running as backup
   - Watch for edge case issues
   - Optimize queries as needed

2. **After stability confirmed**
   - Export final MongoDB backup
   - Cancel MongoDB hosting
   - Enjoy cost savings ($800+/month)

## Cost Comparison

### Before (MongoDB)
- Hosting: ~$1000/month
- Storage (300GB): Included
- **Total: $1000/month**

### After (Supabase)
- Pro plan: $25/month
- Storage (292GB): $36.50/month
- Large compute: $110/month
- **Total: $172/month**

**Savings: $828/month ($9,936/year)**

## Troubleshooting

### Issue: "PostgreSQL pool not initialized"

**Cause:** Settings not loaded or incorrect

**Fix:**
```bash
meteor run --settings settings-postgres.json
```

### Issue: "Connection timeout"

**Cause:** Supabase database paused or wrong credentials

**Fix:**
1. Check Supabase dashboard
2. Unpause database if needed
3. Verify credentials in settings

### Issue: "Duplicate key violation"

**Cause:** Data already exists in PostgreSQL

**Fix:**
- Expected on re-migration
- Uses `ON CONFLICT (id) DO NOTHING`
- Safe to ignore

### Issue: "Foreign key constraint violation"

**Cause:** Referenced record doesn't exist

**Fix:**
- Migrate dependencies first (e.g., users before creatures)
- Check migration order in tools

### Issue: Slow queries

**Cause:** Missing indexes or poor query plan

**Fix:**
```sql
-- Check query plan
EXPLAIN ANALYZE SELECT * FROM creatures WHERE owner_id = 'uuid';

-- Add index if needed
CREATE INDEX idx_creatures_owner ON creatures(owner_id);
```

## Support & Resources

- **Migration Plan**: `migration/QUICK_MIGRATION_PLAN.md`
- **Schema Documentation**: `migration/SCHEMA_DESIGN_NOTES.md`
- **Migration Tools**: `migration/tools/README.md`
- **PostgreSQL Schema**: `migration/postgres-schema.sql`

## Next Steps

1. **Install dependencies**: `cd app && meteor npm install`
2. **Configure settings**: `cp settings-postgres.example.json settings-postgres.json`
3. **Test locally**: `meteor run --settings settings-postgres.json`
4. **Enable one collection**: Start with `experiences`
5. **Test thoroughly**: Run through checklist
6. **Gradually expand**: Enable more collections
7. **Deploy to production**: Follow deployment steps

Good luck with the migration! 🚀
