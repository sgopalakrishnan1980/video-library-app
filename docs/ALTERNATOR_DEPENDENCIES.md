# ScyllaDB Alternator Lambda - Dependencies

## Current `lambda-function.zip` (DynamoDB)

The standard Lambda package contains:

- `index.js` - Handler using AWS SDK v3
- `node_modules/@aws-sdk/client-dynamodb`
- `node_modules/@aws-sdk/lib-dynamodb`
- `node_modules/@smithy/*`, `@aws-crypto/*`, etc. (SDK v3 transitive deps)

## Alternator Build - Additional Dependencies

The Alternator variant (`alternator_index.js`) requires **different** dependencies:

| Dependency | Purpose |
|------------|---------|
| `aws-sdk` v2 (^2.1691.0) | Alternator load balancer module uses AWS SDK v2 only |
| `Alternator.js` | ScyllaDB client-side load balancer (bundled in `src/`) |

### Why AWS SDK v2?

The [ScyllaDB alternator-load-balancing](https://github.com/scylladb/alternator-load-balancing/tree/master/javascript) JavaScript module is built for AWS SDK v2. It overrides internal SDK behavior to route requests across Alternator nodes. There is no SDK v3 equivalent in the official repo.

### Build Alternator Lambda Package

```bash
# Install alternator deps (aws-sdk v2)
npm install --prefix . aws-sdk@^2.1691.0

# Create zip: alternator_index.js + Alternator.js + node_modules/aws-sdk
cd src
zip -r alternator-lambda.zip alternator_index.js Alternator.js
cd ..
zip -r src/alternator-lambda.zip node_modules/aws-sdk

# Deploy (set Handler to alternator_index.handler)
aws lambda update-function-code \
  --function-name VideoLibraryAPI \
  --zip-file fileb://src/alternator-lambda.zip \
  --region us-east-1
```

### Package Contents Comparison

| File | DynamoDB (index.js) | Alternator (alternator_index.js) |
|------|---------------------|----------------------------------|
| Handler file | index.js | alternator_index.js |
| Load balancer | — | Alternator.js |
| SDK | @aws-sdk/client-dynamodb, @aws-sdk/lib-dynamodb | aws-sdk (v2) |
| Config | Env vars (TABLE_NAME) | In-code (ALTERNATOR_CONFIG) |
