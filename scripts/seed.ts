import { config } from 'dotenv';
import { resolve } from 'path';
import { saveForecast } from '../lib/db/forecasts';
import { saveRawBulletin } from '../lib/db/bulletins';
import { ProvinceForecast, PROVINCES, generateForecastId } from '../lib/models/weather';

// Load .env.local
config({ path: resolve(process.cwd(), '.env.local') });

async function seed() {
  console.log('🌱 Seeding database...\n');

  try {
    // Seed sample bulletin
    console.log('Creating sample bulletin...');
    const today = new Date().toISOString().split('T')[0];
    const sampleBulletin = `
ZAMBIA METEOROLOGICAL DEPARTMENT
WEATHER FORECAST FOR ${today}

Lusaka: Morning partly cloudy with temperatures 18-25°C. 
Afternoon scattered thunderstorms likely. Evening clearing.

Southern: Morning foggy conditions, low of 14°C. Afternoon 
sunny with high of 28°C. Isolated showers possible evening.

Copperbelt: Cloudy throughout with light rain morning and 
afternoon. Temperatures 16-22°C. Moderate winds expected.

Central: Clear skies in the morning, high of 30°C expected.
Afternoon warm with possible isolated showers. Evening clear.

Eastern: Partly cloudy with temperatures ranging 17-26°C.
Light winds throughout the day. Evening mild.
    `.trim();

    await saveRawBulletin(sampleBulletin, 'zmd');
    console.log('✅ Sample bulletin created\n');

    // Seed sample forecasts for 5 provinces
    console.log('Creating sample forecasts...');
    const provincesToSeed = PROVINCES.slice(0, 5); // Lusaka, Central, Copperbelt, Eastern, Luapula

    for (const province of provincesToSeed) {
      const forecast: ProvinceForecast = {
        id: generateForecastId(province, today),
        province,
        date: today,
        lastUpdated: new Date().toISOString(),
        segments: [
          {
            periodId: 'morning',
            start: '06:00',
            end: '12:00',
            summaryPlainEN: 'Partly cloudy with mild temperatures',
            conditionTags: ['partly-cloudy'],
            minTempC: 16,
            maxTempC: 22,
            precipProbability: 20,
            wind: {
              speedKph: 10,
              direction: 'E',
              severity: 'calm',
            },
            severityScore: 2,
          },
          {
            periodId: 'afternoon',
            start: '12:00',
            end: '18:00',
            summaryPlainEN: 'Scattered thunderstorms likely, warm temperatures',
            conditionTags: ['thunderstorm', 'rain'],
            minTempC: 22,
            maxTempC: 28,
            precipProbability: 70,
            wind: {
              speedKph: 25,
              gustKph: 40,
              direction: 'SW',
              severity: 'moderate',
            },
            severityScore: 5,
          },
          {
            periodId: 'evening',
            start: '18:00',
            end: '21:00',
            summaryPlainEN: 'Clearing skies, cooler temperatures',
            conditionTags: ['partly-cloudy'],
            minTempC: 18,
            maxTempC: 22,
            precipProbability: 10,
            wind: {
              speedKph: 8,
              direction: 'E',
              severity: 'calm',
            },
            severityScore: 1,
          },
          {
            periodId: 'night',
            start: '21:00',
            end: '06:00',
            summaryPlainEN: 'Clear skies, cool overnight',
            conditionTags: ['clear'],
            minTempC: 14,
            maxTempC: 18,
            precipProbability: 5,
            wind: {
              speedKph: 5,
              direction: 'NE',
              severity: 'calm',
            },
            severityScore: 0,
          },
        ],
        notes: [
          'This is sample seed data for development and testing',
          'Farmers should monitor conditions before outdoor activities',
        ],
        source: {
          name: 'manual',
          rawTextExcerpt: 'Sample seed data created for Phase 1 development',
        },
        confidence: 'high',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      };

      await saveForecast(forecast, true); // Published
      console.log(`✅ Created forecast for ${province}`);
    }

    console.log('\n🎉 Seeding completed successfully!');
    console.log(`\n📊 Summary:`);
    console.log(`   - 1 raw bulletin`);
    console.log(`   - ${provincesToSeed.length} province forecasts`);
    console.log(`   - All forecasts published and ready to query\n`);

    process.exit(0);
  } catch (error) {
    console.error('❌ Seeding failed:', error);
    process.exit(1);
  }
}

seed();
