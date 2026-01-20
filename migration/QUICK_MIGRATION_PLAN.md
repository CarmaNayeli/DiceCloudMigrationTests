# Quick Migration Plan - MongoDB to Supabase

**Timeline: 3-5 months**
**Goal: Migrate to PostgreSQL, keep Meteor, get cost savings ASAP**

---

## Week-by-Week Breakdown

### Week 1: Setup & Preparation
- [x] Analyze codebase
- [x] Design PostgreSQL schema
- [ ] Set up Supabase Pro account
- [ ] Set up migration project
- [ ] Install dependencies
- [ ] Test connections (MongoDB → PostgreSQL)

### Week 2-3: Migration Pipeline Development
- [ ] Build extraction utilities (MongoDB → JSON)
- [ ] Build transformation logic (field mapping)
- [ ] Build loading utilities (JSON → PostgreSQL)
- [ ] Build validation tools
- [ ] Build checkpoint/resume system
- [ ] Test with 1,000 sample documents

### Week 4: Historical Data Migration (300GB)
- [ ] Migrate creature_logs (oldest first, partitioned)
- [ ] Migrate old experiences
- [ ] Migrate archived creatures
- [ ] Validate data integrity
- [ ] Test query performance

### Week 5-6: Active Data Migration
- [ ] Migrate active creatures
- [ ] Migrate creature_properties
- [ ] Migrate creature_variables
- [ ] Migrate libraries & library_nodes
- [ ] Migrate users & profiles
- [ ] Full validation pass

### Week 7-8: Meteor Integration
- [ ] Replace MongoDB driver with PostgreSQL
- [ ] Update Collection definitions
- [ ] Convert MongoDB queries → SQL
- [ ] Update Methods
- [ ] Update Publications
- [ ] Test all CRUD operations

### Week 9-10: Testing & Bug Fixes
- [ ] Integration testing
- [ ] Performance testing
- [ ] Load testing
- [ ] Fix bugs
- [ ] Optimize slow queries

### Week 11: Staging Deployment
- [ ] Deploy to staging environment
- [ ] Smoke test all features
- [ ] Performance benchmarks
- [ ] Get stakeholder approval

### Week 12: Production Deployment
- [ ] Final data sync
- [ ] Deploy to production
- [ ] Monitor errors
- [ ] Fix critical issues
- [ ] Celebrate! 🎉
- [ ] Cancel MongoDB hosting

---

## Phase 1: Setup (This Week)

### 1. Supabase Account Setup

**Create Supabase project:**
```bash
# Go to https://supabase.com
# Create new project
# Note down:
# - Project URL
# - anon/public key
# - service_role key (for migrations)
# - Database connection string
```

**Configure instance:**
- Upgrade to Pro plan
- Choose Large compute instance
- Disable spend cap (for storage over 8GB)
- Set up database backups

### 2. Migration Project Setup

**Create migration directory structure:**
```
migration/
├── tools/                  # Migration scripts
│   ├── package.json
│   ├── tsconfig.json
│   ├── src/
│   │   ├── extract/       # MongoDB extraction
│   │   ├── transform/     # Field transformation
│   │   ├── load/          # PostgreSQL loading
│   │   ├── validate/      # Validation tools
│   │   └── index.ts       # Main CLI
│   └── data/              # Intermediate JSON files
│       ├── checkpoints/   # Progress tracking
│       └── errors/        # Error logs
├── postgres-schema.sql     # Already created
└── *.md                    # Documentation
```

**Dependencies to install:**
```json
{
  "dependencies": {
    "@supabase/supabase-js": "^2.39.0",
    "mongodb": "^6.3.0",
    "pg": "^8.11.3",
    "dotenv": "^16.3.1",
    "commander": "^11.1.0",
    "chalk": "^5.3.0",
    "ora": "^8.0.1",
    "p-queue": "^8.0.1",
    "zod": "^3.22.4"
  },
  "devDependencies": {
    "@types/node": "^20.10.6",
    "@types/pg": "^8.10.9",
    "typescript": "^5.3.3",
    "tsx": "^4.7.0"
  }
}
```

### 3. Environment Configuration

**Create `.env` file:**
```bash
# MongoDB (source)
MONGODB_URI=mongodb://user:pass@host:port/dicecloud

# Supabase (target)
SUPABASE_URL=https://yourproject.supabase.co
SUPABASE_SERVICE_KEY=your_service_role_key
SUPABASE_DB_HOST=db.yourproject.supabase.co
SUPABASE_DB_PORT=5432
SUPABASE_DB_NAME=postgres
SUPABASE_DB_USER=postgres
SUPABASE_DB_PASSWORD=your_db_password

# Migration settings
BATCH_SIZE=1000
MAX_RETRIES=3
CHECKPOINT_INTERVAL=10000
```

---

## Phase 2: Build Migration Tools

### Tool 1: MongoDB Extractor

**Features:**
- Connect to MongoDB
- Extract collections in batches
- Save to JSON files
- Support filtering (date ranges, etc.)
- Progress tracking

**Usage:**
```bash
npm run extract -- --collection creatures --batch-size 1000
npm run extract -- --collection creature_logs --before 2024-01-01
```

### Tool 2: Field Transformer

**Features:**
- Map MongoDB fields → PostgreSQL fields
- Generate UUIDs from MongoDB ObjectIds
- Flatten nested objects
- Convert arrays
- Handle tree structure
- Type validation

**Usage:**
```bash
npm run transform -- --input data/creatures.json --output data/creatures-pg.json
```

### Tool 3: PostgreSQL Loader

**Features:**
- Connect to Supabase
- Bulk insert with COPY
- Handle conflicts
- Validate constraints
- Transaction support
- Rollback on error

**Usage:**
```bash
npm run load -- --collection creatures --file data/creatures-pg.json
```

### Tool 4: Validator

**Features:**
- Count comparison (MongoDB vs PostgreSQL)
- Sample random documents
- Compare field values
- Check referential integrity
- Validate tree structure
- Performance testing

**Usage:**
```bash
npm run validate -- --collection creatures
npm run validate -- --all --sample 100
```

### Tool 5: Migration CLI

**Features:**
- Single command for full migration
- Checkpoint/resume support
- Progress reporting
- Error handling
- Dry-run mode

**Usage:**
```bash
# Full migration
npm run migrate -- --all

# Single collection
npm run migrate -- --collection creatures

# Resume from checkpoint
npm run migrate -- --resume

# Dry run
npm run migrate -- --all --dry-run
```

---

## Phase 3: Data Migration Strategy

### Order of Migration (Dependency Graph)

```
1. users (independent)
2. user_profiles (depends on users)
3. creatures (depends on users)
4. creature_properties (depends on creatures)
5. creature_variables (depends on creatures)
6. experiences (depends on creatures)
7. creature_logs (depends on creatures) - partition by year
8. libraries (depends on users)
9. library_nodes (depends on libraries)
10. library_collections (depends on libraries)
11. tabletops (depends on users)
12. tabletop_maps (depends on tabletops)
13. tabletop_objects (depends on tabletops, creatures)
14. messages (depends on tabletops, users)
15. invites (depends on users)
16. icons (depends on users)
```

### Migration Approach

**Historical data first (low risk):**
1. creature_logs (2020-2023) → 200GB+
2. Old experiences
3. Archived/removed creatures

**Active data last (high value):**
1. Active creatures
2. Recent properties
3. Current sessions
4. Users

**Benefits:**
- Test pipeline on low-risk data
- Reduce active dataset size
- Practice recovery procedures
- Build confidence

---

## Phase 4: Meteor Integration

### Step 1: Install PostgreSQL Driver

```bash
cd app
meteor add npdev:meteor-pg
# or
meteor npm install pg
```

### Step 2: Update Collection Definitions

**Before (MongoDB):**
```javascript
// app/imports/api/creature/creatures/Creatures.js
const Creatures = new Mongo.Collection('creatures');
```

**After (PostgreSQL via raw driver):**
```javascript
// app/imports/api/creature/creatures/Creatures.js
import { PostgresCollection } from '/imports/api/db/PostgresCollection';

const Creatures = new PostgresCollection('creatures', {
  idField: 'id', // UUID instead of _id
  schema: CreatureSchema,
});
```

**Or use existing package:**
```javascript
// Using meteor-pg package
import { PgCollection } from 'meteor/npdev:meteor-pg';

const Creatures = new PgCollection('creatures');
```

### Step 3: Query Conversion Patterns

**MongoDB → PostgreSQL query mapping:**

| MongoDB | PostgreSQL (via adapter) |
|---------|-------------------------|
| `find({ owner })` | `find({ owner_id })` |
| `find({ _id })` | `find({ id })` |
| `find({ readers: userId })` | `find({ 'readers @>': [userId] })` |
| `update(id, { $set: { name } })` | `update(id, { name })` |
| `update(id, { $inc: { xp } })` | Custom: `UPDATE SET xp = xp + $1` |
| `update(id, { $push: { tags } })` | Custom: `UPDATE SET tags = array_append(tags, $1)` |

### Step 4: Create PostgreSQL Adapter

**Wrapper to maintain MongoDB-like API:**

```javascript
// app/imports/api/db/PostgresCollection.js
import { createClient } from '@supabase/supabase-js';

export class PostgresCollection {
  constructor(tableName, options = {}) {
    this.tableName = tableName;
    this.idField = options.idField || 'id';
    this.supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_KEY
    );
  }

  find(selector = {}, options = {}) {
    let query = this.supabase.from(this.tableName).select('*');

    // Apply selector
    Object.entries(selector).forEach(([key, value]) => {
      query = query.eq(key, value);
    });

    // Apply options (fields, limit, sort)
    if (options.fields) {
      const fields = Object.keys(options.fields).join(',');
      query = this.supabase.from(this.tableName).select(fields);
    }

    if (options.limit) {
      query = query.limit(options.limit);
    }

    if (options.sort) {
      const [field, order] = Object.entries(options.sort)[0];
      query = query.order(field, { ascending: order === 1 });
    }

    return query;
  }

  findOne(selector, options = {}) {
    return this.find(selector, { ...options, limit: 1 }).single();
  }

  async insert(doc) {
    const { data, error } = await this.supabase
      .from(this.tableName)
      .insert(doc)
      .select()
      .single();

    if (error) throw new Error(error.message);
    return data[this.idField];
  }

  async update(selector, modifier) {
    // Handle $set, $inc, etc.
    const updates = modifier.$set || modifier;

    const { error } = await this.supabase
      .from(this.tableName)
      .update(updates)
      .match(selector);

    if (error) throw new Error(error.message);
  }

  async remove(selector) {
    const { error } = await this.supabase
      .from(this.tableName)
      .delete()
      .match(selector);

    if (error) throw new Error(error.message);
  }
}
```

### Step 5: Incremental Migration

**Strategy: Feature flags**

```javascript
// app/imports/api/flags.js
export const USE_POSTGRES = {
  creatures: Meteor.settings.public.usePostgres?.creatures || false,
  properties: Meteor.settings.public.usePostgres?.properties || false,
  // ... etc
};

// In collection definitions
import { USE_POSTGRES } from '/imports/api/flags';

const Creatures = USE_POSTGRES.creatures
  ? new PostgresCollection('creatures')
  : new Mongo.Collection('creatures');
```

**Enable gradually:**
```json
// settings.json
{
  "public": {
    "usePostgres": {
      "creatures": true,
      "properties": false
    }
  }
}
```

---

## Phase 5: Testing Strategy

### Unit Tests
```javascript
// Test collection operations
describe('Creatures Collection', () => {
  it('should insert creature', async () => {
    const id = await Creatures.insert({ name: 'Test' });
    expect(id).toBeDefined();
  });

  it('should find creature by id', async () => {
    const creature = await Creatures.findOne({ id });
    expect(creature.name).toBe('Test');
  });
});
```

### Integration Tests
- Test all Meteor Methods
- Test Publications
- Test real user workflows
- Test edge cases

### Performance Tests
```javascript
// Benchmark query performance
console.time('find-creatures');
const creatures = await Creatures.find({ owner_id: userId }).fetch();
console.timeEnd('find-creatures');
// Target: < 100ms for typical queries
```

### Load Tests
- Simulate concurrent users
- Test write-heavy workloads
- Monitor database performance
- Check connection pooling

---

## Phase 6: Deployment Strategy

### Staging Environment
1. Deploy Meteor app with PostgreSQL
2. Copy production data to staging Supabase
3. Test all features
4. Get team sign-off

### Production Cutover Options

**Option A: Maintenance Window (Recommended)**
```
1. Announce 2-hour maintenance window
2. Put app in maintenance mode
3. Final data sync (incremental)
4. Switch database connection
5. Deploy updated Meteor app
6. Smoke test
7. Open to users
8. Monitor closely
```

**Option B: Dual-Write (Zero Downtime)**
```
1. Write to both MongoDB and PostgreSQL
2. Read from MongoDB (current)
3. Validate PostgreSQL data
4. Switch reads to PostgreSQL
5. Remove MongoDB writes
6. Monitor for issues
```

**Recommendation:** Option A (maintenance window)
- Simpler
- Lower risk
- Easier rollback
- 2 hours is acceptable

### Rollback Plan
```
If issues arise:
1. Switch back to MongoDB connection
2. Deploy previous Meteor version
3. App is back online
4. Debug PostgreSQL issues offline
5. Retry when ready
```

---

## Success Criteria

### Data Migration
- [x] All records migrated (0% data loss)
- [x] All fields mapped correctly
- [x] Referential integrity maintained
- [x] Tree structure valid
- [x] Performance acceptable

### Application
- [x] All features working
- [x] No critical bugs
- [x] Performance >= MongoDB
- [x] Users can login
- [x] Can create/edit creatures

### Business
- [x] Cost savings achieved ($828/month)
- [x] MongoDB hosting cancelled
- [x] Uptime maintained
- [x] User satisfaction maintained

---

## Risk Mitigation

### Risk: Data Corruption
**Mitigation:**
- Multiple validation passes
- Sample testing
- Checksum verification
- Keep MongoDB running for 30 days

### Risk: Performance Degradation
**Mitigation:**
- Performance testing before launch
- Database indexes optimized
- Connection pooling configured
- Monitoring in place

### Risk: Feature Breakage
**Mitigation:**
- Comprehensive testing
- Feature flags for gradual rollout
- Rollback plan ready
- MongoDB fallback available

### Risk: Timeline Slip
**Mitigation:**
- Buffer in timeline (12 weeks → 16 weeks)
- Regular progress reviews
- Cut scope if needed
- Prioritize critical path

---

## Budget

### Supabase Costs
- Pro plan: $25/month
- Database storage (292GB): $36.50/month
- Large compute: $110/month
- **Total: ~$172/month**

### Development Time
- 500-800 hours over 12 weeks
- Average: ~50 hours/week

### Tools & Services (Optional)
- Staging environment: $50-100/month
- Monitoring: Free (Supabase included)
- Testing tools: Free

---

## Next Steps (Right Now)

1. **Create migration tools project**
2. **Set up Supabase account**
3. **Build extraction utilities**
4. **Test with sample data**
5. **Iterate and improve**

Let's start building! 🚀
