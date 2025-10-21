#!/bin/bash
# test_sync.sh - Test the sync script locally

# Load config
source config.env

# Mock data
PAYLOAD='{
  "device": "kobo",
  "timestamp": '$(date +%s)',
  "books": [
    {
      "content_id": "file:///mnt/onboard/test.epub",
      "title": "Test Book",
      "author": "Test Author",
      "percent_complete": 45.5,
      "status": 1,
      "last_read": "2025-10-21 10:30:00"
    }
  ]
}'

echo "Testing API endpoint: $API_ENDPOINT"
echo "Payload:"
echo "$PAYLOAD"
echo ""

# Send request
RESPONSE=$(curl -X POST "$API_ENDPOINT" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $API_KEY" \
    -d "$PAYLOAD" \
    -s -w "\n%{http_code}")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)

echo "Response Code: $HTTP_CODE"
echo "Response Body: $BODY"

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "201" ]; then
    echo ""
    echo "✓ API test successful!"
else
    echo ""
    echo "✗ API test failed!"
fi