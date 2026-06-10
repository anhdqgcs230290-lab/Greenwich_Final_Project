#!/bin/bash

# UIRMS Database Setup Script
# This script sets up the PostgreSQL database for UIRMS

set -e  # Exit on error

# Configuration
DB_NAME=${1:-uirms}
DB_USER=${2:-postgres}
DB_HOST=${3:-localhost}
DB_PORT=${4:-5432}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}UIRMS Database Setup${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""
echo "Database Name: $DB_NAME"
echo "Database User: $DB_USER"
echo "Database Host: $DB_HOST"
echo "Database Port: $DB_PORT"
echo ""

# Check if psql is installed
if ! command -v psql &> /dev/null; then
    echo -e "${RED}Error: psql not found. Please install PostgreSQL client.${NC}"
    exit 1
fi

# Check if schema.sql exists
if [ ! -f "$SCRIPT_DIR/schema.sql" ]; then
    echo -e "${RED}Error: schema.sql not found in $SCRIPT_DIR${NC}"
    exit 1
fi

# Test database connection
echo -e "${YELLOW}Testing database connection...${NC}"
if ! psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -tc "SELECT 1" &> /dev/null; then
    echo -e "${RED}Error: Cannot connect to database server${NC}"
    echo "Make sure PostgreSQL is running and credentials are correct"
    exit 1
fi
echo -e "${GREEN}✓ Connection successful${NC}"
echo ""

# Check if database exists
echo -e "${YELLOW}Checking if database exists...${NC}"
DB_EXISTS=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -tc \
    "SELECT 1 FROM pg_database WHERE datname = '$DB_NAME'" | grep -q 1 && echo "yes" || echo "no")

if [ "$DB_EXISTS" = "yes" ]; then
    echo -e "${YELLOW}Database '$DB_NAME' already exists.${NC}"
    read -p "Do you want to drop and recreate it? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Dropping database '$DB_NAME'...${NC}"
        psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -tc "DROP DATABASE IF EXISTS $DB_NAME;"
        echo -e "${GREEN}✓ Database dropped${NC}"
    else
        echo -e "${YELLOW}Skipping database creation${NC}"
    fi
fi

# Create database if it doesn't exist or was dropped
if [ "$DB_EXISTS" = "no" ] || [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Creating database '$DB_NAME'...${NC}"
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -tc "CREATE DATABASE $DB_NAME;"
    echo -e "${GREEN}✓ Database created${NC}"
    echo ""
fi

# Install PostGIS extension
echo -e "${YELLOW}Installing PostGIS extension...${NC}"
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "CREATE EXTENSION IF NOT EXISTS postgis;" || echo -e "${YELLOW}PostGIS extension already installed${NC}"
echo -e "${GREEN}✓ PostGIS extension ready${NC}"
echo ""

# Load schema
echo -e "${YELLOW}Loading database schema...${NC}"
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "$SCRIPT_DIR/schema.sql"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Schema loaded successfully${NC}"
    echo ""
else
    echo -e "${RED}Error: Failed to load schema${NC}"
    exit 1
fi

# Verify installation
echo -e "${YELLOW}Verifying installation...${NC}"
TABLE_COUNT=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -tc \
    "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" | xargs)
echo -e "${GREEN}✓ Created $TABLE_COUNT tables${NC}"

# Show database info
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Database Information:"
echo "  Name: $DB_NAME"
echo "  Host: $DB_HOST:$DB_PORT"
echo "  User: $DB_USER"
echo ""

# Display connection string for applications
echo "Connection String for Applications:"
echo "  postgresql://$DB_USER@$DB_HOST:$DB_PORT/$DB_NAME"
echo ""

# Show helpful commands
echo "Useful Commands:"
echo "  Connect to database:"
echo "    psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME"
echo ""
echo "  Backup database:"
echo "    pg_dump -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME > backup.sql"
echo ""
echo "  Restore database:"
echo "    psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME < backup.sql"
echo ""
echo "  View all tables:"
echo "    psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c '\\dt'"
echo ""
echo "  View table structure:"
echo "    psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c '\\d+ incidents'"
echo ""
