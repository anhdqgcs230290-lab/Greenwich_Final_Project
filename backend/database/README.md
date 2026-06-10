# UIRMS Database Schema Documentation

## Overview
Complete PostgreSQL 14+ database schema for Urban Incident Reporting & Management System (UIRMS) with PostGIS spatial support.

## Prerequisites
- PostgreSQL 14+
- PostGIS 3.0+
- psql client

## Quick Start

### 1. Install Extensions (First Time)
```bash
# Connect to PostgreSQL
psql -U postgres

# Create database
CREATE DATABASE uirms;

# Connect to the database
\c uirms

# Install extensions
CREATE EXTENSION postgis;
CREATE EXTENSION postgis_topology;
CREATE EXTENSION uuid-ossp;
```

### 2. Load Schema
```bash
# Load schema from the SQL file
psql -U postgres -d uirms -f schema.sql

# Or using stdin
cat schema.sql | psql -U postgres -d uirms
```

### 3. Verify Installation
```bash
psql -U postgres -d uirms -c "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';"
```

## Database Tables

### 1. **users** - Người dùng (Dân cư)
Stores information about citizens reporting incidents.

| Column | Type | Constraints | Description |
|--------|------|-----------|-------------|
| id | BIGSERIAL | PK | Unique identifier |
| phone | VARCHAR(20) | UNIQUE, NOT NULL | Phone number |
| email | VARCHAR(255) | UNIQUE | Email address |
| password_hash | VARCHAR(255) | NOT NULL | Hashed password |
| full_name | VARCHAR(255) | | Full name |
| avatar_url | TEXT | | Avatar URL |
| is_verified | BOOLEAN | DEFAULT false | Email verification status |
| verification_code | VARCHAR(10) | | Verification code |
| bio | TEXT | | User bio |
| created_at | TIMESTAMP TZ | DEFAULT NOW() | Creation timestamp |
| updated_at | TIMESTAMP TZ | DEFAULT NOW() | Last update timestamp |
| deleted_at | TIMESTAMP TZ | | Soft delete timestamp |

**Indexes:**
- idx_users_phone
- idx_users_email
- idx_users_created_at
- idx_users_deleted_at (partial)

---

### 2. **admins** - Quản trị viên & Nhân viên
Stores admin, manager, and technician information.

| Column | Type | Constraints | Description |
|--------|------|-----------|-------------|
| id | BIGSERIAL | PK | Unique identifier |
| username | VARCHAR(100) | UNIQUE, NOT NULL | Username |
| email | VARCHAR(255) | UNIQUE, NOT NULL | Email address |
| password_hash | VARCHAR(255) | NOT NULL | Hashed password |
| full_name | VARCHAR(255) | | Full name |
| role | admin_role ENUM | NOT NULL | 'super_admin', 'manager', 'technician' |
| is_active | BOOLEAN | DEFAULT true | Active status |
| last_login | TIMESTAMP TZ | | Last login timestamp |
| created_at | TIMESTAMP TZ | DEFAULT NOW() | Creation timestamp |
| updated_at | TIMESTAMP TZ | DEFAULT NOW() | Last update timestamp |

**Roles:**
- `super_admin`: Full system access
- `manager`: Can assign incidents, view reports
- `technician`: Can update incident status, view assigned incidents

**Indexes:**
- idx_admins_username
- idx_admins_email
- idx_admins_role
- idx_admins_is_active

---

### 3. **categories** - Phân loại sự cố
Incident categories (pothole, broken light, clogged drain, etc.).

| Column | Type | Constraints | Description |
|--------|------|-----------|-------------|
| id | SMALLSERIAL | PK | Unique identifier |
| name | VARCHAR(100) | UNIQUE, NOT NULL | Category name (e.g., "Ổ gà") |
| description | TEXT | | Description |
| icon_url | TEXT | | Icon URL |
| color_code | VARCHAR(7) | | Hex color code (#RRGGBB) |
| severity_weight | DECIMAL(3,2) | 0.1-2.0 | Severity multiplier for priority calculation |
| is_active | BOOLEAN | DEFAULT true | Active status |
| created_at | TIMESTAMP TZ | DEFAULT NOW() | Creation timestamp |

**Sample Categories:**
- Ổ gà (severity: 1.8)
- Đèn bị hư (severity: 1.2)
- Cống tắc (severity: 1.5)
- Rác trên đường (severity: 0.8)
- Cây cối hư hỏng (severity: 1.3)

**Indexes:**
- idx_categories_name
- idx_categories_is_active

---

### 4. **incidents** - Báo cáo sự cố
Main table storing incident reports with spatial data.

| Column | Type | Constraints | Description |
|--------|------|-----------|-------------|
| id | BIGSERIAL | PK | Unique identifier |
| user_id | BIGINT | FK(users), NOT NULL | Reporter user |
| category_id | SMALLINT | FK(categories), NOT NULL | Incident category |
| title | VARCHAR(255) | NOT NULL | Incident title |
| description | TEXT | | Detailed description |
| location_name | VARCHAR(255) | | Address/location name |
| location_point | GEOMETRY(Point, 4326) | | GPS coordinates (WGS84) |
| priority | incident_priority ENUM | DEFAULT 'medium' | 'low', 'medium', 'high', 'critical' |
| status | incident_status ENUM | DEFAULT 'pending' | 'pending', 'assigned', 'in_progress', 'completed', 'rejected' |
| assigned_to | BIGINT | FK(admins) | Assigned manager |
| assigned_technician | BIGINT | FK(admins) | Assigned technician |
| ai_confidence | DECIMAL(3,2) | 0.0-1.0 | AI classification confidence |
| ai_suggested_category | SMALLINT | FK(categories) | AI suggested category |
| is_duplicate | BOOLEAN | DEFAULT false | Duplicate flag |
| duplicate_of | BIGINT | FK(incidents) | Reference incident if duplicate |
| created_at | TIMESTAMP TZ | DEFAULT NOW() | Reporting timestamp |
| updated_at | TIMESTAMP TZ | DEFAULT NOW() | Last update timestamp |
| completed_at | TIMESTAMP TZ | | Completion timestamp |
| deleted_at | TIMESTAMP TZ | | Soft delete timestamp |

**Spatial Index:**
- idx_incidents_location_point (GIST)

**Other Indexes:**
- idx_incidents_user_id
- idx_incidents_category_id
- idx_incidents_status
- idx_incidents_priority
- idx_incidents_assigned_to
- idx_incidents_assigned_technician
- idx_incidents_created_at

---

### 5. **incident_images** - Ảnh sự cố
Stores images and AI analysis results for incidents.

| Column | Type | Constraints | Description |
|--------|------|-----------|-------------|
| id | BIGSERIAL | PK | Unique identifier |
| incident_id | BIGINT | FK(incidents), NOT NULL | Associated incident |
| image_url | TEXT | NOT NULL | S3/Cloud storage URL |
| ai_analysis | JSONB | | AI detection results {label, confidence, tags} |
| uploaded_by | BIGINT | FK(users) | Uploader user |
| is_before | BOOLEAN | DEFAULT true | Before/after fix indicator |
| created_at | TIMESTAMP TZ | DEFAULT NOW() | Upload timestamp |

**Index:**
- idx_incident_images_incident_id

---

### 6. **incident_updates** - Lịch sử cập nhật
Audit trail of incident status changes and comments.

| Column | Type | Constraints | Description |
|--------|------|-----------|-------------|
| id | BIGSERIAL | PK | Unique identifier |
| incident_id | BIGINT | FK(incidents), NOT NULL | Associated incident |
| old_status | VARCHAR(50) | | Previous status |
| new_status | VARCHAR(50) | NOT NULL | New status |
| comment | TEXT | | Update comment |
| updated_by | BIGINT | FK(admins), NOT NULL | Admin who updated |
| update_type | incident_update_type ENUM | NOT NULL | 'status_change', 'assignment', 'comment', 'image_added' |
| created_at | TIMESTAMP TZ | DEFAULT NOW() | Update timestamp |

**Indexes:**
- idx_incident_updates_incident_id
- idx_incident_updates_created_at

---

### 7. **technicians** - Thợ sửa chữa / Bộ phận
Technician profiles with service area and performance metrics.

| Column | Type | Constraints | Description |
|--------|------|-----------|-------------|
| id | BIGSERIAL | PK | Unique identifier |
| admin_id | BIGINT | FK(admins), UNIQUE | Reference to admin account |
| department | VARCHAR(100) | | Department/unit name |
| phone | VARCHAR(20) | | Phone number |
| area_zone | GEOMETRY(Polygon, 4326) | | Service area boundary (WGS84) |
| avg_resolution_time | DECIMAL(8,2) | | Average resolution time (minutes) |
| completed_incidents | INT | >= 0 | Total completed incidents |
| rating | DECIMAL(3,2) | 0-5 | User rating |
| created_at | TIMESTAMP TZ | DEFAULT NOW() | Record creation time |

**Spatial Index:**
- idx_technicians_area_zone (GIST)

**Other Index:**
- idx_technicians_admin_id

---

### 8. **notifications** - Thông báo
Push notifications and alerts for users.

| Column | Type | Constraints | Description |
|--------|------|-----------|-------------|
| id | BIGSERIAL | PK | Unique identifier |
| user_id | BIGINT | FK(users), NOT NULL | Recipient user |
| incident_id | BIGINT | FK(incidents) | Related incident |
| title | VARCHAR(255) | NOT NULL | Notification title |
| message | TEXT | NOT NULL | Notification message |
| notification_type | notification_type ENUM | NOT NULL | 'status_update', 'new_reply', 'system', 'reminder' |
| is_read | BOOLEAN | DEFAULT false | Read status |
| action_url | TEXT | | Deep link URL |
| created_at | TIMESTAMP TZ | DEFAULT NOW() | Creation timestamp |
| read_at | TIMESTAMP TZ | | Read timestamp |

**Indexes:**
- idx_notifications_user_id
- idx_notifications_is_read
- idx_notifications_created_at
- idx_notifications_user_created (composite)

---

## Views

### incidents_heatmap_data
Returns incident locations for heatmap visualization.

```sql
SELECT id, location_point, priority, status, created_at
FROM incidents
WHERE deleted_at IS NULL AND location_point IS NOT NULL;
```

### admin_dashboard_stats
Statistics for admin dashboard (incidents by date, status, category).

```sql
SELECT report_date, status, category_name, incident_count, critical_count
FROM incidents grouped by date, status, category;
```

### active_incidents_by_technician
Current workload for each technician.

```sql
SELECT technician_id, full_name, active_incidents_count, avg_resolution_time, rating
FROM technicians with active incidents;
```

---

## Functions

### `update_updated_at_column()`
Automatically updates `updated_at` timestamp on record modification.

**Usage:**
```sql
-- Trigger used on users, admins, incidents tables
```

---

### `calculate_incident_priority(severity_weight, created_at)`
Calculates dynamic priority based on category severity and time elapsed.

**Parameters:**
- `severity_weight`: Category severity (0.1-2.0)
- `created_at`: Incident creation time

**Returns:** incident_priority ('low', 'medium', 'high', 'critical')

**Algorithm:**
```
severity_score = severity_weight * (1 + hours_elapsed / 24)
If score >= 1.8: 'critical'
If score >= 1.3: 'high'
If score >= 0.8: 'medium'
Else: 'low'
```

---

### `get_incidents_near_location(latitude, longitude, distance_meters)`
Finds incidents within a specified radius.

**Parameters:**
- `latitude`: Latitude (WGS84)
- `longitude`: Longitude (WGS84)
- `distance_meters`: Search radius (default: 5000m)

**Returns:**
```
incident_id, title, distance_meters, status, priority
```

**Example:**
```sql
SELECT * FROM get_incidents_near_location(10.7755, 106.6878, 1000);
```

---

### `count_unread_notifications(user_id)`
Counts unread notifications for a user.

**Returns:** Integer count

**Example:**
```sql
SELECT count_unread_notifications(1);
```

---

### `mark_incident_completed(incident_id, comment)`
Marks incident as completed and updates technician statistics.

**Parameters:**
- `incident_id`: Incident ID
- `comment`: Completion comment (optional)

**Returns:** Boolean (true on success)

**Side Effects:**
- Updates incident status to 'completed'
- Sets completed_at timestamp
- Creates incident_update record
- Updates technician's completed_incidents and avg_resolution_time

**Example:**
```sql
SELECT mark_incident_completed(123, 'Pothole filled and repaved');
```

---

## Triggers

| Trigger | Table | Event | Function | Purpose |
|---------|-------|-------|----------|---------|
| trg_update_users_updated_at | users | BEFORE UPDATE | update_updated_at_column() | Auto-update timestamp |
| trg_update_admins_updated_at | admins | BEFORE UPDATE | update_updated_at_column() | Auto-update timestamp |
| trg_update_incidents_updated_at | incidents | BEFORE UPDATE | update_updated_at_column() | Auto-update timestamp |
| trg_incident_status_notification | incidents | AFTER UPDATE | create_notification_on_incident_update() | Create notification on status change |

---

## ENUM Types

### admin_role
```sql
'super_admin'    -- Full system access
'manager'        -- Can manage incidents and technicians
'technician'     -- Can update incident status
```

### incident_priority
```sql
'low'       -- Minor issues
'medium'    -- Standard issues
'high'      -- Urgent issues
'critical'  -- Emergency situations
```

### incident_status
```sql
'pending'       -- Reported, awaiting review
'assigned'      -- Assigned to technician
'in_progress'   -- Being worked on
'completed'     -- Fixed/resolved
'rejected'      -- Cannot be fixed or invalid
```

### incident_update_type
```sql
'status_change'  -- Status was changed
'assignment'     -- Assigned to technician
'comment'        -- Comment added
'image_added'    -- Image attached
```

### notification_type
```sql
'status_update'  -- Incident status changed
'new_reply'      -- New comment on incident
'system'         -- System notification
'reminder'       -- Reminder notification
```

---

## Constraints & Relationships

### Foreign Keys
- `incidents.user_id` → `users.id` (ON DELETE CASCADE)
- `incidents.category_id` → `categories.id` (ON DELETE RESTRICT)
- `incidents.assigned_to` → `admins.id` (ON DELETE SET NULL)
- `incidents.assigned_technician` → `admins.id` (ON DELETE SET NULL)
- `incident_images.incident_id` → `incidents.id` (ON DELETE CASCADE)
- `incident_images.uploaded_by` → `users.id` (ON DELETE SET NULL)
- `incident_updates.incident_id` → `incidents.id` (ON DELETE CASCADE)
- `incident_updates.updated_by` → `admins.id` (ON DELETE RESTRICT)
- `technicians.admin_id` → `admins.id` (ON DELETE CASCADE)
- `notifications.user_id` → `users.id` (ON DELETE CASCADE)
- `notifications.incident_id` → `incidents.id` (ON DELETE CASCADE)

### Unique Constraints
- `users(phone)`
- `users(email)` - if provided
- `admins(username)`
- `admins(email)`
- `categories(name)`
- `technicians(admin_id)`

### Check Constraints
- `users.email` - valid email format
- `admins.email` - valid email format
- `categories.severity_weight` - between 0.1 and 2.0
- `categories.color_code` - valid hex color (#RRGGBB)
- `incidents.ai_confidence` - between 0.0 and 1.0
- `technicians.completed_incidents` - >= 0
- `technicians.rating` - between 0 and 5

---

## PostGIS Spatial Features

### Spatial Columns
- `incidents.location_point` - Point geometry (WGS84 SRID 4326)
- `technicians.area_zone` - Polygon geometry (WGS84 SRID 4326)

### Common Spatial Queries

**Find incidents within 5km:**
```sql
SELECT * FROM get_incidents_near_location(10.7755, 106.6878, 5000);
```

**Find incidents in technician's zone:**
```sql
SELECT i.* FROM incidents i, technicians t
WHERE ST_Contains(t.area_zone, i.location_point)
AND t.admin_id = 42;
```

**Distance between two incidents:**
```sql
SELECT ST_Distance(i1.location_point, i2.location_point) * 111000 as meters
FROM incidents i1, incidents i2
WHERE i1.id = 1 AND i2.id = 2;
```

---

## Sample Data

The schema includes sample data for testing:

### Users (3 records)
- 0912345678 (Nguyễn Văn A)
- 0987654321 (Trần Thị B)
- 0934567890 (Phạm Văn C)

### Admins (4 records)
- admin_super (Super Admin)
- manager_1 (Manager)
- tech_1 (Technician)
- tech_2 (Technician)

### Categories (5 records)
- Ổ gà (severity: 1.8)
- Đèn bị hư (severity: 1.2)
- Cống tắc (severity: 1.5)
- Rác trên đường (severity: 0.8)
- Cây cối hư hỏng (severity: 1.3)

### Incidents (2 records)
- "Ổ gà lớn trên Đường A" (status: in_progress, priority: high)
- "Đèn đường chính không hoạt động" (status: pending, priority: medium)

---

## Backup & Restore

### Full Database Backup
```bash
pg_dump -U postgres -d uirms > uirms_backup.sql
```

### Restore from Backup
```bash
psql -U postgres < uirms_backup.sql
```

### Export Schema Only
```bash
pg_dump -U postgres -d uirms --schema-only > schema_only.sql
```

### Export Data Only
```bash
pg_dump -U postgres -d uirms --data-only > data_only.sql
```

---

## Performance Optimization

### Query Statistics
```sql
-- Analyze query performance
EXPLAIN ANALYZE SELECT * FROM incidents WHERE status = 'pending';

-- Update statistics
VACUUM ANALYZE;
```

### Maintenance
```sql
-- Reindex tables (occasionally)
REINDEX DATABASE uirms;

-- Full vacuum (during maintenance window)
VACUUM FULL ANALYZE;
```

---

## Troubleshooting

### PostGIS Not Found
```bash
# Install PostGIS
sudo apt-get install postgresql-14-postgis
```

### Connection Issues
```bash
# Test connection
psql -U postgres -d uirms -c "SELECT 1;"
```

### Performance Issues
```bash
# Check slow queries
EXPLAIN ANALYZE SELECT ...;

# Check missing indexes
SELECT schemaname, tablename, indexname FROM pg_indexes
WHERE schemaname = 'public';
```

---

## Additional Resources

- [PostgreSQL 14 Documentation](https://www.postgresql.org/docs/14/)
- [PostGIS Manual](https://postgis.net/docs/)
- [pgAdmin Web Interface](https://www.pgadmin.org/)
- [DBeaver Database Tool](https://dbeaver.io/)

---

**Last Updated:** June 2026  
**Database Version:** PostgreSQL 14+  
**PostGIS Version:** 3.0+  
**Schema Version:** 1.0
