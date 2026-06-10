# UIRMS Database Schema - Complete Package Index

## 📦 Package Contents

This directory contains the complete PostgreSQL database schema for the Urban Incident Reporting & Management System (UIRMS).

### 📄 Documentation Files

#### 1. **SUMMARY.md** - START HERE
Quick overview of the project, features, and setup instructions.
- ✅ Best for: Quick understanding of what's included
- 📊 Contents: 8 tables, 20+ indexes, 5 functions, 4 triggers, 3 views
- ⏱️ Read time: 5 minutes

#### 2. **README.md** - Detailed Documentation
Complete reference guide with all table structures, views, and functions.
- ✅ Best for: Understanding schema design and relationships
- 📊 Contents: Full table reference, field definitions, constraints, examples
- ⏱️ Read time: 15-20 minutes

#### 3. **MIGRATION_GUIDE.md** - Setup & Migration
Step-by-step guide for installation, data migration, and maintenance.
- ✅ Best for: Setting up the database and migrating from other systems
- 📊 Contents: Installation, testing, troubleshooting, monitoring, backups
- ⏱️ Read time: 20-30 minutes

### 🗄️ SQL Files

#### 4. **schema.sql** - Database Schema (25.6 KB)
Complete SQL script with all database objects.

**Contains:**
- PostgreSQL extensions (PostGIS, uuid-ossp)
- 5 ENUM types for status, priority, and notifications
- 8 main tables with relationships
- 20+ performance indexes (B-tree and GiST spatial)
- 3 views for analytics and reporting
- 5 PL/pgSQL functions for business logic
- 4 triggers for automatic updates
- Comprehensive comments and documentation
- Sample data for testing (3 users, 4 admins, 5 categories, 2 incidents)

**Usage:**
```bash
# Linux/macOS
psql -U postgres -d uirms -f schema.sql

# Windows
psql -U postgres -d uirms -f schema.sql
```

### 🚀 Setup Scripts

#### 5. **setup.sh** - Linux/macOS Setup (4.6 KB)
Automated installation script for Unix-like systems.

**Features:**
- ✅ Creates database with proper encoding
- ✅ Installs PostGIS extension
- ✅ Loads schema automatically
- ✅ Verifies installation
- ✅ Provides helpful commands

**Usage:**
```bash
chmod +x setup.sh
./setup.sh uirms postgres localhost 5432
```

**Parameters:**
- `uirms` - Database name (default)
- `postgres` - Database user (default)
- `localhost` - Database host (default)
- `5432` - Database port (default)

#### 6. **setup.bat** - Windows Setup (3.9 KB)
Automated installation script for Windows systems.

**Features:**
- ✅ Creates database with proper encoding
- ✅ Installs PostGIS extension
- ✅ Loads schema automatically
- ✅ Verifies installation
- ✅ Provides helpful commands

**Usage:**
```batch
setup.bat uirms postgres localhost 5432
```

### ⚙️ Configuration

#### 7. **.env.database.template** - Environment Variables Template
Template file for database connection configuration.

**Usage:**
```bash
# Copy template to actual config
cp .env.database.template .env.database

# Edit with your credentials
nano .env.database
```

**Variables:**
- `DB_HOST` - PostgreSQL server hostname
- `DB_PORT` - PostgreSQL server port (default: 5432)
- `DB_NAME` - Database name (default: uirms)
- `DB_USER` - Database user (default: uirms_app)
- `DB_PASSWORD` - User password (REQUIRED)
- `DB_POOL_*` - Connection pool settings
- `DATABASE_URL` - Full connection string
- `BACKUP_*` - Backup configuration

---

## 🎯 Quick Start Guide

### Option 1: Automated Setup (Recommended)

#### On Windows:
```bash
cd backend\database
setup.bat
# Follow prompts
```

#### On Linux/macOS:
```bash
cd backend/database
chmod +x setup.sh
./setup.sh
# Follow prompts
```

### Option 2: Manual Setup

#### Step 1: Create Database
```bash
psql -U postgres
```

```sql
CREATE DATABASE uirms;
\c uirms
CREATE EXTENSION postgis;
CREATE EXTENSION uuid-ossp;
```

#### Step 2: Load Schema
```bash
psql -U postgres -d uirms -f schema.sql
```

#### Step 3: Verify
```bash
psql -U postgres -d uirms -c "SELECT COUNT(*) FROM users;"
```

---

## 📋 What's Included

### Tables (8 total)
| Table | Purpose | Rows | Keys |
|-------|---------|------|------|
| users | Citizens reporting incidents | 3 | PK, phone, email |
| admins | System staff | 4 | PK, username, email, role |
| categories | Incident types | 5 | PK, name, severity |
| incidents | Main incident reports | 2 | PK, FK user/category, spatial |
| incident_images | Incident photos | 1 | PK, FK incident, AI analysis |
| incident_updates | Audit trail | 1 | PK, FK incident |
| technicians | Service workers | 2 | PK, FK admin, spatial zone |
| notifications | User alerts | 1 | PK, FK user/incident |

### Indexes (20+)
- B-tree: phone, email, status, priority, created_at, etc.
- GiST (Spatial): location_point, area_zone
- Partial: deleted_at IS NULL
- Composite: user_id + created_at

### Views (3)
- `incidents_heatmap_data` - Location visualization
- `admin_dashboard_stats` - Statistics reporting
- `active_incidents_by_technician` - Workload tracking

### Functions (5)
- `update_updated_at_column()` - Auto-update timestamps
- `calculate_incident_priority()` - Dynamic priority
- `get_incidents_near_location()` - Spatial search
- `count_unread_notifications()` - User notifications
- `mark_incident_completed()` - Status update

### Triggers (4)
- Auto-update timestamps on INSERT/UPDATE
- Auto-create notifications on incident status change

### ENUM Types (5)
- admin_role: super_admin, manager, technician
- incident_priority: low, medium, high, critical
- incident_status: pending, assigned, in_progress, completed, rejected
- incident_update_type: status_change, assignment, comment, image_added
- notification_type: status_update, new_reply, system, reminder

---

## 🧪 Testing the Schema

### Verify Tables
```sql
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' ORDER BY table_name;
```

### Check Indexes
```sql
SELECT indexname FROM pg_indexes 
WHERE schemaname = 'public' ORDER BY indexname;
```

### Test Functions
```sql
SELECT * FROM get_incidents_near_location(10.7755, 106.6878, 5000);
SELECT count_unread_notifications(1);
```

### View Sample Data
```sql
SELECT * FROM users;
SELECT * FROM admin_dashboard_stats;
SELECT * FROM active_incidents_by_technician;
```

---

## 🔒 Security Considerations

### Password Security
- ✅ DO: Use strong passwords (min 16 characters)
- ✅ DO: Use environment variables for credentials
- ✅ DO: Enable SSL for production connections
- ❌ DON'T: Hardcode passwords in scripts
- ❌ DON'T: Commit credentials to version control

### Database User Permissions
```sql
-- Create application user
CREATE USER uirms_app WITH PASSWORD 'strong_password';

-- Grant limited permissions
GRANT CONNECT ON DATABASE uirms TO uirms_app;
GRANT USAGE ON SCHEMA public TO uirms_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO uirms_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO uirms_app;
```

### Row-Level Security (Optional)
```sql
-- Enable RLS for users table
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Users can only see their own records
CREATE POLICY user_isolation ON users
  USING (id = current_user_id());
```

---

## 📊 Schema Visualization

```
┌─────────────────────────────────────────────────────────────┐
│                    UIRMS Database Schema                    │
└─────────────────────────────────────────────────────────────┘

                           users (3)
                              │
                              ├─→ incidents (2) ←─── categories (5)
                              │        │
                              │        ├─→ incident_images (1)
                              │        ├─→ incident_updates (1)
                              │        └─→ notifications (1)
                              │
                              └─→ notifications (1)

                           admins (4)
                              │
                              ├─→ incidents (2) [assigned_to]
                              ├─→ incidents (2) [assigned_technician]
                              └─→ technicians (2) [1:1 via admin_id]

                        technicians (2)
                              │
                              └─→ Service Area (Polygon, GiST Index)

                        incidents (2)
                              │
                              └─→ Location (Point, GiST Index)
```

---

## 📝 Sample Data Included

### Users
```
Phone: 0912345678 | Email: user1@example.com | Name: Nguyễn Văn A | Verified: Yes
Phone: 0987654321 | Email: user2@example.com | Name: Trần Thị B | Verified: Yes
Phone: 0934567890 | Email: user3@example.com | Name: Phạm Văn C | Verified: No
```

### Admins
```
Username: admin_super | Role: super_admin   | Name: Lê Văn Admin
Username: manager_1   | Role: manager       | Name: Võ Thị Manager
Username: tech_1      | Role: technician    | Name: Hoàng Văn Kỹ Thuật
Username: tech_2      | Role: technician    | Name: Bùi Thị Kỹ Thuật
```

### Categories
```
Ổ gà (Pothole)              | Severity: 1.8 | Color: #D32F2F | Priority: HIGH
Đèn bị hư (Broken Light)    | Severity: 1.2 | Color: #F57C00 | Priority: MEDIUM
Cống tắc (Clogged Drain)    | Severity: 1.5 | Color: #1976D2 | Priority: HIGH
Rác trên đường (Trash)      | Severity: 0.8 | Color: #7CB342 | Priority: LOW
Cây cối hư hỏng (Damaged)   | Severity: 1.3 | Color: #388E3C | Priority: MEDIUM
```

### Incidents
```
"Ổ gà lớn trên Đường A"        | Status: in_progress | Priority: high    | Assigned
"Đèn đường chính không hoạt động" | Status: pending      | Priority: medium | Not assigned
```

---

## 🛠️ Troubleshooting

### Common Issues

#### "psql: command not found"
- Install PostgreSQL client
- Add PostgreSQL bin directory to PATH

#### "FATAL: database does not exist"
- Run setup script: `setup.sh` or `setup.bat`
- Or create manually: `createdb uirms`

#### "Extension postgis does not exist"
- Install PostGIS package
- Create extension: `CREATE EXTENSION postgis;`

#### Connection refused on port 5432
- Ensure PostgreSQL is running
- Check firewall settings
- Verify connection parameters

**See MIGRATION_GUIDE.md for detailed troubleshooting.**

---

## 📚 Documentation Index

| Document | Purpose | Read Time |
|----------|---------|-----------|
| SUMMARY.md | Overview & features | 5 min |
| README.md | Detailed schema reference | 15-20 min |
| MIGRATION_GUIDE.md | Setup & maintenance | 20-30 min |
| schema.sql | SQL implementation | Reference |
| setup.sh / setup.bat | Automated installation | Reference |

---

## 🔄 Maintenance Schedule

| When | What | Command |
|------|------|---------|
| Daily | Review logs | `tail -f /var/log/postgresql/` |
| Weekly | Update stats | `VACUUM ANALYZE;` |
| Monthly | Full maintenance | `VACUUM FULL ANALYZE;` |
| Quarterly | Archive old data | See MIGRATION_GUIDE.md |
| As needed | Backup | `pg_dump ... > backup.sql` |

---

## 📞 Quick Reference

### Connection String
```
postgresql://uirms_app:password@localhost:5432/uirms
```

### Create Database
```bash
createdb -U postgres uirms
```

### Load Schema
```bash
psql -U postgres -d uirms -f schema.sql
```

### Backup
```bash
pg_dump -U postgres -d uirms > backup.sql
```

### Restore
```bash
psql -U postgres -d uirms < backup.sql
```

### Connect
```bash
psql -U postgres -d uirms
```

---

## ✅ Verification Checklist

After setup, verify everything works:

- [ ] Database created: `psql -U postgres -d uirms -c "\l"`
- [ ] 8 tables created: `psql -U postgres -d uirms -c "\dt"`
- [ ] PostGIS working: `SELECT postgis_version();`
- [ ] Sample users exist: `SELECT COUNT(*) FROM users;` (should be 3)
- [ ] Functions callable: `SELECT count_unread_notifications(1);`
- [ ] Views accessible: `SELECT * FROM admin_dashboard_stats;`
- [ ] Spatial data: `SELECT COUNT(*) FROM incidents WHERE location_point IS NOT NULL;`

---

## 📄 Files Summary

| File | Size | Purpose |
|------|------|---------|
| schema.sql | 25.6 KB | Complete database schema |
| README.md | 17.4 KB | Detailed documentation |
| MIGRATION_GUIDE.md | 14.2 KB | Setup & migration guide |
| setup.sh | 4.6 KB | Linux/macOS setup script |
| setup.bat | 3.9 KB | Windows setup script |
| .env.database.template | 1.4 KB | Configuration template |
| INDEX.md | This file | Package overview |

**Total Package Size:** ~67 KB

---

## 🎓 Learning Resources

- [PostgreSQL Official Docs](https://www.postgresql.org/docs/14/)
- [PostGIS Manual](https://postgis.net/docs/)
- [Database Design Best Practices](https://www.postgresql.org/docs/14/sql-syntax.html)
- [pgAdmin Web Interface](https://www.pgadmin.org/)
- [DBeaver Community IDE](https://dbeaver.io/)

---

## 📞 Support

For questions or issues:

1. Check **MIGRATION_GUIDE.md** - Troubleshooting section
2. Review **README.md** - Detailed documentation
3. Consult PostgreSQL documentation
4. Check PostGIS manual for spatial queries

---

**Last Updated:** June 10, 2026  
**Schema Version:** 1.0  
**Status:** ✅ Production Ready  
**Tested On:** PostgreSQL 14+, PostGIS 3.0+
