# Modern Stack Migration Plan - "Do It Right"

## Executive Summary

**Goal:** Migrate from Meteor + MongoDB to Next.js + Supabase with full optimization

**Timeline:** 9-12 months (with cost savings starting at month 3)

**Cost Savings:** ~$10,000/year (~$830/month)

**Strategy:** Hybrid approach - quick database migration for cost savings, then proper rebuild

---

## Recommended Tech Stack

```
┌─────────────────────────────────────────────────────────────┐
│                         FRONTEND                             │
│  Next.js 14+ (App Router) + React 18 + TypeScript          │
│  - Server Components for performance                         │
│  - Client Components for interactivity                       │
│  - Streaming & Suspense for fast loads                      │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                       API LAYER                              │
│  tRPC v10 - End-to-end type safety                          │
│  - No code generation needed                                 │
│  - Type inference from backend to frontend                   │
│  - Procedures instead of REST endpoints                      │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                       DATABASE                               │
│  Supabase (PostgreSQL 15+)                                  │
│  - Row Level Security (RLS) for permissions                 │
│  - Realtime subscriptions (WebSocket)                        │
│  - Edge Functions (Deno) for computation                     │
│  - Built-in Auth                                             │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    SUPPORTING TECH                           │
│  - Zustand (state management - simple, fast)                │
│  - React Query / tRPC (data fetching)                       │
│  - Zod (runtime validation + TypeScript types)              │
│  - Tailwind CSS + shadcn/ui (styling)                       │
│  - Vitest (unit tests) + Playwright (e2e tests)             │
└─────────────────────────────────────────────────────────────┘
```

---

## Why This Stack?

### Next.js 14+ (App Router)
**Instead of:** Meteor Blaze/React

**Benefits:**
- ✅ Server Components → Less JavaScript sent to browser
- ✅ Automatic code splitting → Faster page loads
- ✅ Image optimization built-in
- ✅ Streaming UI → Show content as it loads
- ✅ Huge community, excellent docs
- ✅ Vercel hosting (or self-host)

**Example:**
```typescript
// app/creatures/[id]/page.tsx - Server Component (runs on server)
export default async function CreaturePage({ params }: { params: { id: string } }) {
  // Direct database query, no API needed
  const creature = await getCreature(params.id);

  return (
    <div>
      <h1>{creature.name}</h1>
      {/* Client component for interactivity */}
      <CreatureSheet creature={creature} />
    </div>
  );
}
```

### tRPC
**Instead of:** Meteor Methods

**Benefits:**
- ✅ Full type safety from DB → API → Frontend
- ✅ No manual API documentation needed
- ✅ Autocomplete everywhere
- ✅ Refactor-safe (TypeScript catches breaks)

**Example:**
```typescript
// server/routers/creatures.ts
export const creaturesRouter = router({
  list: protectedProcedure
    .query(async ({ ctx }) => {
      return ctx.supabase
        .from('creatures')
        .select('*')
        .eq('owner_id', ctx.user.id);
    }),

  update: protectedProcedure
    .input(z.object({
      id: z.string().uuid(),
      name: z.string().min(1),
    }))
    .mutation(async ({ ctx, input }) => {
      return ctx.supabase
        .from('creatures')
        .update({ name: input.name })
        .eq('id', input.id)
        .eq('owner_id', ctx.user.id); // RLS also enforces this
    }),
});

// Frontend - FULL TYPE SAFETY
const creatures = trpc.creatures.list.useQuery();
//    ^? { data: Creature[] | undefined, isLoading: boolean, ... }

const updateCreature = trpc.creatures.update.useMutation();
await updateCreature.mutateAsync({
  id: '...',
  name: 'New Name',
  // TypeScript error if you add wrong fields!
});
```

### Supabase
**Instead of:** MongoDB

**Benefits:**
- ✅ PostgreSQL → Better for relational data
- ✅ RLS → Security at database level
- ✅ Realtime → Built-in WebSocket subscriptions
- ✅ Auth → Built-in user management
- ✅ Storage → File uploads included
- ✅ Edge Functions → Serverless compute

### Zustand
**Instead of:** Meteor Session/ReactiveVar

**Benefits:**
- ✅ Simple API (much simpler than Redux)
- ✅ No boilerplate
- ✅ Great TypeScript support
- ✅ Works with React 18

**Example:**
```typescript
// stores/creatureStore.ts
import { create } from 'zustand';

interface CreatureStore {
  selectedCreatureId: string | null;
  setSelectedCreature: (id: string) => void;
}

export const useCreatureStore = create<CreatureStore>((set) => ({
  selectedCreatureId: null,
  setSelectedCreature: (id) => set({ selectedCreatureId: id }),
}));

// Usage in any component
function CreatureSelector() {
  const { selectedCreatureId, setSelectedCreature } = useCreatureStore();
  return <div onClick={() => setSelectedCreature('abc')}>...</div>;
}
```

---

## Phase-by-Phase Implementation Plan

### Phase 1: Database Migration + Quick Win (Months 1-3)

**Goal:** Migrate to Supabase, keep Meteor running, get cost savings

**Tasks:**
1. Design PostgreSQL schema (use JSONB for properties initially)
2. Build migration pipeline
3. Migrate data (300GB)
4. Update Meteor to use PostgreSQL instead of MongoDB
5. Deploy V2.5 (Meteor + Supabase)

**Deliverable:** Cost savings achieved (~$830/month)

**Details:** Already covered in previous schema files

---

### Phase 2: Next.js Foundation (Months 3-4)

**Goal:** Set up modern frontend infrastructure

**Tasks:**

#### Week 1-2: Project Setup
```bash
# Create Next.js project
npx create-next-app@latest dicecloud-v3 \
  --typescript \
  --tailwind \
  --app \
  --src-dir

# Install core dependencies
npm install @trpc/server @trpc/client @trpc/react-query
npm install @supabase/supabase-js @supabase/ssr
npm install @tanstack/react-query
npm install zustand
npm install zod

# Install UI library
npx shadcn-ui@latest init
```

**File structure:**
```
dicecloud-v3/
├── src/
│   ├── app/                    # Next.js App Router pages
│   │   ├── layout.tsx          # Root layout
│   │   ├── page.tsx            # Home page
│   │   ├── creatures/
│   │   │   ├── page.tsx        # Creature list
│   │   │   └── [id]/
│   │   │       ├── page.tsx    # Creature detail
│   │   │       └── layout.tsx  # Creature layout
│   │   └── api/
│   │       └── trpc/[trpc]/route.ts  # tRPC endpoint
│   ├── components/             # React components
│   │   ├── ui/                 # shadcn components
│   │   ├── creatures/
│   │   └── properties/
│   ├── server/                 # Server-side code
│   │   ├── db/
│   │   │   └── client.ts       # Supabase client
│   │   ├── routers/
│   │   │   ├── creatures.ts
│   │   │   ├── properties.ts
│   │   │   └── libraries.ts
│   │   └── trpc.ts             # tRPC setup
│   ├── lib/                    # Utilities
│   │   ├── supabase/
│   │   └── utils.ts
│   └── stores/                 # Zustand stores
│       └── creatureStore.ts
└── package.json
```

#### Week 3-4: Core Infrastructure

**Auth setup:**
```typescript
// src/lib/supabase/server.ts
import { createServerClient } from '@supabase/ssr';
import { cookies } from 'next/headers';

export function createClient() {
  const cookieStore = cookies();

  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        get(name: string) {
          return cookieStore.get(name)?.value;
        },
      },
    }
  );
}
```

**tRPC setup:**
```typescript
// src/server/trpc.ts
import { initTRPC, TRPCError } from '@trpc/server';
import { createClient } from '@/lib/supabase/server';
import superjson from 'superjson';

const t = initTRPC.context<{
  supabase: ReturnType<typeof createClient>;
  user: { id: string } | null;
}>().create({
  transformer: superjson,
});

export const router = t.router;
export const publicProcedure = t.procedure;

export const protectedProcedure = t.procedure.use(async ({ ctx, next }) => {
  if (!ctx.user) {
    throw new TRPCError({ code: 'UNAUTHORIZED' });
  }
  return next({
    ctx: {
      ...ctx,
      user: ctx.user,
    },
  });
});
```

**Deliverable:** Working Next.js app with auth, tRPC, Supabase connection

---

### Phase 3: Core Creature System (Months 4-6)

**Goal:** Build creature CRUD, properties, character sheets

**Week 1-2: Database Access Layer**

```typescript
// src/server/db/creatures.ts
import { z } from 'zod';

export const creatureSchema = z.object({
  id: z.string().uuid(),
  name: z.string(),
  type: z.enum(['pc', 'npc', 'monster']),
  picture: z.string().url().nullable(),
  owner_id: z.string().uuid(),
  // ... all fields
});

export type Creature = z.infer<typeof creatureSchema>;

export async function getCreature(supabase: any, id: string) {
  const { data, error } = await supabase
    .from('creatures')
    .select('*')
    .eq('id', id)
    .single();

  if (error) throw error;
  return creatureSchema.parse(data);
}
```

**Week 3-4: Creature Router**

```typescript
// src/server/routers/creatures.ts
export const creaturesRouter = router({
  list: protectedProcedure
    .query(async ({ ctx }) => {
      const { data } = await ctx.supabase
        .from('creatures')
        .select('id, name, type, picture')
        .or(`owner_id.eq.${ctx.user.id},readers.cs.{${ctx.user.id}},writers.cs.{${ctx.user.id}}`)
        .eq('removed', false)
        .order('name');

      return data;
    }),

  byId: protectedProcedure
    .input(z.object({ id: z.string().uuid() }))
    .query(async ({ ctx, input }) => {
      return getCreature(ctx.supabase, input.id);
    }),

  create: protectedProcedure
    .input(z.object({
      name: z.string().min(1),
      type: z.enum(['pc', 'npc', 'monster']).default('pc'),
    }))
    .mutation(async ({ ctx, input }) => {
      const { data, error } = await ctx.supabase
        .from('creatures')
        .insert({
          name: input.name,
          type: input.type,
          owner_id: ctx.user.id,
        })
        .select()
        .single();

      if (error) throw new TRPCError({ code: 'INTERNAL_SERVER_ERROR', message: error.message });
      return data;
    }),

  update: protectedProcedure
    .input(z.object({
      id: z.string().uuid(),
      name: z.string().min(1).optional(),
      picture: z.string().url().optional(),
    }))
    .mutation(async ({ ctx, input }) => {
      const { id, ...updates } = input;

      const { data, error } = await ctx.supabase
        .from('creatures')
        .update(updates)
        .eq('id', id)
        .eq('owner_id', ctx.user.id) // Only owner can update
        .select()
        .single();

      if (error) throw new TRPCError({ code: 'INTERNAL_SERVER_ERROR', message: error.message });
      return data;
    }),

  delete: protectedProcedure
    .input(z.object({ id: z.string().uuid() }))
    .mutation(async ({ ctx, input }) => {
      // Soft delete
      await ctx.supabase
        .from('creatures')
        .update({
          removed: true,
          removed_at: new Date().toISOString(),
        })
        .eq('id', input.id)
        .eq('owner_id', ctx.user.id);

      return { success: true };
    }),
});
```

**Week 5-6: Creature Pages**

```typescript
// src/app/creatures/page.tsx (Server Component)
import { createClient } from '@/lib/supabase/server';
import { CreatureList } from '@/components/creatures/CreatureList';

export default async function CreaturesPage() {
  const supabase = createClient();
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) redirect('/login');

  return (
    <div className="container mx-auto py-8">
      <h1 className="text-3xl font-bold mb-6">My Characters</h1>
      <CreatureList />
    </div>
  );
}

// src/components/creatures/CreatureList.tsx (Client Component)
'use client';

import { trpc } from '@/lib/trpc/client';

export function CreatureList() {
  const { data: creatures, isLoading } = trpc.creatures.list.useQuery();
  const createCreature = trpc.creatures.create.useMutation();

  if (isLoading) return <div>Loading...</div>;

  return (
    <div>
      <button
        onClick={() => createCreature.mutate({ name: 'New Character' })}
        className="btn btn-primary"
      >
        Create Character
      </button>

      <div className="grid grid-cols-3 gap-4 mt-6">
        {creatures?.map((creature) => (
          <CreatureCard key={creature.id} creature={creature} />
        ))}
      </div>
    </div>
  );
}
```

**Week 7-8: Properties System**

```typescript
// src/server/routers/properties.ts
export const propertiesRouter = router({
  list: protectedProcedure
    .input(z.object({ creatureId: z.string().uuid() }))
    .query(async ({ ctx, input }) => {
      const { data } = await ctx.supabase
        .from('creature_properties')
        .select('*')
        .eq('creature_id', input.creatureId)
        .eq('removed', false)
        .order('tree_left');

      return data;
    }),

  create: protectedProcedure
    .input(z.object({
      creatureId: z.string().uuid(),
      type: z.string(),
      name: z.string(),
      parentId: z.string().uuid().optional(),
      data: z.record(z.any()),
    }))
    .mutation(async ({ ctx, input }) => {
      // Verify ownership of creature
      const creature = await getCreature(ctx.supabase, input.creatureId);
      if (creature.owner_id !== ctx.user.id) {
        throw new TRPCError({ code: 'FORBIDDEN' });
      }

      // Insert property
      const { data, error } = await ctx.supabase
        .from('creature_properties')
        .insert({
          creature_id: input.creatureId,
          type: input.type,
          name: input.name,
          parent_id: input.parentId,
          root_id: input.creatureId,
          data: input.data,
        })
        .select()
        .single();

      if (error) throw new TRPCError({ code: 'INTERNAL_SERVER_ERROR', message: error.message });

      // Mark creature as dirty
      await ctx.supabase
        .from('creatures')
        .update({ dirty: true })
        .eq('id', input.creatureId);

      return data;
    }),

  // ... update, delete, reorder
});
```

**Week 9-10: Character Sheet UI**

Build the main character sheet interface with all the properties displayed.

**Deliverable:** Working creature management system

---

### Phase 4: Computation Engine (Months 6-8)

**Goal:** Port the calculation/parsing system

**Challenge:** Your current system is sophisticated with:
- Parser for formulas
- Variable resolution
- Dependency tracking
- Property tree traversal

**Options:**

#### Option A: Port to Edge Functions (Recommended)
```typescript
// supabase/functions/recompute-creature/index.ts
import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from '@supabase/supabase-js';

serve(async (req) => {
  const { creatureId } = await req.json();
  const supabase = createClient(...);

  // Load all properties
  const { data: properties } = await supabase
    .from('creature_properties')
    .select('*')
    .eq('creature_id', creatureId)
    .eq('removed', false);

  // Run computation (port your engine here)
  const variables = await computeVariables(properties);

  // Save results
  await supabase
    .from('creature_variables')
    .upsert({
      creature_id: creatureId,
      variables,
    });

  await supabase
    .from('creatures')
    .update({ dirty: false, last_computed_at: new Date().toISOString() })
    .eq('id', creatureId);

  return new Response(JSON.stringify({ success: true }), {
    headers: { 'Content-Type': 'application/json' },
  });
});
```

#### Option B: Keep in Node.js API
Run computation in tRPC procedures (simpler migration from Meteor).

**Work required:**
1. Port parser (should be straightforward TypeScript)
2. Port resolver
3. Port computation engine
4. Add tests
5. Optimize for performance

**Deliverable:** Working computation system

---

### Phase 5: Tree Optimization (Month 8)

**Goal:** Implement proper tree queries

**Recommendation: Use ltree extension**

```sql
-- Migration
ALTER TABLE creature_properties ADD COLUMN path ltree;

-- Update paths (one-time)
UPDATE creature_properties SET path = text2ltree(
  COALESCE(parent_id::text || '.', '') || id::text
);

-- Index
CREATE INDEX idx_creature_properties_path_gist ON creature_properties USING GIST(path);
```

**Queries become simple:**
```typescript
// Get all descendants
const { data } = await supabase
  .from('creature_properties')
  .select('*')
  .filter('path', 'match', `${parentPath}.*`);

// Get ancestors
const { data } = await supabase
  .from('creature_properties')
  .select('*')
  .filter('path', 'isAncestor', nodePath);
```

**Deliverable:** Optimized tree queries

---

### Phase 6: Libraries System (Months 9-10)

**Goal:** Rebuild library management, marketplace

**Tasks:**
1. Library CRUD
2. Library nodes tree
3. Copy from library to creature
4. Library marketplace
5. Subscriptions

**Deliverable:** Working library system

---

### Phase 7: Tabletop Features (Month 10-11)

**Goal:** Rebuild game session features

**Tasks:**
1. Tabletop CRUD
2. Maps
3. Objects/tokens
4. Real-time updates (Supabase Realtime)
5. Chat/messages

**Example real-time:**
```typescript
'use client';

export function TabletopView({ tabletopId }: { tabletopId: string }) {
  const [objects, setObjects] = useState([]);

  useEffect(() => {
    const supabase = createBrowserClient(...);

    // Subscribe to object changes
    const channel = supabase
      .channel(`tabletop-${tabletopId}`)
      .on('postgres_changes', {
        event: '*',
        schema: 'public',
        table: 'tabletop_objects',
        filter: `map_id=eq.${mapId}`,
      }, (payload) => {
        if (payload.eventType === 'INSERT') {
          setObjects((prev) => [...prev, payload.new]);
        } else if (payload.eventType === 'UPDATE') {
          setObjects((prev) => prev.map((obj) =>
            obj.id === payload.new.id ? payload.new : obj
          ));
        } else if (payload.eventType === 'DELETE') {
          setObjects((prev) => prev.filter((obj) => obj.id !== payload.old.id));
        }
      })
      .subscribe();

    return () => {
      channel.unsubscribe();
    };
  }, [tabletopId]);

  return <Canvas objects={objects} />;
}
```

**Deliverable:** Working tabletop features

---

### Phase 8: Polish & Optimization (Month 11-12)

**Goal:** Performance, UX, bug fixes

**Tasks:**

1. **Performance Optimization**
   - Image optimization
   - Code splitting
   - Lazy loading
   - Bundle size reduction
   - Database query optimization
   - Add database indexes based on slow query log

2. **UX Polish**
   - Loading states
   - Error handling
   - Animations
   - Mobile responsive
   - Dark mode
   - Keyboard shortcuts

3. **Testing**
   ```typescript
   // Unit tests with Vitest
   test('creates creature', async () => {
     const creature = await createCreature({ name: 'Test' });
     expect(creature.name).toBe('Test');
   });

   // E2E tests with Playwright
   test('user can create character', async ({ page }) => {
     await page.goto('/creatures');
     await page.click('text=Create Character');
     await page.fill('input[name="name"]', 'Test Character');
     await page.click('button[type="submit"]');
     await expect(page.locator('text=Test Character')).toBeVisible();
   });
   ```

4. **Documentation**
   - API documentation (auto-generated from tRPC)
   - User guide
   - Developer setup guide

5. **Monitoring**
   ```typescript
   // Add error tracking (e.g., Sentry)
   import * as Sentry from '@sentry/nextjs';

   Sentry.init({
     dsn: process.env.SENTRY_DSN,
     tracesSampleRate: 0.1,
   });
   ```

**Deliverable:** Production-ready application

---

### Phase 9: Migration & Launch (Month 12)

**Goal:** Migrate users from V2 to V3

**Strategy:**

1. **Beta Testing (Weeks 1-2)**
   - Invite select users to V3
   - Gather feedback
   - Fix critical bugs

2. **Gradual Rollout (Weeks 3-4)**
   - Migrate users in batches
   - Monitor performance
   - Keep V2 running as fallback

3. **Full Launch**
   - All users on V3
   - Announce new features
   - Celebrate!

4. **V2 Decommission (Week 5-6)**
   - Keep V2 read-only for 30 days
   - Archive data
   - Shut down Meteor instance

**Deliverable:** V3 in production, V2 retired

---

## Schema Optimization: Fully Normalized

When doing it right, properly normalize the property types:

```sql
-- Base properties table (common fields)
CREATE TABLE properties (
  id UUID PRIMARY KEY,
  creature_id UUID REFERENCES creatures(id),
  type TEXT NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  tags TEXT[],
  disabled BOOLEAN DEFAULT FALSE,
  -- tree structure
  parent_id UUID,
  path ltree,
  -- soft delete
  removed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Specific tables for complex types
CREATE TABLE actions (
  id UUID PRIMARY KEY REFERENCES properties(id) ON DELETE CASCADE,
  uses INTEGER,
  uses_used INTEGER DEFAULT 0,
  reset TEXT CHECK (reset IN ('shortRest', 'longRest', 'day')),
  action_type TEXT NOT NULL,
  roll_bonus TEXT, -- calculation
  attack_roll TEXT, -- calculation
  resources JSONB
);

CREATE TABLE spells (
  id UUID PRIMARY KEY REFERENCES properties(id) ON DELETE CASCADE,
  level INTEGER NOT NULL CHECK (level BETWEEN 0 AND 9),
  school TEXT NOT NULL,
  casting_time TEXT NOT NULL,
  range TEXT NOT NULL,
  duration TEXT NOT NULL,
  verbal BOOLEAN DEFAULT FALSE,
  somatic BOOLEAN DEFAULT FALSE,
  material TEXT,
  concentration BOOLEAN DEFAULT FALSE,
  ritual BOOLEAN DEFAULT FALSE,
  prepared BOOLEAN DEFAULT FALSE,
  always_prepared BOOLEAN DEFAULT FALSE
);

CREATE TABLE items (
  id UUID PRIMARY KEY REFERENCES properties(id) ON DELETE CASCADE,
  quantity INTEGER DEFAULT 1,
  weight NUMERIC,
  value NUMERIC,
  equipped BOOLEAN DEFAULT FALSE,
  attuned BOOLEAN DEFAULT FALSE,
  requires_attunement BOOLEAN DEFAULT FALSE
);

-- etc. for all 35 types
```

**Benefits:**
- ✅ Better query performance
- ✅ Type-safe queries
- ✅ Proper constraints (CHECK, FOREIGN KEY)
- ✅ Easier to understand
- ✅ Better for analytics

**Tradeoff:**
- More tables to manage
- More complex queries (JOINs)
- More migration work

**When to do this:**
- Phase 8 (Month 11-12) or
- After V3 launch as optimization

---

## Development Workflow

### Git Strategy
```
main (production)
  └── develop (staging)
       ├── feature/creature-system
       ├── feature/properties
       └── feature/libraries
```

### CI/CD Pipeline
```yaml
# .github/workflows/test.yml
name: Test
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
      - run: npm ci
      - run: npm run test
      - run: npm run build
```

### Local Development
```bash
# Terminal 1: Database (local Supabase)
npx supabase start

# Terminal 2: Next.js dev server
npm run dev

# Terminal 3: Type checking
npm run type-check -- --watch
```

---

## Cost Comparison: Ongoing Operations

### V2 (Current: Meteor + MongoDB)
- MongoDB Atlas: $1,000/month
- Hosting (Galaxy): $100/month?
- **Total: ~$1,100/month**

### V3 (Modern Stack)
- Supabase Pro: $25/month
  - Database storage (292GB): $36.50/month
  - Large compute: $110/month
  - **Subtotal: ~$172/month**
- Vercel Pro (optional): $20/month (or self-host for free)
- **Total: ~$192/month**

**Savings: ~$908/month = ~$10,900/year**

---

## Risk Mitigation

### Technical Risks

1. **Calculation Engine Port**
   - Risk: Complex logic, hard to debug
   - Mitigation: Extensive testing, compare outputs V2 vs V3

2. **Data Migration**
   - Risk: Data loss, corruption
   - Mitigation: Multiple test runs, validation scripts, backups

3. **Performance Regression**
   - Risk: V3 slower than V2
   - Mitigation: Performance testing, profiling, optimization

### Business Risks

1. **User Adoption**
   - Risk: Users don't like V3
   - Mitigation: Beta testing, gradual rollout, keep V2 available

2. **Timeline Slip**
   - Risk: Takes longer than 12 months
   - Mitigation: Agile approach, MVP first, iterate

3. **Budget Overrun**
   - Risk: Costs more than expected
   - Mitigation: Time tracking, regular reviews

---

## Success Metrics

### Technical
- ✅ Page load time < 2s
- ✅ API response time < 200ms (p95)
- ✅ Test coverage > 80%
- ✅ Zero critical bugs

### Business
- ✅ Cost savings achieved ($900+/month)
- ✅ User satisfaction maintained/improved
- ✅ Zero data loss during migration
- ✅ Uptime > 99.9%

### Developer Experience
- ✅ Type safety across entire stack
- ✅ Easy to onboard new developers
- ✅ Fast local development
- ✅ Clear documentation

---

## Resources Needed

### Tools & Services
- GitHub (code hosting)
- Supabase Pro ($172/month)
- Vercel (optional, $20/month)
- Sentry (error tracking, free tier OK)
- Linear/GitHub Projects (project management)

### Your Time
- Full-time: ~12 months
- Part-time: ~18-24 months

### External Help (Optional)
- Designer for UI/UX polish: 40-80 hours
- QA testing: 40-80 hours
- Technical writer for docs: 20-40 hours

---

## Next Steps

1. **Review this plan** - Does it align with your vision?
2. **Set up Phase 1** - Start with database migration for quick wins
3. **Build Phase 2** - Set up Next.js foundation (can start in parallel)
4. **Ship iteratively** - Don't wait for perfection

Would you like me to:
- Create the Next.js project structure?
- Build the first tRPC router as an example?
- Design the normalized property tables?
- Create the migration pipeline scripts?
