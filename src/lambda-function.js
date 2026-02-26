const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { DynamoDBDocumentClient, GetCommand, ScanCommand, PutCommand } = require("@aws-sdk/lib-dynamodb");

const client = new DynamoDBClient({});
const ddbDocClient = DynamoDBDocumentClient.from(client);

const TABLE_NAME = process.env.TABLE_NAME || "VideoLibrary";

// CORS headers
const headers = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "Content-Type",
    "Access-Control-Allow-Methods": "GET, POST, OPTIONS"
};

exports.handler = async (event) => {
    console.log('Event:', JSON.stringify(event, null, 2));
    
    // Handle OPTIONS request for CORS
    if (event.httpMethod === 'OPTIONS' || event.requestContext?.http?.method === 'OPTIONS') {
        return {
            statusCode: 200,
            headers,
            body: ''
        };
    }
    
    const path = event.path || event.rawPath || '';
    const method = event.httpMethod || event.requestContext?.http?.method || 'GET';
    
    try {
        // Route: GET /scan - Scan items with pk filter
        if (path === '/scan' && method === 'GET') {
            return await handleScan(event);
        }
        
        // Route: GET /videos - Get video by pk and sk
        if (path === '/videos' && method === 'GET') {
            return await handleGetVideo(event);
        }
        
        // Route: GET /progress - Get user progress
        if (path === '/progress' && method === 'GET') {
            return await handleGetProgress(event);
        }
        
        // Route: POST /progress - Save user progress
        if (path === '/progress' && method === 'POST') {
            return await handleSaveProgress(event);
        }
        
        // Default response for unknown routes
        return {
            statusCode: 404,
            headers,
            body: JSON.stringify({
                error: 'Not Found',
                message: `Route ${method} ${path} not found`
            })
        };
        
    } catch (error) {
        console.error('Error:', error);
        return {
            statusCode: 500,
            headers,
            body: JSON.stringify({
                error: 'Internal Server Error',
                message: error.message
            })
        };
    }
};

async function handleScan(event) {
    const params = event.queryStringParameters || {};
    const pk = params.pk || 'Library';
    
    console.log('Scanning with pk:', pk);
    
    const command = new ScanCommand({
        TableName: TABLE_NAME,
        FilterExpression: 'pk = :pk',
        ExpressionAttributeValues: {
            ':pk': pk
        }
    });
    
    const result = await ddbDocClient.send(command);
    
    console.log('Scan result:', JSON.stringify(result, null, 2));
    
    // Return items in a format the frontend expects
    return {
        statusCode: 200,
        headers,
        body: JSON.stringify({
            items: result.Items || []
        })
    };
}

async function handleGetVideo(event) {
    const params = event.queryStringParameters || {};
    const pk = params.pk;
    const sk = params.sk;
    
    if (!pk || !sk) {
        return {
            statusCode: 400,
            headers,
            body: JSON.stringify({
                error: 'Bad Request',
                message: 'Both pk and sk parameters are required'
            })
        };
    }
    
    console.log('Getting video with pk:', pk, 'sk:', sk);
    
    const command = new GetCommand({
        TableName: TABLE_NAME,
        Key: {
            pk: pk,
            sk: sk
        }
    });
    
    const result = await ddbDocClient.send(command);
    
    if (!result.Item) {
        return {
            statusCode: 404,
            headers,
            body: JSON.stringify({
                error: 'Not Found',
                message: 'Video not found'
            })
        };
    }
    
    return {
        statusCode: 200,
        headers,
        body: JSON.stringify(result.Item)
    };
}

async function handleGetProgress(event) {
    const params = event.queryStringParameters || {};
    const userId = params.userId;
    const videoId = params.videoId;
    
    if (!userId || !videoId) {
        return {
            statusCode: 400,
            headers,
            body: JSON.stringify({
                error: 'Bad Request',
                message: 'Both userId and videoId parameters are required'
            })
        };
    }
    
    console.log('Getting progress for userId:', userId, 'videoId:', videoId);
    
    // Progress is stored with pk = "PROGRESS#{userId}" and sk = videoId
    const command = new GetCommand({
        TableName: TABLE_NAME,
        Key: {
            pk: `PROGRESS#${userId}`,
            sk: videoId
        }
    });
    
    try {
        const result = await ddbDocClient.send(command);
        
        if (!result.Item) {
            // Return default progress if not found
            return {
                statusCode: 200,
                headers,
                body: JSON.stringify({
                    currentTime: 0,
                    completed: false
                })
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
    } catch (error) {
        console.error('Error getting progress:', error);
        // Return default on error
        return {
            statusCode: 200,
            headers,
            body: JSON.stringify({
                currentTime: 0,
                completed: false
            })
        };
    }
}

async function handleSaveProgress(event) {
    let body;
    try {
        body = JSON.parse(event.body || '{}');
    } catch (error) {
        return {
            statusCode: 400,
            headers,
            body: JSON.stringify({
                error: 'Bad Request',
                message: 'Invalid JSON in request body'
            })
        };
    }
    
    const { userId, videoId, currentTime, completed } = body;
    
    if (!userId || !videoId || currentTime === undefined) {
        return {
            statusCode: 400,
            headers,
            body: JSON.stringify({
                error: 'Bad Request',
                message: 'userId, videoId, and currentTime are required'
            })
        };
    }
    
    console.log('Saving progress for userId:', userId, 'videoId:', videoId, 'currentTime:', currentTime);
    
    const timestamp = new Date().toISOString();
    
    // Store progress with pk = "PROGRESS#{userId}" and sk = videoId
    const command = new PutCommand({
        TableName: TABLE_NAME,
        Item: {
            pk: `PROGRESS#${userId}`,
            sk: videoId,
            userId: userId,
            videoId: videoId,
            currentTime: Number(currentTime),
            completed: completed || false,
            timestamp: body.timestamp || timestamp,
            lastUpdated: timestamp
        }
    });
    
    await ddbDocClient.send(command);
    
    return {
        statusCode: 200,
        headers,
        body: JSON.stringify({
            message: 'Progress saved successfully',
            userId: userId,
            videoId: videoId,
            currentTime: currentTime,
            completed: completed || false
        })
    };
}
