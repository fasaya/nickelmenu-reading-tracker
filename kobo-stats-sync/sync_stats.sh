#!/bin/sh
# sync_stats.sh - Sync Kobo reading stats to API
# Place in: /mnt/onboard/.adds/kobo-stats-sync/

SCRIPT_DIR="$(dirname "$0")"
CONFIG_FILE="$SCRIPT_DIR/config.env"
DB_PATH="/mnt/onboard/.kobo/KoboReader.sqlite"

# Helper function to show notification (if fbink available)
notify() {
    if command -v fbink > /dev/null 2>&1; then
        fbink -m -t regular "$1" &
    fi
}

# Load configuration
if [ -f "$CONFIG_FILE" ]; then
    . "$CONFIG_FILE"
else
    echo "✗ Config file not found!"
    echo ""
    echo "Expected at:"
    echo "$CONFIG_FILE"
    echo ""
    echo "Please copy config.env.example"
    echo "to config.env and edit it."
    notify "Config missing!"
    exit 0
fi

# Check if connected to WiFi
if ! ping -c 1 -W 2 8.8.8.8 > /dev/null 2>&1; then
    echo "✗ No internet connection"
    echo ""
    echo "Please connect to WiFi first"
    notify "No WiFi!"
    exit 0
fi

# Extract reading stats from Kobo database
get_reading_stats() {
    local SQLITE_CMD=""
    
    # Find sqlite3 command
    if [ -f "$SCRIPT_DIR/sqlite3" ]; then
        # Use bundled sqlite3 binary
        SQLITE_CMD="$SCRIPT_DIR/sqlite3"
    elif command -v sqlite3 > /dev/null 2>&1; then
        # Use system sqlite3
        SQLITE_CMD="sqlite3"
    fi
    
    # Try sqlite3 command first
    if [ -n "$SQLITE_CMD" ]; then
        "$SQLITE_CMD" "$DB_PATH" <<EOF
SELECT 
    ContentID,
    BookID,
    BookTitle,
    Title,
    Language,
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
WHERE ContentType = 6
ORDER BY DateLastRead DESC;
EOF
    # Fallback to Python if sqlite3 not available
    elif command -v python3 > /dev/null 2>&1; then
        python3 "$SCRIPT_DIR/query_db.py"
    elif command -v python > /dev/null 2>&1; then
        python "$SCRIPT_DIR/query_db.py"
    else
        echo "✗ Cannot query database!" >&2
        echo "" >&2
        echo "Missing required tools:" >&2
        echo "  - sqlite3 (not found)" >&2
        echo "  - python (not found)" >&2
        echo "" >&2
        echo "Solution:" >&2
        echo "Run ./download_sqlite3.sh to get" >&2
        echo "a compatible sqlite3 binary" >&2
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
    while IFS='|' read -r content_id book_id book_title title language author date_last_read time_spent last_started last_finished read_status percent_read rest_estimate chapter_estimate chapter_progress; do
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
        echo "      \"language\": \"$language\","
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
        -v -w "\n%{http_code}" 2>&1
}

# Main execution
echo "Syncing reading stats..."
echo ""

# Check database exists
if [ ! -f "$DB_PATH" ]; then
    echo "✗ Database not found"
    echo ""
    echo "Expected at:"
    echo "$DB_PATH"
    notify "DB not found!"
    exit 0
fi

# Get stats and build payload
STATS=$(get_reading_stats)
if [ -z "$STATS" ]; then
    echo "✗ No books found with reading progress"
    echo ""
    echo "Make sure you've read at least"
    echo "a few pages of a book first!"
    notify "No books to sync!"
    exit 0
fi

BOOK_COUNT=$(echo "$STATS" | wc -l | tr -d ' ')
echo "Found: $BOOK_COUNT books"
echo ""

PAYLOAD=$(echo "$STATS" | build_payload)

# Save payload to temp file for debugging
TEMP_PAYLOAD="/tmp/kobo-sync-payload.json"
echo "$PAYLOAD" > "$TEMP_PAYLOAD"

# Send to API
echo "Sending to: $API_ENDPOINT"
echo ""
RESPONSE=$(send_to_api "$PAYLOAD")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)

# Save full response for debugging
echo "$RESPONSE" > /tmp/kobo-sync-response.log

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "201" ]; then
    echo "✓ SUCCESS!"
    echo ""
    echo "Synced $BOOK_COUNT books"
    echo "HTTP Status: $HTTP_CODE"
    
    # Show notification on Kobo
    notify "✓ Synced $BOOK_COUNT books!"
else
    echo "✗ FAILED"
    echo ""
    echo "HTTP Status: $HTTP_CODE"
    echo ""
    echo "Debug files saved to /tmp/"
    echo "- kobo-sync-payload.json"
    echo "- kobo-sync-response.log"
    
    notify "✗ Sync failed! ($HTTP_CODE)"
fi