import { config } from 'dotenv';
import { resolve } from 'path';
import { sql } from '@vercel/postgres';

// Load .env.local
config({ path: resolve(process.cwd(), '.env.local') });

async function testConnection() {
  try {
    console.log('🔌 Testing database connection...\n');
    
    const result = await sql`SELECT NOW() as current_time, version() as pg_version`;
    
    console.log('✅ Database connected successfully!');
    console.log('Current time:', result.rows[0].current_time);
    console.log('PostgreSQL version:', result.rows[0].pg_version.split(',')[0]);
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Database connection failed:', error);
    console.error('\n💡 Make sure you have:');
    console.error('   1. Created a Vercel Postgres database');
    console.error('   2. Run: vercel env pull .env.local');
    console.error('   3. Set POSTGRES_URL in .env.local');
    process.exit(1);
  }
}

testConnection();
