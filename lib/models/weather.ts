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
