#!/bin/bash
# Build Lambda deployment package with AWS SDK v3 (required for Node.js 18)
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

echo "Building Lambda package..."
cd "$PROJECT_ROOT"

# Install deps (Node 18 Lambda does not include aws-sdk v2)
npm install --omit=dev --no-package-lock 2>/dev/null || npm install --production 2>/dev/null || true

# Create zip: index.js + node_modules at root (Lambda extracts to /var/task)
rm -f src/lambda-function.zip
cd "$PROJECT_ROOT/src"
zip -q lambda-function.zip index.js
cd "$PROJECT_ROOT"
zip -rq src/lambda-function.zip node_modules

echo "✓ Package: src/lambda-function.zip"
echo "  Contents:"
unzip -l src/lambda-function.zip | head -20
