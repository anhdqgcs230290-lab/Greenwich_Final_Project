@echo off
REM UIRMS Database Setup Script for Windows
REM This script sets up the PostgreSQL database for UIRMS

setlocal enabledelayedexpansion

REM Configuration
set DB_NAME=%1
if "!DB_NAME!"=="" set DB_NAME=uirms

set DB_USER=%2
if "!DB_USER!"=="" set DB_USER=postgres

set DB_HOST=%3
if "!DB_HOST!"=="" set DB_HOST=localhost

set DB_PORT=%4
if "!DB_PORT!"=="" set DB_PORT=5432

REM Get script directory
set SCRIPT_DIR=%~dp0

echo.
echo ========================================
echo UIRMS Database Setup
echo ========================================
echo.
echo Database Name: !DB_NAME!
echo Database User: !DB_USER!
echo Database Host: !DB_HOST!
echo Database Port: !DB_PORT!
echo.

REM Check if psql is installed
where psql >nul 2>nul
if errorlevel 1 (
    echo Error: psql not found. Please install PostgreSQL client and add it to PATH.
    pause
    exit /b 1
)

REM Check if schema.sql exists
if not exist "!SCRIPT_DIR!schema.sql" (
    echo Error: schema.sql not found in !SCRIPT_DIR!
    pause
    exit /b 1
)

REM Test database connection
echo Testing database connection...
psql -h !DB_HOST! -p !DB_PORT! -U !DB_USER! -tc "SELECT 1" >nul 2>nul
if errorlevel 1 (
    echo Error: Cannot connect to database server
    echo Make sure PostgreSQL is running and credentials are correct
    pause
    exit /b 1
)
echo Connection successful
echo.

REM Check if database exists
echo Checking if database exists...
psql -h !DB_HOST! -p !DB_PORT! -U !DB_USER! -tc "SELECT 1 FROM pg_database WHERE datname = '!DB_NAME!'" >nul 2>nul
if errorlevel 1 (
    set DB_EXISTS=no
) else (
    set DB_EXISTS=yes
)

if "!DB_EXISTS!"=="yes" (
    echo Database '!DB_NAME!' already exists.
    set /p DROP_DB="Do you want to drop and recreate it? (y/N): "
    if /i "!DROP_DB!"=="y" (
        echo Dropping database '!DB_NAME!'...
        psql -h !DB_HOST! -p !DB_PORT! -U !DB_USER! -tc "DROP DATABASE IF EXISTS !DB_NAME!;"
        echo Database dropped
        set DB_EXISTS=no
    )
)

if "!DB_EXISTS!"=="no" (
    echo Creating database '!DB_NAME!'...
    psql -h !DB_HOST! -p !DB_PORT! -U !DB_USER! -tc "CREATE DATABASE !DB_NAME!;"
    echo Database created
    echo.
)

REM Install PostGIS extension
echo Installing PostGIS extension...
psql -h !DB_HOST! -p !DB_PORT! -U !DB_USER! -d !DB_NAME! -c "CREATE EXTENSION IF NOT EXISTS postgis;"
echo PostGIS extension ready
echo.

REM Load schema
echo Loading database schema...
psql -h !DB_HOST! -p !DB_PORT! -U !DB_USER! -d !DB_NAME! -f "!SCRIPT_DIR!schema.sql"

if errorlevel 1 (
    echo Error: Failed to load schema
    pause
    exit /b 1
)
echo Schema loaded successfully
echo.

REM Verify installation
echo Verifying installation...
for /f %%i in ('psql -h !DB_HOST! -p !DB_PORT! -U !DB_USER! -d !DB_NAME! -tc "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" ^| findstr /r "[0-9]"') do set TABLE_COUNT=%%i
echo Created !TABLE_COUNT! tables
echo.

REM Display summary
echo ========================================
echo Setup Complete!
echo ========================================
echo.
echo Database Information:
echo   Name: !DB_NAME!
echo   Host: !DB_HOST!:!DB_PORT!
echo   User: !DB_USER!
echo.
echo Connection String:
echo   postgresql://!DB_USER!@!DB_HOST!:!DB_PORT!/!DB_NAME!
echo.
echo Useful Commands:
echo   Connect to database:
echo     psql -h !DB_HOST! -p !DB_PORT! -U !DB_USER! -d !DB_NAME!
echo.
echo   Backup database:
echo     pg_dump -h !DB_HOST! -p !DB_PORT! -U !DB_USER! -d !DB_NAME! ^> backup.sql
echo.
echo   View all tables:
echo     psql -h !DB_HOST! -p !DB_PORT! -U !DB_USER! -d !DB_NAME! -c "\dt"
echo.
echo   View table structure:
echo     psql -h !DB_HOST! -p !DB_PORT! -U !DB_USER! -d !DB_NAME! -c "\d+ incidents"
echo.

pause
