# Status Ribbon Documentation

## Overview

The status ribbon is a fixed bottom bar that displays real-time API monitoring information, including the DynamoDB endpoint in use and response times for all read/write operations.

## Visual Appearance

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ ● API: abc123.execute-api.us-east-1.amazonaws.com/prod | Last Operation:   │
│ POST progress [video-001] | Response Time: 145ms | Total Requests: 23 |    │
│ Avg Response: 167ms                                                         │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Status Ribbon Components

### 1. Status Indicator (●)
- **Green (pulsing)**: Active API call in progress
- **Gray (static)**: Idle, no recent activity
- **Red (pulsing)**: Error occurred in last request

### 2. API Endpoint
- **Display**: Shows hostname and path of API Gateway endpoint
- **Format**: `abc123.execute-api.us-east-1.amazonaws.com/prod`
- **Hover**: Full URL shown in title attribute
- **Max Width**: 300px with ellipsis for overflow
- **Color**: Light blue (#63b3ed)

### 3. Last Operation
- **Display**: Shows the most recent API operation
- **Format**: `[METHOD] [endpoint] [identifier]`
- **Examples**:
  - `SCAN videos`
  - `GET progress [video-001]`
  - `POST progress [video-002]`
  - `GET videos`
- **Color**: Light cyan (#90cdf4)
- **Style**: Italic

### 4. Response Time
- **Display**: Milliseconds for the last API call
- **Format**: `145ms`, `1234ms`
- **Color Coding**:
  - **Green** (< 200ms): Fast response
  - **Orange** (200-500ms): Medium response
  - **Red** (> 500ms): Slow response
- **Measurement**: Uses `performance.now()` for precision

### 5. Total Requests
- **Display**: Cumulative count of all API calls since page load
- **Format**: Integer count
- **Includes**: All operations (GET, POST, SCAN)
- **Color**: Green (#48bb78)

### 6. Average Response
- **Display**: Rolling average of response times
- **Calculation**: Average of last 100 requests
- **Format**: Milliseconds
- **Color Coding**: Same as Response Time
- **Updates**: After each API call

## API Operations Tracked

### 1. Video Loading Operations
```javascript
Operation: "SCAN videos"
Endpoint: /scan?pk=Library
Method: GET
Typical Response: 150-300ms
```

### 2. Progress Read Operations
```javascript
Operation: "GET progress [video-001]"
Endpoint: /progress?userId=user-123&videoId=video-001
Method: GET
Typical Response: 50-150ms
```

### 3. Progress Write Operations
```javascript
Operation: "POST progress [video-001]"
Endpoint: /progress
Method: POST
Typical Response: 100-250ms
Frequency: Every 3 seconds while playing
```

## Technical Implementation

### API Call Wrapper Function

```javascript
async function apiCall(url, options = {}, operation = 'API Call') {
    const startTime = performance.now();
    
    try {
        const response = await fetch(url, options);
        const endTime = performance.now();
        const responseTime = Math.round(endTime - startTime);
        
        logApiCall(operation, responseTime, response.ok);
        
        return response;
    } catch (error) {
        const endTime = performance.now();
        const responseTime = Math.round(endTime - startTime);
        
        logApiCall(operation + ' (ERROR)', responseTime, false);
        
        throw error;
    }
}
```

### Logging Function

```javascript
function logApiCall(operation, responseTimeMs, success = true) {
    totalRequests++;
    totalResponseTime += responseTimeMs;
    responseTimes.push(responseTimeMs);
    
    // Keep only last 100 response times
    if (responseTimes.length > 100) {
        responseTimes.shift();
    }
    
    // Update UI elements
    updateStatusDisplay(operation, responseTimeMs, success);
}
```

### Response Time Tracking

```javascript
// Global variables
let totalRequests = 0;
let totalResponseTime = 0;
let responseTimes = []; // Rolling window of last 100

// Calculate average
const avgTime = Math.round(
    responseTimes.reduce((a, b) => a + b, 0) / responseTimes.length
);
```

## Color Coding System

### Response Time Thresholds

| Range | Color | Class | Meaning |
|-------|-------|-------|---------|
| 0-199ms | Green (#48bb78) | response-time-good | Excellent |
| 200-499ms | Orange (#ed8936) | response-time-medium | Acceptable |
| 500ms+ | Red (#f56565) | response-time-slow | Poor |

### Status Indicator States

| State | Color | Animation | Trigger |
|-------|-------|-----------|---------|
| Idle | Gray (#718096) | None | Default state |
| Active | Green (#48bb78) | Pulse (2s) | During API call |
| Error | Red (#f56565) | Pulse (1s) | API call failed |

## Visual Styling

### CSS Classes

```css
.status-ribbon {
    position: fixed;
    bottom: 0;
    background: linear-gradient(135deg, #2d3748 0%, #1a202c 100%);
    color: white;
    font-family: 'Courier New', monospace;
    z-index: 1000;
}

.status-indicator {
    width: 8px;
    height: 8px;
    border-radius: 50%;
    animation: pulse 2s infinite;
}

@keyframes pulse {
    0%, 100% { opacity: 1; }
    50% { opacity: 0.5; }
}
```

### Responsive Design

**Desktop (> 768px)**:
- Full information displayed
- Font size: 0.85em
- Padding: 10px 20px
- All separators visible

**Mobile (≤ 768px)**:
- Condensed layout
- Font size: 0.7em
- Padding: 8px 10px
- Separators hidden
- Endpoint max-width: 150px

## Usage Examples

### Normal Operation
```
● API: abc123.execute-api.us-east-1.amazonaws.com/prod | 
Last Operation: POST progress [video-001] | 
Response Time: 145ms | 
Total Requests: 23 | 
Avg Response: 167ms
```

### Error State
```
● API: abc123.execute-api.us-east-1.amazonaws.com/prod | 
Last Operation: POST progress [video-001] (ERROR) | 
Response Time: 5234ms | 
Total Requests: 24 | 
Avg Response: 189ms
```

### Initial State (No API Configured)
```
● API: Not configured | 
Last Operation: None | 
Response Time: -- | 
Total Requests: 0 | 
Avg Response: --
```

### During Video Playback
```
Status updates every 3 seconds:

T+0s:  POST progress [video-001] | 152ms | Total: 15 | Avg: 178ms
T+3s:  POST progress [video-001] | 148ms | Total: 16 | Avg: 176ms
T+6s:  POST progress [video-001] | 156ms | Total: 17 | Avg: 175ms
T+9s:  POST progress [video-001] | 143ms | Total: 18 | Avg: 173ms
```

## Performance Monitoring Benefits

### 1. Real-Time Feedback
- See immediate impact of API changes
- Identify slow endpoints
- Monitor backend health

### 2. Debugging Aid
- Verify correct endpoint is being used
- Track failed requests
- Monitor request frequency

### 3. Performance Optimization
- Identify slow operations
- Compare response times across operations
- Track performance degradation

### 4. User Transparency
- Users see what's happening behind the scenes
- Build trust through visibility
- Educational for developers

## Typical Response Times

### Expected Performance

| Operation | Expected (ms) | Good (ms) | Poor (ms) |
|-----------|---------------|-----------|-----------|
| SCAN videos | 150-300 | < 200 | > 500 |
| GET progress | 50-150 | < 100 | > 300 |
| POST progress | 100-250 | < 200 | > 400 |

### Factors Affecting Response Time

1. **Network Latency**: Distance to AWS region
2. **DynamoDB Performance**: Table size, indexes
3. **Lambda Cold Starts**: First request slower
4. **API Gateway**: Throttling, rate limits
5. **Client Connection**: WiFi vs cellular

## Troubleshooting

### High Response Times

**Symptom**: Response times consistently > 500ms

**Potential Causes**:
1. **Network Issues**
   - Check internet connection
   - Try different network
   - Check for VPN interference

2. **DynamoDB Throttling**
   - Check CloudWatch metrics
   - Verify provisioned capacity
   - Consider on-demand mode

3. **Lambda Cold Starts**
   - Implement Lambda warming
   - Increase concurrent executions
   - Use provisioned concurrency

4. **API Gateway Issues**
   - Check throttle settings
   - Review CloudWatch logs
   - Verify route configuration

### Error States

**Symptom**: Red indicator, ERROR in operation

**Check**:
1. Browser console for error messages
2. Network tab in DevTools
3. API Gateway logs
4. Lambda CloudWatch logs

### No Updates

**Symptom**: Status ribbon not updating

**Check**:
1. API endpoint configured correctly
2. JavaScript console for errors
3. Browser DevTools network tab
4. Refresh page

## Advanced Features

### Custom Operation Labeling

```javascript
// In your code
await apiCall(url, options, 'Custom Operation Name');

// Examples
await apiCall(scanUrl, {}, 'Load All Videos');
await apiCall(progressUrl, {}, 'Save Viewing Progress');
```

### Response Time Alerts

```javascript
function logApiCall(operation, responseTimeMs, success) {
    // ... existing code ...
    
    // Alert on slow requests
    if (responseTimeMs > 1000) {
        console.warn(`Slow API call: ${operation} took ${responseTimeMs}ms`);
    }
    
    // Alert on errors
    if (!success) {
        console.error(`API call failed: ${operation}`);
    }
}
```

### Statistics Export

```javascript
function getApiStats() {
    return {
        totalRequests: totalRequests,
        totalResponseTime: totalResponseTime,
        avgResponseTime: Math.round(
            responseTimes.reduce((a, b) => a + b, 0) / responseTimes.length
        ),
        recentResponseTimes: responseTimes.slice(-10),
        endpoint: document.getElementById('apiEndpoint').value
    };
}

// Export stats
console.log(getApiStats());
```

### Performance Monitoring Dashboard

```javascript
// Track performance over time
const performanceLog = [];

function logApiCall(operation, responseTimeMs, success) {
    // ... existing code ...
    
    performanceLog.push({
        timestamp: new Date().toISOString(),
        operation: operation,
        responseTime: responseTimeMs,
        success: success
    });
    
    // Keep last 1000 entries
    if (performanceLog.length > 1000) {
        performanceLog.shift();
    }
}

// Analyze performance
function analyzePerformance() {
    const byOperation = {};
    
    performanceLog.forEach(log => {
        if (!byOperation[log.operation]) {
            byOperation[log.operation] = [];
        }
        byOperation[log.operation].push(log.responseTime);
    });
    
    return Object.entries(byOperation).map(([op, times]) => ({
        operation: op,
        count: times.length,
        avg: Math.round(times.reduce((a, b) => a + b, 0) / times.length),
        min: Math.min(...times),
        max: Math.max(...times)
    }));
}

console.table(analyzePerformance());
```

## Integration with Monitoring Tools

### CloudWatch Integration

The status ribbon complements CloudWatch monitoring:

```
Client Side (Status Ribbon)     Server Side (CloudWatch)
─────────────────────────       ─────────────────────────
Response Time: 145ms       →    API Gateway Latency
Total Requests: 23         →    Request Count
Avg Response: 167ms        →    Average Latency
Operation: POST progress   →    Method/Resource metrics
```

### Best Practices

1. **Monitor Both Sides**: Use status ribbon + CloudWatch
2. **Set Alerts**: CloudWatch alarms for backend issues
3. **Compare Metrics**: Client vs server response times
4. **Track Trends**: Look for degradation over time
5. **Debug Correlation**: Match client errors to server logs

## Future Enhancements

Potential improvements:

- [ ] Export statistics to CSV
- [ ] Performance graphs/charts
- [ ] Request history panel
- [ ] Per-operation statistics
- [ ] Error rate tracking
- [ ] Bandwidth monitoring
- [ ] Request/response size
- [ ] Toggle ribbon visibility
- [ ] Full-screen mode
- [ ] Custom color themes

---

**The status ribbon provides real-time visibility into all API operations!** Monitor performance, debug issues, and understand your application's behavior at a glance.
