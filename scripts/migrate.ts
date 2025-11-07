import { config } from 'dotenv';
import { resolve } from 'path';
import { sql } from '@vercel/postgres';
import { readFileSync } from 'fs';
import { join } from 'path';

// Load .env.local
config({ path: resolve(process.cwd(), '.env.local') });

async function runMigrations() {
  try {
    console.log('🚀 Running database migrations...\n');

    // Read migration file
    const migrationPath = join(process.cwd(), 'migrations', '0001_initial_schema.sql');
    const migrationSQL = readFileSync(migrationPath, 'utf-8');

    // Execute as a single transaction
    console.log('Executing migration as a single transaction...');
    await sql.query(migrationSQL);

    console.log('\n✅ Migrations completed successfully!');

    // Verify tables
    const tables = await sql`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public'
      ORDER BY table_name;
    `;

    console.log('\n📊 Created tables:');
    tables.rows.forEach(row => console.log(`  - ${row.table_name}`));

    process.exit(0);
  } catch (error) {
    console.error('❌ Migration failed:', error);
    process.exit(1);
  }
}

runMigrations();
