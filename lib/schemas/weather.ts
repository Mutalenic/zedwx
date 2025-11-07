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
