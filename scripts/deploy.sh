#!/bin/bash

# Video Library - Quick Deploy Script
# This script automates the deployment of the video library application

set -e  # Exit on error

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# Configuration
REGION=${AWS_REGION:-us-east-1}
STACK_NAME=${STACK_NAME:-video-library}
BUCKET_NAME=${BUCKET_NAME:-video-library-$(date +%s)}
TABLE_NAME=${TABLE_NAME:-VideoLibrary}

echo "=================================================="
echo "Video Library Deployment Script"
echo "=================================================="
echo ""
echo "Configuration:"
echo "  Project Root: $PROJECT_ROOT"
echo "  Region: $REGION"
echo "  Stack Name: $STACK_NAME"
echo "  Bucket Name: $BUCKET_NAME"
echo "  Table Name: $TABLE_NAME"
echo ""

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "ERROR: AWS CLI is not installed"
    echo "Please install it from: https://aws.amazon.com/cli/"
    exit 1
fi

# Check if AWS credentials are configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo "ERROR: AWS credentials are not configured"
    echo "Please run: aws configure"
    exit 1
fi

echo "Step 1: Building Lambda deployment package..."
cd "$PROJECT_ROOT/src"
if [ -f lambda-function.zip ]; then
    rm lambda-function.zip
fi
zip -q lambda-function.zip lambda-function.js
echo "✓ Lambda package created"
echo ""

echo "Step 2: Uploading Lambda package to S3 (temporary)..."
# We need to upload Lambda to S3 first for CloudFormation
LAMBDA_BUCKET="lambda-deploy-temp-$(date +%s)"
aws s3 mb s3://$LAMBDA_BUCKET --region $REGION 2>/dev/null || true
aws s3 cp lambda-function.zip s3://$LAMBDA_BUCKET/lambda-function.zip
echo "✓ Lambda uploaded to s3://$LAMBDA_BUCKET/lambda-function.zip"
echo ""

echo "Step 3: Validating CloudFormation template..."
aws cloudformation validate-template \
    --template-body file://$PROJECT_ROOT/infrastructure/cloudformation-template.yaml \
    --region $REGION > /dev/null
echo "✓ Template is valid"
echo ""

echo "Step 4: Deploying CloudFormation stack..."
aws cloudformation create-stack \
    --stack-name $STACK_NAME \
    --template-body file://$PROJECT_ROOT/infrastructure/cloudformation-template.yaml \
    --parameters \
        ParameterKey=S3BucketName,ParameterValue=$BUCKET_NAME \
        ParameterKey=TableName,ParameterValue=$TABLE_NAME \
    --capabilities CAPABILITY_IAM \
    --region $REGION

echo "Waiting for stack creation to complete (this may take 2-3 minutes)..."
aws cloudformation wait stack-create-complete \
    --stack-name $STACK_NAME \
    --region $REGION

echo "✓ Stack created successfully"
echo ""

echo "Step 5: Getting stack outputs..."
OUTPUTS=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs')

API_ENDPOINT=$(echo $OUTPUTS | jq -r '.[] | select(.OutputKey=="ApiEndpoint") | .OutputValue')
WEBSITE_URL=$(echo $OUTPUTS | jq -r '.[] | select(.OutputKey=="WebsiteURL") | .OutputValue')
S3_BUCKET=$(echo $OUTPUTS | jq -r '.[] | select(.OutputKey=="S3BucketName") | .OutputValue')

echo "✓ Retrieved stack outputs"
echo ""

echo "Step 6: Updating Lambda function code..."
aws lambda update-function-code \
    --function-name VideoLibraryAPI \
    --zip-file fileb://$PROJECT_ROOT/src/lambda-function.zip \
    --region $REGION > /dev/null

echo "Waiting for Lambda update..."
aws lambda wait function-updated \
    --function-name VideoLibraryAPI \
    --region $REGION

echo "✓ Lambda function updated"
echo ""

echo "Step 7: Loading sample data into DynamoDB..."
aws dynamodb batch-write-item \
    --request-items file://$PROJECT_ROOT/sample-data/batch-write-items.json \
    --region $REGION > /dev/null
echo "✓ Sample data loaded (12 Blender videos)"
echo ""

echo "Step 8: Uploading static website to S3..."
aws s3 cp $PROJECT_ROOT/src/video-library.html s3://$S3_BUCKET/video-library.html
echo "✓ Website uploaded"
echo ""

echo "Step 9: Cleaning up temporary Lambda bucket..."
aws s3 rm s3://$LAMBDA_BUCKET/lambda-function.zip 2>/dev/null || true
aws s3 rb s3://$LAMBDA_BUCKET --force 2>/dev/null || true
echo "✓ Cleanup complete"
echo ""

echo "=================================================="
echo "Deployment Complete! 🎉"
echo "=================================================="
echo ""
echo "Access your video library at:"
echo "  $WEBSITE_URL"
echo ""
echo "API Endpoint (save this in the web interface):"
echo "  $API_ENDPOINT"
echo ""
echo "Testing the API..."
curl -s "${API_ENDPOINT}/scan?pk=Library" | head -c 100
echo "..."
echo ""
echo ""
echo "Next steps:"
echo "  1. Open the website URL above"
echo "  2. Enter the API endpoint: $API_ENDPOINT"
echo "  3. Enter primary key: Library"
echo "  4. Click 'Save Configuration'"
echo "  5. Click 'Load Videos'"
echo ""
echo "Your library includes 12 Blender Open Movies with thumbnails!"
echo ""
echo "To add more videos:"
echo "  aws dynamodb put-item \\"
echo "    --table-name $TABLE_NAME \\"
echo "    --item '{\"pk\":{\"S\":\"Library\"},\"sk\":{\"S\":\"13\"},\"title\":{\"S\":\"My Video\"},\"video\":{\"S\":\"https://video-url.mp4\"}}' \\"
echo "    --region $REGION"
echo ""
echo "To delete everything:"
echo "  aws s3 rm s3://$S3_BUCKET --recursive"
echo "  aws cloudformation delete-stack --stack-name $STACK_NAME --region $REGION"
echo ""
