# DiceCloud + Supabase Realtime - Quick Start

**5-Minute Setup Guide** for running DiceCloud with Supabase instead of MongoDB oplog tailing.

---

## Prerequisites

✅ Meteor installed
✅ Supabase account (free tier OK for testing)
✅ 5 minutes

---

## Step 1: Create Supabase Project (2 minutes)

1. Visit https://supabase.com and sign in
2. Click **"New Project"**
3. Set:
   - Name: `dicecloud-test`
   - Password: *generate and save it*
   - Region: *closest to you*
4. Wait for project creation (~2 min)

---

## Step 2: Get Credentials (30 seconds)

### Database Credentials
Go to **Settings → Database**:
- Host: `db.xxxxxxxxxxxxx.supabase.co`
- Password: *the one you just set*

### API Credentials
Go to **Settings → API**:
- Project URL: `https://xxxxxxxxxxxxx.supabase.co`
- service_role key: `eyJhbGc...` (keep secret!)

---

## Step 3: Create Database Schema (1 minute)

1. In Supabase dashboard, go to **SQL Editor**
2. Copy contents from `/migration/postgres-schema.sql`
3. Paste and click **Run**
4. Wait for "Success" message

---

## Step 4: Enable Realtime (30 seconds)

1. Go to **Database → Replication**
2. Toggle ON for these tables:
   - creatures
   - creature_properties
   - creature_variables
   - creature_logs
   - libraries
   - library_nodes
3. Click **Save**

---

## Step 5: Configure DiceCloud (1 minute)

```bash
cd app

# Copy example settings
cp settings-postgres.example.json settings-local.json

# Edit with your credentials
nano settings-local.json
```

Replace these values:

```json
{
  "postgres": {
    "host": "db.YOUR_PROJECT.supabase.co",
    "password": "YOUR_DB_PASSWORD",
    "supabaseUrl": "https://YOUR_PROJECT.supabase.co",
    "supabaseKey": "YOUR_SERVICE_ROLE_KEY"
  }
}
```

**Also update:**
```json
{
  "public": {
    "usePostgres": {
      "creatures": true,
      "creatureProperties": true,
      "creatureVariables": true,
      "creatureLogs": true,
      "libraries": true,
      "libraryNodes": true
    }
  }
}
```

---

## Step 6: Install & Run (1 minute)

```bash
# Install dependencies (if not done yet)
meteor npm install

# Run DiceCloud
meteor run --settings settings-local.json
```

You should see:

```
=> App running at: http://localhost:3000/

[DB] Creating PostgreSQL collection: creatures → creatures
[Realtime] Successfully subscribed to creatures
[Realtime] Successfully subscribed to creature_properties
...
```

---

## Step 7: Test It! (30 seconds)

### Browser
1. Open http://localhost:3000/
2. Sign up / Log in
3. Create a character

### Verify Realtime
Open Supabase **SQL Editor** and run:

```sql
-- Find your character
SELECT id, name FROM creatures LIMIT 5;

-- Update it
UPDATE creatures
SET name = 'Real-time Test!'
WHERE id = 'your-creature-id';
```

**The name should update instantly in your browser!** ✨

---

## Troubleshooting

### "PostgreSQL pool not initialized"
→ Check your `settings-local.json` credentials
→ Run: `meteor reset && meteor run --settings settings-local.json`

### "Realtime not working"
→ Go to Database → Replication and enable tables
→ Wait 1-2 minutes, restart app

### "Connection refused"
→ Check your IP in Settings → Database
→ Try connection pooler: `pooler.supabase.co:6543`

---

## What's Different from MongoDB?

| MongoDB | Supabase |
|---------|----------|
| Oplog tailing | PostgreSQL WAL |
| `_id` | `id` (UUID) |
| Nested objects | JSONB columns |
| Replica set required | Built-in replication |
| Extra Redis needed | No extra services |

---

## Next Steps

- **Full Setup Guide**: See `/SUPABASE_SETUP_GUIDE.md`
- **Migration Docs**: See `/migration/QUICK_MIGRATION_PLAN.md`
- **Schema Details**: See `/migration/postgres-schema.sql`

---

## Cost Savings

**Before (MongoDB):**
- M30 Atlas: ~$1,000/month for 300GB
- Redis: $50-100/month
- **Total: $1,050+/month**

**After (Supabase):**
- Pro plan: $25/month
- 300GB storage: $37.50/month
- Large compute: $110/month
- **Total: $172.50/month**

**Savings: $877.50/month** 💰

---

That's it! You're now running DiceCloud with Supabase Realtime instead of MongoDB oplog tailing. 🚀
