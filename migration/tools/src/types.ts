import { ObjectId } from 'mongodb';

// ============================================================================
// Migration Types
// ============================================================================

export interface MigrationConfig {
  batchSize: number;
  maxRetries: number;
  checkpointInterval: number;
  parallelBatches: number;
  dryRun?: boolean;
}

export interface Checkpoint {
  collection: string;
  lastId: string;
  processedCount: number;
  totalCount: number;
  timestamp: Date;
  errors: number;
}

export interface MigrationStats {
  collection: string;
  startTime: Date;
  endTime?: Date;
  totalRecords: number;
  processedRecords: number;
  successfulRecords: number;
  failedRecords: number;
  errors: MigrationError[];
}

export interface MigrationError {
  id: string;
  error: string;
  data?: any;
  timestamp: Date;
}

// ============================================================================
// Collection Mappings
// ============================================================================

export const COLLECTION_MAPPINGS: Record<string, CollectionMapping> = {
  creatures: {
    mongoCollection: 'creatures',
    pgTable: 'creatures',
    idField: '_id',
    pgIdField: 'id',
  },
  creatureProperties: {
    mongoCollection: 'creatureProperties',
    pgTable: 'creature_properties',
    idField: '_id',
    pgIdField: 'id',
  },
  creatureVariables: {
    mongoCollection: 'creatureVariables',
    pgTable: 'creature_variables',
    idField: '_id',
    pgIdField: 'id',
  },
  creatureLogs: {
    mongoCollection: 'creatureLogs',
    pgTable: 'creature_logs',
    idField: '_id',
    pgIdField: 'id',
  },
  experiences: {
    mongoCollection: 'experiences',
    pgTable: 'experiences',
    idField: '_id',
    pgIdField: 'id',
  },
  libraries: {
    mongoCollection: 'libraries',
    pgTable: 'libraries',
    idField: '_id',
    pgIdField: 'id',
  },
  libraryNodes: {
    mongoCollection: 'libraryNodes',
    pgTable: 'library_nodes',
    idField: '_id',
    pgIdField: 'id',
  },
  users: {
    mongoCollection: 'users',
    pgTable: 'user_profiles',
    idField: '_id',
    pgIdField: 'id',
  },
};

export interface CollectionMapping {
  mongoCollection: string;
  pgTable: string;
  idField: string;
  pgIdField: string;
}

// ============================================================================
// MongoDB Document Types
// ============================================================================

export interface MongoCreature {
  _id: ObjectId | string;
  name: string;
  owner: string;
  readers?: string[];
  writers?: string[];
  public?: boolean;
  type?: 'pc' | 'npc' | 'monster';
  denormalizedStats?: {
    xp?: number;
    milestoneLevels?: number;
  };
  propCount?: number;
  dirty?: boolean;
  removed?: boolean;
  removedAt?: Date;
  removedWith?: string;
  // ... other fields
  [key: string]: any;
}

export interface MongoCreatureProperty {
  _id: ObjectId | string;
  creatureId?: string;
  type: string;
  name?: string;
  description?: string;
  tags?: string[];
  disabled?: boolean;
  root?: {
    id: string;
    collection: string;
  };
  parentId?: string;
  left?: number;
  right?: number;
  removed?: boolean;
  removedAt?: Date;
  // ... type-specific fields
  [key: string]: any;
}

// ============================================================================
// PostgreSQL Row Types
// ============================================================================

export interface PgCreature {
  id: string; // UUID
  name: string;
  owner_id: string; // UUID
  readers?: string[]; // UUID[]
  writers?: string[]; // UUID[]
  public?: boolean;
  type?: 'pc' | 'npc' | 'monster';
  denormalized_xp?: number;
  denormalized_milestone_levels?: number;
  prop_count?: number;
  dirty?: boolean;
  removed?: boolean;
  removed_at?: Date;
  removed_with?: string; // UUID
  created_at?: Date;
  updated_at?: Date;
  [key: string]: any;
}

export interface PgCreatureProperty {
  id: string; // UUID
  creature_id: string; // UUID
  type: string;
  name?: string;
  description?: string;
  tags?: string[];
  disabled?: boolean;
  data: Record<string, any>; // JSONB
  root_id: string; // UUID
  root_collection: string;
  parent_id?: string; // UUID
  tree_left?: number;
  tree_right?: number;
  removed?: boolean;
  removed_at?: Date;
  removed_with?: string; // UUID
  created_at?: Date;
  updated_at?: Date;
}

// ============================================================================
// Field Transformation Rules
// ============================================================================

export interface FieldMapping {
  mongoField: string;
  pgField: string;
  transform?: (value: any) => any;
  required?: boolean;
}

export const CREATURE_FIELD_MAPPINGS: FieldMapping[] = [
  { mongoField: '_id', pgField: 'id', transform: (v) => v }, // Will be UUID
  { mongoField: 'name', pgField: 'name' },
  { mongoField: 'owner', pgField: 'owner_id', transform: (v) => v }, // Will be UUID
  { mongoField: 'readers', pgField: 'readers', transform: (v) => v || [] },
  { mongoField: 'writers', pgField: 'writers', transform: (v) => v || [] },
  { mongoField: 'public', pgField: 'public', transform: (v) => v || false },
  { mongoField: 'type', pgField: 'type', transform: (v) => v || 'pc' },
  { mongoField: 'denormalizedStats.xp', pgField: 'denormalized_xp', transform: (v) => v || 0 },
  { mongoField: 'denormalizedStats.milestoneLevels', pgField: 'denormalized_milestone_levels', transform: (v) => v || 0 },
  { mongoField: 'propCount', pgField: 'prop_count', transform: (v) => v || 0 },
  { mongoField: 'dirty', pgField: 'dirty', transform: (v) => v || false },
  { mongoField: 'removed', pgField: 'removed', transform: (v) => v || false },
  { mongoField: 'removedAt', pgField: 'removed_at' },
  { mongoField: 'removedWith', pgField: 'removed_with', transform: (v) => v }, // Will be UUID
];

export const PROPERTY_FIELD_MAPPINGS: FieldMapping[] = [
  { mongoField: '_id', pgField: 'id' },
  { mongoField: 'creatureId', pgField: 'creature_id' },
  { mongoField: 'type', pgField: 'type', required: true },
  { mongoField: 'name', pgField: 'name' },
  { mongoField: 'description', pgField: 'description' },
  { mongoField: 'tags', pgField: 'tags', transform: (v) => v || [] },
  { mongoField: 'disabled', pgField: 'disabled', transform: (v) => v || false },
  { mongoField: 'root.id', pgField: 'root_id', required: true },
  { mongoField: 'root.collection', pgField: 'root_collection', required: true },
  { mongoField: 'parentId', pgField: 'parent_id' },
  { mongoField: 'left', pgField: 'tree_left' },
  { mongoField: 'right', pgField: 'tree_right' },
  { mongoField: 'removed', pgField: 'removed', transform: (v) => v || false },
  { mongoField: 'removedAt', pgField: 'removed_at' },
  { mongoField: 'removedWith', pgField: 'removed_with' },
];

// Fields to exclude from JSONB data field
export const PROPERTY_EXCLUDED_FIELDS = [
  '_id', 'creatureId', 'type', 'name', 'description', 'tags', 'disabled',
  'root', 'parentId', 'left', 'right', 'removed', 'removedAt', 'removedWith',
  'inactive', 'deactivatedByAncestor', 'deactivatedBySelf', 'deactivatedByToggle',
  'dirty', 'icon', 'libraryNodeId', 'slotQuantityFilled', 'color',
  'deactivatingToggleId', 'triggerIds'
];
