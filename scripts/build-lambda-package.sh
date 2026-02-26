#!/bin/bash

echo "Building Lambda deployment package..."

# Create temp directory
mkdir -p /tmp/lambda-package
cd /tmp/lambda-package

# Copy Lambda function
cat > index.js << 'EOF'
// Lambda function for Video Library API
// Uses AWS SDK v3 (built into Node.js 18 runtime)

const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { DynamoDBDocumentClient, ScanCommand, GetCommand, PutCommand } = require("@aws-sdk/lib-dynamodb");

const TABLE_NAME = process.env.TABLE_NAME || "VideoLibrary";

const client = new DynamoDBClient({});
const dynamodb = DynamoDBDocumentClient.from(client);

const headers = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
    "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
    "Content-Type": "application/json"
};

exports.handler = async (event) => {
    console.log('Event received:', JSON.stringify(event, null, 2));
    
    try {
        // Handle OPTIONS
        const method = event.requestContext?.http?.method || event.httpMethod || 'GET';
        if (method === 'OPTIONS') {
            return { statusCode: 200, headers, body: '' };
        }
        
        const path = event.rawPath || event.path || '';
        const queryParams = event.queryStringParameters || {};
        
        console.log('Processing:', method, path, queryParams);
        
        // Route: GET /scan
        if (path.includes('/scan') && method === 'GET') {
            const pk = queryParams.pk || 'Library';
            console.log('Scanning with pk:', pk);
            
            const result = await dynamodb.send(new ScanCommand({
                TableName: TABLE_NAME,
                FilterExpression: 'pk = :pk',
                ExpressionAttributeValues: { ':pk': pk }
            }));
            
            console.log('Found items:', result.Count);
            return {
                statusCode: 200,
                headers,
                body: JSON.stringify({ items: result.Items || [], count: result.Count || 0 })
            };
        }
        
        // Route: GET /videos
        if (path.includes('/videos') && method === 'GET') {
            const { pk, sk } = queryParams;
            if (!pk || !sk) {
                return { statusCode: 400, headers, body: JSON.stringify({ error: 'pk and sk required' }) };
            }
            
            const result = await dynamodb.send(new GetCommand({
                TableName: TABLE_NAME,
                Key: { pk, sk }
            }));
            
            if (!result.Item) {
                return { statusCode: 404, headers, body: JSON.stringify({ error: 'Not found' }) };
            }
            
            return { statusCode: 200, headers, body: JSON.stringify(result.Item) };
        }
        
        // Route: GET /progress
        if (path.includes('/progress') && method === 'GET') {
            const { userId, videoId } = queryParams;
            if (!userId || !videoId) {
                return { statusCode: 400, headers, body: JSON.stringify({ error: 'userId and videoId required' }) };
            }
            
            try {
                const result = await dynamodb.send(new GetCommand({
                    TableName: TABLE_NAME,
                    Key: { pk: `PROGRESS#${userId}`, sk: videoId }
                }));
                
                return {
                    statusCode: 200,
                    headers,
                    body: JSON.stringify({
                        currentTime: result.Item?.currentTime || 0,
                        completed: result.Item?.completed || false,
                        timestamp: result.Item?.timestamp,
                        lastUpdated: result.Item?.lastUpdated
                    })
                };
            } catch (err) {
                return { statusCode: 200, headers, body: JSON.stringify({ currentTime: 0, completed: false }) };
            }
        }
        
        // Route: POST /progress
        if (path.includes('/progress') && method === 'POST') {
            const body = JSON.parse(event.body || '{}');
            const { userId, videoId, currentTime, completed, timestamp } = body;
            
            if (!userId || !videoId || currentTime === undefined) {
                return { statusCode: 400, headers, body: JSON.stringify({ error: 'userId, videoId, currentTime required' }) };
            }
            
            const now = new Date().toISOString();
            await dynamodb.send(new PutCommand({
                TableName: TABLE_NAME,
                Item: {
                    pk: `PROGRESS#${userId}`,
                    sk: videoId,
                    userId,
                    videoId,
                    currentTime: Number(currentTime),
                    completed: completed || false,
                    timestamp: timestamp || now,
                    lastUpdated: now
                }
            }));
            
            return {
                statusCode: 200,
                headers,
                body: JSON.stringify({ message: 'Progress saved', userId, videoId, currentTime })
            };
        }
        
        return { statusCode: 404, headers, body: JSON.stringify({ error: 'Route not found' }) };
        
    } catch (error) {
        console.error('Error:', error);
        return {
            statusCode: 500,
            headers,
            body: JSON.stringify({ error: error.message, stack: error.stack })
        };
    }
};
EOF

# Create package.json (not needed for Node 18 runtime, but good practice)
cat > package.json << 'EOF'
{
  "name": "video-library-api",
  "version": "1.0.0",
  "description": "Video Library Lambda Function",
  "main": "index.js",
  "dependencies": {}
}
EOF

# Create zip
echo "Creating deployment package..."
zip -q -r lambda-function.zip index.js package.json

# Move to current directory
mv lambda-function.zip ~/monster-scale-demo/video-library-app/

cd ~/monster-scale-demo/video-library-app/

echo "✓ Lambda package created: lambda-function.zip"
echo ""
echo "Now update the Lambda function:"
echo ""
echo "aws lambda update-function-code \\"
echo "  --function-name VideoLibraryAPI \\"
echo "  --zip-file fileb://lambda-function.zip"
echo ""
echo "Wait for it to update:"
echo ""
echo "aws lambda wait function-updated --function-name VideoLibraryAPI"
echo ""
echo "Then test:"
echo ""
echo "curl \"\$(aws cloudformation describe-stacks --stack-name video-library --query 'Stacks[0].Outputs[?OutputKey==\`ApiEndpoint\`].OutputValue' --output text)/scan?pk=Library\""

# Cleanup
rm -rf /tmp/lambda-package
