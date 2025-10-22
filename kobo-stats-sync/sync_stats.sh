#!/bin/sh
# sync_stats.sh - Sync Kobo reading stats to API
# Place in: /mnt/onboard/.adds/kobo-stats-sync/

SCRIPT_DIR="$(dirname "$0")"
CONFIG_FILE="$SCRIPT_DIR/config.env"
DB_PATH="/mnt/onboard/.kobo/KoboReader.sqlite"

# Load configuration
if [ -f "$CONFIG_FILE" ]; then
    . "$CONFIG_FILE"
else
    echo "Config file not found: $CONFIG_FILE"
    exit 1
fi

# Check if connected to WiFi
if ! ping -c 1 -W 2 8.8.8.8 > /dev/null 2>&1; then
    echo "No internet connection"
    exit 1
fi

# Extract reading stats from Kobo database
get_reading_stats() {
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
        -s -w "\n%{http_code}"
}

# Main execution
echo "Syncing reading stats..."

# Get stats and build payload
PAYLOAD=$(get_reading_stats | build_payload)

# Send to API
RESPONSE=$(send_to_api "$PAYLOAD")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "201" ]; then
    echo "✓ Stats synced successfully!"
    # Show notification on Kobo
    fbink -m -t regular "Stats synced!" &
else
    echo "✗ Sync failed (HTTP $HTTP_CODE)"
    fbink -m -t regular "Sync failed!" &
fi