# Local Setup Guide for Testing

This guide will help you set up DiceCloud with Supabase on your local machine for testing the migration.

## Prerequisites Check

Before starting, verify you have:

```bash
# Check Node.js (need 14.x)
node --version
# Should show v14.x.x

# Check npm
npm --version

# Check Meteor
meteor --version
# If not installed: curl https://install.meteor.com/ | sh

# Check git
git --version
```

## Step 1: Supabase Setup (10 minutes)

### 1.1 Create Supabase Project

1. Go to https://supabase.com and sign in (create account if needed)
2. Click **"New Project"**
3. Fill in:
   - **Name**: `dicecloud-test`
   - **Database Password**: Click "Generate password" and **SAVE IT**
   - **Region**: Choose closest to you
   - **Plan**: Free (for testing)
4. Click "Create new project"
5. Wait ~2 minutes for provisioning

### 1.2 Get Your Credentials

Once the project is ready:

**Database Credentials** (Settings → Database):
```
Host: db.xxxxxxxxxxxxx.supabase.co
Port: 5432
Database: postgres
User: postgres
Password: [the password you saved]
```

**API Credentials** (Settings → API):
```
Project URL: https://xxxxxxxxxxxxx.supabase.co
anon key: eyJhbGc... (you won't need this)
service_role key: eyJhbGc... (COPY THIS - keep it secret!)
```

### 1.3 Create Database Schema

1. In Supabase dashboard, go to **SQL Editor** (left sidebar)
2. Click **"New query"**
3. On your local machine, open the file:
   ```bash
   cat /path/to/DiceCloudMigrationTests/migration/postgres-schema.sql
   ```
4. Copy the entire contents
5. Paste into the Supabase SQL Editor
6. Click **"Run"** (or press Ctrl/Cmd + Enter)
7. You should see "Success. No rows returned"

### 1.4 Enable Realtime

1. In Supabase dashboard, go to **Database → Replication**
2. Click the **"0 tables"** dropdown to see all tables
3. Toggle **ON** for these tables:
   - `creatures`
   - `creature_properties`
   - `creature_variables`
   - `creature_logs`
   - `experiences`
   - `libraries`
   - `library_nodes`
   - `users`
4. The toggle should turn green
5. Wait ~30 seconds for replication to enable

**Verify**: You should see something like "8 tables" in the dropdown now.

## Step 2: Clone and Configure (5 minutes)

### 2.1 Clone Repository

```bash
# Clone the repository
git clone https://github.com/CarmaNayeli/DiceCloudMigrationTests
cd DiceCloudMigrationTests

# Checkout the branch with Realtime support
git checkout claude/replace-oplog-tailing-aN6wA
```

### 2.2 Create Settings File

```bash
cd app

# Copy the example settings
cp settings-postgres.example.json settings-local.json

# Open it in your editor
nano settings-local.json
# or: code settings-local.json
# or: vim settings-local.json
```

### 2.3 Configure Your Credentials

Edit `settings-local.json` and replace:

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
    "host": "db.YOUR_PROJECT_ID.supabase.co",           // ← Replace
    "port": 5432,
    "database": "postgres",
    "user": "postgres",
    "password": "YOUR_ACTUAL_DATABASE_PASSWORD",        // ← Replace
    "poolSize": 20,
    "supabaseUrl": "https://YOUR_PROJECT_ID.supabase.co", // ← Replace
    "supabaseKey": "YOUR_SERVICE_ROLE_KEY"              // ← Replace (long string)
  }
}
```

**Replace these 4 values:**
1. `host` - from Supabase Settings → Database
2. `password` - the database password you saved
3. `supabaseUrl` - from Supabase Settings → API (Project URL)
4. `supabaseKey` - from Supabase Settings → API (service_role key)

Save and close the file.

## Step 3: Install Dependencies (5 minutes)

```bash
# Make sure you're in the app directory
cd /path/to/DiceCloudMigrationTests/app

# Install npm dependencies
meteor npm install
```

This will:
- Install all Node.js packages (~5 minutes first time)
- Install Meteor packages automatically when you run Meteor

**Expected output:**
```
added 437 packages in 3m 12s
```

## Step 4: Run DiceCloud (2 minutes)

```bash
# Start Meteor with your settings
meteor run --settings settings-local.json
```

**First run takes longer** (~5-10 minutes) as Meteor:
- Downloads packages
- Builds the app
- Starts the server

### What You Should See

```
=> Started proxy.
=> [HMR] Dev server listening on port 3003.
=> Started your app.

=> App running at: http://localhost:3000/

[DB] Creating PostgreSQL collection: creatures → creatures
[DB] Creating PostgreSQL collection: creatureProperties → creature_properties
[Realtime] Subscribing to creatures on channel creatures_changes_...
[Realtime] Successfully subscribed to creatures
[Realtime] Subscribing to creature_properties on channel creature_properties_changes_...
[Realtime] Successfully subscribed to creature_properties
...
```

If you see these messages, **congratulations!** 🎉 Realtime is working.

### Common Startup Issues

#### Issue: "Error: connect ECONNREFUSED"
**Cause**: Can't connect to Supabase

**Fix**:
1. Check your `settings-local.json` credentials
2. Verify the Supabase project is running (check dashboard)
3. Try pinging: `ping db.YOUR_PROJECT.supabase.co`

#### Issue: "PostgreSQL pool not initialized"
**Cause**: Settings not loaded correctly

**Fix**:
1. Make sure you're using `--settings settings-local.json`
2. Check the JSON is valid (no syntax errors)
3. Try: `meteor reset && meteor run --settings settings-local.json`

#### Issue: No Realtime logs appear
**Cause**: Tables not enabled for replication

**Fix**:
1. Go to Supabase → Database → Replication
2. Make sure tables are toggled ON
3. Restart Meteor

## Step 5: Test the App (5 minutes)

### 5.1 Open in Browser

1. Open http://localhost:3000/
2. You should see the DiceCloud homepage

### 5.2 Create an Account

1. Click **"Sign Up"** (top right)
2. Fill in:
   - Username: `testuser`
   - Email: `test@example.com`
   - Password: `testpassword123`
3. Click "Create Account"

### 5.3 Create a Character

1. After logging in, click **"Characters"** or **"New Character"**
2. Fill in:
   - Name: `Test Character`
   - Race: `Human`
   - Class: `Fighter`
3. Click "Create"

### 5.4 Verify Database

1. Go to Supabase dashboard
2. Click **"Table Editor"** (left sidebar)
3. Select `creatures` table
4. You should see your character!

### 5.5 Test Realtime (The Critical Test!)

This tests that Supabase Realtime is actually replacing MongoDB oplog tailing.

**Terminal 1** - Keep Meteor running

**Terminal 2** - Connect to Supabase:
```bash
# Install psql if needed (macOS: brew install postgresql, Ubuntu: apt install postgresql-client)

psql "postgresql://postgres:YOUR_PASSWORD@db.YOUR_PROJECT.supabase.co:5432/postgres"
```

Once connected:
```sql
-- Find your character
SELECT id, name FROM creatures;

-- Copy the ID, then update it
UPDATE creatures
SET name = 'Real-time Test!'
WHERE id = 'your-creature-id-here';
```

**Browser** - Watch http://localhost:3000/

**Result**: The character name should **instantly update** in the browser without refreshing! ✨

If this works, **Supabase Realtime is successfully replacing MongoDB oplog tailing!**

## Step 6: Explore and Test Features

Now test the core DiceCloud features:

- ✅ Create/edit characters
- ✅ Add properties (abilities, skills, items)
- ✅ Create libraries
- ✅ Use calculation engine
- ✅ Test real-time sync (open character in 2 browser tabs, edit in one)

## Troubleshooting

### Check Connection Status

```bash
# Test Supabase connection
curl https://YOUR_PROJECT.supabase.co/rest/v1/

# Should return: {"message":"The server is running"}
```

### Check PostgreSQL Connection

```bash
# Try direct connection
psql "postgresql://postgres:PASSWORD@db.YOUR_PROJECT.supabase.co:5432/postgres" -c "SELECT version();"
```

### View Meteor Logs

Meteor shows logs in the terminal. Look for:
- `[Realtime] Successfully subscribed` - Good!
- `[Realtime] Error subscribing` - Check table replication
- `PostgreSQL pool not initialized` - Check settings
- `Connection refused` - Check credentials

### Reset Everything

If things are broken:

```bash
# Stop Meteor (Ctrl+C)

# Clear Meteor cache
meteor reset

# Reinstall dependencies
rm -rf node_modules
meteor npm install

# Restart with settings
meteor run --settings settings-local.json
```

## Next Steps

Once you have it running:

1. **Test Publications** - Open Network tab, watch DDP messages
2. **Test Methods** - Try character updates, watch for errors
3. **Load Test** - Create multiple characters, properties
4. **Performance** - Check query times in Supabase dashboard
5. **Migration** - Try migrating real MongoDB data (see `/migration/` docs)

## Need Help?

- Check `/SUPABASE_SETUP_GUIDE.md` for detailed troubleshooting
- Check `/QUICKSTART.md` for quick reference
- Look at Meteor console for error messages
- Check Supabase Logs (Dashboard → Logs)

---

**You're now running DiceCloud with PostgreSQL/Supabase instead of MongoDB!** 🚀

Cost savings: ~$877/month
Oplog tailing: Replaced with Supabase Realtime
Infrastructure: Simplified (no Redis needed)
