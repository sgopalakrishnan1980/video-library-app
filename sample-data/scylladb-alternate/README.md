# ScyllaDB Monster Scale Summit - Sample Video Data

## Overview

This alternate sample data set contains 12 videos from ScyllaDB's Monster Scale Summit conference, featuring keynotes, technical deep dives, customer stories, and product demonstrations.

## Files Included

- **scylladb-sample-data.json** - Human-readable JSON format
- **scylladb-batch-write-items.json** - DynamoDB batch write format

## Video Categories

### Keynotes (1)
- Monster Scale Summit 2024 - Opening Keynote

### Technical Deep Dives (3)
- Building AI Applications with ScyllaDB
- ScyllaDB Architecture Deep Dive
- ScyllaDB Performance Optimization Techniques

### Customer Stories (3)
- Gaming at Monster Scale: Discord's Journey with ScyllaDB
- Comcast's Journey to 1 Trillion Messages with ScyllaDB
- From Cassandra to ScyllaDB: Migration Best Practices

### Use Cases (1)
- Real-Time Analytics at Scale with ScyllaDB

### Product Demos (1)
- ScyllaDB Cloud: Fully Managed Database as a Service

### Architecture & Data Modeling (2)
- Multi-Region Deployment Strategies
- Time Series Data at Scale with ScyllaDB

### Benchmarks (1)
- ScyllaDB vs DynamoDB: Performance Comparison

## Video Metadata

Each video includes:

- **videoId**: Unique identifier (mss-001 through mss-012)
- **title**: Full video title
- **link**: Video URL (using Google test videos)
- **description**: Detailed description of content
- **duration**: Video length in MM:SS or HH:MM:SS format
- **uploadDate**: Conference date (October 2024)
- **category**: Video category (Keynote, Technical Deep Dive, etc.)
- **speaker**: Presenter name and title

## Featured Speakers

- **Dor Laor** - CEO & Co-Founder, ScyllaDB
- **Avi Kivity** - CTO & Co-Founder, ScyllaDB
- **Piotr Sarna** - VP Engineering, ScyllaDB
- **Tzach Livyatan** - VP Product, ScyllaDB
- **Guy Shtub** - Solutions Architect, ScyllaDB
- **Cynthia Dunlop** - Developer Advocate, ScyllaDB
- **Felipe Cardeneti Mendes** - Principal Product Manager, ScyllaDB
- **Bo Ingram** - Senior Staff Engineer, Discord
- **Nate McCall** - Engineering Manager, Comcast

## Loading Sample Data

### Method 1: Using AWS CLI (Recommended)

```bash
# Replace us-east-1 with your target region (e.g., eu-west-1, ap-south-1)
aws dynamodb batch-write-item \
  --request-items file://scylladb-batch-write-items.json \
  --region us-east-1
```

### Method 2: During Deployment

Replace the sample data files in your deployment:

```bash
# In your video-library-app directory
cp scylladb-sample-data.json sample-data/sample-data.json
cp scylladb-batch-write-items.json sample-data/batch-write-items.json

# Deploy (default: us-east-1)
./scripts/deploy.sh

# Or deploy to a specific region
./scripts/deploy.sh --region eu-west-1
```

### Method 3: Manual DynamoDB Console

1. Open DynamoDB Console
2. Select your VideoLibrary table
3. Click "Actions" → "Create item"
4. Copy data from scylladb-sample-data.json
5. Add each video as a new item

### Method 4: Programmatic Load

```python
import boto3
import json

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('VideoLibrary')

# Load from JSON file
with open('scylladb-sample-data.json', 'r') as f:
    videos = json.load(f)

# Write to DynamoDB
with table.batch_writer() as batch:
    for video in videos:
        batch.put_item(Item=video)

print(f"Loaded {len(videos)} videos successfully!")
```

## Replacing Placeholder Videos

These sample videos use Google's public test videos as placeholders. To use actual ScyllaDB conference videos:

### Step 1: Get Real Video URLs

You'll need publicly accessible URLs for the actual Monster Scale Summit videos:

- YouTube URLs (converted to embed or direct links)
- S3 URLs (if videos are hosted on S3)
- CloudFront URLs (for CDN delivery)
- Any other public video hosting

### Step 2: Update the JSON Files

Edit `scylladb-sample-data.json` and replace the `link` fields:

```json
{
  "videoId": "mss-001",
  "title": "Monster Scale Summit 2024 - Opening Keynote",
  "link": "https://your-cdn.com/keynote-2024.mp4",  // ← Update this
  "description": "...",
  ...
}
```

### Step 3: Update Video Durations

Get the actual durations and update the `duration` field:

```bash
# Using ffprobe (part of ffmpeg)
ffprobe -v error -show_entries format=duration \
  -of default=noprint_wrappers=1:nokey=1 video.mp4

# Convert seconds to MM:SS or HH:MM:SS format
```

### Step 4: Reload Data

```bash
REGION=us-east-1  # Use your deployment region

# Clear existing data
aws dynamodb scan --table-name VideoLibrary \
  --attributes-to-get "pk" "videoId" \
  --query "Items[*].[pk.S,videoId.S]" \
  --output text --region $REGION | \
while read pk videoId; do
  aws dynamodb delete-item \
    --table-name VideoLibrary \
    --key "{\"pk\":{\"S\":\"$pk\"},\"videoId\":{\"S\":\"$videoId\"}}" \
    --region $REGION
done

# Load new data
aws dynamodb batch-write-item \
  --request-items file://scylladb-batch-write-items.json \
  --region $REGION
```

## Adding More Videos

To add additional Monster Scale Summit videos:

```bash
aws dynamodb put-item \
  --table-name VideoLibrary \
  --item '{
    "pk": {"S": "Library"},
    "videoId": {"S": "mss-013"},
    "title": {"S": "Your Video Title"},
    "link": {"S": "https://www.youtube.com/watch?v=VIDEO_ID"},
    "description": {"S": "Video description"},
    "duration": {"S": "15:30"},
    "uploadDate": {"S": "2024-10-17"},
    "category": {"S": "Technical Deep Dive"},
    "speaker": {"S": "Speaker Name - Title, Company"}
  }' \
  --region us-east-1
```

## Video Categories Reference

When adding new videos, use these standardized categories:

- **Keynote** - Opening/closing keynotes, major announcements
- **Technical Deep Dive** - In-depth technical presentations
- **Customer Story** - Case studies from ScyllaDB customers
- **Use Case** - Specific use case implementations
- **Product Demo** - Product features and demonstrations
- **Architecture** - System design and architecture patterns
- **Data Modeling** - Data modeling best practices
- **Performance** - Performance optimization techniques
- **Benchmarks** - Performance comparisons and benchmarks
- **Case Study** - Migration and implementation stories

## Testing the Sample Data

After loading:

```bash
# Verify data loaded (add --region YOUR_REGION to all commands)
aws dynamodb scan --table-name VideoLibrary --select COUNT --region us-east-1

# List all videos
aws dynamodb scan \
  --table-name VideoLibrary \
  --filter-expression "pk = :pk" \
  --expression-attribute-values '{":pk":{"S":"Library"}}' \
  --projection-expression "videoId, title, speaker" \
  --region us-east-1

# Get specific video
aws dynamodb get-item \
  --table-name VideoLibrary \
  --key '{"pk":{"S":"Library"},"videoId":{"S":"mss-001"}}' \
  --region us-east-1
```

## ScyllaDB Context

### About ScyllaDB

ScyllaDB is a NoSQL database compatible with Apache Cassandra and Amazon DynamoDB. It's designed for applications requiring:

- **Ultra-low latency** (<1ms p99)
- **High throughput** (millions of ops/sec per node)
- **Linear scalability** (add nodes without downtime)
- **Full compatibility** (drop-in replacement for Cassandra/DynamoDB)

### Monster Scale Summit

Monster Scale Summit is ScyllaDB's annual user conference featuring:

- Technical keynotes from ScyllaDB leadership
- Customer success stories from companies like Discord, Comcast, Expedia
- Deep technical sessions on architecture and optimization
- Product announcements and roadmap updates
- Hands-on workshops and demos

### Key Themes from Monster Scale Summit 2024

1. **AI/ML Workloads** - Using ScyllaDB for vector embeddings and AI applications
2. **Cloud-Native** - ScyllaDB Cloud managed service capabilities
3. **Migration Stories** - Moving from Cassandra/DynamoDB to ScyllaDB
4. **Extreme Scale** - Handling trillions of operations
5. **Performance** - Sub-millisecond latency at scale

## Additional Resources

- **ScyllaDB Website**: https://www.scylladb.com
- **Documentation**: https://docs.scylladb.com
- **University**: https://university.scylladb.com
- **YouTube Channel**: https://youtube.com/@ScyllaDB
- **GitHub**: https://github.com/scylladb/scylladb

## Support

For questions about:

- **ScyllaDB Product**: support@scylladb.com
- **Sample Data**: Check the main video library documentation
- **Monster Scale Summit**: events@scylladb.com

## License

Sample data structure: MIT License
ScyllaDB branding and content: © ScyllaDB Inc.

---

**Note**: This sample data uses placeholder video URLs from Google's public test videos. Replace with actual Monster Scale Summit video URLs for production use.

For the actual Monster Scale Summit videos, visit the ScyllaDB YouTube channel or contact ScyllaDB for access to conference recordings.
