
-- ============================================
-- SETUP DATABASE HOTEL NUSANTARA
-- ============================================

-- Create database jika belum ada
-- CREATE DATABASE hotel_nusantara
--   WITH 
--   OWNER = postgres
--   ENCODING = 'UTF8'
--   LC_COLLATE = 'en_US.UTF-8'
--   LC_CTYPE = 'en_US.UTF-8'
--   TABLESPACE = pg_default
--   CONNECTION LIMIT = -1
--   IS_TEMPLATE = False;

-- \c hotel_nusantara

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS btree_gist;
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS tablefunc;

-- Set optimal parameters untuk booking system
ALTER DATABASE hotel_nusantara SET timezone TO 'Asia/Jakarta';
ALTER DATABASE hotel_nusantara SET datestyle TO 'ISO, DMY';
ALTER DATABASE hotel_nusantara SET intervalstyle TO 'iso_8601';

-- Create schema jika ingin terpisah
-- CREATE SCHEMA hotel;
-- SET search_path TO hotel, public;

-- Grant permissions
-- GRANT ALL ON SCHEMA hotel TO hotel_admin;
-- GRANT USAGE ON SCHEMA hotel TO hotel_user;
-- GRANT SELECT ON ALL TABLES IN SCHEMA hotel TO hotel_report;

-- Log message
DO $$
BEGIN
    RAISE NOTICE '✅ Database hotel_nusantara setup completed';
    RAISE NOTICE '📅 Timezone: Asia/Jakarta';
    RAISE NOTICE '🔧 Extensions: btree_gist, pg_stat_statements, uuid-ossp installed';
END $$;