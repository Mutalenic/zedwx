# ZedWx - Zambian Weather Application

Next.js 14 full-stack weather application for Zambian provinces with ZMD bulletin parsing, powered by Neon Postgres.

## 🌍 Overview

ZedWx provides weather forecasts for Zambia's 10 provinces:
- Central
- Copperbelt
- Eastern
- Luapula
- Muchinga
- Northern
- North-Western
- Southern
- Western
- Lusaka

## 🚀 Tech Stack

- **Framework**: Next.js 14 (App Router, React 18)
- **Database**: Neon Postgres (Serverless)
- **Language**: TypeScript
- **Styling**: Tailwind CSS
- **Validation**: Zod
- **Data Fetching**: SWR
- **Testing**: Vitest

## 📦 Getting Started

### Prerequisites

- Node.js 18+ 
- npm or pnpm
- Neon/Vercel account (for database)

### Installation

1. **Clone the repository**

```bash
git clone https://github.com/Mutalenic/zedwx.git
cd zedwx
```

2. **Install dependencies**

```bash
npm install
```

3. **Set up environment variables**

```bash
cp .env.example .env.local
```

Edit `.env.local` and add your Neon Postgres credentials. See [SETUP_VERCEL.md](./SETUP_VERCEL.md) for detailed instructions.

4. **Run migrations**

```bash
npx tsx scripts/migrate.ts
```

5. **Seed the database** (optional, for development)

```bash
npx tsx scripts/seed.ts
```

6. **Start the development server**

```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) to see the application.

## 🗄️ Database Schema

The application uses three main tables:

- **forecasts** - Canonical weather forecast data (JSONB)
- **raw_bulletins** - Raw ZMD bulletins for audit trail
- **sms_subscriptions** - User SMS alert subscriptions

## 📝 Scripts

```bash
# Development
npm run dev              # Start dev server
npm run build            # Production build
npm run lint             # Lint code

# Database
npx tsx scripts/test-db.ts    # Test database connection
npx tsx scripts/migrate.ts    # Run migrations
npx tsx scripts/seed.ts       # Seed sample data

# Testing
npm run test             # Run tests (when implemented)
```

## 🏗️ Project Structure

```
├── app/                 # Next.js app directory
├── lib/                 # Core library code
│   ├── models/         # TypeScript data models
│   ├── schemas/        # Zod validation schemas
│   └── db/             # Database helper functions
├── migrations/          # SQL migration files
├── scripts/            # Utility scripts
├── public/             # Static assets
└── README.md
```

## 🌤️ Features

### Phase 1 (✅ Complete)
- ✅ Next.js foundation with TypeScript
- ✅ Neon Postgres database
- ✅ Province-based data models
- ✅ Database migrations and seeding

### Phase 2 (🔜 Next)
- 🔜 Open-Meteo API integration
- 🔜 RESTful weather endpoints
- 🔜 Server-side caching

### Future Phases
- ZMD bulletin parser with confidence scoring
- Admin UI for bulletin review
- Public province-centric UI
- SMS alerts via Africa's Talking
- PWA with offline support

See [MIGRATION_PLAN.md](./MIGRATION_PLAN.md) for the full roadmap.

## 📖 Documentation

- [QUICKSTART.md](./QUICKSTART.md) - Quick reference guide
- [SETUP_VERCEL.md](./SETUP_VERCEL.md) - Vercel/Neon setup instructions
- [PROGRESS_TRACKER.md](./PROGRESS_TRACKER.md) - Development progress

## 🔐 Environment Variables

Required variables (see `.env.example`):

- `POSTGRES_URL` - Neon Postgres connection string
- `POSTGRES_*` - Additional Postgres credentials

Optional (for future phases):
- `OPENWEATHER_API_KEY` - OpenWeather fallback
- `AFRICAS_TALKING_API_KEY` - SMS alerts

## 🤝 Contributing

This is a personal project in active development. Contributions welcome once Phase 2 is complete.

## 📄 License

MIT

## 🏷️ Project Status

**Current Phase**: Phase 1 Complete ✅  
**Next Phase**: Phase 2 - Open-Meteo Integration  
**Branch**: `dev`  
**Last Updated**: 2025-11-07

---

**Previous Rails Version**: Archived in `archive/rails-v1` branch and tagged as `rails-v1.0`
