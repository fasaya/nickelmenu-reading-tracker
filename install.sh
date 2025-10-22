#!/bin/bash
# Quick installation script for Kobo Stats Sync

KOBO_MOUNT="/Volumes/KOBOeReader"
KOBO_DEST="$KOBO_MOUNT/.adds/kobo-stats-sync"
NM_DEST="$KOBO_MOUNT/.adds/nm"

echo "===== Kobo Stats Sync Installer ====="
echo ""

# Check if Kobo is connected
if [ ! -d "$KOBO_MOUNT" ]; then
    echo "✗ Kobo not found at $KOBO_MOUNT"
    echo ""
    echo "Please connect your Kobo via USB first."
    exit 1
fi

echo "✓ Kobo found at $KOBO_MOUNT"
echo ""

# Create directories
echo "Creating directories..."
mkdir -p "$KOBO_DEST"
mkdir -p "$NM_DEST"
echo "✓ Directories created"
echo ""

# Copy scripts
echo "Copying scripts..."
cp kobo-stats-sync/sync_stats.sh "$KOBO_DEST/"
cp kobo-stats-sync/sync_stats_verbose.sh "$KOBO_DEST/"
cp kobo-stats-sync/query_db.py "$KOBO_DEST/"

# Copy sqlite3 binary if it exists
if [ -f kobo-stats-sync/sqlite3 ]; then
    cp kobo-stats-sync/sqlite3 "$KOBO_DEST/"
    echo "✓ sqlite3 binary included"
fi

# Check if config.env exists, if not copy example
if [ ! -f kobo-stats-sync/config.env ]; then
    echo "⚠ config.env not found, copying example..."
    cp kobo-stats-sync/config.env.example "$KOBO_DEST/config.env"
    echo "⚠ IMPORTANT: Edit config.env with your API credentials!"
else
    cp kobo-stats-sync/config.env "$KOBO_DEST/"
    echo "✓ Using existing config.env"
fi

# Copy NickelMenu config
cp nm/kobo-stats-sync "$NM_DEST/"

# Make scripts executable
chmod +x "$KOBO_DEST/sync_stats.sh"
chmod +x "$KOBO_DEST/sync_stats_verbose.sh"
chmod +x "$KOBO_DEST/query_db.py"

# Make sqlite3 executable if it exists
if [ -f "$KOBO_DEST/sqlite3" ]; then
    chmod +x "$KOBO_DEST/sqlite3"
fi

echo "✓ Scripts copied and made executable"
echo ""

echo "===== Installation Complete! ====="
echo ""
echo "Files installed to:"
echo "  $KOBO_DEST/"
echo "  $NM_DEST/kobo-stats-sync"
echo ""
echo "Next steps:"
if [ ! -f kobo-stats-sync/config.env ]; then
    echo "1. Edit $KOBO_DEST/config.env"
    echo "   - Set your API_ENDPOINT"
    echo "   - Set your API_KEY"
    echo "2. Safely eject your Kobo"
    echo "3. Restart your Kobo"
else
    echo "1. Safely eject your Kobo"
    echo "2. Restart your Kobo"
fi
echo "4. Look for 'Sync Reading Stats' in the menu"
echo ""
echo "Troubleshooting:"
echo "  Run: ./tests/test_api_connection.sh"
echo "  See: DEBUGGING.md"

