/**
 * Video Library Lambda - uses AWS SDK v3 (required for Node.js 18 runtime)
 * Node.js 18 Lambda does NOT include aws-sdk v2 - only v3 is bundled.
 * Handler: index.handler
 */
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, QueryCommand, GetCommand, PutCommand } = require('@aws-sdk/lib-dynamodb');

const client = new DynamoDBClient({});
const dynamodb = DynamoDBDocumentClient.from(client);

const TABLE_NAME = process.env.TABLE_NAME || 'VideoLibrary';

const headers = {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS'
};

exports.handler = async (event) => {
    console.log('Event:', JSON.stringify(event, null, 2));

    if (event.httpMethod === 'OPTIONS' || event.requestContext?.http?.method === 'OPTIONS') {
        return { statusCode: 200, headers, body: '' };
    }

    const path = (event.path || event.rawPath || '').toString();
    const method = event.httpMethod || event.requestContext?.http?.method || 'GET';
    const queryParams = event.queryStringParameters || {};

    try {
        if (path.includes('/progress')) {
            if (method === 'GET') {
                return await handleGetProgress(queryParams);
            }
            if (method === 'POST') {
                return await handleSaveProgress(event.body);
            }
        }

        if (path.includes('/scan') && method === 'GET') {
            return await handleScan(queryParams);
        }

        if (path.includes('/videos') && method === 'GET') {
            return await handleGetVideo(queryParams);
        }

        return {
            statusCode: 404,
            headers,
            body: JSON.stringify({ error: 'Not Found', message: `Route ${method} ${path} not found` })
        };
    } catch (error) {
        console.error('Error:', error);
        return {
            statusCode: 500,
            headers,
            body: JSON.stringify({
                error: 'Internal Server Error',
                message: error.message,
                code: error.code
            })
        };
    }
};

async function handleScan(queryParams) {
    const pk = queryParams.pk || 'Library';
    const result = await dynamodb.send(new QueryCommand({
        TableName: TABLE_NAME,
        KeyConditionExpression: 'pk = :pk',
        ExpressionAttributeValues: { ':pk': pk }
    }));

    return {
        statusCode: 200,
        headers,
        body: JSON.stringify({ items: result.Items || [], count: result.Count || 0 })
    };
}

async function handleGetVideo(queryParams) {
    const { pk, sk } = queryParams;
    if (!pk || !sk) {
        return {
            statusCode: 400,
            headers,
            body: JSON.stringify({ error: 'Bad Request', message: 'Both pk and sk parameters are required' })
        };
    }

    const result = await dynamodb.send(new GetCommand({
        TableName: TABLE_NAME,
        Key: { pk, sk }
    }));

    if (!result.Item) {
        return {
            statusCode: 404,
            headers,
            body: JSON.stringify({ error: 'Not Found', message: 'Video not found' })
        };
    }

    return {
        statusCode: 200,
        headers,
        body: JSON.stringify(result.Item)
    };
}

async function handleGetProgress(queryParams) {
    const { userId, videoId } = queryParams;
    if (!userId || !videoId) {
        return {
            statusCode: 400,
            headers,
            body: JSON.stringify({ error: 'userId and videoId required' })
        };
    }

    try {
        const result = await dynamodb.send(new GetCommand({
            TableName: TABLE_NAME,
            Key: { pk: `PROGRESS#${userId}`, sk: videoId }
        }));

        if (!result.Item) {
            return {
                statusCode: 200,
                headers,
                body: JSON.stringify({ currentTime: 0, completed: false })
            };
        }

        return {
            statusCode: 200,
            headers,
            body: JSON.stringify({
                currentTime: result.Item.currentTime || 0,
                completed: result.Item.completed || false,
                timestamp: result.Item.timestamp,
                lastUpdated: result.Item.lastUpdated
            })
        };
    } catch (err) {
        console.error('Error getting progress:', err);
        return {
            statusCode: 200,
            headers,
            body: JSON.stringify({ currentTime: 0, completed: false })
        };
    }
}

async function handleSaveProgress(bodyStr) {
    let body;
    try {
        body = JSON.parse(bodyStr || '{}');
    } catch (error) {
        return {
            statusCode: 400,
            headers,
            body: JSON.stringify({ error: 'Invalid JSON in request body' })
        };
    }

    const { userId, videoId, currentTime, completed } = body;
    if (!userId || !videoId || currentTime === undefined) {
        return {
            statusCode: 400,
            headers,
            body: JSON.stringify({ error: 'userId, videoId, and currentTime are required' })
        };
    }

    const timestamp = new Date().toISOString();
    await dynamodb.send(new PutCommand({
        TableName: TABLE_NAME,
        Item: {
            pk: `PROGRESS#${userId}`,
            sk: videoId,
            userId,
            videoId,
            currentTime: Number(currentTime),
            completed: completed || false,
            timestamp: body.timestamp || timestamp,
            lastUpdated: timestamp
        }
    }));

    return {
        statusCode: 200,
        headers,
        body: JSON.stringify({
            message: 'Progress saved successfully',
            userId,
            videoId,
            currentTime,
            completed: completed || false
        })
    };
}
