# Phase 1: Next.js Foundation - Implementation Guide

**Status**: Ready to Start  
**Duration**: 3-5 days  
**Dependencies**: Phase 0 complete  
**Target Completion**: 2025-11-12

---

## Overview

Phase 1 establishes the foundational Next.js application structure with TypeScript, sets up Vercel Postgres database, and creates the core data models that will power the entire application.

---

## Pre-Flight Checklist

Before starting Phase 1:

- [x] Migration plan documented
- [x] .gitignore updated
- [ ] Create archive branch for Rails app
- [ ] Vercel account ready
- [ ] Node.js 18+ installed
- [ ] Git configured for regular commits

---

## Step 1: Archive Rails Application

### 1.1 Create Archive Branch

```bash
# Commit any remaining Rails changes
git add -A
git commit -m "chore: final rails state before migration"

# Create archive branch
git checkout -b archive/rails-v1
git push origin archive/rails-v1

# Return to dev branch
git checkout dev

# Tag the Rails version
git tag -a rails-v1.0 -m "Rails app final version before Next.js migration"
git push origin rails-v1.0
```

### 1.2 Document Rails API Endpoints

Create quick reference for API parity testing:

```bash
# Test Rails endpoint (if running)
curl http://localhost:3000/api/v1/weather?location=Lusaka

# Expected response format (document this)
{
  "location": "Lusaka",
  "coordinates": { "lat": -15.4167, "lon": 28.2833 },
  "current": { ... },
  "forecast": [ ... ],
  "source": "open-meteo"
}
```

---

## Step 2: Initialize Next.js Project

### 2.1 Create Next.js App

```bash
# Navigate to parent directory
cd /home/nicholas/Documents/projects_personal

# Create new Next.js app (in a temporary location first)
npx create-next-app@latest zedwx-next --typescript --tailwind --app --no-src-dir --import-alias "@/*"

# Answer prompts:
# ✔ Would you like to use TypeScript? … Yes
# ✔ Would you like to use ESLint? … Yes
# ✔ Would you like to use Tailwind CSS? … Yes
# ✔ Would you like to use `src/` directory? … No
# ✔ Would you like to use App Router? … Yes
# ✔ Would you like to customize the default import alias? … Yes (@/*)
# ✔ What import alias would you like configured? … @/*
```

### 2.2 Copy Next.js Files to Main Repo

```bash
# Move into the new project
cd zedwx-next

# Copy all Next.js files to the main repo (preserving Rails in archive)
cp -r * /home/nicholas/Documents/projects_personal/zedwx/
cp -r .* /home/nicholas/Documents/projects_personal/zedwx/ 2>/dev/null || true

# Return to main repo
cd /home/nicholas/Documents/projects_personal/zedwx

# Remove Rails files (they're safe in archive branch)
rm -rf app/controllers app/jobs app/mailers app/models app/services app/views
rm -rf config/application.rb config/routes.rb config/environments
rm -rf db/migrate db/schema.rb
rm -rf spec/ test/
rm Gemfile Gemfile.lock Rakefile config.ru

# Commit the Next.js scaffold
git add -A
git commit -m "feat(phase-1): initialize Next.js 14 app with TypeScript and Tailwind"
```

### 2.3 Install Additional Dependencies

```bash
npm install @vercel/postgres zod swr date-fns
npm install -D @types/node

# Install development tools
npm install -D vitest @vitest/ui
npm install -D prettier eslint-config-prettier

# Commit dependencies
git add package.json package-lock.json
git commit -m "feat(phase-1): add core dependencies (postgres, zod, swr)"
```

---

## Step 3: Set Up Vercel Postgres Database

### 3.1 Create Vercel Project

```bash
# Install Vercel CLI
npm i -g vercel

# Login to Vercel
vercel login

# Link project
vercel link

# Follow prompts:
# Set up and deploy "~/Documents/projects_personal/zedwx"? [Y/n] y
# Which scope? (your account)
# Link to existing project? [y/N] n
# What's your project's name? zedwx
# In which directory is your code located? ./
```

### 3.2 Create Postgres Database

In Vercel Dashboard (https://vercel.com):

1. Go to Storage tab
2. Click "Create Database"
3. Select "Postgres"
4. Name: `zedwx-db`
5. Region: Choose closest to Zambia (e.g., `fra1` - Frankfurt)
6. Click "Create"

### 3.3 Connect Database to Project

```bash
# Pull environment variables
vercel env pull .env.local

# This creates .env.local with:
# POSTGRES_URL="..."
# POSTGRES_PRISMA_URL="..."
# POSTGRES_URL_NON_POOLING="..."
# etc.
```

### 3.4 Verify Connection

Create a test script:

```bash
# Create scripts directory
mkdir -p scripts
```

Create `scripts/test-db.ts`:

```typescript
import { sql } from '@vercel/postgres';

async function testConnection() {
  try {
    const result = await sql`SELECT NOW()`;
    console.log('✅ Database connected successfully!');
    console.log('Current time:', result.rows[0].now);
  } catch (error) {
    console.error('❌ Database connection failed:', error);
    process.exit(1);
  }
}

testConnection();
```

Run test:

```bash
npx tsx scripts/test-db.ts
```

Expected output: `✅ Database connected successfully!`

---

## Step 4: Create Database Schema

### 4.1 Create Migration Files

```bash
mkdir -p migrations
```

Create `migrations/0001_initial_schema.sql`:

```sql
-- Core forecasts table (canonical weather data)
CREATE TABLE IF NOT EXISTS forecasts (
  id TEXT PRIMARY KEY,
  province TEXT NOT NULL CHECK (province IN (
    'Central', 'Copperbelt', 'Eastern', 'Luapula', 'Muchinga',
    'Northern', 'North-Western', 'Southern', 'Western', 'Lusaka'
  )),
  date DATE NOT NULL,
  forecast JSONB NOT NULL,
  source TEXT NOT NULL,
  confidence TEXT CHECK (confidence IN ('low', 'medium', 'high')),
  severity_score INTEGER DEFAULT 0 CHECK (severity_score BETWEEN 0 AND 10),
  published BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Raw bulletins table (audit trail and reprocessing)
CREATE TABLE IF NOT EXISTS raw_bulletins (
  id SERIAL PRIMARY KEY,
  bulletin_text TEXT NOT NULL,
  source TEXT DEFAULT 'zmd',
  fetched_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  processed BOOLEAN DEFAULT FALSE,
  processor_notes TEXT,
  processed_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- SMS subscriptions table
CREATE TABLE IF NOT EXISTS sms_subscriptions (
  id SERIAL PRIMARY KEY,
  phone_number TEXT NOT NULL UNIQUE,
  province TEXT NOT NULL CHECK (province IN (
    'Central', 'Copperbelt', 'Eastern', 'Luapula', 'Muchinga',
    'Northern', 'North-Western', 'Southern', 'Western', 'Lusaka'
  )),
  active BOOLEAN DEFAULT TRUE,
  consent_given_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  unsubscribed_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Performance indexes
CREATE INDEX IF NOT EXISTS idx_forecasts_province_date 
  ON forecasts (province, date DESC);

CREATE INDEX IF NOT EXISTS idx_forecasts_published 
  ON forecasts (published) 
  WHERE published = TRUE;

CREATE INDEX IF NOT EXISTS idx_forecasts_severity 
  ON forecasts (severity_score DESC)
  WHERE severity_score >= 7;

CREATE INDEX IF NOT EXISTS idx_bulletins_processed 
  ON raw_bulletins (processed, fetched_at DESC);

CREATE INDEX IF NOT EXISTS idx_subs_active 
  ON sms_subscriptions (active, province) 
  WHERE active = TRUE;

-- GIN index for JSONB queries
CREATE INDEX IF NOT EXISTS idx_forecasts_forecast_gin 
  ON forecasts USING GIN (forecast);

-- Updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply trigger to forecasts table
DROP TRIGGER IF EXISTS update_forecasts_updated_at ON forecasts;
CREATE TRIGGER update_forecasts_updated_at
  BEFORE UPDATE ON forecasts
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

### 4.2 Create Migration Runner

Create `scripts/migrate.ts`:

```typescript
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
      .filter(s => s.length > 0);

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

  } catch (error) {
    console.error('❌ Migration failed:', error);
    process.exit(1);
  }
}

runMigrations();
```

### 4.3 Run Migration

```bash
npx tsx scripts/migrate.ts
```

Expected output:
```
🚀 Running database migrations...
Executing statement 1/15...
...
✅ Migrations completed successfully!

📊 Created tables:
  - forecasts
  - raw_bulletins
  - sms_subscriptions
```

### 4.4 Commit Migration

```bash
git add migrations/ scripts/
git commit -m "feat(phase-1): create database schema with forecasts, bulletins, and subscriptions tables"
```

---

## Step 5: Create TypeScript Data Models

### 5.1 Create Models Directory Structure

```bash
mkdir -p lib/models lib/schemas lib/types
```

### 5.2 Create Core Weather Models

Create `lib/models/weather.ts`:

```typescript
/**
 * Core weather data models for ZedWx
 * Supports both ZMD bulletin parsing and Open-Meteo API data
 */

// Zambia's 10 provinces (from Rails Location model)
export const PROVINCES = [
  'Central',
  'Copperbelt',
  'Eastern',
  'Luapula',
  'Muchinga',
  'Northern',
  'North-Western',
  'Southern',
  'Western',
  'Lusaka',
] as const;

export type Province = typeof PROVINCES[number];

// Time periods for daily forecasts
export type PeriodId = 
  | 'morning'    // 06:00-12:00
  | 'afternoon'  // 12:00-18:00
  | 'evening'    // 18:00-21:00
  | 'night'      // 21:00-00:00
  | 'overnight'  // 00:00-06:00
  | 'day';       // General daytime

// Weather condition categories
export type WeatherCondition = 
  | 'clear'
  | 'partly-cloudy'
  | 'cloudy'
  | 'overcast'
  | 'fog'
  | 'drizzle'
  | 'rain'
  | 'heavy-rain'
  | 'thunderstorm'
  | 'hail'
  | 'wind'
  | 'dust'
  | 'smoke';

// Wind severity levels
export type WindSeverity = 'calm' | 'moderate' | 'strong' | 'dangerous';

// Confidence levels for parsed data
export type ConfidenceLevel = 'low' | 'medium' | 'high';

// Data sources
export type WeatherSource = 
  | 'zmd'              // Zambia Meteorological Department
  | 'open-meteo'       // Open-Meteo API
  | 'openweather'      // OpenWeather API
  | 'visual-crossing'  // Visual Crossing API
  | 'manual';          // Manually entered

/**
 * Time segment within a day (e.g., morning, afternoon)
 */
export interface TimeSegment {
  periodId: PeriodId;
  start?: string;              // ISO time (HH:mm)
  end?: string;                // ISO time (HH:mm)
  summaryPlainEN: string;      // Human-readable English summary
  conditionTags: WeatherCondition[]; // Parsed weather conditions
  precipProbability?: number;  // 0-100
  minTempC?: number;
  maxTempC?: number;
  wind?: {
    speedKph?: number;
    gustKph?: number;
    direction?: string;        // N, NE, E, SE, S, SW, W, NW
    severity?: WindSeverity;
  };
  severityScore?: number;      // 0-10 (10 = most severe)
  icons?: string[];            // Icon keys for UI rendering
}

/**
 * Province-specific forecast for a single day
 * This is the canonical data structure stored in forecasts.forecast JSONB
 */
export interface ProvinceForecast {
  id: string;                  // Format: "{province}-{YYYY-MM-DD}"
  province: Province;
  date: string;                // YYYY-MM-DD
  lastUpdated: string;         // ISO datetime
  segments: TimeSegment[];     // Time-of-day forecasts
  notes?: string[];            // Additional context or warnings
  source: {
    name: WeatherSource;
    rawId?: string;            // ID in source system
    rawUrl?: string;           // Source URL
    rawTextExcerpt?: string;   // First 500 chars of raw bulletin
  };
  confidence?: ConfidenceLevel;
  createdAt?: string;
  updatedAt?: string;
}

/**
 * Province coordinates (from Rails Location model)
 * Used for API calls to weather services
 */
export interface ProvinceCoordinates {
  lat: number;
  lon: number;
  name: string;
}

export const PROVINCE_COORDS: Record<Province, ProvinceCoordinates> = {
  'Central': {
    lat: -14.5333,
    lon: 28.2833,
    name: 'Central Province',
  },
  'Copperbelt': {
    lat: -12.8389,
    lon: 28.2136,
    name: 'Copperbelt Province',
  },
  'Eastern': {
    lat: -13.6333,
    lon: 32.6500,
    name: 'Eastern Province',
  },
  'Luapula': {
    lat: -11.6667,
    lon: 29.3333,
    name: 'Luapula Province',
  },
  'Muchinga': {
    lat: -11.2167,
    lon: 31.9500,
    name: 'Muchinga Province',
  },
  'Northern': {
    lat: -10.1333,
    lon: 31.1333,
    name: 'Northern Province',
  },
  'North-Western': {
    lat: -12.5000,
    lon: 25.8500,
    name: 'North-Western Province',
  },
  'Southern': {
    lat: -16.8167,
    lon: 26.5167,
    name: 'Southern Province',
  },
  'Western': {
    lat: -15.3167,
    lon: 23.1333,
    name: 'Western Province',
  },
  'Lusaka': {
    lat: -15.4167,
    lon: 28.2833,
    name: 'Lusaka Province',
  },
};

/**
 * Helper: Check if a string is a valid province
 */
export function isValidProvince(value: unknown): value is Province {
  return typeof value === 'string' && PROVINCES.includes(value as Province);
}

/**
 * Helper: Get coordinates for a province
 */
export function getProvinceCoords(province: Province): ProvinceCoordinates {
  return PROVINCE_COORDS[province];
}

/**
 * Helper: Generate forecast ID
 */
export function generateForecastId(province: Province, date: string): string {
  return `${province.toLowerCase().replace(/\s+/g, '-')}-${date}`;
}
```

### 5.3 Create Zod Validation Schemas

Create `lib/schemas/weather.ts`:

```typescript
import { z } from 'zod';
import { PROVINCES } from '../models/weather';

export const ProvinceSchema = z.enum(PROVINCES);

export const PeriodIdSchema = z.enum([
  'morning',
  'afternoon',
  'evening',
  'night',
  'overnight',
  'day',
]);

export const WeatherConditionSchema = z.enum([
  'clear',
  'partly-cloudy',
  'cloudy',
  'overcast',
  'fog',
  'drizzle',
  'rain',
  'heavy-rain',
  'thunderstorm',
  'hail',
  'wind',
  'dust',
  'smoke',
]);

export const WindSeveritySchema = z.enum(['calm', 'moderate', 'strong', 'dangerous']);

export const ConfidenceLevelSchema = z.enum(['low', 'medium', 'high']);

export const WeatherSourceSchema = z.enum([
  'zmd',
  'open-meteo',
  'openweather',
  'visual-crossing',
  'manual',
]);

export const TimeSegmentSchema = z.object({
  periodId: PeriodIdSchema,
  start: z.string().optional(),
  end: z.string().optional(),
  summaryPlainEN: z.string().min(1),
  conditionTags: z.array(WeatherConditionSchema),
  precipProbability: z.number().min(0).max(100).optional(),
  minTempC: z.number().optional(),
  maxTempC: z.number().optional(),
  wind: z.object({
    speedKph: z.number().optional(),
    gustKph: z.number().optional(),
    direction: z.string().optional(),
    severity: WindSeveritySchema.optional(),
  }).optional(),
  severityScore: z.number().min(0).max(10).optional(),
  icons: z.array(z.string()).optional(),
});

export const ProvinceForecastSchema = z.object({
  id: z.string(),
  province: ProvinceSchema,
  date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  lastUpdated: z.string().datetime(),
  segments: z.array(TimeSegmentSchema),
  notes: z.array(z.string()).optional(),
  source: z.object({
    name: WeatherSourceSchema,
    rawId: z.string().optional(),
    rawUrl: z.string().url().optional(),
    rawTextExcerpt: z.string().max(500).optional(),
  }),
  confidence: ConfidenceLevelSchema.optional(),
  createdAt: z.string().datetime().optional(),
  updatedAt: z.string().datetime().optional(),
});

// Query parameter schemas for API routes
export const WeatherQuerySchema = z.object({
  province: ProvinceSchema,
  date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional(),
});
```

### 5.4 Commit Models

```bash
git add lib/
git commit -m "feat(phase-1): create TypeScript weather models and Zod schemas"
```

---

## Step 6: Create Database Helper Functions

### 6.1 Create DB Utils

Create `lib/db/forecasts.ts`:

```typescript
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
```

Create `lib/db/bulletins.ts`:

```typescript
import { sql } from '@vercel/postgres';

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
```

### 6.2 Commit DB Utils

```bash
git add lib/db/
git commit -m "feat(phase-1): create database helper functions for forecasts and bulletins"
```

---

## Step 7: Create Seed Data

### 7.1 Create Seed Script

Create `scripts/seed.ts`:

```typescript
import { saveForecast } from '../lib/db/forecasts';
import { saveRawBulletin } from '../lib/db/bulletins';
import { ProvinceForecast, PROVINCES, generateForecastId } from '../lib/models/weather';

async function seed() {
  console.log('🌱 Seeding database...\n');

  try {
    // Seed sample bulletin
    console.log('Creating sample bulletin...');
    const sampleBulletin = `
ZAMBIA METEOROLOGICAL DEPARTMENT
WEATHER FORECAST FOR ${new Date().toISOString().split('T')[0]}

Lusaka: Morning partly cloudy with temperatures 18-25°C. 
Afternoon scattered thunderstorms likely. Evening clearing.

Southern: Morning foggy conditions, low of 14°C. Afternoon 
sunny with high of 28°C. Isolated showers possible evening.

Copperbelt: Cloudy throughout with light rain morning and 
afternoon. Temperatures 16-22°C. Moderate winds expected.
    `.trim();

    await saveRawBulletin(sampleBulletin, 'zmd');
    console.log('✅ Sample bulletin created\n');

    // Seed sample forecasts
    console.log('Creating sample forecasts...');
    const today = new Date().toISOString().split('T')[0];

    for (const province of PROVINCES.slice(0, 3)) { // Just 3 samples
      const forecast: ProvinceForecast = {
        id: generateForecastId(province, today),
        province,
        date: today,
        lastUpdated: new Date().toISOString(),
        segments: [
          {
            periodId: 'morning',
            summaryPlainEN: 'Partly cloudy with mild temperatures',
            conditionTags: ['partly-cloudy'],
            minTempC: 16,
            maxTempC: 22,
            precipProbability: 20,
          },
          {
            periodId: 'afternoon',
            summaryPlainEN: 'Scattered thunderstorms likely, warm',
            conditionTags: ['thunderstorm', 'rain'],
            minTempC: 22,
            maxTempC: 28,
            precipProbability: 70,
            severityScore: 5,
          },
          {
            periodId: 'evening',
            summaryPlainEN: 'Clearing skies, cooler temperatures',
            conditionTags: ['partly-cloudy'],
            minTempC: 18,
            maxTempC: 22,
            precipProbability: 10,
          },
        ],
        source: {
          name: 'manual',
          rawTextExcerpt: 'Sample seed data for development',
        },
        confidence: 'high',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      };

      await saveForecast(forecast, true);
      console.log(`✅ Created forecast for ${province}`);
    }

    console.log('\n🎉 Seeding completed successfully!');
  } catch (error) {
    console.error('❌ Seeding failed:', error);
    process.exit(1);
  }
}

seed();
```

### 7.2 Run Seed

```bash
npx tsx scripts/seed.ts
```

### 7.3 Commit Seed

```bash
git add scripts/seed.ts
git commit -m "feat(phase-1): create database seed script with sample data"
```

---

## Step 8: Verify Phase 1 Completion

### 8.1 Verification Checklist

Run through this checklist:

- [ ] Next.js app runs successfully (`npm run dev`)
- [ ] Vercel Postgres connected and migrations ran
- [ ] All tables created (forecasts, raw_bulletins, sms_subscriptions)
- [ ] Seed data inserted successfully
- [ ] TypeScript models compile without errors
- [ ] No ESLint errors (`npm run lint`)
- [ ] Git history shows regular commits

### 8.2 Manual Testing

```bash
# Start dev server
npm run dev

# Visit http://localhost:3000
# Should see default Next.js page

# Test database connection
npx tsx scripts/test-db.ts

# Query seed data
npx tsx -e "
import { getLatestForecasts } from './lib/db/forecasts';
getLatestForecasts().then(f => console.log(JSON.stringify(f, null, 2)));
"
```

---

## Step 9: Documentation & Cleanup

### 9.1 Update README

Create or update `README.md`:

```markdown
# ZedWx - Zambian Weather Application

Next.js 14 full-stack weather application for Zambian provinces with ZMD bulletin parsing.

## Tech Stack

- **Framework**: Next.js 14 (App Router)
- **Database**: Vercel Postgres
- **Language**: TypeScript
- **Styling**: Tailwind CSS
- **Validation**: Zod
- **Data Fetching**: SWR

## Development

\`\`\`bash
# Install dependencies
npm install

# Set up environment
cp .env.example .env.local
# Add your POSTGRES_URL and other secrets

# Run migrations
npx tsx scripts/migrate.ts

# Seed database
npx tsx scripts/seed.ts

# Start dev server
npm run dev
\`\`\`

## Project Status

**Phase 1 (Foundation)**: ✅ Complete  
**Phase 2 (Open-Meteo)**: 🔜 Next  

See [MIGRATION_PLAN.md](./MIGRATION_PLAN.md) for full roadmap.

## License

MIT
```

### 9.2 Create Environment Example

Create `.env.example`:

```bash
# Vercel Postgres
POSTGRES_URL=""
POSTGRES_PRISMA_URL=""
POSTGRES_URL_NON_POOLING=""
POSTGRES_USER=""
POSTGRES_HOST=""
POSTGRES_PASSWORD=""
POSTGRES_DATABASE=""

# Optional: Weather API fallbacks (for later phases)
# OPENWEATHER_API_KEY=""
# VISUAL_CROSSING_API_KEY=""

# Optional: SMS providers (for later phases)
# AFRICAS_TALKING_API_KEY=""
# AFRICAS_TALKING_USERNAME=""
```

### 9.3 Final Commit

```bash
git add README.md .env.example
git commit -m "docs(phase-1): update README and create env example"

# Tag this phase
git tag -a phase-1-complete -m "Phase 1: Next.js foundation complete"
git push origin dev --tags
```

---

## Phase 1 Deliverables Summary

At the end of Phase 1, you will have:

✅ Next.js 14 application with TypeScript and Tailwind CSS  
✅ Vercel Postgres database with complete schema  
✅ TypeScript data models for weather forecasts  
✅ Zod validation schemas  
✅ Database helper functions (forecasts, bulletins)  
✅ Seed data for development/testing  
✅ Clean git history with regular commits  
✅ Documentation (README, env example)  

---

## Common Issues & Solutions

### Issue: Database connection fails

**Solution**: Verify `.env.local` has correct `POSTGRES_URL` from Vercel

```bash
vercel env pull .env.local --force
```

### Issue: TypeScript errors after creating models

**Solution**: Restart TypeScript server in VS Code (Cmd+Shift+P → "TypeScript: Restart TS Server")

### Issue: Migration fails with "relation already exists"

**Solution**: Migrations use `IF NOT EXISTS` - this is expected. Check tables:

```bash
npx tsx -e "
import { sql } from '@vercel/postgres';
sql\`SELECT table_name FROM information_schema.tables WHERE table_schema='public'\`
  .then(r => console.log(r.rows));
"
```

---

## Next Steps: Phase 2

Once Phase 1 is complete, proceed to **Phase 2: Open-Meteo Integration**

1. Port Rails `OpenMeteoService` to TypeScript
2. Create `/api/weather` route (Rails API parity)
3. Add server-side caching
4. Test against Rails responses

See `PHASE_2_IMPLEMENTATION.md` (to be created) for details.

---

**Phase 1 Target Completion**: 2025-11-12  
**Next Phase Start**: 2025-11-12  
**Document Updated**: 2025-11-07
