#!/bin/bash
# sync_from_computer.sh - Extract data from Kobo and sync from your computer
# Use this if your Kobo doesn't have sqlite3 or python

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/kobo-stats-sync/config.env"
DB_PATH="/Volumes/KOBOeReader/.kobo/KoboReader.sqlite"

echo "===== Kobo Stats Sync (From Computer) ====="
echo ""

# Load configuration
if [ -f "$CONFIG_FILE" ]; then
    . "$CONFIG_FILE"
else
    echo "✗ Config file not found: $CONFIG_FILE"
    echo "Please create config.env first"
    exit 1
fi

echo "API Endpoint: $API_ENDPOINT"
echo ""

# Check if Kobo is connected
if [ ! -f "$DB_PATH" ]; then
    echo "✗ Kobo database not found at: $DB_PATH"
    echo ""
    echo "Please:"
    echo "  1. Connect your Kobo via USB"
    echo "  2. Wait for it to mount at /Volumes/KOBOeReader"
    echo "  3. Run this script again"
    exit 1
fi

echo "✓ Kobo connected"
echo "✓ Database found"
echo ""

# Check if sqlite3 is available on computer
if ! command -v sqlite3 > /dev/null 2>&1; then
    echo "✗ sqlite3 not found on your computer"
    echo ""
    echo "Please install sqlite3:"
    echo "  brew install sqlite3"
    exit 1
fi

echo "Querying database..."

# Extract reading stats
STATS=$(sqlite3 "$DB_PATH" <<EOF
.mode tabs
SELECT 
    ContentID,
    COALESCE(Title, 'NULL') as Title,
    COALESCE(Language, 'NULL') as Language,
    COALESCE(Attribution, 'NULL') as Attribution,
    COALESCE(DateLastRead, 'NULL') as DateLastRead,
    COALESCE(FirstTimeReading, 0) as FirstTimeReading,
    COALESCE(TimeSpentReading, 0) as TimeSpentReading,
    COALESCE(LastTimeStartedReading, 'NULL') as LastTimeStartedReading,
    COALESCE(LastTimeFinishedReading, 'NULL') as LastTimeFinishedReading,
    COALESCE(ReadStatus, 0) as ReadStatus,
    COALESCE(___PercentRead, 0) as PercentRead,
    COALESCE(RestOfBookEstimate, 0) as RestOfBookEstimate,
    COALESCE(CurrentChapterEstimate, 0) as CurrentChapterEstimate,
    COALESCE(CurrentChapterProgress, 0) as CurrentChapterProgress,
    COALESCE(replace(replace(replace(Description, char(10), ' '), char(13), ' '), char(9), ' '), 'NULL') as Description,
    COALESCE(Publisher, 'NULL') as Publisher
FROM content
WHERE ContentType = 6
ORDER BY DateLastRead DESC;
EOF
)

if [ -z "$STATS" ]; then
    echo "✗ No books found with reading progress"
    echo ""
    echo "Make sure you've read at least a few pages of a book!"
    exit 0
fi

BOOK_COUNT=$(echo "$STATS" | wc -l | tr -d ' ')
echo "✓ Found $BOOK_COUNT books with reading progress"
echo ""

# Build JSON payload
echo "Building JSON payload..."

PAYLOAD="{"
PAYLOAD="$PAYLOAD
  \"device\": \"kobo\","
PAYLOAD="$PAYLOAD
  \"timestamp\": $(date +%s),"
PAYLOAD="$PAYLOAD
  \"books\": ["

first=true
while IFS=$'\t' read -r content_id title language attribution date_last_read first_time_reading time_spent_reading last_time_started_reading last_time_finished_reading read_status percent_read rest_of_book_estimate current_chapter_estimate current_chapter_progress description publisher; do
    [[ -z "$content_id" ]] && continue
    
    # Convert 'NULL' placeholder back to empty
    [[ "$title" == "NULL" ]] && title=""
    [[ "$language" == "NULL" ]] && language=""
    [[ "$attribution" == "NULL" ]] && attribution=""
    [[ "$date_last_read" == "NULL" ]] && date_last_read=""
    [[ "$last_time_started_reading" == "NULL" ]] && last_time_started_reading=""
    [[ "$last_time_finished_reading" == "NULL" ]] && last_time_finished_reading=""
    [[ "$description" == "NULL" ]] && description=""
    [[ "$publisher" == "NULL" ]] && publisher=""
    
    # ESCAPE DOUBLE QUOTES IN ALL STRING FIELDS
    title="${title//\"/\\\"}"
    language="${language//\"/\\\"}"
    attribution="${attribution//\"/\\\"}"
    date_last_read="${date_last_read//\"/\\\"}"
    last_time_started_reading="${last_time_started_reading//\"/\\\"}"
    last_time_finished_reading="${last_time_finished_reading//\"/\\\"}"
    description="${description//\"/\\\"}"
    publisher="${publisher//\"/\\\"}"
    
    # Also escape backslashes first to prevent double-escaping
    description="${description//\\/\\\\}"
    description="${description//\"/\\\"}"
    
    if [ "$first" = true ]; then
        first=false
    else
        PAYLOAD="$PAYLOAD,"
    fi
    
    PAYLOAD="$PAYLOAD
    {"
    PAYLOAD="$PAYLOAD
      \"content_id\": \"$content_id\","
    PAYLOAD="$PAYLOAD
      \"title\": \"$title\","
    PAYLOAD="$PAYLOAD
      \"language\": \"$language\","
    PAYLOAD="$PAYLOAD
      \"author\": \"$attribution\","
    PAYLOAD="$PAYLOAD
      \"date_last_read\": \"$date_last_read\","
    PAYLOAD="$PAYLOAD
      \"first_time_reading\": $first_time_reading,"
    PAYLOAD="$PAYLOAD
      \"time_spent_reading\": $time_spent_reading,"
    PAYLOAD="$PAYLOAD
      \"last_time_started_reading\": \"$last_time_started_reading\","
    PAYLOAD="$PAYLOAD
      \"last_time_finished_reading\": \"$last_time_finished_reading\","
    PAYLOAD="$PAYLOAD
      \"read_status\": $read_status,"
    PAYLOAD="$PAYLOAD
      \"percent_read\": $percent_read,"
    PAYLOAD="$PAYLOAD
      \"rest_of_book_estimate\": $rest_of_book_estimate,"
    PAYLOAD="$PAYLOAD
      \"current_chapter_estimate\": $current_chapter_estimate,"
    PAYLOAD="$PAYLOAD
      \"current_chapter_progress\": $current_chapter_progress,"
    PAYLOAD="$PAYLOAD
      \"description\": \"$description\","
    PAYLOAD="$PAYLOAD
      \"publisher\": \"$publisher\""
    PAYLOAD="$PAYLOAD
    }"
done <<< "$STATS"

PAYLOAD="$PAYLOAD
  ]"
PAYLOAD="$PAYLOAD
}"

# Save payload for debugging
echo "$PAYLOAD" > /tmp/kobo-sync-payload.json
echo "✓ Payload saved to: /tmp/kobo-sync-payload.json"
echo ""

# Send to API
echo "Sending to API..."
RESPONSE=$(curl -X POST "$API_ENDPOINT" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -H "X-API-Key: $API_KEY" \
    -d "$PAYLOAD" \
    --connect-timeout 10 \
    --max-time 30 \
    -w "\n%{http_code}" 2>&1)

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)

echo ""
if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "201" ]; then
    echo "✓ SUCCESS!"
    echo ""
    echo "Synced $BOOK_COUNT books"
    echo "HTTP Status: $HTTP_CODE"
else
    echo "✗ FAILED"
    echo ""
    echo "HTTP Status: $HTTP_CODE"
    echo ""
    echo "Full response saved to: /tmp/kobo-sync-response.log"
    echo "$RESPONSE" > /tmp/kobo-sync-response.log
fi

echo ""
echo "===== Sync Complete ====="
echo ""
echo "This script synced data FROM your computer."
echo "To sync directly from Kobo, you need to install sqlite3 on it."
echo "See SQLITE3_SETUP.md for instructions."

