import { MongoClient, Db, Collection, Document } from 'mongodb';
import dotenv from 'dotenv';

dotenv.config();

let client: MongoClient | null = null;
let db: Db | null = null;

/**
 * Connect to MongoDB
 */
export async function connectMongo(): Promise<Db> {
  if (db) return db;

  const uri = process.env.MONGODB_URI;
  if (!uri) {
    throw new Error('MONGODB_URI environment variable is not set');
  }

  console.log('Connecting to MongoDB...');

  client = new MongoClient(uri);
  await client.connect();

  db = client.db();

  console.log('✓ Connected to MongoDB');

  return db;
}

/**
 * Disconnect from MongoDB
 */
export async function disconnectMongo(): Promise<void> {
  if (client) {
    await client.close();
    client = null;
    db = null;
    console.log('✓ Disconnected from MongoDB');
  }
}

/**
 * Get MongoDB collection
 */
export function getMongoCollection<T extends Document = Document>(
  collectionName: string
): Collection<T> {
  if (!db) {
    throw new Error('MongoDB not connected. Call connectMongo() first.');
  }
  return db.collection<T>(collectionName);
}

/**
 * Count documents in collection
 */
export async function countDocuments(
  collectionName: string,
  filter: Record<string, any> = {}
): Promise<number> {
  const collection = getMongoCollection(collectionName);
  return await collection.countDocuments(filter);
}

/**
 * Extract documents in batches with callback
 */
export async function extractBatch<T extends Document = Document>(
  collectionName: string,
  batchSize: number,
  filter: Record<string, any> = {},
  onBatch: (docs: T[], progress: { processed: number; total: number }) => Promise<void>
): Promise<void> {
  const collection = getMongoCollection<T>(collectionName);

  // Get total count
  const total = await collection.countDocuments(filter);
  console.log(`Total documents to process: ${total}`);

  if (total === 0) {
    console.log('No documents to process');
    return;
  }

  let processed = 0;
  let lastId: any = null;

  while (processed < total) {
    // Build query
    const query = lastId
      ? { ...filter, _id: { $gt: lastId } }
      : filter;

    // Fetch batch
    const docs = await collection
      .find(query)
      .sort({ _id: 1 })
      .limit(batchSize)
      .toArray();

    if (docs.length === 0) break;

    // Process batch
    await onBatch(docs, { processed, total });

    // Update progress
    processed += docs.length;
    lastId = docs[docs.length - 1]._id;

    // Progress log
    const percent = ((processed / total) * 100).toFixed(1);
    console.log(`Progress: ${processed}/${total} (${percent}%)`);
  }

  console.log(`✓ Completed: ${processed} documents processed`);
}

/**
 * Get all collection names
 */
export async function getCollectionNames(): Promise<string[]> {
  if (!db) {
    throw new Error('MongoDB not connected');
  }

  const collections = await db.listCollections().toArray();
  return collections.map(c => c.name);
}

/**
 * Test MongoDB connection
 */
export async function testMongoConnection(): Promise<boolean> {
  try {
    await connectMongo();
    const collections = await getCollectionNames();
    console.log(`✓ MongoDB connection successful`);
    console.log(`  Collections found: ${collections.length}`);
    console.log(`  Sample collections: ${collections.slice(0, 5).join(', ')}`);
    return true;
  } catch (error: any) {
    console.error('✗ MongoDB connection failed:', error.message);
    return false;
  }
}
