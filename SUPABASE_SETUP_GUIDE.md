# DiceCloud with Supabase Realtime - Setup Guide

This guide walks you through setting up a DiceCloud instance using Supabase with Realtime instead of MongoDB oplog tailing.

## Prerequisites

- Node.js 14+ and npm
- Meteor installed: `curl https://install.meteor.com/ | sh`
- A Supabase account (free tier works for testing, Pro for production)
- Git

---

## Part 1: Supabase Setup

### 1.1 Create Supabase Project

1. Go to https://supabase.com and sign in
2. Click "New Project"
3. Fill in:
   - **Name**: `dicecloud-dev` (or your choice)
   - **Database Password**: Generate a strong password and save it
   - **Region**: Choose closest to your users
4. Wait 2-3 minutes for project creation

### 1.2 Get Connection Details

After project is created, go to **Settings → Database**:

```bash
# Note these down:
Host: db.xxxxxxxxxxxxx.supabase.co
Database name: postgres
Port: 5432
User: postgres
Password: [the password you set]
```

Go to **Settings → API**:

```bash
# Note these down:
Project URL: https://xxxxxxxxxxxxx.supabase.co
anon/public key: eyJhbGc...
service_role key: eyJhbGc... (keep this secret!)
```

### 1.3 Run PostgreSQL Schema

1. Go to **SQL Editor** in Supabase dashboard
2. Open the schema file at `/home/user/DiceCloudMigrationTests/migration/postgres-schema.sql`
3. Copy the entire contents
4. Paste into SQL Editor
5. Click "Run" to create all tables

### 1.4 Enable Realtime

In Supabase dashboard, go to **Database → Replication**:

1. Enable replication for these tables (click the toggle):
   - ☑ creatures
   - ☑ creature_properties
   - ☑ creature_variables
   - ☑ creature_logs
   - ☑ libraries
   - ☑ library_nodes
   - ☑ users
   - ☑ experiences

2. Click "Save" or "Apply Changes"

**Important**: Realtime uses PostgreSQL's WAL (Write-Ahead Log). Make sure your Supabase plan supports sufficient database replication.

---

## Part 2: DiceCloud Setup

### 2.1 Clone and Install

```bash
# Clone the repository
git clone https://github.com/CarmaNayeli/DiceCloudMigrationTests dicecloud
cd dicecloud/app

# Install dependencies
meteor npm install

# Install additional Supabase dependencies
meteor npm install @supabase/supabase-js pg
```

### 2.2 Configure Settings

Create `settings-local.json` in the `app/` directory:

```bash
cp settings-postgres.example.json settings-local.json
```

Edit `settings-local.json` with your Supabase credentials:

```json
{
  "public": {
    "environment": "development",
    "disablePatreon": true,
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
  },
  "postgres": {
    "host": "db.xxxxxxxxxxxxx.supabase.co",
    "port": 5432,
    "database": "postgres",
    "user": "postgres",
    "password": "YOUR_DATABASE_PASSWORD",
    "poolSize": 20,
    "supabaseUrl": "https://xxxxxxxxxxxxx.supabase.co",
    "supabaseKey": "YOUR_SERVICE_ROLE_KEY"
  }
}
```

**Replace:**
- `db.xxxxxxxxxxxxx.supabase.co` → your Supabase host
- `YOUR_DATABASE_PASSWORD` → your database password
- `https://xxxxxxxxxxxxx.supabase.co` → your project URL
- `YOUR_SERVICE_ROLE_KEY` → your service role key

### 2.3 Start DiceCloud

```bash
cd app
meteor run --settings settings-local.json
```

You should see:

```
=> Started proxy.
=> [HMR] Dev server listening on port 3003.
=> Started your app.
=> App running at: http://localhost:3000/

[DB] Creating PostgreSQL collection: creatures → creatures
[DB] Creating PostgreSQL collection: creatureProperties → creature_properties
[Realtime] Subscribed to changes on creatures
[Realtime] Subscribed to changes on creature_properties
...
```

Visit http://localhost:3000/ to see DiceCloud running!

---

## Part 3: Testing Realtime

### 3.1 Create a Test User

1. Open http://localhost:3000/
2. Click "Sign Up"
3. Create an account

### 3.2 Test Real-Time Updates

**Terminal 1 - Open psql:**
```bash
# Connect to your Supabase database
psql "postgresql://postgres:YOUR_PASSWORD@db.xxxxxxxxxxxxx.supabase.co:5432/postgres"
```

**Terminal 2 - Watch DiceCloud:**
Open http://localhost:3000/ and create a character

**Terminal 1 - Update in database:**
```sql
-- Find your creature
SELECT id, name FROM creatures LIMIT 5;

-- Update it
UPDATE creatures
SET name = 'Updated from Database!'
WHERE id = 'your-creature-id';
```

**Result**: The name should instantly update in your browser! 🎉

This proves Supabase Realtime is working as a replacement for MongoDB oplog tailing.

---

## Part 4: Migrating Data from MongoDB (Optional)

If you have existing MongoDB data to migrate:

### 4.1 Set up MongoDB Connection

In `settings-local.json`, add:

```json
{
  "mongodb": {
    "url": "mongodb://localhost:27017/meteor"
  },
  "postgres": { ... }
}
```

### 4.2 Run Migration Tools

```bash
cd migration/tools

# Copy environment template
cp .env.example .env

# Edit .env with your credentials
nano .env

# Install dependencies
npm install

# Run migration
npm run migrate -- --all
```

See `/migration/QUICK_MIGRATION_PLAN.md` for detailed migration instructions.

---

## Part 5: Configuration Options

### 5.1 Feature Flags

Enable/disable PostgreSQL per collection in `settings-local.json`:

```json
{
  "public": {
    "usePostgres": {
      "creatures": true,        // Use PostgreSQL
      "libraries": false,       // Use MongoDB
      "libraryNodes": true      // Use PostgreSQL
    }
  }
}
```

This allows **gradual migration** - you can test one collection at a time!

### 5.2 Performance Tuning

For production, adjust pool size and Realtime settings:

```json
{
  "postgres": {
    "poolSize": 50,              // Increase for more concurrent users
    "idleTimeoutMillis": 30000,
    "connectionTimeoutMillis": 10000
  },
  "realtime": {
    "eventsPerSecond": 10,      // Rate limit for Realtime events
    "maxChannelsPerClient": 100
  }
}
```

### 5.3 Production Checklist

Before deploying to production:

- [ ] Upgrade to Supabase Pro plan
- [ ] Set up database backups (Settings → Database → Backups)
- [ ] Configure point-in-time recovery (PITR)
- [ ] Set up monitoring (Settings → Monitoring)
- [ ] Enable SSL enforcement
- [ ] Set up proper indexes (see `postgres-schema.sql`)
- [ ] Test with production-like data volume
- [ ] Load test with expected concurrent users
- [ ] Configure rate limiting
- [ ] Set up error tracking (Sentry, etc.)

---

## Part 6: Troubleshooting

### Issue: "PostgreSQL pool not initialized"

**Cause**: Missing or incorrect Supabase credentials

**Fix**:
1. Check `settings-local.json` has all postgres fields
2. Verify credentials in Supabase dashboard
3. Restart Meteor: `meteor reset && meteor run --settings settings-local.json`

### Issue: "Realtime not working"

**Cause**: Tables not enabled for replication

**Fix**:
1. Go to Supabase → Database → Replication
2. Enable all DiceCloud tables
3. Wait 1-2 minutes for changes to propagate
4. Restart your app

### Issue: "Connection timeout"

**Cause**: Firewall or network issue

**Fix**:
1. Check your IP is allowed in Supabase → Settings → Database → Connection Pooling
2. Try connection pooler URL instead: `pooler.supabase.co:6543`
3. Verify network connectivity: `telnet db.xxxxx.supabase.co 5432`

### Issue: "Too many connections"

**Cause**: Pool size too high or connection leak

**Fix**:
1. Reduce `poolSize` to 10-20
2. Check for connection leaks in code
3. Upgrade Supabase plan for more connections
4. Use connection pooler (PgBouncer) in Supabase settings

### Issue: "Slow queries"

**Cause**: Missing indexes or inefficient queries

**Fix**:
1. Check Supabase → Database → Query Performance
2. Add indexes as needed (see schema file)
3. Use `EXPLAIN ANALYZE` in SQL Editor
4. Consider database size upgrade

---

## Part 7: Architecture Overview

### How Realtime Replaces Oplog Tailing

**Old (MongoDB + redis-oplog):**
```
MongoDB oplog → Redis → Meteor DDP → Client
```

**New (Supabase Realtime):**
```
PostgreSQL WAL → Supabase Realtime → Meteor DDP → Client
```

### Key Differences

| Feature | MongoDB Oplog | Supabase Realtime |
|---------|--------------|-------------------|
| Change Detection | Oplog tailing | WAL replication |
| Transport | Redis pub/sub | WebSocket |
| Filtering | Client-side | Server-side (RLS) |
| Latency | ~10-50ms | ~20-100ms |
| Setup Complexity | High (replica set) | Low (click toggle) |
| Cost | Extra Redis needed | Included in Supabase |

### Publication Flow

```javascript
// Before (MongoDB)
Meteor.publish('creatures', function(userId) {
  return Creatures.find({ owner: userId });
  // → Meteor uses oplog to detect changes
});

// After (PostgreSQL + Realtime)
Meteor.publish('creatures', function(userId) {
  return Creatures.find({ owner_id: userId });
  // → PostgresCollection.observeChanges() uses Supabase Realtime
});
```

The API stays the same! The PostgresCollection class handles the translation.

---

## Next Steps

1. **Test core features**: Create characters, add properties, test in-game
2. **Monitor performance**: Check Supabase dashboard for slow queries
3. **Set up backups**: Configure automated backups in Supabase
4. **Read migration docs**: See `/migration/QUICK_MIGRATION_PLAN.md`
5. **Join community**: Share feedback and ask questions

---

## Support

- **DiceCloud Issues**: https://github.com/ThaumRystra/DiceCloud/issues
- **Supabase Docs**: https://supabase.com/docs
- **Migration Help**: See `/migration/MODERN_STACK_PLAN.md`

---

## Cost Comparison

### Before (MongoDB Atlas)

- **Database**: M30 instance ($1,000/month for 300GB)
- **Oplog access**: Requires replica set (+$$$)
- **Redis**: redis-oplog caching ($50-100/month)
- **Total**: ~$1,050-1,100/month

### After (Supabase)

- **Database**: Pro plan ($25/month)
- **Storage**: 300GB ($37.50/month)
- **Compute**: Large instance ($110/month)
- **Realtime**: Included
- **Total**: ~$172.50/month

**Savings: $877.50/month ($10,530/year)** 💰

---

Ready to go! Your DiceCloud instance is now running on Supabase with Realtime. 🚀
