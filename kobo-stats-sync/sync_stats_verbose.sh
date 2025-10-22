#!/bin/sh
# sync_stats.sh - Sync Kobo reading stats to API (VERBOSE VERSION)
# Place in: /mnt/onboard/.adds/kobo-stats-sync/

SCRIPT_DIR="$(dirname "$0")"
CONFIG_FILE="$SCRIPT_DIR/config.env"
DB_PATH="/mnt/onboard/.kobo/KoboReader.sqlite"
LOG_FILE="/mnt/onboard/.adds/kobo-stats-sync/sync.log"

# Function to log both to file and stdout
log() {
    echo "$1" | tee -a "$LOG_FILE"
}

# Helper function to show notification (if fbink available)
notify() {
    if command -v fbink > /dev/null 2>&1; then
        fbink -m -t regular "$1" &
    fi
}

# Start fresh log
echo "===== Sync Started: $(date) =====" > "$LOG_FILE"

# Load configuration
if [ -f "$CONFIG_FILE" ]; then
    . "$CONFIG_FILE"
    log "✓ Config loaded"
else
    log "✗ Config file not found: $CONFIG_FILE"
    log "Please copy config.env.example to config.env"
    notify "Config missing!"
    exit 0
fi

log "API Endpoint: $API_ENDPOINT"
log ""

# Check if connected to WiFi
log "Checking internet connection..."
if ! ping -c 1 -W 2 8.8.8.8 > /dev/null 2>&1; then
    log "✗ No internet connection"
    log "Please connect to WiFi first"
    notify "No WiFi!"
    exit 0
fi
log "✓ Internet connected"

# Check database exists
if [ ! -f "$DB_PATH" ]; then
    log "✗ Database not found: $DB_PATH"
    notify "DB not found!"
    exit 0
fi
log "✓ Database found"

# Extract reading stats from Kobo database
get_reading_stats() {
    local SQLITE_CMD=""
    
    # Find sqlite3 command
    if [ -f "$SCRIPT_DIR/sqlite3" ]; then
        # Use bundled sqlite3 binary
        SQLITE_CMD="$SCRIPT_DIR/sqlite3"
        log "Using bundled sqlite3: $SCRIPT_DIR/sqlite3"
    elif command -v sqlite3 > /dev/null 2>&1; then
        # Use system sqlite3
        SQLITE_CMD="sqlite3"
        log "Using system sqlite3"
    fi
    
    # Try sqlite3 command first
    if [ -n "$SQLITE_CMD" ]; then
        "$SQLITE_CMD" "$DB_PATH" <<EOF
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
    # Fallback to Python if sqlite3 not available
    elif command -v python3 > /dev/null 2>&1; then
        log "Using python3 for database query"
        python3 "$SCRIPT_DIR/query_db.py"
    elif command -v python > /dev/null 2>&1; then
        log "Using python for database query"
        python "$SCRIPT_DIR/query_db.py"
    else
        log "✗ Cannot query database!"
        log "Missing required tools: sqlite3, python"
        log ""
        log "Solution: Run ./download_sqlite3.sh"
        return 1
    fi
}

# Build JSON payload
build_payload() {
    echo "{"
    echo "  \"device\": \"kobo\","
    echo "  \"timestamp\": $(date +%s),"
    echo "  \"books\": ["
    
    first=true
    while IFS='|' read -r content_id book_id book_title title author date_last_read time_spent last_started last_finished read_status percent_read rest_estimate chapter_estimate chapter_progress; do
        if [ "$first" = true ]; then
            first=false
        else
            echo ","
        fi
        
        echo "    {"
        echo "      \"content_id\": \"$content_id\","
        echo "      \"book_id\": \"$book_id\","
        echo "      \"book_title\": \"$book_title\","
        echo "      \"title\": \"$title\","
        echo "      \"author\": \"$author\","
        echo "      \"date_last_read\": \"$date_last_read\","
        echo "      \"time_spent_reading\": $time_spent,"
        echo "      \"last_time_started_reading\": \"$last_started\","
        echo "      \"last_time_finished_reading\": \"$last_finished\","
        echo "      \"read_status\": $read_status,"
        echo "      \"percent_read\": $percent_read,"
        echo "      \"rest_of_book_estimate\": $rest_estimate,"
        echo "      \"current_chapter_estimate\": $chapter_estimate,"
        echo "      \"current_chapter_progress\": $chapter_progress"
        echo -n "    }"
    done
    
    echo ""
    echo "  ]"
    echo "}"
}

# Send to API
send_to_api() {
    local payload="$1"
    
    curl -X POST "$API_ENDPOINT" \
        -H "Content-Type: application/json" \
        -H "X-API-Key: $API_KEY" \
        -d "$payload" \
        --connect-timeout 10 \
        --max-time 30 \
        -v -w "\n%{http_code}" 2>&1 >> "$LOG_FILE"
}

# Get stats
log "Querying database..."
STATS=$(get_reading_stats)
if [ -z "$STATS" ]; then
    log "✗ No reading stats found"
    log "  (No books with progress > 0%)"
    log ""
    log "Make sure you've read at least a few pages of a book!"
    notify "No books to sync!"
    exit 0
fi

BOOK_COUNT=$(echo "$STATS" | wc -l | tr -d ' ')
log "✓ Found $BOOK_COUNT books with reading progress"

# Build payload
log "Building JSON payload..."
PAYLOAD=$(echo "$STATS" | build_payload)

# Save payload for debugging
PAYLOAD_FILE="/mnt/onboard/.adds/kobo-stats-sync/last_payload.json"
echo "$PAYLOAD" > "$PAYLOAD_FILE"
log "✓ Payload saved to: $PAYLOAD_FILE"

# Show first 300 chars in log
log ""
log "Payload preview:"
echo "$PAYLOAD" | head -c 300 >> "$LOG_FILE"
log "..."
log ""

# Send to API
log "Sending to API..."
RESPONSE=$(send_to_api "$PAYLOAD")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)

log ""
log "HTTP Response Code: $HTTP_CODE"

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "201" ]; then
    log "✓ Stats synced successfully!"
    log ""
    log "Synced $BOOK_COUNT books at $(date)"
    
    # Show success notification
    notify "✓ Synced $BOOK_COUNT books!"
else
    log "✗ Sync failed (HTTP $HTTP_CODE)"
    log ""
    log "Check the log file for details:"
    log "$LOG_FILE"
    
    # Show error notification  
    notify "✗ Sync failed! Check logs"
fi

log ""
log "===== Sync Completed: $(date) ====="

