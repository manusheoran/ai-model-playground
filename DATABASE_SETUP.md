# Database Setup Guide

This guide will help you set up PostgreSQL for the AI Model Playground application.

## Quick Start Options

### Option 1: Use SQLite (No PostgreSQL Required) - Coming Soon
For development purposes, you can use SQLite instead of PostgreSQL. This option will be added in a future update.

### Option 2: Local PostgreSQL

#### macOS
```bash
# Install PostgreSQL using Homebrew
brew install postgresql@15

# Start PostgreSQL service
brew services start postgresql@15

# Create database
createdb ai_playground

# Initialize schema using the SQL script
psql ai_playground < scripts/init-db.sql

# Or use the API endpoint
curl -X POST http://localhost:3000/api/init-db
```

#### Linux (Ubuntu/Debian)
```bash
# Install PostgreSQL
sudo apt update
sudo apt install postgresql postgresql-contrib

# Start PostgreSQL
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Create user and database
sudo -u postgres createuser -P myuser
sudo -u postgres createdb -O myuser ai_playground

# Initialize schema
psql -U myuser -d ai_playground < scripts/init-db.sql
```

#### Windows
1. Download PostgreSQL from [postgresql.org](https://www.postgresql.org/download/windows/)
2. Run the installer
3. Note the password you set for the postgres user
4. Open pgAdmin or command line
5. Create database: `CREATE DATABASE ai_playground;`
6. Run the init script from `scripts/init-db.sql`

### Option 3: Docker (Easiest for Development)

Create a `docker-compose.yml`:

```yaml
version: '3.8'
services:
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: ai_playground
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./scripts/init-db.sql:/docker-entrypoint-initdb.d/init.sql

volumes:
  postgres_data:
```

Then run:
```bash
docker-compose up -d
```

Update `.env.local`:
```env
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/ai_playground
```

### Option 4: Cloud PostgreSQL (Production)

#### Neon (Serverless, Free Tier)
1. Go to [neon.tech](https://neon.tech)
2. Create account and new project
3. Copy the connection string
4. Update `.env.local`:
   ```env
   DATABASE_URL=postgresql://user:password@ep-xxx.region.neon.tech/neondb
   ```
5. Initialize schema via API:
   ```bash
   curl -X POST http://localhost:3000/api/init-db
   ```

#### Supabase (Free Tier with Dashboard)
1. Go to [supabase.com](https://supabase.com)
2. Create new project
3. Go to Settings > Database
4. Copy "Direct Connection" string
5. Update `.env.local`
6. Run initialization

#### Railway (One-Click Setup)
1. Go to [railway.app](https://railway.app)
2. Click "New Project"
3. Select "Provision PostgreSQL"
4. Copy the `DATABASE_URL` from variables
5. Update `.env.local`

#### Vercel Postgres (Integrated with Vercel)
```bash
# Install Vercel CLI
npm i -g vercel

# Create Vercel Postgres
vercel postgres create

# Link to project
vercel link

# Pull environment variables
vercel env pull .env.local
```

## Connection String Format

Standard PostgreSQL connection string:
```
postgresql://[user]:[password]@[host]:[port]/[database]?[parameters]
```

Example:
```
postgresql://myuser:mypassword@localhost:5432/ai_playground
```

With SSL (required by most cloud providers):
```
postgresql://user:password@host:5432/database?sslmode=require
```

## Schema Details

### Tables

#### `comparisons`
Stores the prompt and metadata for each comparison.

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| prompt | TEXT | User's prompt |
| created_at | TIMESTAMP | Creation timestamp |

#### `model_responses`
Stores individual model responses for each comparison.

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| comparison_id | UUID | Foreign key to comparisons |
| model_name | VARCHAR(100) | Name of the model |
| response_text | TEXT | Model's response |
| prompt_tokens | INTEGER | Number of prompt tokens |
| completion_tokens | INTEGER | Number of completion tokens |
| total_tokens | INTEGER | Total tokens used |
| response_time_ms | INTEGER | Response time in milliseconds |
| estimated_cost | DECIMAL(10, 6) | Estimated cost in USD |
| error | TEXT | Error message if any |
| created_at | TIMESTAMP | Creation timestamp |

### Indexes
- `idx_model_responses_comparison`: Speeds up queries by comparison_id
- `idx_comparisons_created_at`: Speeds up history queries ordered by date

## Initialization Methods

### Method 1: API Endpoint (Recommended)
```bash
# Start the dev server
npm run dev

# Initialize database
curl -X POST http://localhost:3000/api/init-db
```

Response:
```json
{
  "message": "Database initialized successfully"
}
```

### Method 2: SQL Script
```bash
psql -U username -d ai_playground < scripts/init-db.sql
```

### Method 3: pgAdmin or Database GUI
1. Open pgAdmin, DBeaver, or TablePlus
2. Connect to your database
3. Open `scripts/init-db.sql`
4. Execute the script

## Verifying Setup

### Check Tables
```sql
-- List all tables
\dt

-- Check comparisons table structure
\d comparisons

-- Check model_responses table structure
\d model_responses
```

### Test Connection
```javascript
// Test script (test-db.js)
const { Pool } = require('pg');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
});

async function test() {
  try {
    const result = await pool.query('SELECT NOW()');
    console.log('✅ Database connected:', result.rows[0]);
    process.exit(0);
  } catch (error) {
    console.error('❌ Database error:', error.message);
    process.exit(1);
  }
}

test();
```

Run with:
```bash
node test-db.js
```

## Troubleshooting

### Connection Refused
- Ensure PostgreSQL is running
- Check the port (default: 5432)
- Verify host address (localhost vs 127.0.0.1)

### Authentication Failed
- Check username and password
- Verify `pg_hba.conf` allows connections
- Try `trust` authentication method for local development

### SSL Required
Add `?sslmode=require` to your connection string:
```env
DATABASE_URL=postgresql://user:pass@host:5432/db?sslmode=require
```

### Too Many Connections
- Use connection pooling (already implemented)
- Reduce `max` connections in pool config
- Upgrade database tier for more connections

### Permission Denied
```sql
-- Grant necessary permissions
GRANT ALL PRIVILEGES ON DATABASE ai_playground TO myuser;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO myuser;
```

## Database Maintenance

### Backup
```bash
# Full backup
pg_dump ai_playground > backup.sql

# Data only
pg_dump --data-only ai_playground > data_backup.sql

# Specific tables
pg_dump --table=comparisons --table=model_responses ai_playground > tables_backup.sql
```

### Restore
```bash
psql ai_playground < backup.sql
```

### Clean Old Data
```sql
-- Delete comparisons older than 30 days
DELETE FROM comparisons 
WHERE created_at < NOW() - INTERVAL '30 days';
```

### Vacuum & Analyze
```sql
-- Optimize database
VACUUM ANALYZE;
```

## Connection Pooling

The application uses connection pooling by default via the `pg` library. Configuration in `lib/db.ts`:

```typescript
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  max: 20, // Maximum connections in pool
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});
```

## Security Best Practices

1. **Never commit database credentials** to version control
2. **Use strong passwords** for database users
3. **Enable SSL** for production connections
4. **Restrict database access** by IP if possible
5. **Regular backups** are essential
6. **Use read-only connections** for queries when possible
7. **Implement row-level security** for multi-tenant apps

## Performance Tips

1. **Use indexes** on frequently queried columns (already implemented)
2. **Limit result sets** with pagination
3. **Use connection pooling** (already implemented)
4. **Monitor slow queries** with `pg_stat_statements`
5. **Regular VACUUM** to prevent bloat
6. **Consider read replicas** for high-traffic applications

## Monitoring

### Check Connection Count
```sql
SELECT count(*) FROM pg_stat_activity;
```

### Check Database Size
```sql
SELECT pg_size_pretty(pg_database_size('ai_playground'));
```

### Check Table Sizes
```sql
SELECT 
  schemaname,
  tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

## Migration to Production

When moving from development to production:

1. Export data from development database
2. Set up production database (use managed service)
3. Update `DATABASE_URL` in production environment
4. Run initialization script
5. Import data if needed
6. Test thoroughly
7. Monitor performance and adjust as needed
