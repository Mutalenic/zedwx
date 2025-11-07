import { sql } from '@vercel/postgres';
import { ProvinceForecast, Province } from '../models/weather';
import { ProvinceForecastSchema } from '../schemas/weather';

/**
 * Fetch a forecast from the database
 */
export async function getForecast(
  province: Province,
  date: string
): Promise<ProvinceForecast | null> {
  try {
    const result = await sql`
      SELECT forecast 
      FROM forecasts 
      WHERE province = ${province} 
        AND date = ${date}
        AND published = TRUE
      ORDER BY updated_at DESC
      LIMIT 1
    `;

    if (result.rows.length === 0) {
      return null;
    }

    const forecast = result.rows[0].forecast as ProvinceForecast;
    
    // Validate against schema
    const validated = ProvinceForecastSchema.parse(forecast);
    
    return validated;
  } catch (error) {
    console.error('Error fetching forecast:', error);
    throw error;
  }
}

/**
 * Save a forecast to the database
 */
export async function saveForecast(
  forecast: ProvinceForecast,
  published: boolean = false
): Promise<void> {
  try {
    // Validate before saving
    const validated = ProvinceForecastSchema.parse(forecast);

    const maxSeverity = Math.max(
      ...validated.segments.map(s => s.severityScore || 0)
    );

    await sql`
      INSERT INTO forecasts (
        id, 
        province, 
        date, 
        forecast, 
        source, 
        confidence, 
        severity_score, 
        published,
        created_at,
        updated_at
      )
      VALUES (
        ${validated.id},
        ${validated.province},
        ${validated.date},
        ${JSON.stringify(validated)},
        ${validated.source.name},
        ${validated.confidence || 'medium'},
        ${maxSeverity},
        ${published},
        NOW(),
        NOW()
      )
      ON CONFLICT (id) 
      DO UPDATE SET
        forecast = EXCLUDED.forecast,
        source = EXCLUDED.source,
        confidence = EXCLUDED.confidence,
        severity_score = EXCLUDED.severity_score,
        published = EXCLUDED.published,
        updated_at = NOW()
    `;
  } catch (error) {
    console.error('Error saving forecast:', error);
    throw error;
  }
}

/**
 * Get latest forecasts for all provinces
 */
export async function getLatestForecasts(): Promise<ProvinceForecast[]> {
  try {
    const result = await sql`
      SELECT DISTINCT ON (province) forecast
      FROM forecasts
      WHERE published = TRUE
        AND date >= CURRENT_DATE
      ORDER BY province, date ASC, updated_at DESC
    `;

    return result.rows.map(row => 
      ProvinceForecastSchema.parse(row.forecast)
    );
  } catch (error) {
    console.error('Error fetching latest forecasts:', error);
    throw error;
  }
}

/**
 * Get forecasts by province for date range
 */
export async function getForecastsByProvince(
  province: Province,
  startDate: string,
  endDate: string
): Promise<ProvinceForecast[]> {
  try {
    const result = await sql`
      SELECT forecast
      FROM forecasts
      WHERE province = ${province}
        AND date >= ${startDate}
        AND date <= ${endDate}
        AND published = TRUE
      ORDER BY date ASC
    `;

    return result.rows.map(row => 
      ProvinceForecastSchema.parse(row.forecast)
    );
  } catch (error) {
    console.error('Error fetching forecasts by province:', error);
    throw error;
  }
}
