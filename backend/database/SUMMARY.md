# UIRMS Database Schema - Summary

## 📋 Project Deliverables

This package contains a **complete PostgreSQL 14+ database schema** for the Urban Incident Reporting & Management System (UIRMS) with PostGIS spatial support.

### Files Included

1. **schema.sql** (25.6 KB)
   - Complete database schema with all tables, indexes, views, functions, and triggers
   - Sample data for testing (3 users, 4 admins, 5 categories, 2 incidents)
   - Comprehensive comments and documentation

2. **README.md** (17.4 KB)
   - Detailed documentation of all tables and fields
   - View and function specifications
   - Enum types and constraints
   - Query examples and best practices

3. **MIGRATION_GUIDE.md** (14.2 KB)
   - Step-by-step setup instructions
   - Data migration procedures
   - Testing and validation checklist
   - Troubleshooting guide
   - Maintenance procedures

4. **setup.sh** (4.6 KB)
   - Linux/macOS automated setup script
   - Database creation and schema loading
   - Installation verification

5. **setup.bat** (3.9 KB)
   - Windows automated setup script
   - Database creation and schema loading
   - Installation verification

---

## 🏗️ Schema Overview

### 8 Main Tables

| Table | Purpose | Records | Key Features |
|-------|---------|---------|--------------|
| **users** | Citizens reporting incidents | 3 sample | Phone verified, soft delete |
| **admins** | System staff (super_admin, manager, technician) | 4 sample | Role-based access |
| **categories** | Incident types (pothole, light, drain, etc.) | 5 sample | Severity weighting, color coding |
| **incidents** | Main incident reports | 2 sample | Spatial location, AI confidence, duplicate tracking |
| **incident_images** | Photos with AI analysis | 1 sample | JSONB AI results |
| **incident_updates** | Audit trail of changes | 1 sample | Status history, comments |
| **technicians** | Service workers with zones | 2 sample | Service area (Polygon), performance metrics |
| **notifications** | User alerts | 1 sample | Read tracking, action URLs |

### 20+ Indexes
- B-tree indexes on frequently searched fields
- GiST spatial indexes on location_point and area_zone
- Partial indexes on soft-deleted records

### 3 Views
- `incidents_heatmap_data` - Location visualization
- `admin_dashboard_stats` - Reporting statistics
- `active_incidents_by_technician` - Workload tracking

### 5 Functions
- `update_updated_at_column()` - Auto timestamp update
- `calculate_incident_priority()` - Dynamic priority calculation
- `get_incidents_near_location()` - Spatial queries
- `count_unread_notifications()` - User notifications
- `mark_incident_completed()` - Status update with stats

### 4 Triggers
- Auto-update timestamps on users, admins, incidents
- Auto-create notification on incident status change

### 5 ENUM Types
- `admin_role`: super_admin, manager, technician
- `incident_priority`: low, medium, high, critical
- `incident_status`: pending, assigned, in_progress, completed, rejected
- `incident_update_type`: status_change, assignment, comment, image_added
- `notification_type`: status_update, new_reply, system, reminder

---

## 🚀 Quick Start

### On Windows
```batch
cd backend\database
setup.bat uirms postgres localhost 5432
```

### On Linux/macOS
```bash
cd backend/database
chmod +x setup.sh
./setup.sh uirms postgres localhost 5432
```

### Manual Installation
```bash
# 1. Create database
psql -U postgres -c "CREATE DATABASE uirms;"

# 2. Connect and create extensions
psql -U postgres -d uirms -c "CREATE EXTENSION postgis;"

# 3. Load schema
psql -U postgres -d uirms -f schema.sql
```

---

## ✨ Key Features

### 1. **Spatial Support (PostGIS)**
```sql
-- Find incidents within 5km radius
SELECT * FROM get_incidents_near_location(10.7755, 106.6878, 5000);

-- Find incidents in technician's service zone
SELECT i.* FROM incidents i, technicians t
WHERE ST_Contains(t.area_zone, i.location_point)
AND t.admin_id = 42;
```

### 2. **Role-Based Access Control**
- **Super Admin**: Full system access
- **Manager**: Can assign incidents, view all reports
- **Technician**: Can update incident status, view assigned incidents

### 3. **AI Integration**
```sql
-- Store AI classification results
ai_confidence DECIMAL(3,2)      -- 0.00-1.00 confidence score
ai_suggested_category SMALLINT  -- AI recommended category
ai_analysis JSONB               -- Detailed results {label, confidence, tags}
```

### 4. **Dynamic Priority System**
Priority is calculated based on:
- Category severity weight (0.1-2.0)
- Time elapsed since reporting (increases over time)
- Score >= 1.8: Critical
- Score >= 1.3: High
- Score >= 0.8: Medium
- Score < 0.8: Low

### 5. **Incident Deduplication**
```sql
-- Mark as duplicate
is_duplicate BOOLEAN      -- Flag
duplicate_of BIGINT       -- Reference to original incident
```

### 6. **Soft Delete Support**
```sql
-- Records marked as deleted but retained for audit
deleted_at TIMESTAMP WITH TIME ZONE
-- Query active records: WHERE deleted_at IS NULL
```

### 7. **Comprehensive Audit Trail**
- All changes logged in `incident_updates`
- Update types: status_change, assignment, comment, image_added
- Tracks who changed what and when

### 8. **Performance Metrics**
```sql
-- Technician statistics
completed_incidents INT
avg_resolution_time DECIMAL(8,2)    -- Minutes
rating DECIMAL(3,2)                 -- 0-5 stars
```

---

## 📊 Data Model Relationships

```
users (1) ──────────► incidents (N)
         └──────────► notifications (N)

admins (1) ──────────► incidents (N) [assigned_to]
        ├──────────► incidents (N) [assigned_technician]
        └──────────► technicians (1:1)

categories (1) ──────────► incidents (N)
            └──────────► incidents (N) [ai_suggested_category]

incidents (1) ──────────► incident_images (N)
          ├──────────► incident_updates (N)
          └──────────► notifications (N)

users (1) ──────────► incident_images (N)

admins (1) ──────────► incident_updates (N)
```

---

## 🔒 Constraints & Integrity

### Foreign Key Relationships
- `incidents.user_id` → `users.id` (CASCADE delete)
- `incidents.category_id` → `categories.id` (RESTRICT delete)
- `incidents.assigned_technician` → `admins.id` (SET NULL)
- `technicians.admin_id` → `admins.id` (CASCADE delete)

### Data Validation
- Email format: `email ~ '^[^@]+@[^@]+\.[^@]+$'`
- Hex color: `color_code ~ '^#[0-9A-Fa-f]{6}$'`
- Severity weight: `0.1 <= severity_weight <= 2.0`
- AI confidence: `0.0 <= ai_confidence <= 1.0`
- Rating: `0 <= rating <= 5`

### Unique Constraints
- `users(phone)`, `users(email)`
- `admins(username)`, `admins(email)`
- `categories(name)`
- `technicians(admin_id)`

---

## 🧪 Testing

### Included Sample Data
- **3 Users**: Nguyễn Văn A, Trần Thị B, Phạm Văn C
- **4 Admins**: 1 super_admin, 1 manager, 2 technicians
- **5 Categories**: Ổ gà, Đèn bị hư, Cống tắc, Rác trên đường, Cây cối hư hỏng
- **2 Incidents**: One in_progress with images, one pending
- **Locations**: Vietnam (Ho Chi Minh City area - SRID 4326)

### Verification Queries
```sql
-- Verify all tables created
SELECT COUNT(*) FROM information_schema.tables 
WHERE table_schema = 'public';  -- Should return 8

-- Check sample data
SELECT COUNT(*) FROM users;              -- 3
SELECT COUNT(*) FROM admins;             -- 4
SELECT COUNT(*) FROM categories;         -- 5
SELECT COUNT(*) FROM incidents;          -- 2
SELECT COUNT(*) FROM technicians;        -- 2

-- Test spatial function
SELECT * FROM get_incidents_near_location(10.7755, 106.6878, 5000);

-- Test views
SELECT * FROM admin_dashboard_stats;
SELECT * FROM active_incidents_by_technician;
```

---

## 📈 Performance Optimizations

### Indexing Strategy
- **B-tree indexes**: Standard lookups (phone, email, status, priority, created_at)
- **GiST indexes**: Spatial queries (location_point, area_zone)
- **Partial indexes**: Soft-deleted records filtering
- **Composite indexes**: Multi-column searches

### Query Optimization Tips
```sql
-- Use created_at for date range queries
SELECT * FROM incidents 
WHERE created_at >= NOW() - INTERVAL '30 days';

-- Use spatial indexes for location searches
SELECT * FROM incidents 
WHERE ST_DWithin(location_point, point, 5000, true);

-- Use EXPLAIN ANALYZE
EXPLAIN ANALYZE SELECT ...;
```

### Maintenance
```sql
-- Update statistics
VACUUM ANALYZE;

-- Reindex periodically
REINDEX DATABASE uirms;

-- Monitor slow queries
SELECT query, mean_time FROM pg_stat_statements 
ORDER BY mean_time DESC LIMIT 10;
```

---

## 🔄 Migration Path

### From Legacy System
1. Export existing data
2. Create staging tables
3. Transform and validate data
4. Load into new schema
5. Verify referential integrity
6. Switch application connection

See **MIGRATION_GUIDE.md** for detailed procedures.

---

## 🛠️ Maintenance Schedule

| Frequency | Task | Command |
|-----------|------|---------|
| Daily | Monitor logs | Check pg logs |
| Weekly | Analyze queries | `ANALYZE;` |
| Monthly | Full maintenance | `VACUUM FULL ANALYZE;` |
| Quarterly | Archive old data | Delete completed incidents > 1 year |
| Quarterly | Backup | `pg_dump -Fc uirms > backup.dump` |
| Yearly | Upgrade PostgreSQL | Test on staging first |

---

## 📞 Support & Documentation

- **PostgreSQL Docs**: https://www.postgresql.org/docs/14/
- **PostGIS Manual**: https://postgis.net/docs/
- **Database Design**: See README.md
- **Migration Help**: See MIGRATION_GUIDE.md
- **SQL Examples**: See README.md "Views" and "Functions" sections

---

## 📝 Version Information

- **Schema Version**: 1.0
- **PostgreSQL**: 14.0+
- **PostGIS**: 3.0+
- **Created**: June 2026
- **Status**: Production Ready

---

## 🎯 Next Steps

1. **For Development Setup**:
   - Run setup script: `setup.sh` or `setup.bat`
   - Verify with test queries from README.md
   - Load sample data (included in schema.sql)

2. **For Production Deployment**:
   - Read MIGRATION_GUIDE.md
   - Plan backup strategy
   - Configure connection pooling
   - Set up monitoring
   - Test failover procedures

3. **For Application Integration**:
   - Use connection string: `postgresql://user:pass@host:port/uirms`
   - Implement connection pooling (pg-pool, PgBouncer)
   - Map application entities to database tables
   - Test with sample data provided

---

**Schema Created By**: Copilot CLI  
**Last Updated**: June 10, 2026  
**Maintenance**: Automatic triggers and functions included  
**Backup**: Highly recommended (scripts included)
