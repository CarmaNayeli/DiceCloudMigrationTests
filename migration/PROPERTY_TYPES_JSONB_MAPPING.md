# Property Types JSONB Mapping

This document shows how the 35 different property types from MongoDB will map to the PostgreSQL `creature_properties.data` JSONB field.

## Approach

**MongoDB**: Each property type has its own schema attached with a selector
```javascript
CreatureProperties.attachSchema(ActionSchema, { selector: { type: 'action' } })
```

**PostgreSQL**: Common fields are columns, type-specific fields go in JSONB
```sql
-- Columns for ALL properties
type TEXT NOT NULL,           -- 'action', 'spell', etc.
name TEXT,
description TEXT,
tags TEXT[],
disabled BOOLEAN,

-- Type-specific fields in JSONB
data JSONB NOT NULL DEFAULT '{}'::jsonb
```

---

## Example: Action Property

### MongoDB Document
```javascript
{
  _id: "abc123",
  type: "action",
  name: "Fireball",
  description: "A bright streak...",
  tags: ["spell", "damage"],
  disabled: false,

  // Action-specific fields:
  uses: "3",
  usesUsed: 1,
  reset: "longRest",
  actionType: "action",
  target: "creature",
  rollBonus: "1d6",

  // Tree structure
  root: { id: "creatureId", collection: "creatures" },
  parentId: "folderId",
  left: 10,
  right: 11,

  // Computed
  inactive: false,
  dirty: true
}
```

### PostgreSQL Row
```sql
INSERT INTO creature_properties (
  id,                    -- UUID
  type,                  -- TEXT
  name,                  -- TEXT (column)
  description,           -- TEXT (column)
  tags,                  -- TEXT[] (column)
  disabled,              -- BOOLEAN (column)

  data,                  -- JSONB (everything else)

  root_id,               -- UUID (column)
  root_collection,       -- TEXT (column)
  parent_id,             -- UUID (column)
  tree_left,             -- INTEGER (column)
  tree_right,            -- INTEGER (column)

  inactive,              -- BOOLEAN (column)
  dirty                  -- BOOLEAN (column)
) VALUES (
  'uuid-here',
  'action',
  'Fireball',
  'A bright streak...',
  ARRAY['spell', 'damage'],
  false,

  -- JSONB contains action-specific fields
  '{
    "uses": "3",
    "usesUsed": 1,
    "reset": "longRest",
    "actionType": "action",
    "target": "creature",
    "rollBonus": "1d6"
  }'::jsonb,

  'creature-uuid',
  'creatures',
  'folder-uuid',
  10,
  11,

  false,
  true
);
```

### Query Examples

**Get actions with uses**:
```sql
SELECT name, data->>'uses' as max_uses, data->>'usesUsed' as used
FROM creature_properties
WHERE type = 'action'
  AND creature_id = $1
  AND data ? 'uses';
```

**Update uses**:
```sql
UPDATE creature_properties
SET data = jsonb_set(data, '{usesUsed}', ((data->>'usesUsed')::int + 1)::text::jsonb)
WHERE id = $1;
```

---

## Common Fields (All Types)

These are **columns** in the table:

| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | Primary key |
| `creature_id` | UUID | FK to creatures |
| `type` | TEXT | Property type discriminator |
| `name` | TEXT | Display name |
| `description` | TEXT | Long description |
| `tags` | TEXT[] | Array of tags |
| `disabled` | BOOLEAN | Is property disabled |
| `icon` | JSONB | Icon object |
| `library_node_id` | UUID | Source library node |
| `slot_quantity_filled` | INTEGER | Slot filling |
| `color` | TEXT | Hex color |
| `root_id` | UUID | Tree root reference |
| `root_collection` | TEXT | Root collection name |
| `parent_id` | UUID | Parent in tree |
| `tree_left` | INTEGER | Nested set left |
| `tree_right` | INTEGER | Nested set right |
| `inactive` | BOOLEAN | Denormalized inactive flag |
| `deactivated_by_ancestor` | BOOLEAN | Inactive due to parent |
| `deactivated_by_self` | BOOLEAN | Inactive due to self |
| `deactivated_by_toggle` | BOOLEAN | Inactive due to toggle |
| `deactivating_toggle_id` | UUID | Toggle that deactivated |
| `trigger_ids` | JSONB | Trigger references |
| `dirty` | BOOLEAN | Needs recompute |
| `removed` | BOOLEAN | Soft delete |
| `removed_at` | TIMESTAMPTZ | Soft delete time |
| `removed_with` | UUID | Cascade delete source |

---

## Type-Specific Fields (in JSONB `data`)

### Action
```jsonb
{
  "uses": "3",              // String (calc)
  "usesUsed": 1,            // Integer
  "reset": "longRest",      // String enum
  "actionType": "action",   // String enum
  "target": "creature",     // String
  "rollBonus": "1d6",       // String (calc)
  "attackRoll": "1d20+5",   // String (calc)
  "resources": {...}        // Object
}
```

### Attribute
```jsonb
{
  "attributeType": "ability",  // String enum
  "baseValue": "10",           // String (calc)
  "modifier": "+2",            // String (calc)
  "overridden": false,         // Boolean
  "damage": 0,                 // Number
  "reset": "longRest"          // String enum
}
```

### Spell
```jsonb
{
  "level": 3,                  // Integer
  "school": "evocation",       // String
  "castingTime": "1 action",   // String
  "range": "150 feet",         // String
  "duration": "instantaneous", // String
  "verbal": true,              // Boolean
  "somatic": true,             // Boolean
  "material": "bat guano",     // String
  "concentration": false,      // Boolean
  "ritual": false,             // Boolean
  "prepared": true,            // Boolean
  "alwaysPrepared": false      // Boolean
}
```

### Item
```jsonb
{
  "quantity": 1,               // Number
  "weight": "5",               // String (calc)
  "value": "50",               // String (calc)
  "equipped": true,            // Boolean
  "attuned": false,            // Boolean
  "requiresAttunement": false  // Boolean
}
```

### Buff
```jsonb
{
  "applied": true,             // Boolean
  "appliedBy": ["action-id"],  // Array of strings
  "duration": "1 hour",        // String
  "targetTags": ["attack"]     // Array of strings
}
```

### Class
```jsonb
{
  "level": 5,                  // Integer
  "hitDiceSize": "d8",         // String
  "spellCastingAbility": "intelligence",  // String
  "variableName": "wizardLevel"  // String
}
```

### Feature
```jsonb
{
  "summary": "Short summary",  // String
  "featureType": "passive"     // String enum
}
```

### Skill
```jsonb
{
  "skillType": "acrobatics",   // String enum
  "ability": "dexterity",      // String
  "proficiency": 1,            // Number (0, 0.5, 1, 2)
  "advantage": 0,              // Number (-1, 0, 1)
  "passiveBonus": "+5"         // String (calc)
}
```

### Proficiency
```jsonb
{
  "proficiencyType": "weapon", // String enum
  "value": "1"                 // String (calc)
}
```

### Damage
```jsonb
{
  "amount": "2d6+3",           // String (calc)
  "damageType": "fire",        // String enum
  "target": "each"             // String
}
```

### Adjustment
```jsonb
{
  "amount": "+2",              // String (calc)
  "operation": "add",          // String enum (add, mul, min, max, etc.)
  "targetTags": ["strength"],  // Array of strings
  "amount": "2"                // String (calc)
}
```

### Toggle
```jsonb
{
  "enabled": true,             // Boolean
  "toggleAction": "action",    // String enum
  "condition": "hasShield"     // String (calc)
}
```

### Folder
```jsonbonb
{
  // Folders typically have no extra fields
}
```

### Note
```jsonb
{
  "summary": "Short note"      // String
}
```

### Roll
```jsonb
{
  "roll": "1d20+5"             // String (calc)
}
```

### SavingThrow
```jsonb
{
  "savingThrowAbility": "wisdom",  // String enum
  "dc": "15",                      // String (calc)
  "targetTags": ["spell"]          // Array of strings
}
```

---

## MongoDB → JSONB Transformation

### Python Example
```python
def transform_property(mongo_doc):
    """Transform MongoDB property to PostgreSQL row"""

    # Common columns
    common_fields = [
        '_id', 'type', 'name', 'description', 'tags', 'disabled',
        'icon', 'libraryNodeId', 'slotQuantityFilled', 'color',
        'root', 'parentId', 'left', 'right',
        'inactive', 'deactivatedByAncestor', 'dirty',
        'removed', 'removedAt', 'removedWith'
    ]

    # Extract common fields to columns
    columns = {}
    for field in common_fields:
        if field in mongo_doc:
            columns[field] = mongo_doc[field]

    # Everything else goes in JSONB 'data'
    data = {}
    for key, value in mongo_doc.items():
        if key not in common_fields and not key.startswith('_'):
            data[key] = value

    return {
        **columns,
        'data': json.dumps(data)  # Convert to JSONB
    }
```

### Node.js Example
```javascript
function transformProperty(mongoDoc) {
  const commonFields = new Set([
    '_id', 'type', 'name', 'description', 'tags', 'disabled',
    'icon', 'libraryNodeId', 'slotQuantityFilled', 'color',
    'root', 'parentId', 'left', 'right',
    'inactive', 'deactivatedByAncestor', 'dirty',
    'removed', 'removedAt', 'removedWith'
  ]);

  // Extract columns
  const columns = {};
  const data = {};

  for (const [key, value] of Object.entries(mongoDoc)) {
    if (commonFields.has(key)) {
      columns[key] = value;
    } else if (!key.startsWith('_')) {
      data[key] = value;
    }
  }

  return {
    ...columns,
    data: JSON.stringify(data)
  };
}
```

---

## Querying JSONB Data

### Common Patterns

**Check field exists**:
```sql
WHERE data ? 'uses'
```

**Get string value**:
```sql
SELECT data->>'actionType' as action_type
```

**Get numeric value**:
```sql
SELECT (data->>'usesUsed')::int as uses_used
```

**Get nested value**:
```sql
SELECT data->'resources'->>'hp' as hp
```

**Filter by JSONB field**:
```sql
WHERE data->>'reset' = 'longRest'
```

**Filter by numeric comparison**:
```sql
WHERE (data->>'level')::int >= 3
```

**Update JSONB field**:
```sql
UPDATE creature_properties
SET data = jsonb_set(data, '{usesUsed}', '0')
WHERE id = $1;
```

**Increment JSONB number**:
```sql
UPDATE creature_properties
SET data = jsonb_set(
  data,
  '{usesUsed}',
  (COALESCE((data->>'usesUsed')::int, 0) + 1)::text::jsonb
)
WHERE id = $1;
```

**Array contains**:
```sql
WHERE data->'targetTags' ? 'attack'
```

---

## Performance Optimization

### Hot Fields → Columns

If a JSONB field is queried frequently, extract it to a column:

```sql
-- Add column
ALTER TABLE creature_properties ADD COLUMN uses INTEGER;

-- Populate from JSONB
UPDATE creature_properties
SET uses = (data->>'uses')::int
WHERE data ? 'uses';

-- Index it
CREATE INDEX idx_creature_props_uses ON creature_properties(uses)
WHERE type = 'action';

-- Query is now fast
SELECT * FROM creature_properties
WHERE type = 'action' AND uses > 0;
```

**Candidates for extraction**:
- `level` (for spells, classes)
- `equipped` (for items)
- `applied` (for buffs)
- `enabled` (for toggles)

---

## Code Migration Examples

### MongoDB Query
```javascript
// Find all spells of level 3+
CreatureProperties.find({
  creatureId: id,
  type: 'spell',
  level: { $gte: 3 }
})
```

### PostgreSQL Query (Supabase)
```javascript
// Option 1: JSONB query
supabase
  .from('creature_properties')
  .select('*')
  .eq('creature_id', id)
  .eq('type', 'spell')
  .gte('data->>level', 3)

// Option 2: If level is extracted to column
supabase
  .from('creature_properties')
  .select('*')
  .eq('creature_id', id)
  .eq('type', 'spell')
  .gte('level', 3)
```

### MongoDB Update
```javascript
// Use an action
CreatureProperties.update(actionId, {
  $inc: { usesUsed: 1 }
})
```

### PostgreSQL Update (raw SQL)
```sql
UPDATE creature_properties
SET data = jsonb_set(
  data,
  '{usesUsed}',
  (COALESCE((data->>'usesUsed')::int, 0) + 1)::text::jsonb
),
updated_at = NOW()
WHERE id = $1
```

---

## Migration Script Pseudo-code

```javascript
// For each property in MongoDB
for await (const mongoProp of mongoProperties.find()) {

  // Map _id to UUID
  const id = mapMongoIdToUUID(mongoProp._id);

  // Extract common fields
  const columns = {
    id,
    creature_id: mapMongoIdToUUID(mongoProp.creatureId),
    type: mongoProp.type,
    name: mongoProp.name || null,
    description: mongoProp.description || null,
    tags: mongoProp.tags || [],
    disabled: mongoProp.disabled || false,
    // ... etc
  };

  // Build JSONB data object
  const data = {};
  const excludeFields = [
    '_id', 'type', 'name', 'description', 'tags', 'disabled',
    'root', 'parentId', 'left', 'right', 'removed', 'creatureId'
  ];

  for (const [key, value] of Object.entries(mongoProp)) {
    if (!excludeFields.includes(key) && !key.startsWith('_')) {
      data[key] = value;
    }
  }

  columns.data = data;

  // Insert into PostgreSQL
  await pg.query(`
    INSERT INTO creature_properties (
      id, creature_id, type, name, description, tags, disabled,
      root_id, parent_id, tree_left, tree_right,
      data, created_at
    ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, NOW())
  `, [
    columns.id,
    columns.creature_id,
    columns.type,
    columns.name,
    columns.description,
    columns.tags,
    columns.disabled,
    columns.root_id,
    columns.parent_id,
    columns.tree_left,
    columns.tree_right,
    JSON.stringify(columns.data)
  ]);
}
```

---

## Validation

After migration, validate JSONB structure:

```sql
-- Check all properties have data field
SELECT COUNT(*) FROM creature_properties WHERE data IS NULL;
-- Should be 0

-- Check each type has expected fields
SELECT type, jsonb_object_keys(data) as keys
FROM creature_properties
WHERE type = 'action'
LIMIT 5;

-- Verify no data loss (compare counts)
-- MongoDB: db.creatureProperties.countDocuments({ type: 'spell' })
-- PostgreSQL:
SELECT COUNT(*) FROM creature_properties WHERE type = 'spell';
```

---

## Future Optimization

Once migration is stable, consider extracting hot fields:

1. **Profile queries** - which JSONB fields are queried most?
2. **Extract to columns** - add columns for hot fields
3. **Add indexes** - index the new columns
4. **Update application code** - query columns instead of JSONB
5. **Benchmark** - compare performance before/after

**Don't premature optimize** - start with JSONB, extract later if needed.

---

## References

- PostgreSQL JSONB functions: https://www.postgresql.org/docs/current/functions-json.html
- JSONB indexing: https://www.postgresql.org/docs/current/datatype-json.html#JSON-INDEXING
- Supabase JSONB queries: https://supabase.com/docs/guides/database/json
