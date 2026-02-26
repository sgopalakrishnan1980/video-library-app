# Sample Data Options

This directory contains sample video data for testing the video library application.

## Available Sample Data Sets

### 1. Generic Test Videos (Default)

**Files:**
- `sample-data.json` - 7 generic test videos
- `batch-write-items.json` - DynamoDB batch format

**Content:**
- Big Buck Bunny (Animation, 9:56)
- Elephants Dream (Animation, 10:53)
- For Bigger Blazes (Commercial, 0:15)
- For Bigger Escape (Commercial, 0:15)
- For Bigger Fun (Commercial, 0:15)
- Sintel (Animation, 14:48)
- Tears of Steel (Sci-Fi, 12:14)

**Use Case:**
- Quick testing and demos
- Generic content appropriate for any audience
- Actual video titles match the Google test video content

**Notes:**
These use Google's public test videos with titles and descriptions that accurately match the actual video content. Perfect for testing the application without any context confusion.

### 2. ScyllaDB Monster Scale Summit (Alternate)

**Location:** `scylladb-alternate/`

**Files:**
- `scylladb-sample-data.json` - 12 conference videos
- `scylladb-batch-write-items.json` - DynamoDB batch format
- `README.md` - Detailed documentation

**Content:**
- 12 videos from ScyllaDB's Monster Scale Summit 2024
- Includes keynotes, technical sessions, customer stories
- Features real speakers: Dor Laor, Avi Kivity, Piotr Sarna, and more
- Categorized by type: Keynote, Technical Deep Dive, Customer Story, etc.

**Use Case:**
- ScyllaDB-specific demos and presentations
- Conference video library simulation
- Professional business context

**Important Notes:**
- ⚠️ Uses Google test videos as **placeholders**
- Titles, speakers, and descriptions are ScyllaDB-specific
- Video content does NOT match the titles (generic test videos)
- To use real videos, replace the `link` URLs with actual conference recordings
- See `scylladb-alternate/README.md` for complete instructions

## Loading Sample Data

### Option 1: Load Default Generic Videos

These are loaded automatically by the deployment script:

```bash
./scripts/deploy.sh
```

Or manually:

```bash
aws dynamodb batch-write-item \
  --request-items file://sample-data/batch-write-items.json
```

### Option 2: Load ScyllaDB Videos

```bash
aws dynamodb batch-write-item \
  --request-items file://sample-data/scylladb-alternate/scylladb-batch-write-items.json
```

### Option 3: Switch Sample Data Before Deployment

Replace the default files with ScyllaDB data:

```bash
# Backup originals
mv sample-data/sample-data.json sample-data/sample-data.json.bak
mv sample-data/batch-write-items.json sample-data/batch-write-items.json.bak

# Use ScyllaDB data
cp sample-data/scylladb-alternate/scylladb-sample-data.json sample-data/sample-data.json
cp sample-data/scylladb-alternate/scylladb-batch-write-items.json sample-data/batch-write-items.json

# Deploy
./scripts/deploy.sh
```

## Comparison

| Feature | Generic Videos | ScyllaDB Videos |
|---------|---------------|-----------------|
| **Count** | 7 videos | 12 videos |
| **Context** | Generic test content | ScyllaDB conference |
| **Titles Match Content** | ✅ Yes | ❌ No (placeholders) |
| **Speaker Info** | ❌ No | ✅ Yes |
| **Categories** | Animation, Commercial, Sci-Fi | Keynote, Technical, Customer Story |
| **Business Context** | ❌ Generic | ✅ Professional |
| **Ready to Use** | ✅ Yes | ⚠️ Needs real video URLs |
| **Use Case** | Testing, demos | Business presentations |

## Creating Your Own Sample Data

### JSON Format

```json
[
  {
    "pk": "Library",
    "videoId": "unique-id",
    "title": "Video Title",
    "link": "https://your-video-url.mp4",
    "description": "Video description",
    "duration": "10:25",
    "uploadDate": "2024-01-15",
    "category": "Your Category",
    "speaker": "Speaker Name (optional)"
  }
]
```

### DynamoDB Batch Format

```json
{
  "VideoLibrary": [
    {
      "PutRequest": {
        "Item": {
          "pk": { "S": "Library" },
          "videoId": { "S": "unique-id" },
          "title": { "S": "Video Title" },
          "link": { "S": "https://your-video-url.mp4" },
          "description": { "S": "Video description" },
          "duration": { "S": "10:25" },
          "uploadDate": { "S": "2024-01-15" },
          "category": { "S": "Your Category" }
        }
      }
    }
  ]
}
```

## Supported Video Formats

- **MP4** (H.264) - Recommended, best compatibility
- **WebM** - Good browser support
- **Ogg** - Limited support

## Video Hosting Options

- Amazon S3
- CloudFront CDN
- YouTube (embed URLs)
- Google Cloud Storage
- Any publicly accessible HTTPS URL

## Clearing Sample Data

To remove all videos and start fresh:

```bash
# Scan for all items
aws dynamodb scan --table-name VideoLibrary \
  --attributes-to-get "pk" "videoId" \
  --query "Items[*].[pk.S,videoId.S]" \
  --output text | \
while read pk videoId; do
  aws dynamodb delete-item \
    --table-name VideoLibrary \
    --key "{\"pk\":{\"S\":\"$pk\"},\"videoId\":{\"S\":\"$videoId\"}}"
done
```

## Adding Individual Videos

```bash
aws dynamodb put-item \
  --table-name VideoLibrary \
  --item '{
    "pk": {"S": "Library"},
    "videoId": {"S": "my-video-001"},
    "title": {"S": "My Video Title"},
    "link": {"S": "https://my-video-url.mp4"},
    "duration": {"S": "15:30"}
  }'
```

## Tips

1. **Duration Format**: Use MM:SS for videos under 1 hour, HH:MM:SS for longer
2. **Video IDs**: Use meaningful prefixes (e.g., `mss-001`, `tutorial-001`)
3. **Categories**: Keep consistent category names for better organization
4. **Descriptions**: Add detailed descriptions for better context
5. **Upload Dates**: Use ISO format (YYYY-MM-DD)

## Documentation

- **Generic Videos**: Self-explanatory, uses actual video titles
- **ScyllaDB Videos**: See `scylladb-alternate/README.md` for detailed info

## Support

For questions about:
- Sample data structure → Check main project docs
- ScyllaDB videos → See `scylladb-alternate/README.md`
- Adding your own videos → See main DEPLOYMENT_GUIDE.md

---

**Default:** Generic test videos (titles match content)  
**Alternate:** ScyllaDB conference videos (professional context, placeholder URLs)

Choose the sample data that best fits your use case!
