#!/bin/sh
# query_db.sh - Alternative database query using dump and awk
# For Kobo devices without sqlite3 or Python

DB_PATH="/mnt/onboard/.kobo/KoboReader.sqlite"

# Check if database exists
if [ ! -f "$DB_PATH" ]; then
    echo "Database not found: $DB_PATH" >&2
    exit 1
fi

# Try to use any available database tool
if command -v sqlite3 > /dev/null 2>&1; then
    # Use sqlite3 if available
    sqlite3 "$DB_PATH" <<EOF
SELECT 
    ContentID,
    BookID,
    BookTitle,
    Title,
    Attribution,
    DateLastRead,
    TimeSpentReading,
    LastTimeStartedReading,
    LastTimeFinishedReading,
    ReadStatus,
    ___PercentRead,
    RestOfBookEstimate,
    CurrentChapterEstimate,
    CurrentChapterProgress
FROM content
WHERE ContentType IN (6, 10, 16)
AND ___PercentRead > 0
ORDER BY DateLastRead DESC;
EOF
elif command -v python3 > /dev/null 2>&1; then
    # Use Python 3 if available
    python3 "$(dirname "$0")/query_db.py"
elif command -v python > /dev/null 2>&1; then
    # Use Python 2 if available
    python "$(dirname "$0")/query_db.py"
else
    # No database tools available - provide helpful error
    echo "Error: Cannot query database" >&2
    echo "" >&2
    echo "Your Kobo is missing required tools:" >&2
    echo "  - sqlite3 (not found)" >&2
    echo "  - python/python3 (not found)" >&2
    echo "" >&2
    echo "Possible solutions:" >&2
    echo "1. Update Kobo firmware to latest version" >&2
    echo "2. Install sqlite3 binary manually" >&2
    echo "3. Install Python for Kobo" >&2
    exit 1
fi

