#!/bin/bash
# Test script syntax and basic functionality

echo "===== Testing Script Syntax ====="
echo ""

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Test main script syntax
echo "Testing sync_stats.sh..."
if sh -n "$SCRIPT_DIR/kobo-stats-sync/sync_stats.sh"; then
    echo "✓ sync_stats.sh has valid syntax"
else
    echo "✗ sync_stats.sh has syntax errors!"
    exit 1
fi

echo ""

# Test verbose script syntax
echo "Testing sync_stats_verbose.sh..."
if sh -n "$SCRIPT_DIR/kobo-stats-sync/sync_stats_verbose.sh"; then
    echo "✓ sync_stats_verbose.sh has valid syntax"
else
    echo "✗ sync_stats_verbose.sh has syntax errors!"
    exit 1
fi

echo ""

# Check file encodings
echo "Checking file encodings..."
if file "$SCRIPT_DIR/kobo-stats-sync/sync_stats.sh" | grep -q "CRLF"; then
    echo "✗ sync_stats.sh has Windows line endings (CRLF)"
    echo "  Fix with: dos2unix or save with LF line endings"
    exit 1
else
    echo "✓ sync_stats.sh has Unix line endings (LF)"
fi

if file "$SCRIPT_DIR/kobo-stats-sync/sync_stats_verbose.sh" | grep -q "CRLF"; then
    echo "✗ sync_stats_verbose.sh has Windows line endings (CRLF)"
    echo "  Fix with: dos2unix or save with LF line endings"
    exit 1
else
    echo "✓ sync_stats_verbose.sh has Unix line endings (LF)"
fi

echo ""

# Check shebangs
echo "Checking shebangs..."
SHEBANG1=$(head -1 "$SCRIPT_DIR/kobo-stats-sync/sync_stats.sh")
SHEBANG2=$(head -1 "$SCRIPT_DIR/kobo-stats-sync/sync_stats_verbose.sh")

if [ "$SHEBANG1" = "#!/bin/sh" ]; then
    echo "✓ sync_stats.sh has correct shebang"
else
    echo "✗ sync_stats.sh has incorrect shebang: $SHEBANG1"
fi

if [ "$SHEBANG2" = "#!/bin/sh" ]; then
    echo "✓ sync_stats_verbose.sh has correct shebang"
else
    echo "✗ sync_stats_verbose.sh has incorrect shebang: $SHEBANG2"
fi

echo ""
echo "===== All Tests Passed! ====="
echo ""
echo "Scripts are ready to be installed on Kobo."
echo "Next: Run ./install.sh when Kobo is connected"

