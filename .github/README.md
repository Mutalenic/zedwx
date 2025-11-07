# GitHub Actions CI/CD Setup

This repository uses GitHub Actions for continuous integration and deployment.

## Workflows

### 1. CI Pipeline (`ci.yml`)
Runs on every push and pull request to `main` and `dev` branches.

**Jobs:**
- **Lint**: Runs ESLint to check code quality
- **Type Check**: Validates TypeScript types
- **Test**: Runs the test suite
- **Build**: Creates a production build (only if all checks pass)

### 2. Production Deploy (`deploy.yml`)
Deploys to Vercel production when code is pushed to `main`.

**Triggers:** Push to `main` branch

### 3. Preview Deploy (`preview.yml`)
Creates preview deployments for pull requests targeting `main`.

**Features:**
- Deploys to a unique preview URL
- Posts the preview URL as a PR comment

## Required Secrets

Add these secrets to your GitHub repository settings (`Settings > Secrets and variables > Actions`):

### Database Secrets (for CI build)
- `POSTGRES_URL`: Your Neon/Vercel Postgres connection URL
- `POSTGRES_URL_NON_POOLING`: Non-pooling connection URL

### Vercel Deployment Secrets (optional, if using GitHub Actions for deployment)
- `VERCEL_TOKEN`: Your Vercel API token
- `VERCEL_ORG_ID`: Your Vercel organization ID (optional)
- `VERCEL_PROJECT_ID`: Your Vercel project ID (optional)

### How to Get Vercel Secrets

1. **VERCEL_TOKEN**: 
   - Go to https://vercel.com/account/tokens
   - Create a new token
   - Copy and add it to GitHub secrets

2. **VERCEL_ORG_ID** and **VERCEL_PROJECT_ID**:
   ```bash
   # Install Vercel CLI
   npm i -g vercel

   # Link your project
   vercel link

   # Check .vercel/project.json for the IDs
   cat .vercel/project.json
   ```

## Alternative: Vercel Git Integration

If you prefer, you can use Vercel's built-in Git integration instead of the GitHub Actions deployment workflows:

1. Connect your GitHub repository to Vercel
2. Vercel will automatically deploy on push to `main` (production) and create preview deployments for PRs
3. In this case, you can keep just the `ci.yml` workflow for testing and remove `deploy.yml` and `preview.yml`

## Running Locally

The same checks that run in CI can be run locally:

```bash
# Lint
npm run lint

# Type check
npx tsc --noEmit

# Test
npm test

# Build
npm run build
```

## Status Badges

Add these to your README.md to show build status:

```markdown
[![CI](https://github.com/Mutalenic/zedwx/actions/workflows/ci.yml/badge.svg)](https://github.com/Mutalenic/zedwx/actions/workflows/ci.yml)
```
