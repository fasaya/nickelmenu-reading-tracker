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
    Title,
    Attribution,
    ___PercentRead,
    ReadStatus,
    ___UserID,
    DateLastRead
FROM content
WHERE ContentType = 6
AND ___PercentRead > 0
ORDER BY DateLastRead DESC
LIMIT 20;
EOF
}

# Build JSON payload
build_payload() {
    echo "{"
    echo "  \"device\": \"kobo\","
    echo "  \"timestamp\": $(date +%s),"
    echo "  \"books\": ["
    
    first=true
    while IFS='|' read -r content_id title author percent status user_id last_read; do
        if [ "$first" = true ]; then
            first=false
        else
            echo ","
        fi
        
        echo "    {"
        echo "      \"content_id\": \"$content_id\","
        echo "      \"title\": \"$title\","
        echo "      \"author\": \"$author\","
        echo "      \"percent_complete\": $percent,"
        echo "      \"status\": $status,"
        echo "      \"last_read\": \"$last_read\""
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
        -H "Authorization: Bearer $API_KEY" \
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