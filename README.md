DiceCloud Migration Tests
=========================

**This is a testing repository for migrating DiceCloud from MongoDB to PostgreSQL/Supabase.**

This repository is a fork of [DiceCloud](https://github.com/ThaumRystra/DiceCloud) specifically created to develop and test the migration from MongoDB Atlas to Supabase (PostgreSQL). It is **not** the official DiceCloud repository.

## About This Repository

This testing instance demonstrates:

- **PostgreSQL/Supabase** as a drop-in replacement for MongoDB
- **Supabase Realtime** replacing MongoDB oplog tailing for real-time updates
- **Cost optimization**: Reducing database costs from ~$1,050/month to ~$172/month
- **Migration tooling** for moving 300GB+ of production data
- **Backward compatibility** with the existing Meteor/Vue.js application

## What is DiceCloud?

DiceCloud is a free, auditable, real-time character sheet for D&D 5e. Visit [dicecloud.com](https://dicecloud.com) for the production instance, or check out the [official repository](https://github.com/ThaumRystra/DiceCloud).

## Migration Status

This repository contains:

- ✅ PostgreSQL schema design (`/migration/postgres-schema.sql`)
- ✅ MongoDB-compatible collection adapter (`/app/imports/api/db/PostgresCollection.ts`)
- ✅ Supabase Realtime integration (replaces oplog tailing)
- ✅ Migration tooling framework (`/migration/tools/`)
- ✅ Feature flags for gradual collection migration
- 🚧 Data migration scripts (in progress)
- 🚧 Production deployment testing (pending)

## Quick Start

**For detailed setup instructions, see [QUICKSTART.md](./QUICKSTART.md) (5-minute setup) or [SUPABASE_SETUP_GUIDE.md](./SUPABASE_SETUP_GUIDE.md) (comprehensive guide).**

### Prerequisites

- [Git](https://www.atlassian.com/git/tutorials/install-git)
- [Meteor](https://www.meteor.com/install)
- [Supabase](https://supabase.com) account (free tier works for testing)

### Basic Setup

1. **Clone this repository**:
   ```bash
   git clone https://github.com/CarmaNayeli/DiceCloudMigrationTests
   cd DiceCloudMigrationTests/app
   meteor npm install
   ```

2. **Set up Supabase**:
   - Create a project at https://supabase.com
   - Run `/migration/postgres-schema.sql` in SQL Editor
   - Enable Realtime for tables (Database → Replication)

3. **Configure settings**:
   ```bash
   cp settings-postgres.example.json settings-local.json
   # Edit settings-local.json with your Supabase credentials
   ```

4. **Run the app**:
   ```bash
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

## Configuration

### Settings File Format

Use `settings-local.json` (based on `settings-postgres.example.json`):

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
      "libraries": true,
      "libraryNodes": true
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

### Environment Variables (Optional)

For production deployment, you can also use environment variables:

```bash
# Application
ROOT_URL=https://your-instance.com
MAIL_URL=smtp://your-smtp-url

# Optional: Default libraries
DEFAULT_LIBRARIES=abc123,def456

# Supabase connection (alternative to settings file)
SUPABASE_URL=https://yourproject.supabase.co
SUPABASE_SERVICE_KEY=your_service_role_key
POSTGRES_HOST=db.yourproject.supabase.co
POSTGRES_PASSWORD=your_database_password
```

### Feature Flags

Enable/disable PostgreSQL per collection using the `usePostgres` flags. This allows gradual migration:

- `true` = Use PostgreSQL/Supabase
- `false` = Use MongoDB (if still configured)

## Architecture

### Key Differences from MongoDB Version

| Component | MongoDB (Original) | PostgreSQL/Supabase (This Repo) |
|-----------|-------------------|----------------------------------|
| Database | MongoDB Atlas | PostgreSQL via Supabase |
| Real-time | Oplog tailing + Redis | Supabase Realtime (WAL) |
| Collections | Mongo.Collection | PostgresCollection adapter |
| IDs | ObjectId (`_id`) | UUID (`id`) |
| Nested Data | Native documents | JSONB columns |
| Cost | ~$1,050/month | ~$172/month |

### How Realtime Works

**MongoDB approach:**
```
MongoDB → Oplog → Redis → Meteor DDP → Client
```

**Supabase approach:**
```
PostgreSQL → WAL → Realtime → Meteor DDP → Client
```

The `PostgresCollection` class in `/app/imports/api/db/PostgresCollection.ts` provides a MongoDB-compatible API while using Supabase Realtime under the hood.

## Documentation

- **[QUICKSTART.md](./QUICKSTART.md)** - 5-minute setup guide
- **[SUPABASE_SETUP_GUIDE.md](./SUPABASE_SETUP_GUIDE.md)** - Comprehensive setup and troubleshooting
- **[/migration/QUICK_MIGRATION_PLAN.md](./migration/QUICK_MIGRATION_PLAN.md)** - Data migration strategy
- **[/migration/MODERN_STACK_PLAN.md](./migration/MODERN_STACK_PLAN.md)** - Long-term modernization plan
- **[/migration/postgres-schema.sql](./migration/postgres-schema.sql)** - PostgreSQL schema design

## Contributing

This is a migration testing repository. For contributing to DiceCloud itself, please visit the [official repository](https://github.com/ThaumRystra/DiceCloud).

For migration-specific issues or improvements:
1. Test changes thoroughly with both MongoDB and PostgreSQL backends
2. Ensure backward compatibility with Meteor's Collection API
3. Document any schema changes in `/migration/` directory
4. Update relevant migration guides

## License

Same as DiceCloud - GPL-3.0. See the [official repository](https://github.com/ThaumRystra/DiceCloud) for details.
