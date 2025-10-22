#!/bin/bash
# Download pre-compiled sqlite3 binary for Kobo
# This script downloads a static sqlite3 binary that works on Kobo devices

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEST_DIR="$SCRIPT_DIR/kobo-stats-sync"
KOBO_MOUNT="/Volumes/KOBOeReader"

echo "===== Downloading sqlite3 for Kobo ====="
echo ""

# Create temp directory
TMP_DIR=$(mktemp -d)
cd "$TMP_DIR" || exit 1

echo "Downloading pre-compiled sqlite3 binary..."
echo ""

# Download sqlite3 static binary for ARM (Kobo uses ARM processors)
# Using sqlite.org's amalgamation to compile or a pre-built binary
# For Kobo, we need ARM architecture

# Option 1: Download from a reliable source
SQLITE_URL="https://github.com/NiLuJe/Kobo/raw/master/OCP-Kobo-Forma/usr/local/Kobo/sqlite3"

if command -v curl > /dev/null 2>&1; then
    curl -L -o sqlite3 "$SQLITE_URL" || {
        echo "✗ Download failed from GitHub"
        echo ""
        echo "Alternative: Manually download sqlite3 for ARM"
        echo "  1. Get sqlite3 ARM binary"
        echo "  2. Copy to kobo-stats-sync/sqlite3"
        echo "  3. Run install.sh"
        exit 1
    }
elif command -v wget > /dev/null 2>&1; then
    wget -O sqlite3 "$SQLITE_URL" || {
        echo "✗ Download failed"
        exit 1
    }
else
    echo "✗ Neither curl nor wget available"
    exit 1
fi

# Make executable
chmod +x sqlite3

# Copy to destination
cp sqlite3 "$DEST_DIR/"
echo "✓ sqlite3 binary saved to: $DEST_DIR/sqlite3"
echo ""

# Test it
echo "Testing binary..."
if ./sqlite3 -version > /dev/null 2>&1; then
    echo "✓ Binary is valid"
    VERSION=$(./sqlite3 -version | head -1)
    echo "  Version: $VERSION"
else
    echo "⚠ Binary may not work on your system (it's for Kobo ARM)"
fi

# Cleanup
cd - > /dev/null
rm -rf "$TMP_DIR"

echo ""
echo "===== Download Complete ====="
echo ""
echo "The sqlite3 binary will be copied to your Kobo when you run:"
echo "  ./install.sh"
echo ""
echo "If the download failed, you can manually place an ARM sqlite3"
echo "binary in: $DEST_DIR/sqlite3"

