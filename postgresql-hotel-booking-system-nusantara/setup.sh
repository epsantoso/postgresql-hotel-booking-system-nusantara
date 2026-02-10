#!/bin/bash

# ============================================
# SETUP SCRIPT FOR HOTEL NUSANTARA DATABASE
# ============================================

DB_NAME="hotel_nusantara"
DB_USER="postgres"
DB_HOST="localhost"
DB_PORT="5432"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}============================================${NC}"
echo -e "${YELLOW}🏨 HOTEL NUSANTARA DATABASE SETUP${NC}"
echo -e "${YELLOW}============================================${NC}"

# Check if PostgreSQL is running
if ! pg_isready -h $DB_HOST -p $DB_PORT > /dev/null 2>&1; then
    echo -e "${RED}❌ PostgreSQL is not running on ${DB_HOST}:${DB_PORT}${NC}"
    exit 1
fi

# Create database
echo -e "${GREEN}📁 Creating database: ${DB_NAME}...${NC}"
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -c "CREATE DATABASE ${DB_NAME};"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Database created successfully${NC}"
else
    echo -e "${YELLOW}⚠️  Database might already exist, continuing...${NC}"
fi

# Connect to database and run setup scripts
echo -e "${GREEN}🚀 Setting up database structure...${NC}"

# Run SQL files in correct order
SQL_FILES=(
    "00_database_setup.sql"
    "01_types.sql"
    "02_tables.sql"
    "03_constraints.sql"
    "04_indexes.sql"
    "05_functions.sql"
    "06_triggers.sql"
    "07_views.sql"
    "08_seed_data.sql"
    "09_stored_procedures.sql"
)

for sql_file in "${SQL_FILES[@]}"; do
    if [ -f "sql/${sql_file}" ]; then
        echo -e "${GREEN}📄 Running: ${sql_file}...${NC}"
        psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f "sql/${sql_file}"
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ ${sql_file} executed successfully${NC}"
        else
            echo -e "${RED}❌ Error executing ${sql_file}${NC}"
            exit 1
        fi
    else
        echo -e "${RED}❌ File not found: sql/${sql_file}${NC}"
        exit 1
    fi
done

# Run showcase queries
echo -e "${GREEN}🎯 Running showcase queries...${NC}"
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f "sql/10_showcase_queries.sql"

# Create test user for application
echo -e "${GREEN}👤 Creating application user...${NC}"
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME <<EOF
-- Create application user with limited privileges
CREATE USER hotel_app WITH PASSWORD 'secure_password_123';
GRANT CONNECT ON DATABASE ${DB_NAME} TO hotel_app;
GRANT USAGE ON SCHEMA public TO hotel_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO hotel_app;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO hotel_app;

-- Create read-only user for reports
CREATE USER hotel_report WITH PASSWORD 'readonly_pass_456';
GRANT CONNECT ON DATABASE ${DB_NAME} TO hotel_report;
GRANT USAGE ON SCHEMA public TO hotel_report;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO hotel_report;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO hotel_report;
EOF

# Final summary
echo -e "${YELLOW}============================================${NC}"
echo -e "${GREEN}🎉 DATABASE SETUP COMPLETED SUCCESSFULLY!${NC}"
echo -e "${YELLOW}============================================${NC}"
echo -e "Database: ${DB_NAME}"
echo -e "Host: ${DB_HOST}:${DB_PORT}"
echo -e "Users created:"
echo -e "  - hotel_app (application user)"
echo -e "  - hotel_report (read-only for reports)"
echo -e "${YELLOW}============================================${NC}"
echo -e "Next steps:"
echo -e "1. Test connection: psql -h ${DB_HOST} -p ${DB_PORT} -U hotel_app -d ${DB_NAME}"
echo -e "2. Run sample queries: psql -d ${DB_NAME} -f sql/10_showcase_queries.sql"
echo -e "3. Check views: SELECT * FROM view_dashboard_harian;"
echo -e "${YELLOW}============================================${NC}"