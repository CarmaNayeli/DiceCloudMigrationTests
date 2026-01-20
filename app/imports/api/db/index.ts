/**
 * Database Abstraction Layer
 *
 * Provides a unified interface for both MongoDB and PostgreSQL collections
 * Allows gradual migration with feature flags
 */

export { default as PostgresCollection } from './PostgresCollection';
export { default as createCollection, isPostgresCollection, isMongoCollection } from './createCollection';
export { getDbConfig, shouldUsePostgres, getPostgresConfig } from './dbConfig';
export type { CreateCollectionOptions } from './createCollection';
export type { DatabaseConfig } from './dbConfig';
