#!/bin/sh
# find_tools.sh - Diagnostic script to find database tools on Kobo
# Run this on the Kobo to discover what's available

echo "===== Diagnostic: Finding Database Tools ====="
echo ""

echo "1. Checking for sqlite3..."
if command -v sqlite3 > /dev/null 2>&1; then
    echo "   ✓ sqlite3 found: $(which sqlite3)"
    sqlite3 -version
else
    echo "   ✗ sqlite3 not found in PATH"
fi
echo ""

echo "2. Searching filesystem for sqlite3..."
find /usr -name "*sqlite*" 2>/dev/null | head -10
find /mnt -name "*sqlite*" 2>/dev/null | head -10
echo ""

echo "3. Checking for python..."
if command -v python3 > /dev/null 2>&1; then
    echo "   ✓ python3 found: $(which python3)"
    python3 --version
elif command -v python > /dev/null 2>&1; then
    echo "   ✓ python found: $(which python)"
    python --version
else
    echo "   ✗ No python found in PATH"
fi
echo ""

echo "4. Checking PATH..."
echo "   PATH=$PATH"
echo ""

echo "5. Checking available binaries in common locations..."
echo "   /usr/bin:"
ls /usr/bin 2>/dev/null | grep -i "sql\|python" | head -10
echo "   /usr/local/bin:"
ls /usr/local/bin 2>/dev/null | grep -i "sql\|python" | head -10
echo ""

echo "6. System info..."
uname -a
echo ""

echo "===== End Diagnostic ====="

