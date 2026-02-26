# Video Progress Tracking Feature

## Overview

The video library now includes automatic progress tracking that saves the viewer's position in each video every 3 seconds. When users return to a video, playback resumes from where they left off.

## How It Works

### Client-Side (video-library.html)

1. **User Identification**: Each user gets a unique ID stored in browser localStorage
2. **Automatic Tracking**: While a video plays, progress is saved every 3 seconds
3. **Resume Playback**: When a video loads, the last saved position is retrieved
4. **Event Handling**: Progress is also saved when:
   - User seeks to a different position
   - Video is paused
   - Video completes playback

### Server-Side (Lambda + DynamoDB)

**Progress Data Structure:**
```json
{
  "pk": "PROGRESS#user-12345",
  "videoId": "video-001",
  "userId": "user-12345",
  "currentTime": 125.5,
  "timestamp": "2024-01-27T10:30:00Z",
  "completed": false,
  "lastUpdated": "2024-01-27T10:30:00Z"
}
```

**API Endpoints:**

1. **Save Progress** - `POST /progress`
   ```json
   {
     "userId": "user-12345",
     "videoId": "video-001",
     "currentTime": 125.5,
     "timestamp": "2024-01-27T10:30:00Z",
     "completed": false
   }
   ```

2. **Get Progress** - `GET /progress?userId=user-12345&videoId=video-001`
   ```json
   {
     "userId": "user-12345",
     "videoId": "video-001",
     "currentTime": 125.5,
     "timestamp": "2024-01-27T10:30:00Z",
     "completed": false,
     "lastUpdated": "2024-01-27T10:30:00Z"
   }
   ```

## Technical Implementation

### HTML/JavaScript Features

**Progress Tracking Interval:**
```javascript
// Saves progress every 3 seconds while video is playing
setInterval(() => {
    saveVideoProgress(videoId, currentTime, false);
}, 3000);
```

**Video Player Events:**
- `play` - Starts progress tracking
- `pause` - Stops progress tracking
- `ended` - Marks video as completed
- `seeked` - Saves new position immediately

**User ID Generation:**
```javascript
const userId = 'user-' + Date.now() + '-' + Math.random().toString(36).substr(2, 9);
```

### Lambda Function Updates

**New Handler Functions:**
- `handleSaveProgress()` - Saves video progress to DynamoDB
- `handleGetProgress()` - Retrieves saved progress

**DynamoDB Key Structure:**
- Partition Key: `PROGRESS#{userId}`
- Sort Key: `videoId`

This allows efficient queries for:
- All progress for a specific user
- Specific video progress for a user

### CloudFormation Changes

**Added Permissions:**
```yaml
- dynamodb:PutItem  # For saving progress
```

**New API Routes:**
```yaml
- GET /progress     # Retrieve progress
- POST /progress    # Save progress
```

**CORS Updates:**
```yaml
AllowMethods:
  - GET
  - POST
  - OPTIONS
```

## User Experience

### First Time Watching
1. User clicks video
2. Video starts from beginning
3. Progress saves every 3 seconds
4. Console logs show: "Saving progress: 0:03 / 10:25 (0.5%)"

### Returning to Video
1. User clicks same video again
2. System checks for saved progress
3. Message appears: "Resuming from 2:15"
4. Video jumps to saved position and plays

### Video Completion
1. Video reaches end
2. Progress marked as `completed: true`
3. Final position saved
4. Next time, user can choose to restart or resume

## Data Storage

### DynamoDB Table Items

**Video Items** (unchanged):
```
pk: "Library"
videoId: "video-001"
title: "Introduction to AWS"
link: "https://..."
```

**Progress Items** (new):
```
pk: "PROGRESS#user-12345"
videoId: "video-001"
userId: "user-12345"
currentTime: 125.5
completed: false
timestamp: "2024-01-27T10:30:00Z"
lastUpdated: "2024-01-27T10:30:00Z"
```

### Storage Efficiency

- Each progress update: ~200 bytes
- Updates every 3 seconds while playing
- 1 hour of video = 1,200 updates = ~240 KB
- With DynamoDB compression: ~50-100 KB

**Monthly Costs (1,000 users watching 10 hours each):**
- Write requests: 1,000 users × 10 hours × 1,200 = 12M writes
- Cost: 12M × $1.25/million = $15
- Storage: Minimal (progress data is overwritten)

## Testing

### Manual Testing

1. **Test Progress Saving:**
   ```bash
   # Start video, wait 10 seconds
   # Check browser console for logs
   ```

2. **Test Progress Loading:**
   ```bash
   # Play video for 30 seconds
   # Refresh page
   # Click same video
   # Should resume from 0:30
   ```

3. **Test API Directly:**
   ```bash
   # Save progress
   curl -X POST https://API_ENDPOINT/progress \
     -H "Content-Type: application/json" \
     -d '{
       "userId": "test-user",
       "videoId": "video-001",
       "currentTime": 60.5
     }'
   
   # Get progress
   curl "https://API_ENDPOINT/progress?userId=test-user&videoId=video-001"
   ```

### Automated Testing

```javascript
// Test in browser console
async function testProgressTracking() {
    const videoPlayer = document.getElementById('videoPlayer');
    
    // Simulate 30 seconds of playback
    videoPlayer.currentTime = 30;
    await saveVideoProgress('video-001', 30, false);
    
    // Load progress
    const savedTime = await loadVideoProgress('video-001');
    console.log('Saved time:', savedTime); // Should be 30
}
```

## Browser Compatibility

### Supported Features:
- ✅ localStorage (for user ID)
- ✅ Fetch API (for AJAX calls)
- ✅ HTML5 Video Events
- ✅ setInterval/clearInterval

### Minimum Requirements:
- Chrome 45+
- Firefox 40+
- Safari 10+
- Edge 14+

## Privacy Considerations

### What's Tracked:
- Anonymous user ID (generated locally)
- Video ID being watched
- Playback position
- Timestamps

### What's NOT Tracked:
- Personal information
- IP addresses (unless in Lambda logs)
- Device information
- Location data

### User Control:
Users can clear their watch history by:
```javascript
// Clear user ID (in browser console)
localStorage.removeItem('userId');

// This will generate a new user ID on next visit
// Previous progress will remain in DB but won't be associated
```

## Troubleshooting

### Progress Not Saving

**Check 1: API Endpoint**
```javascript
console.log(document.getElementById('apiEndpoint').value);
// Should show full API Gateway URL
```

**Check 2: Browser Console**
```javascript
// Should see logs every 3 seconds:
"Saving progress: 0:12 / 10:25 (1.9%)"
```

**Check 3: Network Tab**
- Look for POST requests to `/progress`
- Check response status (should be 200)
- Verify request payload

**Check 4: Lambda Logs**
```bash
aws logs tail /aws/lambda/VideoLibraryAPI --follow
```

### Progress Not Loading

**Check 1: User ID**
```javascript
console.log(localStorage.getItem('userId'));
// Should show: user-1234567890-abc123
```

**Check 2: API Response**
```bash
curl "https://API_ENDPOINT/progress?userId=USER_ID&videoId=VIDEO_ID"
```

**Check 3: DynamoDB**
```bash
aws dynamodb get-item \
  --table-name VideoLibrary \
  --key '{"pk":{"S":"PROGRESS#USER_ID"},"videoId":{"S":"VIDEO_ID"}}'
```

### High API Costs

If seeing unexpected costs:

**Reduce Update Frequency:**
```javascript
// Change from 3 seconds to 10 seconds
setInterval(() => {
    saveVideoProgress(...);
}, 10000); // 10 seconds
```

**Implement Local Caching:**
```javascript
let lastSavedTime = 0;
if (Math.abs(currentTime - lastSavedTime) > 5) {
    // Only save if position changed by 5+ seconds
    saveVideoProgress(...);
    lastSavedTime = currentTime;
}
```

## Advanced Features

### Batch Progress Updates

For cost optimization, batch multiple updates:

```javascript
let progressQueue = [];

function queueProgress(videoId, time) {
    progressQueue.push({ videoId, time });
    
    if (progressQueue.length >= 5) {
        flushProgressQueue();
    }
}

async function flushProgressQueue() {
    // Send all queued updates in one request
    await fetch(`${apiEndpoint}/progress/batch`, {
        method: 'POST',
        body: JSON.stringify({ updates: progressQueue })
    });
    progressQueue = [];
}
```

### Cross-Device Sync

Implement user authentication for cross-device progress:

```javascript
// Instead of localStorage userId
const userId = await getUserIdFromCognito();
```

### Analytics Integration

Track viewing patterns:

```javascript
function saveVideoProgress(videoId, currentTime, completed) {
    // Existing save logic...
    
    // Add analytics
    if (completed) {
        analytics.track('video_completed', {
            videoId,
            watchTime: currentTime
        });
    }
}
```

### Progress Visualization

Add progress bar to video cards:

```css
.progress-bar {
    height: 4px;
    background: #667eea;
    width: 0%;
    transition: width 0.3s;
}
```

```javascript
// Update video card with progress
card.innerHTML = `
    <div class="video-title">${title}</div>
    <div class="progress-bar" style="width: ${progress}%"></div>
`;
```

## Security Considerations

### Current Implementation (Development)
- ✅ Anonymous user IDs
- ✅ CORS enabled for any origin
- ✅ No authentication required
- ⚠️ Anyone can read/write any user's progress

### Production Recommendations

1. **Add Authentication:**
```yaml
# API Gateway Authorizer
AuthorizationType: AWS_IAM
# or
AuthorizationType: COGNITO_USER_POOLS
```

2. **Restrict CORS:**
```javascript
const allowedOrigins = ['https://yourdomain.com'];
const origin = event.headers.origin;
if (allowedOrigins.includes(origin)) {
    headers['Access-Control-Allow-Origin'] = origin;
}
```

3. **Validate User Ownership:**
```javascript
// Ensure userId matches authenticated user
if (body.userId !== event.requestContext.authorizer.claims.sub) {
    return { statusCode: 403, body: 'Forbidden' };
}
```

4. **Rate Limiting:**
```yaml
# API Gateway throttling
ThrottleSettings:
  RateLimit: 100
  BurstLimit: 200
```

## Migration Notes

If updating an existing deployment:

1. **Lambda needs PutItem permission**
2. **API Gateway needs POST routes**
3. **CORS needs POST method**
4. **No DynamoDB schema changes needed** (composite key allows both types)

Users can upgrade by simply:
```bash
aws cloudformation update-stack \
  --stack-name video-library \
  --template-body file://cloudformation-template.yaml \
  --capabilities CAPABILITY_IAM
```

## Future Enhancements

- [ ] Watch history page
- [ ] Most watched videos
- [ ] Continue watching section
- [ ] Progress synchronization across devices
- [ ] Offline viewing support
- [ ] Watch time analytics dashboard
- [ ] Sharing watch progress with friends
- [ ] Parental controls with progress tracking
- [ ] Smart resume (skip intros/credits)
- [ ] Binge-watching detection

---

**Progress tracking is now live!** Users' viewing positions are automatically saved every 3 seconds.
