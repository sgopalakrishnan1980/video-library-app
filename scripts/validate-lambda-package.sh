#!/bin/bash
# Validate Lambda deployment package: encoding, structure, handler
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
ZIP_PATH="${1:-$PROJECT_ROOT/src/lambda-function.zip}"

echo "Validating: $ZIP_PATH"
echo ""

# 1. File exists
if [ ! -f "$ZIP_PATH" ]; then
    echo "ERROR: Package not found. Run: ./scripts/build-lambda-package.sh"
    exit 1
fi

# 2. Encoding check for index.js (extract and verify UTF-8, no BOM)
TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT
unzip -q -o "$ZIP_PATH" index.js -d "$TMPDIR" 2>/dev/null || true

if [ -f "$TMPDIR/index.js" ]; then
    # Check for BOM (EF BB BF)
    if head -c 3 "$TMPDIR/index.js" | xxd | grep -q "efbb bf"; then
        echo "WARNING: index.js has UTF-8 BOM - may cause issues. Save as UTF-8 without BOM."
    else
        echo "✓ Encoding: index.js is UTF-8 without BOM"
    fi
    # Check line endings (CRLF can cause issues)
    if file "$TMPDIR/index.js" | grep -q "CRLF"; then
        echo "WARNING: index.js has CRLF line endings. Prefer LF."
    else
        echo "✓ Line endings: LF"
    fi
else
    echo "ERROR: index.js not found in package"
    exit 1
fi

# 3. Package structure
echo ""
echo "Package contents:"
unzip -l "$ZIP_PATH" | head -25

# 4. Required files
if unzip -l "$ZIP_PATH" | grep -q " index.js$"; then
    echo "✓ index.js at root"
else
    echo "ERROR: index.js must be at zip root (for Handler: index.handler)"
    exit 1
fi

if unzip -l "$ZIP_PATH" | grep -q "node_modules/@aws-sdk"; then
    echo "✓ AWS SDK v3 bundled (node_modules/@aws-sdk)"
else
    echo "WARNING: AWS SDK not found. Node.js 18 Lambda does NOT include aws-sdk v2."
    echo "  Add: npm install @aws-sdk/client-dynamodb @aws-sdk/lib-dynamodb"
fi

echo ""
echo "✓ Package validation passed"
