import { Meteor } from 'meteor/meteor';

/**
 * Database Configuration
 *
 * Controls which database backend to use (MongoDB or PostgreSQL)
 * Uses feature flags for gradual rollout
 */

export interface DatabaseConfig {
  usePostgres: {
    creatures: boolean;
    creatureProperties: boolean;
    creatureVariables: boolean;
    creatureLogs: boolean;
    experiences: boolean;
    libraries: boolean;
    libraryNodes: boolean;
    users: boolean;
    [key: string]: boolean;
  };
  postgres?: {
    host: string;
    port: number;
    database: string;
    user: string;
    password: string;
    poolSize?: number;
    supabaseUrl?: string;
    supabaseKey?: string;
  };
}

/**
 * Get database configuration from Meteor settings
 */
export function getDbConfig(): DatabaseConfig {
  const defaultConfig: DatabaseConfig = {
    usePostgres: {
      creatures: false,
      creatureProperties: false,
      creatureVariables: false,
      creatureLogs: false,
      experiences: false,
      libraries: false,
      libraryNodes: false,
      users: false,
    },
  };

  if (!Meteor.settings || !Meteor.settings.public) {
    return defaultConfig;
  }

  const publicSettings = Meteor.settings.public as any;

  return {
    usePostgres: publicSettings.usePostgres || defaultConfig.usePostgres,
    postgres: Meteor.settings.postgres,
  };
}

/**
 * Check if a specific collection should use PostgreSQL
 */
export function shouldUsePostgres(collectionName: string): boolean {
  const config = getDbConfig();
  return config.usePostgres[collectionName] || false;
}

/**
 * Get PostgreSQL connection settings
 */
export function getPostgresConfig() {
  const config = getDbConfig();

  if (!config.postgres) {
    throw new Error('PostgreSQL configuration not found in Meteor.settings.postgres');
  }

  return config.postgres;
}

export default {
  getDbConfig,
  shouldUsePostgres,
  getPostgresConfig,
};
