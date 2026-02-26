#!/bin/bash
# Build Lambda package for ScyllaDB Alternator backend
# Output: src/alternator-lambda.zip
# Handler: alternator_index.handler
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

echo "Building Alternator Lambda package..."
cd "$PROJECT_ROOT"

# Install aws-sdk v2 (required by Alternator.js)
npm install aws-sdk@^2.1691.0 --no-save 2>/dev/null || npm install aws-sdk@^2.1691.0

# Create zip: alternator_index.js + Alternator.js + node_modules/aws-sdk
rm -f src/alternator-lambda.zip
cd "$PROJECT_ROOT/src"
zip -q alternator-lambda.zip alternator_index.js Alternator.js
cd "$PROJECT_ROOT"
zip -rq src/alternator-lambda.zip node_modules/aws-sdk

echo "✓ Package: src/alternator-lambda.zip"
echo "  Handler: alternator_index.handler"
unzip -l src/alternator-lambda.zip | head -25
