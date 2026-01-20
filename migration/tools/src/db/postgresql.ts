import { Pool, PoolClient, QueryResult } from 'pg';
import { createClient, SupabaseClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';

dotenv.config();

let pool: Pool | null = null;
let supabase: SupabaseClient | null = null;

/**
 * Connect to PostgreSQL using pg Pool (for bulk operations)
 */
export function connectPostgres(): Pool {
  if (pool) return pool;

  pool = new Pool({
    host: process.env.POSTGRES_HOST,
    port: parseInt(process.env.POSTGRES_PORT || '5432'),
    database: process.env.POSTGRES_DB,
    user: process.env.POSTGRES_USER,
    password: process.env.POSTGRES_PASSWORD,
    max: 20, // Connection pool size
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 10000,
  });

  pool.on('error', (err) => {
    console.error('Unexpected PostgreSQL error:', err);
  });

  console.log('✓ PostgreSQL pool created');

  return pool;
}

/**
 * Get Supabase client (for API operations)
 */
export function getSupabase(): SupabaseClient {
  if (supabase) return supabase;

  const supabaseUrl = process.env.SUPABASE_URL;
  const supabaseKey = process.env.SUPABASE_SERVICE_KEY;

  if (!supabaseUrl || !supabaseKey) {
    throw new Error('SUPABASE_URL and SUPABASE_SERVICE_KEY must be set');
  }

  supabase = createClient(supabaseUrl, supabaseKey, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  });

  console.log('✓ Supabase client created');

  return supabase;
}

/**
 * Disconnect from PostgreSQL
 */
export async function disconnectPostgres(): Promise<void> {
  if (pool) {
    await pool.end();
    pool = null;
    console.log('✓ Disconnected from PostgreSQL');
  }
}

/**
 * Execute a SQL query
 */
export async function query<T = any>(
  sql: string,
  params?: any[]
): Promise<QueryResult<T>> {
  const pgPool = connectPostgres();
  return await pgPool.query<T>(sql, params);
}

/**
 * Execute a query within a transaction
 */
export async function transaction<T>(
  callback: (client: PoolClient) => Promise<T>
): Promise<T> {
  const pgPool = connectPostgres();
  const client = await pgPool.connect();

  try {
    await client.query('BEGIN');
    const result = await callback(client);
    await client.query('COMMIT');
    return result;
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

/**
 * Bulk insert using COPY (fastest method for PostgreSQL)
 */
export async function bulkInsert(
  tableName: string,
  columns: string[],
  rows: any[][]
): Promise<number> {
  if (rows.length === 0) return 0;

  const pgPool = connectPostgres();
  const client = await pgPool.connect();

  try {
    // Build COPY command
    const copyQuery = `COPY ${tableName} (${columns.join(', ')}) FROM STDIN WITH (FORMAT csv, NULL '\\N')`;

    // Convert rows to CSV format
    const csvData = rows
      .map(row =>
        row
          .map(value => {
            if (value === null || value === undefined) return '\\N';
            if (typeof value === 'string') {
              // Escape quotes and wrap in quotes
              return `"${value.replace(/"/g, '""')}"`;
            }
            if (Array.isArray(value)) {
              // PostgreSQL array format: {val1,val2}
              return `"{${value.join(',')}}`;
            }
            if (typeof value === 'object') {
              // JSON
              return `"${JSON.stringify(value).replace(/"/g, '""')}"`;
            }
            return value;
          })
          .join(',')
      )
      .join('\n');

    // Execute COPY
    const stream = client.query({
      text: copyQuery,
      rowMode: 'array',
    });

    await new Promise((resolve, reject) => {
      stream.on('error', reject);
      stream.on('end', resolve);
      stream.write(csvData);
      stream.end();
    });

    return rows.length;
  } finally {
    client.release();
  }
}

/**
 * Insert rows using standard INSERT (safer, slower)
 */
export async function batchInsert(
  tableName: string,
  columns: string[],
  rows: Record<string, any>[],
  onConflict?: string
): Promise<number> {
  if (rows.length === 0) return 0;

  const pgPool = connectPostgres();

  // Build parameterized query
  const placeholders = rows
    .map((_, rowIndex) => {
      const valueList = columns
        .map((_, colIndex) => `$${rowIndex * columns.length + colIndex + 1}`)
        .join(', ');
      return `(${valueList})`;
    })
    .join(', ');

  const sql = `
    INSERT INTO ${tableName} (${columns.join(', ')})
    VALUES ${placeholders}
    ${onConflict || ''}
  `;

  // Flatten all values into a single array
  const values = rows.flatMap(row => columns.map(col => row[col]));

  await pgPool.query(sql, values);

  return rows.length;
}

/**
 * Count rows in table
 */
export async function countRows(
  tableName: string,
  where?: string
): Promise<number> {
  const sql = where
    ? `SELECT COUNT(*) FROM ${tableName} WHERE ${where}`
    : `SELECT COUNT(*) FROM ${tableName}`;

  const result = await query<{ count: string }>(sql);
  return parseInt(result.rows[0].count);
}

/**
 * Test PostgreSQL connection
 */
export async function testPostgresConnection(): Promise<boolean> {
  try {
    const result = await query('SELECT NOW(), version()');
    console.log('✓ PostgreSQL connection successful');
    console.log(`  Server time: ${result.rows[0].now}`);
    console.log(`  Version: ${result.rows[0].version.split(',')[0]}`);
    return true;
  } catch (error: any) {
    console.error('✗ PostgreSQL connection failed:', error.message);
    return false;
  }
}

/**
 * Check if table exists
 */
export async function tableExists(tableName: string): Promise<boolean> {
  const result = await query(
    `SELECT EXISTS (
      SELECT FROM information_schema.tables
      WHERE table_schema = 'public'
      AND table_name = $1
    )`,
    [tableName]
  );

  return result.rows[0].exists;
}

/**
 * Get table row count
 */
export async function getTableStats(tableName: string): Promise<{
  rowCount: number;
  tableSize: string;
}> {
  const [countResult, sizeResult] = await Promise.all([
    query(`SELECT COUNT(*) FROM ${tableName}`),
    query(`SELECT pg_size_pretty(pg_total_relation_size($1))`, [tableName]),
  ]);

  return {
    rowCount: parseInt(countResult.rows[0].count),
    tableSize: sizeResult.rows[0].pg_size_pretty,
  };
}
