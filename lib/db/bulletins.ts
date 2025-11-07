import { config } from 'dotenv';
import { resolve } from 'path';
import { sql } from '@vercel/postgres';

// Load environment variables if not in production
if (process.env.NODE_ENV !== 'production') {
  config({ path: resolve(process.cwd(), '.env.local') });
}

export interface RawBulletin {
  id: number;
  bulletin_text: string;
  source: string;
  fetched_at: Date;
  processed: boolean;
  processor_notes?: string;
  processed_at?: Date;
}

/**
 * Save a raw bulletin to the database
 */
export async function saveRawBulletin(
  bulletinText: string,
  source: string = 'zmd'
): Promise<number> {
  try {
    const result = await sql`
      INSERT INTO raw_bulletins (bulletin_text, source)
      VALUES (${bulletinText}, ${source})
      RETURNING id
    `;

    return result.rows[0].id;
  } catch (error) {
    console.error('Error saving raw bulletin:', error);
    throw error;
  }
}

/**
 * Mark a bulletin as processed
 */
export async function markBulletinProcessed(
  id: number,
  notes?: string
): Promise<void> {
  try {
    await sql`
      UPDATE raw_bulletins
      SET processed = TRUE,
          processed_at = NOW(),
          processor_notes = ${notes || null}
      WHERE id = ${id}
    `;
  } catch (error) {
    console.error('Error marking bulletin as processed:', error);
    throw error;
  }
}

/**
 * Get unprocessed bulletins
 */
export async function getUnprocessedBulletins(): Promise<RawBulletin[]> {
  try {
    const result = await sql`
      SELECT *
      FROM raw_bulletins
      WHERE processed = FALSE
      ORDER BY fetched_at DESC
      LIMIT 50
    `;

    return result.rows as RawBulletin[];
  } catch (error) {
    console.error('Error fetching unprocessed bulletins:', error);
    throw error;
  }
}

/**
 * Get bulletin by ID
 */
export async function getBulletinById(id: number): Promise<RawBulletin | null> {
  try {
    const result = await sql`
      SELECT *
      FROM raw_bulletins
      WHERE id = ${id}
      LIMIT 1
    `;

    if (result.rows.length === 0) {
      return null;
    }

    return result.rows[0] as RawBulletin;
  } catch (error) {
    console.error('Error fetching bulletin by ID:', error);
    throw error;
  }
}
