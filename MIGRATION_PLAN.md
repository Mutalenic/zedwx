# ZedWx Migration Plan: Rails → Next.js + Vercel Postgres

**Project**: Zambian Weather Application  
**Current State**: Ruby on Rails API (Open-Meteo integration)  
**Target State**: Next.js 14+ App Router + Vercel Postgres + ZMD Bulletin Parser  
**Migration Start**: 2025-11-07  
**Status**: Planning Phase

---

## Executive Summary

Replace the existing Rails API with a modern Next.js full-stack application that:
1. Maintains existing Open-Meteo weather data functionality
2. Adds ZMD (Zambia Meteorological Department) bulletin parsing with admin review
3. Implements province-centric UI for 10 Zambian provinces
4. Provides SMS alerts, offline support, and fallback weather APIs
5. Enables human-in-the-loop validation for critical weather data

---

## Phase 0: Pre-Migration Setup ✅

**Duration**: 1 day  
**Status**: In Progress

### Tasks
- [x] Document existing Rails app functionality
- [x] Create migration plan (this document)
- [x] Update .gitignore to exclude migration docs
- [ ] Archive Rails app to `archive/rails-app/` branch
- [ ] Create initial Next.js project structure
- [ ] Set up Vercel project + Postgres database
- [ ] Configure environment variables

### Existing Rails Functionality to Preserve
```ruby
# Models
- Location (10 provinces: Central, Copperbelt, Eastern, Luapula, Muchinga, 
  Northern, North-Western, Southern, Western, Lusaka)
- Coordinates mapping per province

# Services
- OpenMeteoService (weather data fetching)
- CacheService (Redis-based caching)
- LocationValidator (province validation)

# API Endpoints
- GET /api/v1/weather?location=<province>
  - Returns: temperature, conditions, forecast
  - Caching: 1 hour
  - Error handling: 400/404/500
```

### Migration Dependencies
```json
{
  "preserve": [
    "Province coordinates mapping",
    "Open-Meteo API integration pattern",
    "Caching strategy (1hr TTL)",
    "Error handling patterns"
  ],
  "new_features": [
    "ZMD bulletin parsing",
    "Admin review UI",
    "SMS alerts",
    "PWA offline support",
    "Multi-provider fallbacks"
  ]
}
```

---

## Phase 1: Next.js Foundation

**Duration**: 3-5 days  
**Status**: Not Started

### 1.1 Project Initialization
```bash
# Create Next.js 14 app with TypeScript
npx create-next-app@latest zedwx-next --typescript --tailwind --app --no-src-dir

# Install core dependencies
npm install @vercel/postgres zod swr date-fns
npm install -D @types/node
```

### 1.2 Database Schema
**File**: `migrations/0001_initial_schema.sql`

```sql
-- Forecasts table (canonical weather data)
CREATE TABLE forecasts (
  id TEXT PRIMARY KEY,
  province TEXT NOT NULL,
  date DATE NOT NULL,
  forecast JSONB NOT NULL,
  source TEXT NOT NULL, -- 'zmd', 'open-meteo', 'openweather', etc.
  confidence TEXT CHECK (confidence IN ('low', 'medium', 'high')),
  severity_score INTEGER DEFAULT 0 CHECK (severity_score BETWEEN 0 AND 10),
  published BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Raw bulletins (audit trail)
CREATE TABLE raw_bulletins (
  id SERIAL PRIMARY KEY,
  bulletin_text TEXT NOT NULL,
  source TEXT DEFAULT 'zmd',
  fetched_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  processed BOOLEAN DEFAULT FALSE,
  processor_notes TEXT,
  processed_at TIMESTAMP WITH TIME ZONE
);

-- SMS subscriptions
CREATE TABLE sms_subscriptions (
  id SERIAL PRIMARY KEY,
  phone_number TEXT NOT NULL UNIQUE,
  province TEXT NOT NULL,
  active BOOLEAN DEFAULT TRUE,
  consent_given_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  unsubscribed_at TIMESTAMP WITH TIME ZONE
);

-- Indexes for performance
CREATE INDEX idx_forecasts_province_date ON forecasts (province, date DESC);
CREATE INDEX idx_forecasts_published ON forecasts (published) WHERE published = TRUE;
CREATE INDEX idx_forecasts_severity ON forecasts (severity_score DESC);
CREATE INDEX idx_bulletins_processed ON raw_bulletins (processed, fetched_at DESC);
CREATE INDEX idx_subs_active ON sms_subscriptions (active, province) WHERE active = TRUE;
```

### 1.3 TypeScript Data Models
**File**: `lib/models/weather.ts`

```typescript
// Core types matching Rails Location model
export const PROVINCES = [
  'Central', 'Copperbelt', 'Eastern', 'Luapula', 'Muchinga',
  'Northern', 'North-Western', 'Southern', 'Western', 'Lusaka'
] as const;

export type Province = typeof PROVINCES[number];

export type PeriodId = 'morning' | 'afternoon' | 'evening' | 'night' | 'overnight' | 'day';

export interface TimeSegment {
  periodId: PeriodId;
  start?: string; // ISO time
  end?: string;
  summaryPlainEN: string;
  conditionTags: string[]; // ['rain', 'thunderstorm', 'wind']
  precipProbability?: number; // 0-100
  minTempC?: number;
  maxTempC?: number;
  wind?: {
    speedKph?: number;
    gustKph?: number;
    direction?: string;
    severity?: 'calm' | 'moderate' | 'strong' | 'dangerous';
  };
  severityScore?: number; // 0-10
  icons?: string[]; // Icon keys
}

export interface ProvinceForecast {
  id: string; // e.g., "southern-2025-11-08"
  province: Province;
  date: string; // YYYY-MM-DD
  lastUpdated: string; // ISO datetime
  segments: TimeSegment[];
  notes?: string[];
  source: {
    name: string;
    rawId?: string;
    rawUrl?: string;
    rawTextExcerpt?: string;
  };
  confidence?: 'low' | 'medium' | 'high';
  createdAt?: string;
  updatedAt?: string;
}

// Province coordinates (from Rails Location model)
export const PROVINCE_COORDS: Record<Province, { lat: number; lon: number; name: string }> = {
  'Central': { lat: -14.5333, lon: 28.2833, name: 'Central Province' },
  'Copperbelt': { lat: -12.8389, lon: 28.2136, name: 'Copperbelt Province' },
  'Eastern': { lat: -13.6333, lon: 32.6500, name: 'Eastern Province' },
  'Luapula': { lat: -11.6667, lon: 29.3333, name: 'Luapula Province' },
  'Muchinga': { lat: -11.2167, lon: 31.9500, name: 'Muchinga Province' },
  'Northern': { lat: -10.1333, lon: 31.1333, name: 'Northern Province' },
  'North-Western': { lat: -12.5000, lon: 25.8500, name: 'North-Western Province' },
  'Southern': { lat: -16.8167, lon: 26.5167, name: 'Southern Province' },
  'Western': { lat: -15.3167, lon: 23.1333, name: 'Western Province' },
  'Lusaka': { lat: -15.4167, lon: 28.2833, name: 'Lusaka Province' }
};
```

### 1.4 Deliverables
- [ ] Next.js project initialized
- [ ] Vercel Postgres database created
- [ ] Initial migration executed
- [ ] TypeScript models defined
- [ ] Zod schemas for validation
- [ ] Git commit: "feat: phase 1 - next.js foundation"

---

## Phase 2: Open-Meteo Integration (Preserve Rails Functionality)

**Duration**: 2-3 days  
**Status**: Not Started

### 2.1 Weather Service
**File**: `lib/services/openMeteoService.ts`

```typescript
// Port from Rails OpenMeteoService
export interface OpenMeteoResponse {
  latitude: number;
  longitude: number;
  current: {
    temperature_2m: number;
    relative_humidity_2m: number;
    apparent_temperature: number;
    precipitation: number;
    weather_code: number;
    wind_speed_10m: number;
    wind_direction_10m: number;
  };
  daily: {
    time: string[];
    temperature_2m_max: number[];
    temperature_2m_min: number[];
    precipitation_sum: number[];
    weather_code: number[];
  };
}

export async function fetchOpenMeteo(
  lat: number,
  lon: number
): Promise<OpenMeteoResponse> {
  const url = new URL('https://api.open-meteo.com/v1/forecast');
  url.searchParams.set('latitude', lat.toString());
  url.searchParams.set('longitude', lon.toString());
  url.searchParams.set('current', 'temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,wind_speed_10m,wind_direction_10m');
  url.searchParams.set('daily', 'temperature_2m_max,temperature_2m_min,precipitation_sum,weather_code');
  url.searchParams.set('timezone', 'Africa/Lusaka');
  url.searchParams.set('forecast_days', '7');

  const response = await fetch(url.toString(), {
    next: { revalidate: 3600 } // 1 hour cache (matches Rails)
  });

  if (!response.ok) {
    throw new Error(`Open-Meteo API failed: ${response.statusText}`);
  }

  return response.json();
}
```

### 2.2 API Route (Replaces Rails Controller)
**File**: `app/api/weather/route.ts`

```typescript
import { NextRequest, NextResponse } from 'next/server';
import { PROVINCE_COORDS, Province, PROVINCES } from '@/lib/models/weather';
import { fetchOpenMeteo } from '@/lib/services/openMeteoService';

export async function GET(request: NextRequest) {
  const searchParams = request.nextUrl.searchParams;
  const location = searchParams.get('location');

  // Validate province
  if (!location || !PROVINCES.includes(location as Province)) {
    return NextResponse.json(
      { error: 'Invalid location. Must be one of: ' + PROVINCES.join(', ') },
      { status: 400 }
    );
  }

  const province = location as Province;
  const coords = PROVINCE_COORDS[province];

  try {
    const data = await fetchOpenMeteo(coords.lat, coords.lon);
    
    return NextResponse.json({
      province,
      coordinates: coords,
      current: data.current,
      daily: data.daily,
      source: 'open-meteo',
      fetched_at: new Date().toISOString()
    });
  } catch (error) {
    console.error('Weather fetch failed:', error);
    return NextResponse.json(
      { error: 'Failed to fetch weather data' },
      { status: 500 }
    );
  }
}
```

### 2.3 Deliverables
- [ ] Open-Meteo service implemented
- [ ] API route tested (GET /api/weather?location=Lusaka)
- [ ] Error handling matches Rails patterns
- [ ] Caching configured (1 hour)
- [ ] Git commit: "feat: phase 2 - open-meteo integration"

---

## Phase 3: ZMD Bulletin Parser

**Duration**: 5-7 days  
**Status**: Not Started

### 3.1 Regex Parser
**File**: `lib/parsers/regexParser.ts`

```typescript
import { PROVINCES, Province, TimeSegment } from '../models/weather';

export interface ProvinceBlock {
  province: Province;
  text: string;
  confidence: number;
}

export function splitByProvince(rawText: string): ProvinceBlock[] {
  const blocks: ProvinceBlock[] = [];
  
  for (const province of PROVINCES) {
    // Match province name followed by content until next province or end
    const pattern = new RegExp(
      `${province}\\b[:\\s\\n]*([\\s\\S]*?)(?=(?:${PROVINCES.join('|')})\\b|$)`,
      'i'
    );
    const match = rawText.match(pattern);
    
    if (match && match[1].trim().length > 10) {
      blocks.push({
        province,
        text: match[1].trim(),
        confidence: 0.7 // Base confidence for regex match
      });
    }
  }
  
  return blocks;
}

export function parseTimeSegments(text: string): TimeSegment[] {
  const segments: TimeSegment[] = [];
  const periods = ['morning', 'afternoon', 'evening', 'night', 'tonight', 'overnight'];
  
  for (const period of periods) {
    const pattern = new RegExp(
      `(${period})[:\\s,.-]*([^.\\n]{10,300})`,
      'i'
    );
    const match = text.match(pattern);
    
    if (match) {
      const summaryText = match[2].trim();
      
      segments.push({
        periodId: period === 'tonight' ? 'night' : period as any,
        summaryPlainEN: summaryText,
        conditionTags: extractConditionTags(summaryText),
        precipProbability: extractPrecipProbability(summaryText),
        minTempC: extractTemperature(summaryText, 'min'),
        maxTempC: extractTemperature(summaryText, 'max'),
      });
    }
  }
  
  return segments;
}

function extractConditionTags(text: string): string[] {
  const tags: string[] = [];
  const patterns = {
    rain: /\b(rain|rainy|showers?|drizzle)\b/i,
    thunderstorm: /\b(thunder|lightning|storm|thundery)\b/i,
    wind: /\b(wind|windy|gusty?|breeze)\b/i,
    cloud: /\b(cloud|cloudy|overcast)\b/i,
    clear: /\b(clear|sunny|fair)\b/i,
    fog: /\b(fog|mist|haze)\b/i,
  };
  
  for (const [tag, pattern] of Object.entries(patterns)) {
    if (pattern.test(text)) tags.push(tag);
  }
  
  return tags;
}

function extractPrecipProbability(text: string): number | undefined {
  // Look for phrases like "likely", "possible", "isolated", "scattered"
  if (/\b(likely|expected|widespread)\b/i.test(text)) return 70;
  if (/\b(possible|scattered)\b/i.test(text)) return 50;
  if (/\b(isolated|occasional)\b/i.test(text)) return 30;
  return undefined;
}

function extractTemperature(text: string, type: 'min' | 'max'): number | undefined {
  // Match patterns like "15-25°C" or "high of 28" or "low of 12"
  const rangeMatch = text.match(/(\d+)\s*[-–]\s*(\d+)\s*°?[Cc]?/);
  if (rangeMatch) {
    return type === 'min' ? parseInt(rangeMatch[1]) : parseInt(rangeMatch[2]);
  }
  
  const typePattern = type === 'max' 
    ? /\b(?:high|max|maximum)[^\d]*(\d+)\s*°?[Cc]?/i
    : /\b(?:low|min|minimum)[^\d]*(\d+)\s*°?[Cc]?/i;
  
  const match = text.match(typePattern);
  return match ? parseInt(match[1]) : undefined;
}
```

### 3.2 Confidence Scoring
**File**: `lib/parsers/confidenceScorer.ts`

```typescript
import { TimeSegment } from '../models/weather';

export function calculateConfidence(segments: TimeSegment[]): {
  score: number;
  level: 'low' | 'medium' | 'high';
  details: string[];
} {
  let score = 0;
  const details: string[] = [];
  
  // Base score for successful parse
  score += 0.3;
  details.push('Base parse successful');
  
  // Points for each segment
  score += segments.length * 0.1;
  details.push(`${segments.length} time segments found`);
  
  // Points for temperature data
  const tempSegments = segments.filter(s => s.minTempC || s.maxTempC);
  score += tempSegments.length * 0.15;
  if (tempSegments.length > 0) {
    details.push(`Temperature data in ${tempSegments.length} segments`);
  }
  
  // Points for precipitation probability
  const precipSegments = segments.filter(s => s.precipProbability);
  score += precipSegments.length * 0.1;
  if (precipSegments.length > 0) {
    details.push(`Precipitation probability in ${precipSegments.length} segments`);
  }
  
  // Points for condition tags
  const avgTags = segments.reduce((sum, s) => sum + s.conditionTags.length, 0) / segments.length;
  score += avgTags * 0.05;
  details.push(`Average ${avgTags.toFixed(1)} condition tags per segment`);
  
  // Normalize to 0-1 range
  score = Math.min(score, 1);
  
  // Determine level
  let level: 'low' | 'medium' | 'high';
  if (score >= 0.7) level = 'high';
  else if (score >= 0.4) level = 'medium';
  else level = 'low';
  
  return { score, level, details };
}
```

### 3.3 Deliverables
- [ ] Regex parser implemented
- [ ] Confidence scoring algorithm
- [ ] Unit tests with sample bulletins
- [ ] Git commit: "feat: phase 3 - zmd bulletin parser"

---

## Phase 4: Admin UI & Review Flow

**Duration**: 4-6 days  
**Status**: Not Started

### 4.1 Admin Dashboard
**File**: `app/admin/page.tsx`

```typescript
'use client';

import { useState } from 'react';
import BulletinUploader from '@/components/admin/BulletinUploader';
import ParseReview from '@/components/admin/ParseReview';
import PendingQueue from '@/components/admin/PendingQueue';

export default function AdminPage() {
  const [activeTab, setActiveTab] = useState<'upload' | 'review' | 'queue'>('upload');
  
  return (
    <div className="min-h-screen bg-gray-50">
      <header className="bg-white border-b">
        <div className="max-w-7xl mx-auto px-4 py-4">
          <h1 className="text-2xl font-bold">ZedWx Admin Dashboard</h1>
        </div>
      </header>
      
      <nav className="bg-white border-b">
        <div className="max-w-7xl mx-auto px-4">
          <div className="flex gap-4">
            {(['upload', 'review', 'queue'] as const).map(tab => (
              <button
                key={tab}
                onClick={() => setActiveTab(tab)}
                className={`px-4 py-2 border-b-2 font-medium ${
                  activeTab === tab
                    ? 'border-blue-600 text-blue-600'
                    : 'border-transparent text-gray-600 hover:text-gray-900'
                }`}
              >
                {tab.charAt(0).toUpperCase() + tab.slice(1)}
              </button>
            ))}
          </div>
        </div>
      </nav>
      
      <main className="max-w-7xl mx-auto px-4 py-8">
        {activeTab === 'upload' && <BulletinUploader />}
        {activeTab === 'review' && <ParseReview />}
        {activeTab === 'queue' && <PendingQueue />}
      </main>
    </div>
  );
}
```

### 4.2 Components Structure
```
components/admin/
  ├── BulletinUploader.tsx      # Paste/upload raw bulletin
  ├── ParseReview.tsx           # Review parsed data before publish
  ├── PendingQueue.tsx          # Low-confidence items needing review
  └── ProvinceEditor.tsx        # Edit individual province forecast
```

### 4.3 Deliverables
- [ ] Admin authentication setup
- [ ] Bulletin upload UI
- [ ] Parse preview & edit interface
- [ ] Publish workflow
- [ ] Git commit: "feat: phase 4 - admin ui"

---

## Phase 5: Public Frontend UI

**Duration**: 5-7 days  
**Status**: Not Started

### 5.1 Main App Structure
```
app/
  ├── page.tsx                  # Landing page with province selector
  ├── [province]/page.tsx       # Province forecast detail page
  ├── layout.tsx                # Root layout with PWA meta
  └── api/                      # API routes
      ├── weather/route.ts      # GET weather (Phase 2)
      ├── forecasts/route.ts    # GET canonical forecasts
      └── ingest/
          └── bulletin/route.ts # POST bulletin (admin)
```

### 5.2 Key Components
```typescript
// components/ProvinceSelector.tsx
// components/ForecastCard.tsx
// components/TimelineStrip.tsx
// components/SeverityChip.tsx
// components/AlertBanner.tsx
```

### 5.3 PWA Configuration
**File**: `next.config.js`

```javascript
const withPWA = require('next-pwa')({
  dest: 'public',
  register: true,
  skipWaiting: true,
  disable: process.env.NODE_ENV === 'development'
});

module.exports = withPWA({
  // Next.js config
});
```

### 5.4 Deliverables
- [ ] Province selector with localStorage persistence
- [ ] Forecast cards with timeline view
- [ ] Severity indicators and alerts
- [ ] PWA manifest and service worker
- [ ] Responsive design (mobile-first)
- [ ] Git commit: "feat: phase 5 - public ui"

---

## Phase 6: SMS Alerts & Notifications

**Duration**: 3-4 days  
**Status**: Not Started

### 6.1 SMS Service
**File**: `lib/services/smsService.ts`

```typescript
// Choose: Twilio (global) or Africa's Talking (regional)
export async function sendSMSAlert(
  phoneNumber: string,
  message: string,
  provider: 'twilio' | 'africas-talking' = 'africas-talking'
) {
  if (provider === 'twilio') {
    // Twilio implementation
  } else {
    // Africa's Talking implementation
    const url = 'https://api.africastalking.com/version1/messaging';
    // ... implementation
  }
}
```

### 6.2 Alert Trigger Logic
```typescript
// lib/services/alertService.ts
export async function checkAndSendAlerts(forecast: ProvinceForecast) {
  const maxSeverity = Math.max(...forecast.segments.map(s => s.severityScore || 0));
  
  if (maxSeverity >= 7) {
    // Get all active subscribers for this province
    const subscribers = await getActiveSubscribers(forecast.province);
    
    for (const sub of subscribers) {
      const message = formatAlertMessage(forecast, 'severe');
      await sendSMSAlert(sub.phone_number, message);
    }
  }
}
```

### 6.3 Deliverables
- [ ] SMS provider integration (Africa's Talking)
- [ ] Subscription management API
- [ ] Alert trigger logic
- [ ] Opt-in/opt-out workflow
- [ ] Git commit: "feat: phase 6 - sms alerts"

---

## Phase 7: Caching & Performance

**Duration**: 2-3 days  
**Status**: Not Started

### 7.1 Server-Side Caching
```typescript
// Use Vercel KV or Redis
import { kv } from '@vercel/kv';

export async function getCachedForecast(province: Province, date: string) {
  const key = `forecast:${province}:${date}`;
  const cached = await kv.get(key);
  
  if (cached) return cached;
  
  // Fetch from DB
  const forecast = await fetchFromDB(province, date);
  
  // Cache for 1 hour
  await kv.set(key, forecast, { ex: 3600 });
  
  return forecast;
}
```

### 7.2 Client-Side Caching
```typescript
// Use SWR with localStorage fallback
import useSWR from 'swr';

export function useForecast(province: Province) {
  const { data, error, isLoading } = useSWR(
    `/api/forecasts?province=${province}`,
    fetcher,
    {
      revalidateOnFocus: false,
      revalidateOnReconnect: true,
      refreshInterval: 900000, // 15 minutes
      fallbackData: getLocalStorageFallback(province)
    }
  );
  
  return { forecast: data, error, isLoading };
}
```

### 7.3 Deliverables
- [ ] Redis/Vercel KV caching layer
- [ ] SWR client caching
- [ ] localStorage offline fallback
- [ ] Cache invalidation strategy
- [ ] Git commit: "feat: phase 7 - caching layer"

---

## Phase 8: Testing & Quality Assurance

**Duration**: 3-5 days  
**Status**: Not Started

### 8.1 Test Coverage
```
tests/
  ├── unit/
  │   ├── parsers/
  │   │   ├── regexParser.test.ts
  │   │   └── confidenceScorer.test.ts
  │   └── services/
  │       └── openMeteoService.test.ts
  ├── integration/
  │   ├── api/
  │   │   └── weather.test.ts
  │   └── bulletin-flow.test.ts
  └── e2e/
      ├── user-journey.spec.ts
      └── admin-publish.spec.ts
```

### 8.2 Sample Test Data
```typescript
// tests/fixtures/sample-bulletin.txt
const SAMPLE_BULLETIN = `
ZAMBIA METEOROLOGICAL DEPARTMENT
WEATHER FORECAST FOR NOVEMBER 7, 2025

Lusaka: Morning partly cloudy with temperatures 18-25°C. 
Afternoon scattered thunderstorms likely. Evening clearing.

Southern: Morning foggy conditions, low of 14°C. Afternoon 
sunny with high of 28°C. Isolated showers possible evening.

Copperbelt: Cloudy throughout with light rain morning and 
afternoon. Temperatures 16-22°C. Windy conditions expected.
`;
```

### 8.3 Deliverables
- [ ] Unit tests for all parsers
- [ ] Integration tests for API routes
- [ ] E2E tests for critical user flows
- [ ] Test coverage > 80%
- [ ] Git commit: "test: comprehensive test suite"

---

## Phase 9: Deployment & Monitoring

**Duration**: 2-3 days  
**Status**: Not Started

### 9.1 Vercel Deployment
```bash
# Install Vercel CLI
npm i -g vercel

# Deploy
vercel --prod

# Configure environment variables in Vercel dashboard
# - POSTGRES_URL
# - AFRICAS_TALKING_API_KEY
# - OPENWEATHER_API_KEY (optional fallback)
```

### 9.2 Monitoring Setup
```typescript
// lib/monitoring/sentry.ts
import * as Sentry from "@sentry/nextjs";

Sentry.init({
  dsn: process.env.SENTRY_DSN,
  tracesSampleRate: 0.1,
  environment: process.env.NODE_ENV,
});
```

### 9.3 Cron Jobs
**File**: `vercel.json`

```json
{
  "crons": [
    {
      "path": "/api/cron/fetch-bulletins",
      "schedule": "0 6,14,18 * * *"
    },
    {
      "path": "/api/cron/send-alerts",
      "schedule": "*/30 * * * *"
    }
  ]
}
```

### 9.4 Deliverables
- [ ] Vercel production deployment
- [ ] Environment variables configured
- [ ] Sentry error monitoring
- [ ] Cron jobs for bulletin fetching
- [ ] Analytics setup (Plausible/PostHog)
- [ ] Git commit: "deploy: production setup"

---

## Phase 10: Migration Cutover

**Duration**: 1-2 days  
**Status**: Not Started

### 10.1 Pre-Cutover Checklist
- [ ] All tests passing
- [ ] Production database migrated
- [ ] API endpoints verified (parity with Rails)
- [ ] Performance benchmarks met
- [ ] Backup Rails app data
- [ ] DNS/routing ready to switch

### 10.2 Cutover Steps
1. Set Rails app to read-only mode
2. Export any final Rails data
3. Verify Next.js production deployment
4. Update DNS/routing to Next.js app
5. Monitor for errors (1 hour active monitoring)
6. Archive Rails app to separate branch

### 10.3 Rollback Plan
```bash
# If issues arise, rollback DNS immediately
# Rails app remains on standby for 48 hours
# Then archive to git branch: archive/rails-v1
```

### 10.4 Deliverables
- [ ] Successful cutover to Next.js
- [ ] Rails app archived
- [ ] Zero critical errors in first 24h
- [ ] Git commit: "chore: migration complete"

---

## Technology Stack Comparison

| Component | Rails (Old) | Next.js (New) |
|-----------|-------------|---------------|
| Framework | Ruby on Rails 7.2 | Next.js 14+ (App Router) |
| Database | SQLite3 | Vercel Postgres (PostgreSQL) |
| Caching | Redis (Solid Cache) | Vercel KV / Redis |
| Weather API | Open-Meteo | Open-Meteo + fallbacks |
| Background Jobs | Solid Queue | Vercel Cron |
| Frontend | N/A (API only) | React 18 + Tailwind CSS |
| Testing | RSpec | Vitest + Playwright |
| Deployment | Render.com | Vercel |

---

## Risk Assessment & Mitigation

### High Risk
1. **ZMD bulletin format changes**
   - *Mitigation*: Admin review workflow, confidence scoring, manual override
   
2. **SMS delivery reliability**
   - *Mitigation*: Use Africa's Talking (regional), retry logic, delivery tracking

### Medium Risk
3. **Open-Meteo API rate limits**
   - *Mitigation*: Aggressive caching, fallback to OpenWeather/Visual Crossing

4. **Database scaling with JSONB**
   - *Mitigation*: Proper indexing, pagination, archive old forecasts

### Low Risk
5. **User adoption of new UI**
   - *Mitigation*: Similar API compatibility during transition, progressive rollout

---

## Success Metrics

### Phase Completion Metrics
- [ ] All 10 phases completed
- [ ] 100% API parity with Rails app
- [ ] Test coverage > 80%
- [ ] Lighthouse score > 90

### Post-Launch Metrics (30 days)
- [ ] Zero critical production errors
- [ ] API response time < 200ms (p95)
- [ ] SMS delivery rate > 95%
- [ ] User engagement > Rails baseline

---

## Appendix: Useful Commands

```bash
# Development
npm run dev               # Start dev server
npm run build             # Production build
npm run test              # Run tests
npm run lint              # Lint code

# Database
npx tsx scripts/migrate.ts        # Run migrations
npx tsx scripts/seed.ts           # Seed database

# Deployment
vercel                    # Deploy to preview
vercel --prod             # Deploy to production

# Git workflow
git checkout -b phase-1-foundation
git commit -m "feat: phase 1 complete"
git push origin phase-1-foundation
```

---

## Timeline Summary

| Phase | Duration | Dependencies |
|-------|----------|--------------|
| 0. Pre-Migration Setup | 1 day | - |
| 1. Next.js Foundation | 3-5 days | Phase 0 |
| 2. Open-Meteo Integration | 2-3 days | Phase 1 |
| 3. ZMD Bulletin Parser | 5-7 days | Phase 1 |
| 4. Admin UI | 4-6 days | Phase 3 |
| 5. Public Frontend | 5-7 days | Phase 2, 3 |
| 6. SMS Alerts | 3-4 days | Phase 1 |
| 7. Caching & Performance | 2-3 days | Phase 2, 5 |
| 8. Testing & QA | 3-5 days | All phases |
| 9. Deployment | 2-3 days | Phase 8 |
| 10. Migration Cutover | 1-2 days | Phase 9 |
| **Total** | **31-50 days** | *~6-10 weeks* |

---

## Next Steps (Immediate Actions)

1. ✅ Create this migration plan
2. ⬜ Update .gitignore to exclude MIGRATION_PLAN.md
3. ⬜ Create archive branch for Rails app
4. ⬜ Initialize Next.js project
5. ⬜ Set up Vercel account and Postgres database
6. ⬜ Begin Phase 1 implementation

---

**Document Status**: Living document  
**Last Updated**: 2025-11-07  
**Owner**: Nicholas (Mutalenic)  
**Review Frequency**: After each phase completion
