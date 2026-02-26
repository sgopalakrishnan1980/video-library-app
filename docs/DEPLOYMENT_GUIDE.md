# Video Library - Deployment Guide

## Overview
This solution provides a static web page hosted on S3 that connects to DynamoDB via API Gateway and Lambda to display and play videos.

## Architecture
```
┌─────────┐     ┌──────────────┐     ┌────────┐     ┌──────────┐
│ Browser │────▶│ S3 (Static)  │     │ Lambda │────▶│ DynamoDB │
│         │     │   Website    │     │        │     │  Table   │
└─────────┘     └──────────────┘     └────────┘     └──────────┘
                       │                    ▲
                       │                    │
                       └──────▶ API Gateway─┘
```

## Prerequisites
- AWS Account
- AWS CLI configured with appropriate credentials
- Permissions to create: S3, DynamoDB, Lambda, API Gateway, IAM roles

## Region Selection

All resources (DynamoDB, Lambda, API Gateway, S3) are deployed to a single AWS region. Specify the region via:

- **Deploy script:** `./scripts/deploy.sh --region eu-west-1`
- **Environment variable:** `AWS_REGION=ap-south-1 ./scripts/deploy.sh`
- **AWS CLI:** `--region <region>` on each command

Replace `us-east-1` in the examples below with your chosen region (e.g., `eu-west-1`, `ap-south-1`).

## Deployment Methods

### Method 1: Deploy Script (Recommended)

One-command deployment with region support:

```bash
# Deploy to default region (us-east-1)
./scripts/deploy.sh

# Deploy to a specific region
./scripts/deploy.sh --region eu-west-1
./scripts/deploy.sh -r ap-south-1

# Or use environment variable
AWS_REGION=eu-central-1 ./scripts/deploy.sh
```

### Method 2: CloudFormation (Manual)

1. **Deploy the stack:**
```bash
REGION=us-east-1  # or eu-west-1, ap-south-1, etc.

aws cloudformation create-stack \
  --stack-name video-library \
  --template-body file://infrastructure/cloudformation-template.yaml \
  --parameters ParameterKey=S3BucketName,ParameterValue=my-video-library-bucket-12345 \
  --capabilities CAPABILITY_IAM \
  --region $REGION
```

2. **Wait for stack creation:**
```bash
aws cloudformation wait stack-create-complete \
  --stack-name video-library \
  --region $REGION
```

3. **Get outputs:**
```bash
aws cloudformation describe-stacks \
  --stack-name video-library \
  --region $REGION \
  --query 'Stacks[0].Outputs'
```

### Method 3: Manual Setup

Use `$REGION` or replace with your target region (e.g., `us-east-1`, `eu-west-1`).

#### Step 1: Create DynamoDB Table
```bash
REGION=us-east-1  # Set your target region

aws dynamodb create-table \
  --table-name VideoLibrary \
  --attribute-definitions \
    AttributeName=pk,AttributeType=S \
    AttributeName=videoId,AttributeType=S \
  --key-schema \
    AttributeName=pk,KeyType=HASH \
    AttributeName=videoId,KeyType=RANGE \
  --billing-mode PAY_PER_REQUEST \
  --region $REGION
```

#### Step 2: Load Sample Data
```bash
# Load each video item
aws dynamodb put-item \
  --table-name VideoLibrary \
  --item '{
    "pk": {"S": "Library"},
    "videoId": {"S": "video-001"},
    "title": {"S": "Introduction to AWS"},
    "link": {"S": "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"}
  }' \
  --region $REGION

# Repeat for other videos...
```

Or use batch write:
```bash
aws dynamodb batch-write-item \
  --request-items file://sample-data/batch-write-items.json \
  --region $REGION
```

#### Step 3: Create Lambda Function

1. **Create IAM Role:**
```bash
aws iam create-role \
  --role-name VideoLibraryLambdaRole \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {"Service": "lambda.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }]
  }'
```

2. **Attach policies:**
```bash
aws iam attach-role-policy \
  --role-name VideoLibraryLambdaRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

aws iam put-role-policy \
  --role-name VideoLibraryLambdaRole \
  --policy-name DynamoDBAccess \
  --policy-document "{
    \"Version\": \"2012-10-17\",
    \"Statement\": [{
      \"Effect\": \"Allow\",
      \"Action\": [
        \"dynamodb:GetItem\",
        \"dynamodb:Scan\",
        \"dynamodb:Query\"
      ],
      \"Resource\": \"arn:aws:dynamodb:${REGION}:*:table/VideoLibrary\"
    }]
  }"
```

3. **Create deployment package:**
```bash
zip lambda-function.zip lambda-function.js
```

4. **Create Lambda function:**
```bash
aws lambda create-function \
  --function-name VideoLibraryAPI \
  --runtime nodejs18.x \
  --role arn:aws:iam::YOUR_ACCOUNT_ID:role/VideoLibraryLambdaRole \
  --handler lambda-function.handler \
  --zip-file fileb://lambda-function.zip \
  --environment Variables={TABLE_NAME=VideoLibrary,PRIMARY_KEY=pk} \
  --region $REGION
```

#### Step 4: Create API Gateway

1. **Create HTTP API:**
```bash
aws apigatewayv2 create-api \
  --name VideoLibraryAPI \
  --protocol-type HTTP \
  --cors-configuration AllowOrigins="*",AllowMethods="GET,OPTIONS",AllowHeaders="*" \
  --region $REGION
```

2. **Create integration:**
```bash
aws apigatewayv2 create-integration \
  --api-id YOUR_API_ID \
  --integration-type AWS_PROXY \
  --integration-uri arn:aws:lambda:${REGION}:YOUR_ACCOUNT_ID:function:VideoLibraryAPI \
  --payload-format-version 2.0 \
  --region $REGION
```

3. **Create routes:**
```bash
# Scan route
aws apigatewayv2 create-route \
  --api-id YOUR_API_ID \
  --route-key "GET /scan" \
  --target integrations/YOUR_INTEGRATION_ID \
  --region $REGION

# Get route
aws apigatewayv2 create-route \
  --api-id YOUR_API_ID \
  --route-key "GET /videos" \
  --target integrations/YOUR_INTEGRATION_ID \
  --region $REGION
```

4. **Create stage:**
```bash
aws apigatewayv2 create-stage \
  --api-id YOUR_API_ID \
  --stage-name prod \
  --auto-deploy \
  --region $REGION
```

5. **Grant API Gateway permission to invoke Lambda:**
```bash
aws lambda add-permission \
  --function-name VideoLibraryAPI \
  --statement-id apigateway-invoke \
  --action lambda:InvokeFunction \
  --principal apigateway.amazonaws.com \
  --source-arn "arn:aws:execute-api:${REGION}:YOUR_ACCOUNT_ID:YOUR_API_ID/*/*" \
  --region $REGION
```

#### Step 5: Create S3 Bucket and Deploy Website

1. **Create bucket:**
```bash
aws s3 mb s3://my-video-library-bucket-12345 --region $REGION
```

2. **Enable static website hosting:**
```bash
aws s3 website s3://my-video-library-bucket-12345 \
  --index-document video-library.html \
  --error-document error.html
```

3. **Set bucket policy:**
```bash
aws s3api put-bucket-policy \
  --bucket my-video-library-bucket-12345 \
  --policy '{
    "Version": "2012-10-17",
    "Statement": [{
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::my-video-library-bucket-12345/*"
    }]
  }'
```

4. **Upload website:**
```bash
aws s3 cp video-library.html s3://my-video-library-bucket-12345/
```

5. **Disable public access blocks:**
```bash
aws s3api delete-public-access-block \
  --bucket my-video-library-bucket-12345
```

## Configuration

After deployment, configure the web page:

1. Open the S3 website URL: `http://my-video-library-bucket-12345.s3-website-YOUR_REGION.amazonaws.com`
2. Enter your API Gateway endpoint: `https://YOUR_API_ID.execute-api.YOUR_REGION.amazonaws.com/prod`
3. Enter primary key: `Library`
4. Click "Save Configuration"
5. Click "Load Videos"

## API Endpoints

### Scan Endpoint
```
GET /scan?pk=Library
```
Returns all videos with the specified primary key.

### Get Endpoint
```
GET /videos?pk=Library
```
Returns a single item (when using GET operation) or filtered results.

## DynamoDB Table Structure

**Table Name:** VideoLibrary

**Primary Key:**
- Partition Key: `pk` (String)
- Sort Key: `videoId` (String)

**Attributes:**
- `title` (String) - Video title
- `link` (String) - URL to video file
- `description` (String, optional) - Video description
- `duration` (String, optional) - Video duration
- `uploadDate` (String, optional) - Upload date

## Testing

### Test DynamoDB
```bash
aws dynamodb scan \
  --table-name VideoLibrary \
  --filter-expression "pk = :pk" \
  --expression-attribute-values '{":pk":{"S":"Library"}}' \
  --region $REGION
```

### Test Lambda
```bash
aws lambda invoke \
  --function-name VideoLibraryAPI \
  --payload '{
    "httpMethod": "GET",
    "path": "/scan",
    "queryStringParameters": {"pk": "Library"}
  }' \
  response.json \
  --region $REGION

cat response.json
```

### Test API
```bash
curl "https://YOUR_API_ID.execute-api.YOUR_REGION.amazonaws.com/prod/scan?pk=Library"
```

## Adding Your Own Videos

### Option 1: AWS Console
1. Go to DynamoDB console
2. Select VideoLibrary table
3. Click "Create item"
4. Add attributes:
   - `pk`: Library
   - `videoId`: unique-id
   - `title`: Your video title
   - `link`: URL to your video

### Option 2: AWS CLI
```bash
aws dynamodb put-item \
  --table-name VideoLibrary \
  --item '{
    "pk": {"S": "Library"},
    "videoId": {"S": "my-video-001"},
    "title": {"S": "My Custom Video"},
    "link": {"S": "https://your-video-url.mp4"}
  }' \
  --region $REGION
```

### Option 3: Using Your Own S3 Videos
1. Upload videos to S3 bucket
2. Make them public or use CloudFront
3. Use the S3 URL in the `link` field

## Supported Video Formats

The HTML5 video player supports:
- MP4 (H.264)
- WebM
- Ogg

For best compatibility, use MP4 with H.264 codec.

## Troubleshooting

### Videos not loading
- Check API endpoint URL is correct
- Verify CORS is enabled on API Gateway
- Check browser console for errors
- Verify DynamoDB items have correct structure

### Videos not playing
- Ensure video URL is accessible
- Check video format is supported
- Verify CORS headers on video hosting
- Check browser compatibility

### API errors
- Verify Lambda has DynamoDB permissions
- Check CloudWatch logs for Lambda errors
- Verify API Gateway integration is correct

## Cost Estimation

**DynamoDB:**
- On-demand: ~$1.25 per million reads
- Minimal for small video libraries

**Lambda:**
- Free tier: 1M requests/month
- $0.20 per million requests after

**API Gateway:**
- HTTP API: $1.00 per million requests

**S3:**
- Storage: $0.023 per GB
- Requests: minimal for static site

**Estimated monthly cost for low traffic:** < $1

## Security Considerations

### For Production:
1. **Use CloudFront** for S3 distribution
2. **Implement authentication** (Cognito + API Gateway authorizer)
3. **Enable SSL/TLS** on custom domain
4. **Add WAF** for API protection
5. **Restrict S3 bucket** to CloudFront only
6. **Enable DynamoDB encryption** at rest
7. **Use VPC endpoints** for Lambda-DynamoDB communication
8. **Implement rate limiting** on API Gateway
9. **Add logging** (CloudTrail, CloudWatch)
10. **Use environment-specific** configurations

## Cleanup

### CloudFormation:
```bash
aws cloudformation delete-stack \
  --stack-name video-library \
  --region $REGION
```

### Manual:
```bash
# Delete S3 bucket (add --region if bucket is in a specific region)
aws s3 rb s3://my-video-library-bucket-12345 --force

# Delete API Gateway
aws apigatewayv2 delete-api --api-id YOUR_API_ID --region $REGION

# Delete Lambda
aws lambda delete-function --function-name VideoLibraryAPI --region $REGION

# Delete DynamoDB table
aws dynamodb delete-table --table-name VideoLibrary --region $REGION

# Delete IAM role
aws iam delete-role --role-name VideoLibraryLambdaRole
```

## Next Steps

1. **Add CloudFront** for better performance and HTTPS
2. **Implement authentication** with Cognito
3. **Add upload functionality** for new videos
4. **Create admin interface** for video management
5. **Add video thumbnails** and metadata
6. **Implement search** and filtering
7. **Add video analytics** tracking
8. **Enable video transcoding** with MediaConvert
9. **Add comments** and ratings
10. **Implement video streaming** with adaptive bitrate

## Support

For issues or questions:
- Check AWS documentation
- Review CloudWatch logs
- Test with curl/Postman
- Verify IAM permissions
