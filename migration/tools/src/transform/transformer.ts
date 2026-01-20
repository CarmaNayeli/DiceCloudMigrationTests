import {
  MongoCreature,
  MongoCreatureProperty,
  PgCreature,
  PgCreatureProperty,
  CREATURE_FIELD_MAPPINGS,
  PROPERTY_FIELD_MAPPINGS,
  PROPERTY_EXCLUDED_FIELDS,
} from '../types.js';
import { getUUIDMapper } from '../utils/uuid-mapper.js';

/**
 * Transform MongoDB Creature document to PostgreSQL row
 */
export function transformCreature(mongoDoc: MongoCreature): PgCreature {
  const mapper = getUUIDMapper();

  const pgRow: Partial<PgCreature> = {};

  // Map standard fields
  for (const mapping of CREATURE_FIELD_MAPPINGS) {
    const value = getNestedValue(mongoDoc, mapping.mongoField);

    if (value !== undefined) {
      const transformed = mapping.transform ? mapping.transform(value) : value;
      setNestedValue(pgRow, mapping.pgField, transformed);
    }
  }

  // Convert IDs to UUIDs
  pgRow.id = mapper.toUUID(mongoDoc._id?.toString());
  pgRow.owner_id = mapper.toUUID(mongoDoc.owner);

  if (mongoDoc.readers) {
    pgRow.readers = mapper.toUUIDs(mongoDoc.readers);
  }

  if (mongoDoc.writers) {
    pgRow.writers = mapper.toUUIDs(mongoDoc.writers);
  }

  if (mongoDoc.removedWith) {
    pgRow.removed_with = mapper.toUUID(mongoDoc.removedWith);
  }

  // Handle other fields that might not be in mappings
  if (mongoDoc.alignment) pgRow.alignment = mongoDoc.alignment;
  if (mongoDoc.gender) pgRow.gender = mongoDoc.gender;
  if (mongoDoc.picture) pgRow.picture = mongoDoc.picture;
  if (mongoDoc.avatarPicture) pgRow.avatar_picture = mongoDoc.avatarPicture;
  if (mongoDoc.color) pgRow.color = mongoDoc.color;
  if (mongoDoc.tabletopId) pgRow.tabletop_id = mapper.toUUID(mongoDoc.tabletopId);

  // Settings as JSONB
  if (mongoDoc.settings) {
    pgRow.settings = mongoDoc.settings;
  }

  // Arrays
  if (mongoDoc.allowedLibraries) {
    pgRow.allowed_libraries = mapper.toUUIDs(mongoDoc.allowedLibraries);
  }

  if (mongoDoc.allowedLibraryCollections) {
    pgRow.allowed_library_collections = mapper.toUUIDs(
      mongoDoc.allowedLibraryCollections
    );
  }

  // Compute errors as JSONB
  if (mongoDoc.computeErrors) {
    pgRow.compute_errors = mongoDoc.computeErrors;
  }

  return pgRow as PgCreature;
}

/**
 * Transform MongoDB CreatureProperty document to PostgreSQL row
 */
export function transformCreatureProperty(
  mongoDoc: MongoCreatureProperty
): PgCreatureProperty {
  const mapper = getUUIDMapper();

  const pgRow: Partial<PgCreatureProperty> = {};

  // Map standard fields
  for (const mapping of PROPERTY_FIELD_MAPPINGS) {
    const value = getNestedValue(mongoDoc, mapping.mongoField);

    if (value !== undefined || mapping.required) {
      const transformed = mapping.transform ? mapping.transform(value) : value;
      setNestedValue(pgRow, mapping.pgField, transformed);
    }
  }

  // Convert IDs to UUIDs
  pgRow.id = mapper.toUUID(mongoDoc._id?.toString());
  pgRow.creature_id = mapper.toUUID(mongoDoc.creatureId);
  pgRow.root_id = mapper.toUUID(mongoDoc.root?.id);

  if (mongoDoc.parentId) {
    pgRow.parent_id = mapper.toUUID(mongoDoc.parentId);
  }

  if (mongoDoc.removedWith) {
    pgRow.removed_with = mapper.toUUID(mongoDoc.removedWith);
  }

  // Build JSONB data object from type-specific fields
  const data: Record<string, any> = {};

  for (const [key, value] of Object.entries(mongoDoc)) {
    // Skip fields that are mapped to columns
    if (PROPERTY_EXCLUDED_FIELDS.includes(key)) continue;
    if (key.startsWith('_')) continue; // Skip MongoDB internal fields

    // Include in JSONB data
    data[key] = value;
  }

  pgRow.data = data;

  // Handle denormalized fields (columns, not in JSONB)
  if (mongoDoc.inactive !== undefined) pgRow.inactive = mongoDoc.inactive;
  if (mongoDoc.deactivatedByAncestor !== undefined)
    pgRow.deactivated_by_ancestor = mongoDoc.deactivatedByAncestor;
  if (mongoDoc.deactivatedBySelf !== undefined)
    pgRow.deactivated_by_self = mongoDoc.deactivatedBySelf;
  if (mongoDoc.deactivatedByToggle !== undefined)
    pgRow.deactivated_by_toggle = mongoDoc.deactivatedByToggle;
  if (mongoDoc.deactivatingToggleId)
    pgRow.deactivating_toggle_id = mapper.toUUID(mongoDoc.deactivatingToggleId);
  if (mongoDoc.triggerIds) pgRow.trigger_ids = mongoDoc.triggerIds;
  if (mongoDoc.dirty !== undefined) pgRow.dirty = mongoDoc.dirty;
  if (mongoDoc.icon) pgRow.icon = mongoDoc.icon;
  if (mongoDoc.libraryNodeId)
    pgRow.library_node_id = mapper.toUUID(mongoDoc.libraryNodeId);
  if (mongoDoc.slotQuantityFilled)
    pgRow.slot_quantity_filled = mongoDoc.slotQuantityFilled;
  if (mongoDoc.color) pgRow.color = mongoDoc.color;

  return pgRow as PgCreatureProperty;
}

/**
 * Transform MongoDB CreatureLog to PostgreSQL row
 */
export function transformCreatureLog(mongoDoc: any): any {
  const mapper = getUUIDMapper();

  return {
    id: mapper.toUUID(mongoDoc._id?.toString()),
    creature_id: mapper.toUUID(mongoDoc.creatureId),
    tabletop_id: mongoDoc.tabletopId ? mapper.toUUID(mongoDoc.tabletopId) : null,
    action_id: mongoDoc.actionId ? mapper.toUUID(mongoDoc.actionId) : null,
    creature_name: mongoDoc.creatureName,
    content: mongoDoc.content || [],
    date: mongoDoc.date,
    created_at: mongoDoc.date,
  };
}

/**
 * Transform MongoDB Experience to PostgreSQL row
 */
export function transformExperience(mongoDoc: any): any {
  const mapper = getUUIDMapper();

  return {
    id: mapper.toUUID(mongoDoc._id?.toString()),
    creature_id: mapper.toUUID(mongoDoc.creatureId),
    name: mongoDoc.name,
    xp: mongoDoc.xp || 0,
    levels: mongoDoc.levels || 0,
    date: mongoDoc.date,
    created_at: mongoDoc.date,
  };
}

/**
 * Transform MongoDB Library to PostgreSQL row
 */
export function transformLibrary(mongoDoc: any): any {
  const mapper = getUUIDMapper();

  return {
    id: mapper.toUUID(mongoDoc._id?.toString()),
    name: mongoDoc.name,
    description: mongoDoc.description,
    show_in_market: mongoDoc.showInMarket || false,
    subscriber_count: mongoDoc.subscriberCount || 0,
    owner_id: mapper.toUUID(mongoDoc.owner),
    readers: mongoDoc.readers ? mapper.toUUIDs(mongoDoc.readers) : [],
    writers: mongoDoc.writers ? mapper.toUUIDs(mongoDoc.writers) : [],
    public: mongoDoc.public || false,
    readers_can_copy: mongoDoc.readersCanCopy || false,
  };
}

/**
 * Transform MongoDB LibraryNode to PostgreSQL row
 */
export function transformLibraryNode(mongoDoc: any): any {
  const mapper = getUUIDMapper();

  // Similar to creature properties
  const data: Record<string, any> = {};

  for (const [key, value] of Object.entries(mongoDoc)) {
    if (PROPERTY_EXCLUDED_FIELDS.includes(key)) continue;
    if (key.startsWith('_')) continue;
    data[key] = value;
  }

  return {
    id: mapper.toUUID(mongoDoc._id?.toString()),
    library_id: mapper.toUUID(mongoDoc.libraryId),
    type: mongoDoc.type,
    name: mongoDoc.name,
    description: mongoDoc.description,
    tags: mongoDoc.tags || [],
    data,
    color: mongoDoc.color,
    root_id: mapper.toUUID(mongoDoc.root?.id),
    root_collection: mongoDoc.root?.collection || 'libraries',
    parent_id: mongoDoc.parentId ? mapper.toUUID(mongoDoc.parentId) : null,
    tree_left: mongoDoc.left,
    tree_right: mongoDoc.right,
    removed: mongoDoc.removed || false,
    removed_at: mongoDoc.removedAt,
    removed_with: mongoDoc.removedWith ? mapper.toUUID(mongoDoc.removedWith) : null,
  };
}

/**
 * Transform MongoDB User to PostgreSQL user_profile row
 */
export function transformUser(mongoDoc: any): any {
  const mapper = getUUIDMapper();

  return {
    id: mapper.toUUID(mongoDoc._id?.toString()),
    username: mongoDoc.username,
    display_name: mongoDoc.profile?.name,
    picture: mongoDoc.profile?.picture,
    // Note: Actual auth will be in Supabase auth.users table
    // This is just the profile extension
  };
}

// ============================================================================
// Helper Functions
// ============================================================================

/**
 * Get nested value from object using dot notation
 */
function getNestedValue(obj: any, path: string): any {
  return path.split('.').reduce((current, key) => current?.[key], obj);
}

/**
 * Set nested value in object using dot notation
 */
function setNestedValue(obj: any, path: string, value: any): void {
  const keys = path.split('.');
  const lastKey = keys.pop()!;

  const target = keys.reduce((current, key) => {
    if (!current[key]) current[key] = {};
    return current[key];
  }, obj);

  target[lastKey] = value;
}

/**
 * Generic transformer that routes to specific transformers
 */
export function transform(collection: string, mongoDoc: any): any {
  switch (collection) {
    case 'creatures':
      return transformCreature(mongoDoc);
    case 'creatureProperties':
      return transformCreatureProperty(mongoDoc);
    case 'creatureLogs':
      return transformCreatureLog(mongoDoc);
    case 'experiences':
      return transformExperience(mongoDoc);
    case 'libraries':
      return transformLibrary(mongoDoc);
    case 'libraryNodes':
      return transformLibraryNode(mongoDoc);
    case 'users':
      return transformUser(mongoDoc);
    default:
      throw new Error(`No transformer defined for collection: ${collection}`);
  }
}

/**
 * Batch transform documents
 */
export function transformBatch(
  collection: string,
  mongoDocs: any[]
): any[] {
  return mongoDocs.map(doc => transform(collection, doc));
}
