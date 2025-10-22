#!/bin/bash
# Test script to verify API connection and payload format
# Run this from your computer to test if your backend is working

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG_FILE="$SCRIPT_DIR/kobo-stats-sync/config.env"

# Load configuration
if [ -f "$CONFIG_FILE" ]; then
    . "$CONFIG_FILE"
else
    echo "Config file not found: $CONFIG_FILE"
    exit 1
fi

# Sample test payload
TEST_PAYLOAD='{
  "device": "kobo",
  "timestamp": 1729612800,
  "books": [
    {
      "content_id": "file:///mnt/onboard/Books/test-book.epub",
      "book_id": "test-book-id-123",
      "book_title": "Test Book Title",
      "title": "Test Book Title",
      "author": "Test Author",
      "date_last_read": "2025-10-22T10:30:00Z",
      "time_spent_reading": 3600,
      "last_time_started_reading": "2025-10-22T09:30:00Z",
      "last_time_finished_reading": "2025-10-22T10:30:00Z",
      "read_status": 1,
      "percent_read": 45.5,
      "rest_of_book_estimate": 7200,
      "current_chapter_estimate": 900,
      "current_chapter_progress": 0.75
    }
  ]
}'

echo "===== Testing API Connection ====="
echo "API Endpoint: $API_ENDPOINT"
echo "API Key: ${API_KEY:0:10}... (first 10 chars)"
echo ""
echo "Sending test payload..."
echo ""

# Send request with verbose output
RESPONSE=$(curl -X POST "$API_ENDPOINT" \
    -H "Content-Type: application/json" \
    -H "X-API-Key: $API_KEY" \
    -d "$TEST_PAYLOAD" \
    --connect-timeout 10 \
    --max-time 30 \
    -v -w "\n\n===== HTTP STATUS: %{http_code} =====" 2>&1)

echo "$RESPONSE"
echo ""

# Extract HTTP code
HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP STATUS:" | grep -o '[0-9]\+' | tail -1)

echo ""
echo "===== Result ====="
if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "201" ]; then
    echo "✓ API connection successful! (HTTP $HTTP_CODE)"
    echo "Your backend is receiving data correctly."
else
    echo "✗ API connection failed (HTTP $HTTP_CODE)"
    echo ""
    echo "Common issues:"
    echo "  - Check if your backend server is running"
    echo "  - Verify API_ENDPOINT in config.env is correct"
    echo "  - Check if API_KEY matches your backend configuration"
    echo "  - Look for CORS issues if calling from different domain"
    echo "  - Check backend logs for error details"
fi

