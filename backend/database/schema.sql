/* =========================================================================
   UIRMS (Urban Incident Reporting & Management System)
   Complete PostgreSQL 14+ Database Schema with PostGIS Support
   ========================================================================= */

-- =========================================================================
-- 1. EXTENSIONS
-- =========================================================================
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_topology;
CREATE EXTENSION IF NOT EXISTS uuid-ossp;


-- =========================================================================
-- 2. ENUM TYPES
-- =========================================================================

-- Admin role enum
CREATE TYPE admin_role AS ENUM ('super_admin', 'manager', 'technician');

-- Incident priority enum
CREATE TYPE incident_priority AS ENUM ('low', 'medium', 'high', 'critical');

-- Incident status enum
CREATE TYPE incident_status AS ENUM ('pending', 'assigned', 'in_progress', 'completed', 'rejected');

-- Incident update type enum
CREATE TYPE incident_update_type AS ENUM ('status_change', 'assignment', 'comment', 'image_added');

-- Notification type enum
CREATE TYPE notification_type AS ENUM ('status_update', 'new_reply', 'system', 'reminder');


-- =========================================================================
-- 3. TABLES
-- =========================================================================

-- TABLE: users (Người dùng - Dân cư)
-- Lưu trữ thông tin người dùng báo cáo sự cố
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    phone VARCHAR(20) NOT NULL UNIQUE,
    email VARCHAR(255) UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255),
    avatar_url TEXT,
    is_verified BOOLEAN DEFAULT false,
    verification_code VARCHAR(10),
    bio TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT email_format CHECK (email IS NULL OR email ~ '^[^@]+@[^@]+\.[^@]+$')
);

-- TABLE: admins (Quản trị viên & Nhân viên)
-- Lưu trữ thông tin admin, manager, và technician
CREATE TABLE admins (
    id BIGSERIAL PRIMARY KEY,
    username VARCHAR(100) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255),
    role admin_role NOT NULL DEFAULT 'manager',
    is_active BOOLEAN DEFAULT true,
    last_login TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT email_format CHECK (email ~ '^[^@]+@[^@]+\.[^@]+$')
);

-- TABLE: categories (Phân loại sự cố)
-- Ví dụ: Ổ gà, Đèn bị hư, Cống tắc, v.v.
CREATE TABLE categories (
    id SMALLSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    icon_url TEXT,
    color_code VARCHAR(7) DEFAULT '#000000',
    severity_weight DECIMAL(3,2) NOT NULL DEFAULT 1.0
        CHECK (severity_weight >= 0.1 AND severity_weight <= 2.0),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT valid_hex_color CHECK (color_code ~ '^#[0-9A-Fa-f]{6}$')
);

-- TABLE: incidents (Báo cáo sự cố)
-- Lưu trữ thông tin báo cáo sự cố từ người dùng
CREATE TABLE incidents (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    category_id SMALLINT NOT NULL REFERENCES categories(id) ON DELETE RESTRICT,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    location_name VARCHAR(255),
    location_point GEOMETRY(Point, 4326),
    priority incident_priority NOT NULL DEFAULT 'medium',
    status incident_status NOT NULL DEFAULT 'pending',
    assigned_to BIGINT REFERENCES admins(id) ON DELETE SET NULL,
    assigned_technician BIGINT REFERENCES admins(id) ON DELETE SET NULL,
    ai_confidence DECIMAL(3,2) DEFAULT NULL CHECK (ai_confidence IS NULL OR (ai_confidence >= 0.0 AND ai_confidence <= 1.0)),
    ai_suggested_category SMALLINT REFERENCES categories(id) ON DELETE SET NULL,
    is_duplicate BOOLEAN DEFAULT false,
    duplicate_of BIGINT REFERENCES incidents(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- TABLE: incident_images (Ảnh của sự cố)
-- Lưu trữ URL ảnh và kết quả phân tích AI
CREATE TABLE incident_images (
    id BIGSERIAL PRIMARY KEY,
    incident_id BIGINT NOT NULL REFERENCES incidents(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    ai_analysis JSONB,
    uploaded_by BIGINT REFERENCES users(id) ON DELETE SET NULL,
    is_before BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- TABLE: incident_updates (Lịch sử cập nhật sự cố)
-- Lưu trữ lịch sử thay đổi trạng thái và bình luận
CREATE TABLE incident_updates (
    id BIGSERIAL PRIMARY KEY,
    incident_id BIGINT NOT NULL REFERENCES incidents(id) ON DELETE CASCADE,
    old_status VARCHAR(50),
    new_status VARCHAR(50) NOT NULL,
    comment TEXT,
    updated_by BIGINT NOT NULL REFERENCES admins(id) ON DELETE RESTRICT,
    update_type incident_update_type NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- TABLE: technicians (Thợ sửa chữa / Bộ phận)
-- Lưu trữ thông tin thợ sửa chữa và khu vực phụ trách
CREATE TABLE technicians (
    id BIGSERIAL PRIMARY KEY,
    admin_id BIGINT NOT NULL UNIQUE REFERENCES admins(id) ON DELETE CASCADE,
    department VARCHAR(100),
    phone VARCHAR(20),
    area_zone GEOMETRY(Polygon, 4326),
    avg_resolution_time DECIMAL(8,2) DEFAULT 0,
    completed_incidents INT DEFAULT 0 CHECK (completed_incidents >= 0),
    rating DECIMAL(3,2) DEFAULT 0 CHECK (rating >= 0 AND rating <= 5),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- TABLE: notifications (Thông báo)
-- Lưu trữ thông báo gửi tới người dùng
CREATE TABLE notifications (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    incident_id BIGINT REFERENCES incidents(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    notification_type notification_type NOT NULL,
    is_read BOOLEAN DEFAULT false,
    action_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    read_at TIMESTAMP WITH TIME ZONE
);


-- =========================================================================
-- 4. INDEXES (Tối ưu hóa truy vấn)
-- =========================================================================

-- Users indexes
CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_created_at ON users(created_at);
CREATE INDEX idx_users_deleted_at ON users(deleted_at) WHERE deleted_at IS NULL;

-- Admins indexes
CREATE INDEX idx_admins_username ON admins(username);
CREATE INDEX idx_admins_email ON admins(email);
CREATE INDEX idx_admins_role ON admins(role);
CREATE INDEX idx_admins_is_active ON admins(is_active);

-- Categories indexes
CREATE INDEX idx_categories_name ON categories(name);
CREATE INDEX idx_categories_is_active ON categories(is_active);

-- Incidents indexes
CREATE INDEX idx_incidents_user_id ON incidents(user_id);
CREATE INDEX idx_incidents_category_id ON incidents(category_id);
CREATE INDEX idx_incidents_status ON incidents(status);
CREATE INDEX idx_incidents_priority ON incidents(priority);
CREATE INDEX idx_incidents_assigned_to ON incidents(assigned_to);
CREATE INDEX idx_incidents_assigned_technician ON incidents(assigned_technician);
CREATE INDEX idx_incidents_created_at ON incidents(created_at);
CREATE INDEX idx_incidents_deleted_at ON incidents(deleted_at) WHERE deleted_at IS NULL;
-- Spatial index for location queries
CREATE INDEX idx_incidents_location_point ON incidents USING GIST(location_point);

-- Incident images indexes
CREATE INDEX idx_incident_images_incident_id ON incident_images(incident_id);

-- Incident updates indexes
CREATE INDEX idx_incident_updates_incident_id ON incident_updates(incident_id);
CREATE INDEX idx_incident_updates_created_at ON incident_updates(created_at);

-- Technicians indexes
CREATE INDEX idx_technicians_admin_id ON technicians(admin_id);
-- Spatial index for area zone queries
CREATE INDEX idx_technicians_area_zone ON technicians USING GIST(area_zone);

-- Notifications indexes
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);
CREATE INDEX idx_notifications_created_at ON notifications(created_at);
CREATE INDEX idx_notifications_user_created ON notifications(user_id, created_at DESC);


-- =========================================================================
-- 5. VIEWS
-- =========================================================================

-- VIEW: incidents_heatmap_data
-- Dữ liệu cho bản đồ nhiệt độ (heatmap)
CREATE VIEW incidents_heatmap_data AS
SELECT
    id,
    location_point,
    priority,
    status,
    created_at
FROM incidents
WHERE deleted_at IS NULL AND location_point IS NOT NULL;

-- VIEW: admin_dashboard_stats
-- Thống kê cho dashboard admin
CREATE VIEW admin_dashboard_stats AS
SELECT
    DATE_TRUNC('day', i.created_at)::DATE AS report_date,
    i.status,
    c.name AS category_name,
    COUNT(*) AS incident_count,
    COUNT(CASE WHEN i.priority = 'critical' THEN 1 END) AS critical_count
FROM incidents i
JOIN categories c ON i.category_id = c.id
WHERE i.deleted_at IS NULL
GROUP BY DATE_TRUNC('day', i.created_at)::DATE, i.status, c.name;

-- VIEW: active_incidents_by_technician
-- Những sự cố đang xử lý theo từng thợ
CREATE VIEW active_incidents_by_technician AS
SELECT
    t.id AS technician_id,
    a.full_name,
    COUNT(i.id) AS active_incidents_count,
    t.avg_resolution_time,
    t.rating
FROM technicians t
JOIN admins a ON t.admin_id = a.id
LEFT JOIN incidents i ON i.assigned_technician = a.id AND i.status IN ('assigned', 'in_progress')
GROUP BY t.id, a.full_name, t.avg_resolution_time, t.rating;


-- =========================================================================
-- 6. FUNCTIONS
-- =========================================================================

-- FUNCTION: update_updated_at_column()
-- Tự động cập nhật timestamp updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- FUNCTION: calculate_incident_priority()
-- Tính toán độ ưu tiên dựa trên category severity + thời gian elapsed
CREATE OR REPLACE FUNCTION calculate_incident_priority(
    p_severity_weight DECIMAL,
    p_created_at TIMESTAMP WITH TIME ZONE
)
RETURNS incident_priority AS $$
DECLARE
    v_hours_elapsed DECIMAL;
    v_severity_score DECIMAL;
BEGIN
    v_hours_elapsed := EXTRACT(EPOCH FROM (NOW() - p_created_at)) / 3600.0;
    v_severity_score := p_severity_weight * (1 + (v_hours_elapsed / 24.0));

    IF v_severity_score >= 1.8 THEN
        RETURN 'critical'::incident_priority;
    ELSIF v_severity_score >= 1.3 THEN
        RETURN 'high'::incident_priority;
    ELSIF v_severity_score >= 0.8 THEN
        RETURN 'medium'::incident_priority;
    ELSE
        RETURN 'low'::incident_priority;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- FUNCTION: get_incidents_near_location()
-- Lấy các sự cố gần một vị trí (distance in meters)
CREATE OR REPLACE FUNCTION get_incidents_near_location(
    p_latitude DECIMAL,
    p_longitude DECIMAL,
    p_distance_meters INT DEFAULT 5000
)
RETURNS TABLE (
    incident_id BIGINT,
    title VARCHAR,
    distance_meters NUMERIC,
    status incident_status,
    priority incident_priority
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        i.id,
        i.title,
        ROUND(ST_Distance(i.location_point, ST_SetSRID(ST_MakePoint(p_longitude, p_latitude), 4326))::NUMERIC * 1000, 2),
        i.status,
        i.priority
    FROM incidents i
    WHERE i.deleted_at IS NULL
        AND i.location_point IS NOT NULL
        AND ST_DWithin(
            i.location_point,
            ST_SetSRID(ST_MakePoint(p_longitude, p_latitude), 4326),
            p_distance_meters / 1000.0,
            true
        )
    ORDER BY distance_meters ASC;
END;
$$ LANGUAGE plpgsql;

-- FUNCTION: count_unread_notifications()
-- Đếm số thông báo chưa đọc của người dùng
CREATE OR REPLACE FUNCTION count_unread_notifications(p_user_id BIGINT)
RETURNS INT AS $$
DECLARE
    v_count INT;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM notifications
    WHERE user_id = p_user_id AND is_read = false;
    RETURN v_count;
END;
$$ LANGUAGE plpgsql;

-- FUNCTION: mark_incident_completed()
-- Đánh dấu sự cố là hoàn tất và tính thống kê
CREATE OR REPLACE FUNCTION mark_incident_completed(
    p_incident_id BIGINT,
    p_comment TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    v_admin_id BIGINT;
    v_technician_id BIGINT;
    v_resolution_minutes DECIMAL;
BEGIN
    -- Get admin who will update
    SELECT id INTO v_admin_id FROM admins WHERE role = 'super_admin' LIMIT 1;

    -- Get technician and calculate resolution time
    SELECT i.assigned_technician, EXTRACT(EPOCH FROM (NOW() - i.created_at)) / 60.0
    INTO v_technician_id, v_resolution_minutes
    FROM incidents i
    WHERE i.id = p_incident_id;

    -- Update incident status
    UPDATE incidents
    SET status = 'completed'::incident_status,
        completed_at = NOW()
    WHERE id = p_incident_id;

    -- Create update record
    INSERT INTO incident_updates (incident_id, old_status, new_status, comment, updated_by, update_type)
    VALUES (p_incident_id, 'in_progress', 'completed', p_comment, v_admin_id, 'status_change'::incident_update_type);

    -- Update technician stats
    IF v_technician_id IS NOT NULL THEN
        UPDATE technicians
        SET completed_incidents = completed_incidents + 1,
            avg_resolution_time = (
                CASE
                    WHEN completed_incidents = 0 THEN v_resolution_minutes
                    ELSE (avg_resolution_time * completed_incidents + v_resolution_minutes) / (completed_incidents + 1)
                END
            )
        WHERE admin_id = v_technician_id;
    END IF;

    RETURN true;
END;
$$ LANGUAGE plpgsql;


-- =========================================================================
-- 7. TRIGGERS
-- =========================================================================

-- TRIGGER: update_users_updated_at
CREATE TRIGGER trg_update_users_updated_at
BEFORE UPDATE ON users
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- TRIGGER: update_admins_updated_at
CREATE TRIGGER trg_update_admins_updated_at
BEFORE UPDATE ON admins
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- TRIGGER: update_incidents_updated_at
CREATE TRIGGER trg_update_incidents_updated_at
BEFORE UPDATE ON incidents
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- TRIGGER: create_notification_on_incident_update
-- Tạo thông báo khi cập nhật sự cố
CREATE OR REPLACE FUNCTION create_notification_on_incident_update()
RETURNS TRIGGER AS $$
DECLARE
    v_user_id BIGINT;
    v_incident_title VARCHAR;
BEGIN
    IF NEW.status IS DISTINCT FROM OLD.status THEN
        SELECT user_id, title INTO v_user_id, v_incident_title
        FROM incidents
        WHERE id = NEW.id;

        INSERT INTO notifications (
            user_id, incident_id, title, message, notification_type, action_url
        ) VALUES (
            v_user_id,
            NEW.id,
            'Cập nhật sự cố',
            'Sự cố "' || v_incident_title || '" đã được cập nhật sang trạng thái: ' || NEW.status,
            'status_update'::notification_type,
            '/incidents/' || NEW.id
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_incident_status_notification
AFTER UPDATE ON incidents
FOR EACH ROW
EXECUTE FUNCTION create_notification_on_incident_update();


-- =========================================================================
-- 8. SAMPLE DATA
-- =========================================================================

-- Insert sample users
INSERT INTO users (phone, email, password_hash, full_name, is_verified, bio)
VALUES
    ('0912345678', 'user1@example.com', '$2b$10$abcdefghijklmnopqrstuvwxyz', 'Nguyễn Văn A', true, 'Tôi muốn báo cáo các sự cố trên đường phố'),
    ('0987654321', 'user2@example.com', '$2b$10$abcdefghijklmnopqrstuvwxyz', 'Trần Thị B', true, 'Cư dân tại Quận 1'),
    ('0934567890', 'user3@example.com', '$2b$10$abcdefghijklmnopqrstuvwxyz', 'Phạm Văn C', false, NULL)
ON CONFLICT (phone) DO NOTHING;

-- Insert sample admins
INSERT INTO admins (username, email, password_hash, full_name, role, is_active)
VALUES
    ('admin_super', 'admin@uirms.com', '$2b$10$abcdefghijklmnopqrstuvwxyz', 'Lê Văn Admin', 'super_admin', true),
    ('manager_1', 'manager1@uirms.com', '$2b$10$abcdefghijklmnopqrstuvwxyz', 'Võ Thị Manager', 'manager', true),
    ('tech_1', 'tech1@uirms.com', '$2b$10$abcdefghijklmnopqrstuvwxyz', 'Hoàng Văn Kỹ Thuật', 'technician', true),
    ('tech_2', 'tech2@uirms.com', '$2b$10$abcdefghijklmnopqrstuvwxyz', 'Bùi Thị Kỹ Thuật', 'technician', true)
ON CONFLICT (username) DO NOTHING;

-- Insert sample categories
INSERT INTO categories (name, description, icon_url, color_code, severity_weight)
VALUES
    ('Ổ gà', 'Lỗ hổng trên đường', '/icons/pothole.svg', '#D32F2F', 1.8),
    ('Đèn bị hư', 'Đèn giao thông hoặc đèn đường không hoạt động', '/icons/light.svg', '#F57C00', 1.2),
    ('Cống tắc', 'Hệ thống thoát nước bị tắc', '/icons/drain.svg', '#1976D2', 1.5),
    ('Rác trên đường', 'Rác thải tại các nơi công cộng', '/icons/trash.svg', '#7CB342', 0.8),
    ('Cây cối hư hỏng', 'Cây cối bị gãy hoặc nguy hiểm', '/icons/tree.svg', '#388E3C', 1.3)
ON CONFLICT (name) DO NOTHING;

-- Insert sample incidents (using DO block to handle dynamic data)
DO $$
DECLARE
    v_user_id BIGINT;
    v_manager_id BIGINT;
    v_category_id SMALLINT;
BEGIN
    -- Get sample IDs
    SELECT id INTO v_user_id FROM users WHERE phone = '0912345678' LIMIT 1;
    SELECT id INTO v_manager_id FROM admins WHERE username = 'manager_1' LIMIT 1;
    SELECT id INTO v_category_id FROM categories WHERE name = 'Ổ gà' LIMIT 1;

    IF v_user_id IS NOT NULL AND v_manager_id IS NOT NULL AND v_category_id IS NOT NULL THEN
        INSERT INTO incidents (user_id, category_id, title, description, location_name, location_point, priority, status, assigned_to)
        VALUES (
            v_user_id,
            v_category_id,
            'Ổ gà lớn trên Đường A',
            'Có một lỗ hổng rất lớn trên mặt đường, rất nguy hiểm',
            'Đường A, Quận 1, TP.HCM',
            ST_SetSRID(ST_MakePoint(106.6878, 10.7755), 4326),
            'high'::incident_priority,
            'in_progress'::incident_status,
            v_manager_id
        );
    END IF;
END $$;

DO $$
DECLARE
    v_user_id BIGINT;
    v_category_id SMALLINT;
BEGIN
    -- Get sample IDs
    SELECT id INTO v_user_id FROM users WHERE phone = '0987654321' LIMIT 1;
    SELECT id INTO v_category_id FROM categories WHERE name = 'Đèn bị hư' LIMIT 1;

    IF v_user_id IS NOT NULL AND v_category_id IS NOT NULL THEN
        INSERT INTO incidents (user_id, category_id, title, description, location_name, location_point, priority, status)
        VALUES (
            v_user_id,
            v_category_id,
            'Đèn đường chính không hoạt động',
            'Đèn giao thông tại ngã tư không sáng',
            'Ngã tư Trần Hưng Đạo, Quận 1',
            ST_SetSRID(ST_MakePoint(106.6969, 10.7744), 4326),
            'medium'::incident_priority,
            'pending'::incident_status
        );
    END IF;
END $$;

-- Insert sample incident image
DO $$
DECLARE
    v_incident_id BIGINT;
    v_user_id BIGINT;
BEGIN
    SELECT id INTO v_incident_id FROM incidents WHERE title = 'Ổ gà lớn trên Đường A' LIMIT 1;
    SELECT id INTO v_user_id FROM users WHERE phone = '0912345678' LIMIT 1;

    IF v_incident_id IS NOT NULL AND v_user_id IS NOT NULL THEN
        INSERT INTO incident_images (incident_id, image_url, ai_analysis, uploaded_by, is_before)
        VALUES (
            v_incident_id,
            'https://s3.amazonaws.com/uirms/incidents/image1.jpg',
            '{"label": "pothole", "confidence": 0.95, "tags": ["road_damage", "severe"]}'::JSONB,
            v_user_id,
            true
        );
    END IF;
END $$;

-- Insert sample technicians
DO $$
DECLARE
    v_tech1_id BIGINT;
    v_tech2_id BIGINT;
BEGIN
    SELECT id INTO v_tech1_id FROM admins WHERE username = 'tech_1' LIMIT 1;
    SELECT id INTO v_tech2_id FROM admins WHERE username = 'tech_2' LIMIT 1;

    IF v_tech1_id IS NOT NULL THEN
        INSERT INTO technicians (admin_id, department, phone, avg_resolution_time, completed_incidents, rating)
        VALUES (v_tech1_id, 'Bộ phận Cơ sở hạ tầng', '0912111111', 120.5, 15, 4.5)
        ON CONFLICT (admin_id) DO NOTHING;
    END IF;

    IF v_tech2_id IS NOT NULL THEN
        INSERT INTO technicians (admin_id, department, phone, avg_resolution_time, completed_incidents, rating)
        VALUES (v_tech2_id, 'Bộ phận Cơ sở hạ tầng', '0912222222', 95.3, 22, 4.7)
        ON CONFLICT (admin_id) DO NOTHING;
    END IF;
END $$;

-- Insert sample incident updates
DO $$
DECLARE
    v_incident_id BIGINT;
    v_manager_id BIGINT;
BEGIN
    SELECT id INTO v_incident_id FROM incidents WHERE title = 'Ổ gà lớn trên Đường A' LIMIT 1;
    SELECT id INTO v_manager_id FROM admins WHERE username = 'manager_1' LIMIT 1;

    IF v_incident_id IS NOT NULL AND v_manager_id IS NOT NULL THEN
        INSERT INTO incident_updates (incident_id, old_status, new_status, comment, updated_by, update_type)
        VALUES (
            v_incident_id,
            'pending',
            'assigned',
            'Đã gán cho nhân viên kỹ thuật',
            v_manager_id,
            'assignment'::incident_update_type
        );
    END IF;
END $$;

-- Insert sample notifications
DO $$
DECLARE
    v_incident_id BIGINT;
    v_user_id BIGINT;
BEGIN
    SELECT id INTO v_incident_id FROM incidents WHERE title = 'Ổ gà lớn trên Đường A' LIMIT 1;
    SELECT user_id INTO v_user_id FROM incidents WHERE id = v_incident_id LIMIT 1;

    IF v_incident_id IS NOT NULL AND v_user_id IS NOT NULL THEN
        INSERT INTO notifications (user_id, incident_id, title, message, notification_type, action_url)
        VALUES (
            v_user_id,
            v_incident_id,
            'Cập nhật sự cố',
            'Sự cố của bạn đã được tiếp nhận và gán cho nhân viên xử lý',
            'status_update'::notification_type,
            '/incidents/' || v_incident_id
        );
    END IF;
END $$;


-- =========================================================================
-- 9. PERMISSIONS & COMMENTS
-- =========================================================================

-- Add comments to tables
COMMENT ON TABLE users IS 'Lưu trữ thông tin người dùng (dân cư) báo cáo sự cố';
COMMENT ON TABLE admins IS 'Lưu trữ thông tin quản trị viên, manager, và nhân viên kỹ thuật';
COMMENT ON TABLE categories IS 'Phân loại các loại sự cố (ổ gà, đèn hư, cống tắc, v.v.)';
COMMENT ON TABLE incidents IS 'Báo cáo sự cố chính từ người dùng với vị trí địa lý';
COMMENT ON TABLE incident_images IS 'Ảnh của sự cố và kết quả phân tích AI';
COMMENT ON TABLE incident_updates IS 'Lịch sử cập nhật, bình luận, và thay đổi trạng thái';
COMMENT ON TABLE technicians IS 'Thông tin nhân viên kỹ thuật, khu vực phụ trách, và thống kê';
COMMENT ON TABLE notifications IS 'Thông báo gửi tới người dùng về trạng thái sự cố';

-- Add comments to key columns
COMMENT ON COLUMN incidents.location_point IS 'Tọa độ GPS (WGS84 SRID 4326) của sự cố, hỗ trợ tìm kiếm địa lý';
COMMENT ON COLUMN incidents.ai_confidence IS 'Độ chính xác của việc phân loại AI (0.0 - 1.0)';
COMMENT ON COLUMN technicians.area_zone IS 'Khu vực địa lý (Polygon) mà nhân viên kỹ thuật phụ trách';
COMMENT ON COLUMN categories.severity_weight IS 'Trọng số mức độ nghiêm trọng (0.1 - 2.0) dùng để tính ưu tiên';

-- =========================================================================
-- 10. INDEX STATISTICS & ANALYSIS
-- =========================================================================
-- VACUUM ANALYZE để cập nhật thống kê và tối ưu hóa truy vấn
-- Chạy sau khi insert sample data
-- VACUUM ANALYZE;

/*
SCHEMA SUMMARY:
- 8 bảng chính với relationships logic
- 3 ENUM types cho status, priority, notification_type
- 20+ indexes tối ưu hóa truy vấn (bao gồm spatial indexes)
- 3 views cho analytics và reporting
- 5 functions cho business logic
- 3 triggers cho tự động cập nhật
- Sample data cho 3 users, 4 admins, 5 categories
- Tất cả timestamp sử dụng UTC timezone
- ON DELETE CASCADE/SET NULL phù hợp với logic
- PostGIS support cho location-based queries
*/
