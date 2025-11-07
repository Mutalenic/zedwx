# ⏸️ PAUSE: Manual Vercel Setup Required

**Status**: Phase 1 - 60% Complete  
**Next Step**: Set up Vercel Postgres Database  
**Time Required**: 10-15 minutes

---

## ✅ What We've Completed So Far

1. ✅ Archived Rails app to `archive/rails-v1` branch
2. ✅ Tagged Rails version as `rails-v1.0`
3. ✅ Initialized Next.js 14 with TypeScript and Tailwind
4. ✅ Installed core dependencies (@vercel/postgres, zod, swr, etc.)
5. ✅ Created database schema (migrations/0001_initial_schema.sql)
6. ✅ Created migration scripts (scripts/migrate.ts, scripts/test-db.ts)

---

## 🎯 Next Steps: Vercel Setup (Manual)

### Step 1: Install Vercel CLI

```bash
npm i -g vercel
```

### Step 2: Login to Vercel

```bash
vercel login
```

Follow the prompts to authenticate.

### Step 3: Link Your Project

```bash
cd /home/nicholas/Documents/projects_personal/zedwx
vercel link
```

Answer the prompts:
- Set up and deploy? **Yes**
- Which scope? (Select your account)
- Link to existing project? **No**
- Project name? **zedwx**
- Directory? **./  (current directory)**

### Step 4: Create Postgres Database

1. Go to https://vercel.com/dashboard
2. Select your **zedwx** project
3. Click **Storage** tab
4. Click **Create Database**
5. Select **Postgres**
6. Database name: `zedwx-db`
7. Region: Select closest to Zambia (e.g., `fra1` - Frankfurt or `sin1` - Singapore)
8. Click **Create**

### Step 5: Pull Environment Variables

```bash
vercel env pull .env.local
```

This creates `.env.local` with your database credentials.

### Step 6: Test Database Connection

```bash
npx tsx scripts/test-db.ts
```

Expected output:
```
🔌 Testing database connection...

✅ Database connected successfully!
Current time: 2025-11-07...
PostgreSQL version: PostgreSQL 16.x...
```

### Step 7: Run Migrations

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

---

## ✅ Verification Checklist

Before resuming automation:

- [ ] Vercel CLI installed
- [ ] Logged in to Vercel
- [ ] Project linked to Vercel
- [ ] Postgres database created
- [ ] Environment variables pulled (.env.local exists)
- [ ] Database connection test passed
- [ ] Migrations ran successfully

---

## 🚀 Resume Automation

Once all verification steps are complete, tell me:

**"Vercel setup complete, continue Phase 1"**

And I will:
1. Create TypeScript weather models
2. Create Zod validation schemas  
3. Create database helper functions
4. Create seed data
5. Verify Phase 1 completion
6. Update documentation

---

## 📝 Notes

- The `.env.local` file is already in .gitignore (won't be committed)
- Your database will be in Vercel's serverless Postgres (free tier available)
- Connection pooling is handled automatically by Vercel
- Database is production-ready but starts on free tier

---

## ❓ Troubleshooting

### "Command 'vercel' not found"

```bash
npm i -g vercel
# or
sudo npm i -g vercel
```

### "Database connection failed"

1. Check `.env.local` exists and has `POSTGRES_URL`
2. Verify database created in Vercel dashboard
3. Run `vercel env pull .env.local --force` to refresh credentials

### "Migration failed"

1. Ensure database connection works first (`npx tsx scripts/test-db.ts`)
2. Check migration file syntax
3. Try running migration statements individually

---

**Current Time**: 2025-11-07  
**Estimated Time to Complete Manual Steps**: 10-15 minutes  
**Phase 1 Progress**: 6/10 tasks complete (60%)
