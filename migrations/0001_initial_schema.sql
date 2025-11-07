-- Initial schema for ZedWx Next.js application
-- Created: 2025-11-07
-- Phase: 1 (Foundation)

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
