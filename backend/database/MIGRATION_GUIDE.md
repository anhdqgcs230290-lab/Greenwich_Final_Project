# UIRMS Database Migration Guide

## Overview
This guide covers setting up, migrating, and maintaining the UIRMS PostgreSQL database.

## Table of Contents
1. [Initial Setup](#initial-setup)
2. [Connection Setup](#connection-setup)
3. [Schema Deployment](#schema-deployment)
4. [Data Migration](#data-migration)
5. [Testing & Validation](#testing--validation)
6. [Troubleshooting](#troubleshooting)
7. [Maintenance](#maintenance)

---

## Initial Setup

### Prerequisites
- PostgreSQL 14.0 or higher
- PostGIS 3.0 or higher
- psql client
- (Optional) pgAdmin 4 for GUI management

### Installation

#### On macOS
```bash
# Using Homebrew
brew install postgresql postgis

# Start PostgreSQL
brew services start postgresql

# Verify installation
psql --version
```

#### On Ubuntu/Debian
```bash
# Update packages
sudo apt-get update

# Install PostgreSQL
sudo apt-get install postgresql postgresql-contrib

# Install PostGIS
sudo apt-get install postgresql-14-postgis

# Start PostgreSQL
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

#### On Windows
1. Download PostgreSQL installer from https://www.postgresql.org/download/windows/
2. Run installer and note the password for 'postgres' user
3. Add PostgreSQL bin directory to PATH (usually `C:\Program Files\PostgreSQL\14\bin`)
4. Verify installation:
   ```bash
   psql --version
   ```

---

## Connection Setup

### Create PostgreSQL User for UIRMS
```sql
-- Login as postgres superuser
psql -U postgres

-- Create application user
CREATE USER uirms_app WITH PASSWORD 'secure_password_here';

-- Grant privileges
ALTER ROLE uirms_app WITH LOGIN;
GRANT CONNECT ON DATABASE uirms TO uirms_app;
```

### Setup Connection String
```
postgresql://uirms_app:secure_password_here@localhost:5432/uirms
```

### Test Connection
```bash
# Test with psql
psql -h localhost -p 5432 -U uirms_app -d uirms

# Test from Node.js/Express
const connectionString = 'postgresql://uirms_app:password@localhost:5432/uirms';
```

---

## Schema Deployment

### Method 1: Using Setup Script (Recommended)

#### On Linux/macOS
```bash
cd backend/database
chmod +x setup.sh
./setup.sh uirms postgres localhost 5432
```

#### On Windows
```bash
cd backend\database
setup.bat uirms postgres localhost 5432
```

### Method 2: Manual Deployment

#### Step 1: Create Database
```bash
psql -U postgres

CREATE DATABASE uirms
    WITH OWNER postgres
    ENCODING 'UTF8'
    LC_COLLATE 'en_US.UTF-8'
    LC_CTYPE 'en_US.UTF-8';
```

#### Step 2: Connect to Database
```bash
psql -U postgres -d uirms
```

#### Step 3: Install PostGIS
```sql
CREATE EXTENSION postgis;
CREATE EXTENSION postgis_topology;
CREATE EXTENSION uuid-ossp;

-- Verify PostGIS
SELECT postgis_version();
```

#### Step 4: Load Schema
```bash
# From command line
psql -U postgres -d uirms -f schema.sql

# Or from within psql
\i schema.sql
```

#### Step 5: Verify Installation
```sql
-- Check tables
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public';

-- Check sample data
SELECT COUNT(*) FROM users;
SELECT COUNT(*) FROM admins;
SELECT COUNT(*) FROM categories;
```

---

## Data Migration

### Migration Strategy

#### Phase 1: Backup Existing Data
```bash
# Backup schema only
pg_dump -U postgres -d old_database --schema-only > schema_backup.sql

# Backup data only
pg_dump -U postgres -d old_database --data-only > data_backup.sql

# Full backup
pg_dump -U postgres -d old_database > full_backup.sql
```

#### Phase 2: Transform Data
```sql
-- Create temporary tables for staging
CREATE TEMP TABLE users_staging AS
SELECT
    id,
    phone,
    email,
    password_hash,
    full_name,
    avatar_url,
    NOW() as is_verified,
    NULL as verification_code,
    bio,
    created_at,
    created_at as updated_at,
    NULL as deleted_at
FROM old_database.users;

-- Validate data
SELECT COUNT(*) FROM users_staging;
SELECT COUNT(*) FROM users_staging WHERE phone IS NULL; -- Should be 0
```

#### Phase 3: Load Data
```sql
-- Insert migrated data
INSERT INTO users (
    id, phone, email, password_hash, full_name, avatar_url,
    is_verified, verification_code, bio, created_at, updated_at, deleted_at
)
SELECT * FROM users_staging
ON CONFLICT (phone) DO NOTHING;

-- Reset sequences
SELECT setval('users_id_seq', (SELECT MAX(id) FROM users) + 1);
```

#### Phase 4: Validation
```sql
-- Count records
SELECT COUNT(*) as total_users FROM users;
SELECT COUNT(*) as total_incidents FROM incidents;

-- Check data integrity
SELECT COUNT(*) FROM incidents WHERE user_id NOT IN (SELECT id FROM users);
SELECT COUNT(*) FROM incidents WHERE category_id NOT IN (SELECT id FROM categories);
```

### Example Migration Script
```bash
#!/bin/bash

# Backup old database
pg_dump -U postgres -d old_uirms > old_uirms_backup.sql

# Create fresh database
psql -U postgres -c "DROP DATABASE IF EXISTS uirms;"
psql -U postgres -c "CREATE DATABASE uirms;"

# Load new schema
psql -U postgres -d uirms -f schema.sql

# Restore data (if needed)
# psql -U postgres -d uirms -f data_migration.sql

echo "Migration complete!"
```

---

## Testing & Validation

### Schema Validation

#### Check All Tables Exist
```sql
SELECT COUNT(*) FROM information_schema.tables 
WHERE table_schema = 'public';
-- Should return 8
```

#### Check All Indexes
```sql
SELECT COUNT(*) FROM pg_indexes 
WHERE schemaname = 'public';
-- Should be 20+
```

#### Check Functions
```sql
SELECT COUNT(*) FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_type = 'FUNCTION';
-- Should be 5+
```

#### Check Triggers
```sql
SELECT COUNT(*) FROM information_schema.triggers 
WHERE trigger_schema = 'public';
-- Should be 4
```

### Data Validation

#### Check Sample Data
```sql
-- Users
SELECT COUNT(*) FROM users;
SELECT COUNT(*) FROM users WHERE is_verified = true;

-- Admins
SELECT COUNT(*) FROM admins WHERE role = 'technician';

-- Categories
SELECT COUNT(*) FROM categories WHERE is_active = true;

-- Incidents
SELECT COUNT(*) FROM incidents WHERE status = 'pending';
```

#### Check Spatial Data
```sql
-- Verify PostGIS geometry
SELECT COUNT(*) FROM incidents WHERE location_point IS NOT NULL;
SELECT COUNT(*) FROM technicians WHERE area_zone IS NOT NULL;

-- Test spatial function
SELECT * FROM get_incidents_near_location(10.7755, 106.6878, 5000);
```

### Performance Testing

#### Query Performance
```sql
-- Test incident retrieval
EXPLAIN ANALYZE
SELECT * FROM incidents 
WHERE status = 'pending' 
ORDER BY created_at DESC 
LIMIT 10;

-- Test nearby incidents
EXPLAIN ANALYZE
SELECT * FROM get_incidents_near_location(10.7755, 106.6878, 5000);

-- Test dashboard stats
EXPLAIN ANALYZE
SELECT * FROM admin_dashboard_stats 
WHERE report_date >= CURRENT_DATE - INTERVAL '30 days';
```

#### Index Usage
```sql
-- Check if indexes are being used
SELECT schemaname, tablename, indexname, idx_scan 
FROM pg_stat_user_indexes 
ORDER BY idx_scan DESC;
```

---

## Troubleshooting

### Connection Issues

#### "Could not connect to server"
```bash
# Check if PostgreSQL is running
sudo systemctl status postgresql  # Linux
brew services list              # macOS
services.msc                    # Windows

# Start PostgreSQL
sudo systemctl start postgresql
```

#### "Role does not exist"
```sql
-- Create missing role
CREATE ROLE uirms_app WITH PASSWORD 'password' LOGIN;
```

#### "Database does not exist"
```bash
# List databases
psql -U postgres -l

# Create database
createdb -U postgres uirms
```

### Schema Issues

#### "Extension postgis does not exist"
```bash
# Install PostGIS package
sudo apt-get install postgresql-14-postgis

# Create extension
psql -U postgres -d uirms -c "CREATE EXTENSION postgis;"
```

#### "Syntax error in SQL script"
```bash
# Check PostgreSQL version compatibility
psql --version

# Run with verbose output
psql -U postgres -d uirms -f schema.sql -v ON_ERROR_STOP=1
```

#### Foreign Key Constraint Violation
```sql
-- Check constraint
SELECT constraint_name, table_name 
FROM information_schema.table_constraints 
WHERE constraint_type = 'FOREIGN KEY';

-- Disable temporarily during migration
ALTER TABLE incidents DISABLE TRIGGER ALL;
-- ... do work ...
ALTER TABLE incidents ENABLE TRIGGER ALL;
```

### Performance Issues

#### Slow Queries
```sql
-- Enable query logging
ALTER SYSTEM SET log_min_duration_statement = 1000;
SELECT pg_reload_conf();

-- View slow query logs
SELECT query, calls, total_time, mean_time 
FROM pg_stat_statements 
ORDER BY mean_time DESC LIMIT 10;
```

#### High Memory Usage
```sql
-- Optimize buffer settings
ALTER SYSTEM SET shared_buffers = '256MB';
ALTER SYSTEM SET effective_cache_size = '1GB';
SELECT pg_reload_conf();

-- Run VACUUM
VACUUM ANALYZE;
```

### Data Issues

#### Missing Records
```sql
-- Find orphaned records
SELECT * FROM incident_images 
WHERE incident_id NOT IN (SELECT id FROM incidents);

-- Count mismatches
SELECT COUNT(*) FROM incidents 
WHERE user_id NOT IN (SELECT id FROM users);
```

#### Duplicate Data
```sql
-- Find duplicates
SELECT phone, COUNT(*) 
FROM users 
GROUP BY phone 
HAVING COUNT(*) > 1;

-- Remove duplicates
DELETE FROM users u1 
WHERE u1.ctid > (
    SELECT min(u2.ctid) 
    FROM users u2 
    WHERE u1.phone = u2.phone
);
```

---

## Maintenance

### Regular Backups

#### Automated Daily Backup (Linux/macOS)
```bash
# Create backup script: /usr/local/bin/backup_uirms.sh
#!/bin/bash
BACKUP_DIR="/backups/uirms"
DATE=$(date +%Y%m%d_%H%M%S)
pg_dump -U postgres -d uirms | gzip > $BACKUP_DIR/uirms_$DATE.sql.gz

# Add to crontab
crontab -e
# Add: 0 2 * * * /usr/local/bin/backup_uirms.sh
```

#### Windows Scheduled Task
```batch
:: Create backup script: C:\backups\backup_uirms.bat
@echo off
set DATE=%date:~-4%%date:~-10,2%%date:~-7,2%
set TIME=%time::=%
pg_dump -U postgres -d uirms > C:\backups\uirms_%DATE%_%TIME%.sql

REM Schedule using Task Scheduler
```

#### Restore from Backup
```bash
# Stop application
sudo systemctl stop uirms-app

# Drop and recreate database
psql -U postgres -c "DROP DATABASE uirms;"
psql -U postgres -c "CREATE DATABASE uirms;"

# Restore backup
psql -U postgres -d uirms < backup_file.sql

# Start application
sudo systemctl start uirms-app
```

### Regular Maintenance

#### Daily
```sql
-- Log errors and slow queries
-- Review pg_stat_statements
SELECT query, calls FROM pg_stat_statements ORDER BY calls DESC LIMIT 10;
```

#### Weekly
```sql
-- Analyze query plans for optimization
-- Check for long-running transactions
SELECT pid, usename, application_name, state, query_start 
FROM pg_stat_activity WHERE state != 'idle';
```

#### Monthly
```sql
-- Full maintenance
VACUUM FULL ANALYZE;

-- Reindex if needed
REINDEX DATABASE uirms;

-- Update statistics
ANALYZE;
```

#### Quarterly
```sql
-- Archive old data
DELETE FROM incident_images 
WHERE created_at < CURRENT_DATE - INTERVAL '1 year'
AND incident_id IN (
    SELECT id FROM incidents WHERE status = 'completed'
);

-- Cleanup soft-deleted records
DELETE FROM users WHERE deleted_at < CURRENT_DATE - INTERVAL '90 days';
```

### Monitoring

#### Setup Monitoring (Using pg_stat_statements)
```sql
-- Enable extension
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- View top queries
SELECT query, calls, total_time, mean_time 
FROM pg_stat_statements 
ORDER BY calls DESC LIMIT 20;
```

#### Monitor Connections
```sql
-- Show current connections
SELECT datname, usename, application_name, state 
FROM pg_stat_activity;

-- Monitor locks
SELECT * FROM pg_stat_activity 
WHERE wait_event_type = 'Lock';
```

#### Monitor Table Size
```sql
-- Check table sizes
SELECT schemaname, tablename, pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

---

## Configuration Best Practices

### PostgreSQL Configuration (postgresql.conf)

```ini
# Connection settings
max_connections = 100
superuser_reserved_connections = 5

# Memory settings
shared_buffers = 256MB
effective_cache_size = 1GB
work_mem = 4MB
maintenance_work_mem = 64MB

# WAL settings
wal_buffers = 16MB
checkpoint_completion_target = 0.9
max_wal_size = 2GB

# Query planner
random_page_cost = 1.1
effective_io_concurrency = 200

# Logging
log_destination = 'stderr'
log_directory = '/var/log/postgresql'
logging_collector = on
log_line_prefix = '%t [%p] %u@%d '
log_min_duration_statement = 1000
```

### Application Connection Pool

#### Node.js with pg-pool
```javascript
const { Pool } = require('pg');

const pool = new Pool({
    user: 'uirms_app',
    host: 'localhost',
    database: 'uirms',
    password: 'password',
    port: 5432,
    max: 20,                    // Maximum connections
    idleTimeoutMillis: 30000,   // Close after 30 seconds idle
    connectionTimeoutMillis: 2000,
});

module.exports = pool;
```

---

## Emergency Recovery

### Corruption Detection
```sql
-- Check for data corruption
REINDEX SYSTEM uirms;

-- Verify table integrity
PRAGMA integrity_check;
```

### Point-in-Time Recovery (PITR)
```bash
# Restore to specific time
pg_restore -U postgres -d uirms \
    --target-timeline=base \
    --target-time='2024-01-15 14:30:00' \
    backup_file.dump
```

---

## Additional Resources

- [PostgreSQL Official Documentation](https://www.postgresql.org/docs/)
- [PostGIS Documentation](https://postgis.net/docs/)
- [pgAdmin Web Interface](https://www.pgadmin.org/)
- [DBeaver Community Edition](https://dbeaver.io/)

---

**Last Updated:** June 2026  
**Database Version:** PostgreSQL 14+  
**Maintainer:** UIRMS Team
