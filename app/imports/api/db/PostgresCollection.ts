import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { Pool } from 'pg';
import { Meteor } from 'meteor/meteor';
import SimpleSchema from 'simpl-schema';

/**
 * PostgreSQL Collection - MongoDB-compatible API wrapper for PostgreSQL/Supabase
 *
 * Provides a familiar Mongo.Collection-like interface while using PostgreSQL under the hood.
 * Designed to minimize code changes during the MongoDB → PostgreSQL migration.
 */

interface CollectionOptions {
  idField?: string;
  schema?: SimpleSchema;
  tableName?: string;
}

interface FindOptions {
  fields?: Record<string, number | boolean>;
  limit?: number;
  skip?: number;
  sort?: Record<string, number>;
}

interface Modifier {
  $set?: Record<string, any>;
  $unset?: Record<string, any>;
  $inc?: Record<string, number>;
  $push?: Record<string, any>;
  $pull?: Record<string, any>;
  $addToSet?: Record<string, any>;
}

export class PostgresCollection<T extends Record<string, any> = any> {
  public tableName: string;
  public idField: string;
  private schema?: SimpleSchema;
  private pool?: Pool;
  private supabase?: SupabaseClient;

  constructor(tableName: string, options: CollectionOptions = {}) {
    this.tableName = options.tableName || tableName;
    this.idField = options.idField || 'id';
    this.schema = options.schema;

    // Initialize connections on server only
    if (Meteor.isServer) {
      this.initializeConnections();
    }
  }

  private initializeConnections() {
    // Get connection details from Meteor settings
    const settings = Meteor.settings?.postgres;

    if (!settings) {
      throw new Error('PostgreSQL settings not found in Meteor.settings.postgres');
    }

    // Initialize Supabase client for realtime subscriptions
    if (settings.supabaseUrl && settings.supabaseKey) {
      this.supabase = createClient(settings.supabaseUrl, settings.supabaseKey, {
        auth: {
          autoRefreshToken: false,
          persistSession: false,
        },
      });
    }

    // Initialize pg Pool for efficient bulk operations
    this.pool = new Pool({
      host: settings.host,
      port: settings.port || 5432,
      database: settings.database,
      user: settings.user,
      password: settings.password,
      max: settings.poolSize || 20,
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 10000,
    });

    this.pool.on('error', (err) => {
      console.error('Unexpected PostgreSQL pool error:', err);
    });
  }

  /**
   * Attach SimpleSchema for validation (MongoDB-compatible)
   */
  attachSchema(schema: SimpleSchema) {
    this.schema = schema;
  }

  /**
   * Find documents matching selector
   * Returns a query builder that can be chained
   */
  find(selector: Record<string, any> = {}, options: FindOptions = {}): FindCursor<T> {
    return new FindCursor<T>(this, selector, options);
  }

  /**
   * Find a single document matching selector
   */
  async findOne(selector: Record<string, any> = {}, options: FindOptions = {}): Promise<T | undefined> {
    const cursor = this.find(selector, { ...options, limit: 1 });
    const results = await cursor.fetch();
    return results[0];
  }

  /**
   * Insert a document
   * Returns the inserted document ID
   */
  async insert(doc: Partial<T>): Promise<string> {
    if (!this.pool) {
      throw new Error('PostgreSQL pool not initialized');
    }

    // Validate with schema if attached
    if (this.schema) {
      this.schema.validate(doc);
    }

    // Prepare document
    const preparedDoc = { ...doc };

    // Generate UUID if not provided
    if (!preparedDoc[this.idField]) {
      preparedDoc[this.idField] = await this.generateId();
    }

    // Add timestamps
    if (!preparedDoc.created_at) {
      preparedDoc.created_at = new Date();
    }
    if (!preparedDoc.updated_at) {
      preparedDoc.updated_at = new Date();
    }

    // Build INSERT query
    const columns = Object.keys(preparedDoc);
    const values = Object.values(preparedDoc);
    const placeholders = columns.map((_, i) => `$${i + 1}`).join(', ');

    const query = `
      INSERT INTO ${this.tableName} (${columns.join(', ')})
      VALUES (${placeholders})
      RETURNING ${this.idField}
    `;

    try {
      const result = await this.pool.query(query, values);
      return result.rows[0][this.idField];
    } catch (error: any) {
      console.error(`Error inserting into ${this.tableName}:`, error);
      throw new Meteor.Error('insert-failed', error.message);
    }
  }

  /**
   * Update documents matching selector
   * Supports MongoDB-style modifiers ($set, $inc, $push, etc.)
   */
  async update(
    selector: Record<string, any>,
    modifier: Modifier | Record<string, any>,
    options: { multi?: boolean; upsert?: boolean } = {}
  ): Promise<number> {
    if (!this.pool) {
      throw new Error('PostgreSQL pool not initialized');
    }

    // Parse modifier
    const updates = this.parseModifier(modifier);

    if (Object.keys(updates).length === 0) {
      return 0;
    }

    // Add updated_at timestamp
    updates.updated_at = new Date();

    // Build WHERE clause
    const whereClause = this.buildWhereClause(selector);

    // Build SET clause
    const setClauses: string[] = [];
    const values: any[] = [];
    let paramIndex = 1;

    for (const [key, value] of Object.entries(updates)) {
      setClauses.push(`${key} = $${paramIndex}`);
      values.push(value);
      paramIndex++;
    }

    // Add WHERE parameters
    const whereParams = this.extractWhereParams(selector);
    values.push(...whereParams);

    // Build query
    let query = `
      UPDATE ${this.tableName}
      SET ${setClauses.join(', ')}
      WHERE ${whereClause}
    `;

    // Handle multi option
    if (!options.multi) {
      query += ' LIMIT 1';
    }

    try {
      const result = await this.pool.query(query, values);
      return result.rowCount || 0;
    } catch (error: any) {
      console.error(`Error updating ${this.tableName}:`, error);
      throw new Meteor.Error('update-failed', error.message);
    }
  }

  /**
   * Remove documents matching selector
   */
  async remove(selector: Record<string, any>, options: { multi?: boolean } = {}): Promise<number> {
    if (!this.pool) {
      throw new Error('PostgreSQL pool not initialized');
    }

    const whereClause = this.buildWhereClause(selector);
    const whereParams = this.extractWhereParams(selector);

    let query = `
      DELETE FROM ${this.tableName}
      WHERE ${whereClause}
    `;

    if (!options.multi) {
      query += ' LIMIT 1';
    }

    try {
      const result = await this.pool.query(query, whereParams);
      return result.rowCount || 0;
    } catch (error: any) {
      console.error(`Error removing from ${this.tableName}:`, error);
      throw new Meteor.Error('remove-failed', error.message);
    }
  }

  /**
   * Count documents matching selector
   */
  async count(selector: Record<string, any> = {}): Promise<number> {
    if (!this.pool) {
      throw new Error('PostgreSQL pool not initialized');
    }

    const whereClause = this.buildWhereClause(selector);
    const whereParams = this.extractWhereParams(selector);

    const query = `
      SELECT COUNT(*) as count
      FROM ${this.tableName}
      WHERE ${whereClause}
    `;

    try {
      const result = await this.pool.query(query, whereParams);
      return parseInt(result.rows[0].count, 10);
    } catch (error: any) {
      console.error(`Error counting ${this.tableName}:`, error);
      throw new Meteor.Error('count-failed', error.message);
    }
  }

  /**
   * Upsert a document (update or insert)
   */
  async upsert(selector: Record<string, any>, modifier: Modifier | Record<string, any>): Promise<{ numberAffected: number; insertedId?: string }> {
    const existing = await this.findOne(selector);

    if (existing) {
      const count = await this.update(selector, modifier);
      return { numberAffected: count };
    } else {
      const updates = this.parseModifier(modifier);
      const doc = { ...selector, ...updates };
      const insertedId = await this.insert(doc);
      return { numberAffected: 1, insertedId };
    }
  }

  /**
   * Execute raw SQL query (for complex operations)
   */
  async rawQuery<R = any>(query: string, params: any[] = []): Promise<R[]> {
    if (!this.pool) {
      throw new Error('PostgreSQL pool not initialized');
    }

    try {
      const result = await this.pool.query(query, params);
      return result.rows as R[];
    } catch (error: any) {
      console.error('Raw query error:', error);
      throw new Meteor.Error('query-failed', error.message);
    }
  }

  // ============================================================================
  // Helper Methods
  // ============================================================================

  private async generateId(): Promise<string> {
    if (!this.pool) {
      throw new Error('PostgreSQL pool not initialized');
    }

    const result = await this.pool.query('SELECT uuid_generate_v4() as id');
    return result.rows[0].id;
  }

  private parseModifier(modifier: Modifier | Record<string, any>): Record<string, any> {
    const updates: Record<string, any> = {};

    // Check if it's a MongoDB-style modifier or plain object
    const hasModifiers = Object.keys(modifier).some(key => key.startsWith('$'));

    if (!hasModifiers) {
      // Plain object update
      return modifier;
    }

    // Handle $set
    if (modifier.$set) {
      Object.assign(updates, modifier.$set);
    }

    // Handle $unset (set to null in PostgreSQL)
    if (modifier.$unset) {
      for (const key of Object.keys(modifier.$unset)) {
        updates[key] = null;
      }
    }

    // Handle $inc
    if (modifier.$inc) {
      for (const [key, value] of Object.entries(modifier.$inc)) {
        // Will need special SQL handling: field = field + value
        updates[key] = { $inc: value };
      }
    }

    // Note: $push, $pull, $addToSet will need array operation handling
    if (modifier.$push || modifier.$pull || modifier.$addToSet) {
      console.warn('Array operations ($push, $pull, $addToSet) require custom implementation');
    }

    return updates;
  }

  private buildWhereClause(selector: Record<string, any>): string {
    if (Object.keys(selector).length === 0) {
      return 'TRUE';
    }

    const conditions: string[] = [];
    let paramIndex = 1;

    for (const [key, value] of Object.entries(selector)) {
      if (value === null || value === undefined) {
        conditions.push(`${key} IS NULL`);
      } else if (typeof value === 'object' && !Array.isArray(value)) {
        // Handle MongoDB operators
        for (const [operator, operand] of Object.entries(value)) {
          switch (operator) {
            case '$gt':
              conditions.push(`${key} > $${paramIndex++}`);
              break;
            case '$gte':
              conditions.push(`${key} >= $${paramIndex++}`);
              break;
            case '$lt':
              conditions.push(`${key} < $${paramIndex++}`);
              break;
            case '$lte':
              conditions.push(`${key} <= $${paramIndex++}`);
              break;
            case '$ne':
              conditions.push(`${key} != $${paramIndex++}`);
              break;
            case '$in':
              conditions.push(`${key} = ANY($${paramIndex++})`);
              break;
            case '$nin':
              conditions.push(`${key} != ALL($${paramIndex++})`);
              break;
            case '$exists':
              conditions.push(operand ? `${key} IS NOT NULL` : `${key} IS NULL`);
              paramIndex--; // No parameter needed
              break;
            default:
              console.warn(`Unsupported operator: ${operator}`);
          }
        }
      } else if (Array.isArray(value)) {
        // Array containment check
        conditions.push(`${key} @> $${paramIndex++}`);
      } else {
        conditions.push(`${key} = $${paramIndex++}`);
      }
    }

    return conditions.join(' AND ');
  }

  private extractWhereParams(selector: Record<string, any>): any[] {
    const params: any[] = [];

    for (const [key, value] of Object.entries(selector)) {
      if (value === null || value === undefined) {
        // No parameter for IS NULL
      } else if (typeof value === 'object' && !Array.isArray(value)) {
        // Handle MongoDB operators
        for (const [operator, operand] of Object.entries(value)) {
          if (operator !== '$exists') {
            params.push(operand);
          }
        }
      } else {
        params.push(value);
      }
    }

    return params;
  }
}

/**
 * Cursor class for query chaining (MongoDB-compatible)
 */
class FindCursor<T> {
  private collection: PostgresCollection<T>;
  private selector: Record<string, any>;
  private options: FindOptions;

  constructor(collection: PostgresCollection<T>, selector: Record<string, any>, options: FindOptions) {
    this.collection = collection;
    this.selector = selector;
    this.options = options;
  }

  /**
   * Set field projection
   */
  fields(fields: Record<string, number | boolean>): FindCursor<T> {
    this.options.fields = fields;
    return this;
  }

  /**
   * Set limit
   */
  limit(limit: number): FindCursor<T> {
    this.options.limit = limit;
    return this;
  }

  /**
   * Set skip
   */
  skip(skip: number): FindCursor<T> {
    this.options.skip = skip;
    return this;
  }

  /**
   * Set sort order
   */
  sort(sort: Record<string, number>): FindCursor<T> {
    this.options.sort = sort;
    return this;
  }

  /**
   * Execute query and return results
   */
  async fetch(): Promise<T[]> {
    const pool = (this.collection as any).pool;
    if (!pool) {
      throw new Error('PostgreSQL pool not initialized');
    }

    // Build SELECT clause
    const selectFields = this.buildSelectClause();

    // Build WHERE clause
    const whereClause = (this.collection as any).buildWhereClause(this.selector);
    const whereParams = (this.collection as any).extractWhereParams(this.selector);

    // Build query
    let query = `
      SELECT ${selectFields}
      FROM ${this.collection.tableName}
      WHERE ${whereClause}
    `;

    // Add ORDER BY
    if (this.options.sort) {
      const orderClauses = Object.entries(this.options.sort)
        .map(([field, direction]) => `${field} ${direction === 1 ? 'ASC' : 'DESC'}`)
        .join(', ');
      query += ` ORDER BY ${orderClauses}`;
    }

    // Add LIMIT
    if (this.options.limit) {
      query += ` LIMIT ${this.options.limit}`;
    }

    // Add OFFSET
    if (this.options.skip) {
      query += ` OFFSET ${this.options.skip}`;
    }

    try {
      const result = await pool.query(query, whereParams);
      return result.rows as T[];
    } catch (error: any) {
      console.error(`Error fetching from ${this.collection.tableName}:`, error);
      throw new Meteor.Error('fetch-failed', error.message);
    }
  }

  /**
   * Count results without fetching
   */
  async count(): Promise<number> {
    return this.collection.count(this.selector);
  }

  /**
   * Execute query and return first result
   */
  async fetchOne(): Promise<T | undefined> {
    this.options.limit = 1;
    const results = await this.fetch();
    return results[0];
  }

  private buildSelectClause(): string {
    if (!this.options.fields) {
      return '*';
    }

    const fields: string[] = [];
    for (const [field, include] of Object.entries(this.options.fields)) {
      if (include) {
        fields.push(field);
      }
    }

    return fields.length > 0 ? fields.join(', ') : '*';
  }
}

export default PostgresCollection;
