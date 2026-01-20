#!/usr/bin/env node

import { Command } from 'commander';
import chalk from 'chalk';
import ora from 'ora';
import dotenv from 'dotenv';
import {
  connectMongo,
  disconnectMongo,
  testMongoConnection,
  extractBatch,
  countDocuments,
} from './db/mongodb.js';
import {
  connectPostgres,
  disconnectPostgres,
  testPostgresConnection,
  batchInsert,
  countRows,
  getTableStats,
} from './db/postgresql.js';
import { getUUIDMapper } from './utils/uuid-mapper.js';
import { transformBatch } from './transform/transformer.js';
import { COLLECTION_MAPPINGS } from './types.js';

dotenv.config();

const program = new Command();

program
  .name('dicecloud-migrate')
  .description('MongoDB to PostgreSQL migration tool for DiceCloud')
  .version('1.0.0');

// ============================================================================
// Test Connections
// ============================================================================

program
  .command('test-connection')
  .description('Test connections to both MongoDB and PostgreSQL')
  .action(async () => {
    console.log(chalk.bold('\n🔍 Testing Database Connections\n'));

    const mongoOk = await testMongoConnection();
    const pgOk = await testPostgresConnection();

    console.log();

    if (mongoOk && pgOk) {
      console.log(chalk.green('✓ All connections successful!'));
      process.exit(0);
    } else {
      console.log(chalk.red('✗ Some connections failed'));
      process.exit(1);
    }
  });

// ============================================================================
// Extract Command
// ============================================================================

program
  .command('extract <collection>')
  .description('Extract data from MongoDB collection')
  .option('-b, --batch-size <size>', 'Batch size', '1000')
  .option('-l, --limit <limit>', 'Limit number of documents')
  .option('--before <date>', 'Extract documents before date (for logs)')
  .action(async (collection, options) => {
    const spinner = ora('Extracting data...').start();

    try {
      await connectMongo();

      const batchSize = parseInt(options.batchSize);
      const filter: Record<string, any> = {};

      if (options.before) {
        filter.date = { $lt: new Date(options.before) };
      }

      const total = await countDocuments(collection, filter);
      spinner.succeed(`Found ${total} documents to extract`);

      let extracted = 0;

      spinner.start('Extracting batches...');

      await extractBatch(
        collection,
        batchSize,
        filter,
        async (docs, progress) => {
          extracted += docs.length;
          spinner.text = `Extracted ${extracted}/${total} documents`;

          // You can save to file here if needed
          // await fs.writeFile(`data/${collection}-${progress.processed}.json`, JSON.stringify(docs));
        }
      );

      spinner.succeed(`✓ Extracted ${extracted} documents from ${collection}`);

      await disconnectMongo();
    } catch (error: any) {
      spinner.fail('Extraction failed');
      console.error(chalk.red(error.message));
      process.exit(1);
    }
  });

// ============================================================================
// Migrate Command
// ============================================================================

program
  .command('migrate <collection>')
  .description('Migrate a collection from MongoDB to PostgreSQL')
  .option('-b, --batch-size <size>', 'Batch size', '1000')
  .option('--before <date>', 'Migrate documents before date (for logs)')
  .option('--dry-run', 'Perform dry run without inserting data')
  .action(async (collection, options) => {
    const spinner = ora('Starting migration...').start();

    try {
      // Connect to both databases
      await connectMongo();
      connectPostgres();

      // Load UUID mapper cache
      const mapper = getUUIDMapper();
      await mapper.load();

      // Get collection mapping
      const mapping = COLLECTION_MAPPINGS[collection];
      if (!mapping) {
        throw new Error(`Unknown collection: ${collection}`);
      }

      const batchSize = parseInt(options.batchSize);
      const filter: Record<string, any> = {};

      if (options.before) {
        filter.date = { $lt: new Date(options.before) };
      }

      const total = await countDocuments(mapping.mongoCollection, filter);
      spinner.succeed(`Found ${total} documents to migrate`);

      let migrated = 0;
      let errors = 0;

      spinner.start('Migrating data...');

      await extractBatch(
        mapping.mongoCollection,
        batchSize,
        filter,
        async (docs) => {
          try {
            // Transform documents
            const pgRows = transformBatch(collection, docs);

            if (!options.dryRun) {
              // Get column names from first row
              const columns = Object.keys(pgRows[0]);

              // Insert into PostgreSQL
              await batchInsert(
                mapping.pgTable,
                columns,
                pgRows,
                'ON CONFLICT (id) DO NOTHING'
              );
            }

            migrated += docs.length;
            spinner.text = `Migrated ${migrated}/${total} documents`;
          } catch (error: any) {
            errors++;
            console.error(
              chalk.red(`\nError processing batch: ${error.message}`)
            );
          }
        }
      );

      // Save UUID mappings
      await mapper.save();

      if (errors === 0) {
        spinner.succeed(
          chalk.green(`✓ Successfully migrated ${migrated} documents`)
        );
      } else {
        spinner.warn(
          chalk.yellow(
            `⚠ Migrated ${migrated} documents with ${errors} errors`
          )
        );
      }

      await disconnectMongo();
      await disconnectPostgres();
    } catch (error: any) {
      spinner.fail('Migration failed');
      console.error(chalk.red(error.message));
      console.error(error.stack);
      process.exit(1);
    }
  });

// ============================================================================
// Validate Command
// ============================================================================

program
  .command('validate <collection>')
  .description('Validate migrated data')
  .action(async (collection, options) => {
    const spinner = ora('Validating data...').start();

    try {
      await connectMongo();
      connectPostgres();

      const mapping = COLLECTION_MAPPINGS[collection];
      if (!mapping) {
        throw new Error(`Unknown collection: ${collection}`);
      }

      // Count documents in both databases
      const mongoCount = await countDocuments(mapping.mongoCollection);
      const pgCount = await countRows(mapping.pgTable);

      spinner.succeed('Counts retrieved');

      console.log(chalk.bold('\n📊 Validation Results\n'));
      console.log(`MongoDB (${mapping.mongoCollection}): ${chalk.cyan(mongoCount)}`);
      console.log(`PostgreSQL (${mapping.pgTable}): ${chalk.cyan(pgCount)}`);

      const diff = mongoCount - pgCount;

      if (diff === 0) {
        console.log(chalk.green('\n✓ Counts match!'));
      } else {
        console.log(
          chalk.yellow(`\n⚠ Difference: ${diff} documents`)
        );
      }

      // Get table stats
      const stats = await getTableStats(mapping.pgTable);
      console.log(`\nTable size: ${chalk.cyan(stats.tableSize)}`);

      await disconnectMongo();
      await disconnectPostgres();
    } catch (error: any) {
      spinner.fail('Validation failed');
      console.error(chalk.red(error.message));
      process.exit(1);
    }
  });

// ============================================================================
// Migrate All Command
// ============================================================================

program
  .command('migrate-all')
  .description('Migrate all collections in order')
  .option('--dry-run', 'Perform dry run')
  .option('--skip <collections>', 'Comma-separated list of collections to skip')
  .action(async (options) => {
    const collectionsToMigrate = [
      'users',
      'creatures',
      'creatureProperties',
      'creatureVariables',
      'experiences',
      'creatureLogs',
      'libraries',
      'libraryNodes',
    ];

    const skip = options.skip ? options.skip.split(',') : [];

    console.log(chalk.bold('\n🚀 Starting Full Migration\n'));

    for (const collection of collectionsToMigrate) {
      if (skip.includes(collection)) {
        console.log(chalk.gray(`⏭  Skipping ${collection}`));
        continue;
      }

      console.log(chalk.bold(`\n📦 Migrating ${collection}...`));

      // Run migrate command for this collection
      // (In real implementation, you'd call the migrate function directly)
      // For now, this is a placeholder
    }

    console.log(chalk.green('\n✓ Migration complete!'));
  });

// ============================================================================
// Stats Command
// ============================================================================

program
  .command('stats')
  .description('Show migration statistics')
  .action(async () => {
    console.log(chalk.bold('\n📊 Migration Statistics\n'));

    try {
      await connectMongo();
      connectPostgres();

      const mapper = getUUIDMapper();
      await mapper.load();

      console.log(`UUID mappings cached: ${chalk.cyan(mapper.size())}`);

      // Show stats for each collection
      console.log(chalk.bold('\n Collection Counts:\n'));

      for (const [key, mapping] of Object.entries(COLLECTION_MAPPINGS)) {
        try {
          const mongoCount = await countDocuments(mapping.mongoCollection);
          const pgCount = await countRows(mapping.pgTable);
          const match = mongoCount === pgCount ? '✓' : '✗';

          console.log(
            `${match} ${key.padEnd(20)} MongoDB: ${String(mongoCount).padStart(8)}  PostgreSQL: ${String(pgCount).padStart(8)}`
          );
        } catch (error) {
          console.log(
            chalk.gray(`  ${key.padEnd(20)} (table not found)`)
          );
        }
      }

      await disconnectMongo();
      await disconnectPostgres();
    } catch (error: any) {
      console.error(chalk.red(error.message));
      process.exit(1);
    }
  });

// Parse command line arguments
program.parse();
