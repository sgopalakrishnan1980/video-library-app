# Video Library Application

A serverless video library application that stores video metadata in DynamoDB and serves a static website from S3.

## 🎯 Features

- **Two-Section Layout**: "Continue Watching" and "Library" sections
- **Continue Watching**: Highlights in-progress videos with resume bookmarks
- **Progress Tracking**: Automatically saves viewing position every 3 seconds
- **Resume Playback**: Returns to last watched position when reopening videos
- **Progress Visualization**: Visual progress bars and percentage indicators
- **Real-Time Monitoring**: Status ribbon shows API endpoint and response times ⭐ NEW
- **Performance Metrics**: Track total requests and average response times
- **Static Website**: Beautiful, responsive HTML interface hosted on S3
- **Video Player**: Native HTML5 video player supporting MP4, WebM, and Ogg formats
- **Serverless Backend**: DynamoDB + Lambda + API Gateway
- **Easy Deployment**: One-command CloudFormation deployment
- **CORS Enabled**: Works seamlessly across origins
- **Cost Effective**: Pay-per-use pricing model

## 📋 Files Included

- `video-library.html` - Static website interface with two-section layout and monitoring
- `lambda-function.js` - Lambda function for API operations
- `cloudformation-template.yaml` - Infrastructure as Code
- `sample-data.json` - Sample video data
- `batch-write-items.json` - DynamoDB batch load format
- `deploy.sh` - Automated deployment script
- `DEPLOYMENT_GUIDE.md` - Detailed deployment instructions
- `PROGRESS_TRACKING_GUIDE.md` - Video progress tracking documentation
- `TWO_SECTION_LAYOUT_GUIDE.md` - Two-section layout documentation
- `STATUS_RIBBON_GUIDE.md` - API monitoring status ribbon documentation ⭐ NEW

## 🚀 Quick Start

### Option 1: Automated Deployment (Recommended)

```bash
# Make script executable
chmod +x deploy.sh

# Run deployment
./deploy.sh
```

### Option 2: CloudFormation Deployment

```bash
aws cloudformation create-stack \
  --stack-name video-library \
  --template-body file://cloudformation-template.yaml \
  --parameters ParameterKey=S3BucketName,ParameterValue=my-unique-bucket-name \
  --capabilities CAPABILITY_IAM
```

### Option 3: Manual Deployment

See `DEPLOYMENT_GUIDE.md` for detailed manual deployment steps.

## 🏗️ Architecture

```
┌─────────────┐
│   Browser   │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  S3 Static  │
│   Website   │
└──────┬──────┘
       │
       ▼
┌─────────────┐      ┌─────────┐      ┌──────────┐
│ API Gateway │─────▶│ Lambda  │─────▶│ DynamoDB │
└─────────────┘      └─────────┘      └──────────┘
```

## 📊 DynamoDB Schema

**Table Name**: VideoLibrary

| Attribute | Type | Key Type | Description |
|-----------|------|----------|-------------|
| pk | String | HASH | Primary key (e.g., "Library") |
| videoId | String | RANGE | Unique video identifier |
| title | String | - | Video title |
| link | String | - | URL to video file |
| description | String | - | Video description (optional) |
| duration | String | - | Video duration (optional) |
| uploadDate | String | - | Upload date (optional) |

## 🔌 API Endpoints

### Scan Videos
```
GET /scan?pk=Library
```
Returns all videos matching the primary key.

### Get Single Video
```
GET /videos?pk=Library&videoId=video-001
```
Returns a specific video by ID.

### Save Video Progress ⭐ NEW
```
POST /progress
Body: {
  "userId": "user-12345",
  "videoId": "video-001",
  "currentTime": 125.5,
  "completed": false
}
```
Saves the user's playback position (called automatically every 3 seconds).

### Get Video Progress ⭐ NEW
```
GET /progress?userId=user-12345&videoId=video-001
```
Retrieves the user's last saved position for a video.

## 🎥 Adding Videos

### Method 1: AWS Console
1. Navigate to DynamoDB → VideoLibrary table
2. Click "Create item"
3. Add required attributes

### Method 2: AWS CLI
```bash
aws dynamodb put-item \
  --table-name VideoLibrary \
  --item '{
    "pk": {"S": "Library"},
    "videoId": {"S": "video-001"},
    "title": {"S": "My Video"},
    "link": {"S": "https://example.com/video.mp4"}
  }'
```

### Method 3: Batch Upload
```bash
aws dynamodb batch-write-item \
  --request-items file://batch-write-items.json
```

## 🎨 Using the Web Interface

1. Open the S3 website URL
2. Enter your API Gateway endpoint
3. Enter primary key (default: "Library")
4. Click "Save Configuration"
5. Click "Load Videos"
6. Click any video card to play
7. **Progress is automatically saved every 3 seconds** ⭐
8. **Return to the same video later to resume where you left off** ⭐

## 💰 Cost Estimate

For a typical low-traffic application:

| Service | Cost |
|---------|------|
| DynamoDB | ~$0.10/month |
| Lambda | Free tier (1M requests) |
| API Gateway | ~$0.10/month |
| S3 | ~$0.05/month |
| **Total** | **~$0.25/month** |

## 🔒 Security Best Practices

**Current Setup (Development):**
- ✅ CORS enabled
- ✅ Lambda execution role with minimal permissions
- ✅ Public S3 bucket (read-only)

**For Production, Add:**
- 🔐 CloudFront distribution with SSL
- 🔐 API Gateway authentication (Cognito)
- 🔐 WAF for API protection
- 🔐 Restrict S3 to CloudFront only
- 🔐 Enable DynamoDB encryption
- 🔐 VPC endpoints for Lambda
- 🔐 Rate limiting on API Gateway

## 🧪 Testing

### Test DynamoDB
```bash
aws dynamodb scan \
  --table-name VideoLibrary \
  --filter-expression "pk = :pk" \
  --expression-attribute-values '{":pk":{"S":"Library"}}'
```

### Test API
```bash
curl "https://YOUR_API_ID.execute-api.REGION.amazonaws.com/prod/scan?pk=Library"
```

### Test Website
Open the S3 website URL in your browser.

## 🐛 Troubleshooting

**Videos not loading?**
- Check API endpoint URL
- Verify CORS settings
- Check browser console for errors

**Videos not playing?**
- Ensure video URL is accessible
- Check video format (MP4 recommended)
- Verify CORS on video hosting

**API returning errors?**
- Check Lambda CloudWatch logs
- Verify DynamoDB permissions
- Test Lambda function directly

## 📝 Supported Video Formats

- **MP4** (H.264) - Best compatibility ✅
- **WebM** - Good browser support
- **Ogg** - Limited support

## 🧹 Cleanup

```bash
# Delete CloudFormation stack (deletes everything)
aws cloudformation delete-stack --stack-name video-library

# Or delete manually
aws s3 rb s3://your-bucket-name --force
aws apigatewayv2 delete-api --api-id YOUR_API_ID
aws lambda delete-function --function-name VideoLibraryAPI
aws dynamodb delete-table --table-name VideoLibrary
```

## 🔄 Updates and Modifications

### Update Lambda Code
```bash
zip lambda-function.zip lambda-function.js
aws lambda update-function-code \
  --function-name VideoLibraryAPI \
  --zip-file fileb://lambda-function.zip
```

### Update Website
```bash
aws s3 cp video-library.html s3://your-bucket-name/
```

### Update CloudFormation Stack
```bash
aws cloudformation update-stack \
  --stack-name video-library \
  --template-body file://cloudformation-template.yaml \
  --capabilities CAPABILITY_IAM
```

## 📚 Additional Resources

- [AWS DynamoDB Documentation](https://docs.aws.amazon.com/dynamodb/)
- [AWS Lambda Documentation](https://docs.aws.amazon.com/lambda/)
- [API Gateway Documentation](https://docs.aws.amazon.com/apigateway/)
- [S3 Static Website Hosting](https://docs.aws.amazon.com/AmazonS3/latest/userguide/WebsiteHosting.html)

## 🤝 Contributing

Suggestions for improvements:
1. Add video thumbnails
2. Implement search functionality
3. Add user authentication
4. Video upload interface
5. Admin dashboard
6. Video analytics
7. Comments and ratings
8. Playlist support

## 📄 License

This is a sample application for educational purposes.

## 🙋 Support

For issues:
1. Check `DEPLOYMENT_GUIDE.md`
2. Review CloudWatch logs
3. Verify IAM permissions
4. Test components individually

---

**Built with AWS Serverless Services** ⚡
