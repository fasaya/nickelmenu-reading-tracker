#!/bin/bash
# Find where sqlite3 might be on your Kobo

echo "===== Searching for SQLite3 on Kobo ====="
echo ""

KOBO_MOUNT="/Volumes/KOBOeReader"

if [ ! -d "$KOBO_MOUNT" ]; then
    echo "✗ Kobo not connected"
    echo "Please connect your Kobo via USB"
    exit 1
fi

echo "Checking common locations..."
echo ""

# Check common paths
PATHS=(
    "/usr/bin/sqlite3"
    "/usr/local/bin/sqlite3"
    "/bin/sqlite3"
    "/usr/local/Kobo/sqlite3"
    "/.kobo/sqlite3"
)

# Since we can't directly check Kobo's filesystem from Mac,
# let's create a test script to run ON the Kobo

TEST_SCRIPT="$KOBO_MOUNT/.adds/kobo-stats-sync/check_tools.sh"

cat > "$TEST_SCRIPT" <<'EOF'
#!/bin/sh
echo "===== Checking Available Tools on Kobo ====="
echo ""
echo "Looking for sqlite3..."
which sqlite3 2>/dev/null && echo "✓ Found: $(which sqlite3)"
find /usr -name "sqlite3" 2>/dev/null | head -5
find /bin -name "sqlite3" 2>/dev/null | head -5
find /.kobo -name "sqlite3" 2>/dev/null | head -5
echo ""
echo "Looking for python..."
which python 2>/dev/null && echo "✓ Found: $(which python)"
which python3 2>/dev/null && echo "✓ Found: $(which python3)"
echo ""
echo "Checking PATH..."
echo "PATH=$PATH"
echo ""
echo "Available commands in /usr/bin:"
ls /usr/bin/ | grep -E "sql|python" | head -10
EOF

chmod +x "$TEST_SCRIPT"

echo "✓ Created check script at: $TEST_SCRIPT"
echo ""
echo "===== Next Steps ====="
echo ""
echo "1. Safely eject your Kobo"
echo "2. On Kobo, tap: Main Menu → Sync Stats (Verbose)"
echo "3. After it runs, connect Kobo via USB"
echo "4. Check the log file at:"
echo "   $KOBO_MOUNT/.adds/kobo-stats-sync/sync.log"
echo ""
echo "OR if you have SSH access:"
echo "   ssh root@192.168.x.x"
echo "   sh $TEST_SCRIPT"
echo ""
echo "Send me the output and I'll know exactly what tools are available!"

