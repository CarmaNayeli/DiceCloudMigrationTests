import { createHash } from 'crypto';
import { v5 as uuidv5, v4 as uuidv4 } from 'uuid';
import fs from 'fs/promises';
import path from 'path';

/**
 * UUID Mapper - Converts MongoDB ObjectIds to PostgreSQL UUIDs consistently
 *
 * Strategy: Use deterministic UUID generation (v5) based on ObjectId
 * This ensures the same ObjectId always maps to the same UUID
 */

// Namespace for DiceCloud migrations (random UUID generated once)
const DICECLOUD_NAMESPACE = '6ba7b810-9dad-11d1-80b4-00c04fd430c8';

export class UUIDMapper {
  private cache: Map<string, string> = new Map();
  private cacheFile: string;
  private dirty: boolean = false;

  constructor(cacheDir: string = './data/uuid-cache') {
    this.cacheFile = path.join(cacheDir, 'uuid-mappings.json');
  }

  /**
   * Load existing UUID mappings from disk
   */
  async load(): Promise<void> {
    try {
      const data = await fs.readFile(this.cacheFile, 'utf-8');
      const mappings = JSON.parse(data);
      this.cache = new Map(Object.entries(mappings));
      console.log(`Loaded ${this.cache.size} UUID mappings from cache`);
    } catch (error: any) {
      if (error.code !== 'ENOENT') {
        console.error('Error loading UUID cache:', error);
      }
      // File doesn't exist yet, start fresh
    }
  }

  /**
   * Save UUID mappings to disk
   */
  async save(): Promise<void> {
    if (!this.dirty) return;

    try {
      // Ensure directory exists
      await fs.mkdir(path.dirname(this.cacheFile), { recursive: true });

      // Convert Map to Object
      const mappings = Object.fromEntries(this.cache);

      // Write to disk
      await fs.writeFile(
        this.cacheFile,
        JSON.stringify(mappings, null, 2),
        'utf-8'
      );

      this.dirty = false;
      console.log(`Saved ${this.cache.size} UUID mappings to cache`);
    } catch (error) {
      console.error('Error saving UUID cache:', error);
      throw error;
    }
  }

  /**
   * Convert MongoDB ObjectId to PostgreSQL UUID
   * Uses deterministic UUID v5 generation for consistency
   */
  toUUID(objectId: string | null | undefined): string | null {
    if (!objectId) return null;

    // Normalize ObjectId (could be string or ObjectId object)
    const oid = objectId.toString();

    // Check cache first
    if (this.cache.has(oid)) {
      return this.cache.get(oid)!;
    }

    // Generate deterministic UUID from ObjectId
    const uuid = uuidv5(oid, DICECLOUD_NAMESPACE);

    // Cache it
    this.cache.set(oid, uuid);
    this.dirty = true;

    return uuid;
  }

  /**
   * Convert array of ObjectIds to UUIDs
   */
  toUUIDs(objectIds: string[] | null | undefined): string[] {
    if (!objectIds || !Array.isArray(objectIds)) return [];
    return objectIds.map(id => this.toUUID(id)).filter(Boolean) as string[];
  }

  /**
   * Reverse lookup: Get ObjectId from UUID
   */
  toObjectId(uuid: string | null | undefined): string | null {
    if (!uuid) return null;

    // Search cache for reverse mapping
    for (const [objectId, cachedUuid] of this.cache.entries()) {
      if (cachedUuid === uuid) {
        return objectId;
      }
    }

    return null;
  }

  /**
   * Get cache size
   */
  size(): number {
    return this.cache.size;
  }

  /**
   * Clear cache
   */
  clear(): void {
    this.cache.clear();
    this.dirty = true;
  }

  /**
   * Export mappings as JSON
   */
  export(): Record<string, string> {
    return Object.fromEntries(this.cache);
  }

  /**
   * Import mappings from JSON
   */
  import(mappings: Record<string, string>): void {
    this.cache = new Map(Object.entries(mappings));
    this.dirty = true;
  }
}

// Singleton instance
let uuidMapper: UUIDMapper | null = null;

export function getUUIDMapper(cacheDir?: string): UUIDMapper {
  if (!uuidMapper) {
    uuidMapper = new UUIDMapper(cacheDir);
  }
  return uuidMapper;
}

/**
 * Helper function for quick UUID conversion
 */
export function mongoIdToUUID(objectId: string | null | undefined): string | null {
  return getUUIDMapper().toUUID(objectId);
}

/**
 * Helper function for array conversion
 */
export function mongoIdsToUUIDs(objectIds: string[] | null | undefined): string[] {
  return getUUIDMapper().toUUIDs(objectIds);
}
