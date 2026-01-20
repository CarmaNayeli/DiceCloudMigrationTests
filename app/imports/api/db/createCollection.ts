import { Mongo } from 'meteor/mongo';
import SimpleSchema from 'simpl-schema';
import PostgresCollection from './PostgresCollection';
import { shouldUsePostgres } from './dbConfig';

/**
 * Collection Factory
 *
 * Creates either a MongoDB or PostgreSQL collection based on feature flags
 * Provides a unified interface for the application
 */

export interface CreateCollectionOptions {
  /**
   * The MongoDB collection name (also used as default table name)
   */
  name: string;

  /**
   * PostgreSQL table name (if different from collection name)
   */
  tableName?: string;

  /**
   * Schema to attach to the collection
   */
  schema?: SimpleSchema;

  /**
   * Force use of PostgreSQL regardless of feature flags (for testing)
   */
  forcePostgres?: boolean;

  /**
   * Force use of MongoDB regardless of feature flags (for testing)
   */
  forceMongo?: boolean;
}

/**
 * Create a collection that uses either MongoDB or PostgreSQL
 * based on the configuration in Meteor.settings
 */
export function createCollection<T extends Record<string, any> = any>(
  options: CreateCollectionOptions
): Mongo.Collection<T> | PostgresCollection<T> {
  const { name, tableName, schema, forcePostgres, forceMongo } = options;

  // Determine which database to use
  let usePostgres = shouldUsePostgres(name);

  if (forcePostgres) {
    usePostgres = true;
  }

  if (forceMongo) {
    usePostgres = false;
  }

  // Create appropriate collection
  if (usePostgres) {
    console.log(`[DB] Creating PostgreSQL collection: ${name} → ${tableName || name}`);
    const collection = new PostgresCollection<T>(name, {
      tableName: tableName || name,
      schema,
    });

    if (schema) {
      collection.attachSchema(schema);
    }

    return collection;
  } else {
    console.log(`[DB] Creating MongoDB collection: ${name}`);
    const collection = new Mongo.Collection<T>(name);

    if (schema) {
      (collection as any).attachSchema(schema);
    }

    return collection;
  }
}

/**
 * Helper to check if a collection is using PostgreSQL
 */
export function isPostgresCollection(collection: any): collection is PostgresCollection {
  return collection instanceof PostgresCollection;
}

/**
 * Helper to check if a collection is using MongoDB
 */
export function isMongoCollection(collection: any): collection is Mongo.Collection {
  return collection instanceof Mongo.Collection;
}

export default createCollection;
