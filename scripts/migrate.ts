import { sql } from '@vercel/postgres';
import { readFileSync } from 'fs';
import { join } from 'path';

async function runMigrations() {
  try {
    console.log('🚀 Running database migrations...\n');

    // Read migration file
    const migrationPath = join(process.cwd(), 'migrations', '0001_initial_schema.sql');
    const migrationSQL = readFileSync(migrationPath, 'utf-8');

    // Split by semicolon and execute each statement
    const statements = migrationSQL
      .split(';')
      .map(s => s.trim())
      .filter(s => s.length > 0 && !s.startsWith('--'));

    for (let i = 0; i < statements.length; i++) {
      console.log(`Executing statement ${i + 1}/${statements.length}...`);
      await sql.query(statements[i]);
    }

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
