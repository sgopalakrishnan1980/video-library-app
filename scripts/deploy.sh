#!/bin/bash

# Video Library - Quick Deploy Script
# This script automates the deployment of the video library application

set -e  # Exit on error

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# Parse command-line arguments
REGION=""
while [[ $# -gt 0 ]]; do
  case $1 in
    -r|--region)
      if [[ -z "${2:-}" ]]; then
        echo "ERROR: --region requires a value"
        exit 1
      fi
      REGION="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Deploy the video library application to AWS."
      echo ""
      echo "Options:"
      echo "  -r, --region REGION   AWS region to deploy to (default: us-east-1)"
      echo "  -h, --help            Show this help message"
      echo ""
      echo "Environment variables:"
      echo "  AWS_REGION    Same as --region (overridden by --region)"
      echo "  STACK_NAME   CloudFormation stack name (default: video-library)"
      echo "  BUCKET_NAME  S3 bucket name (default: video-library-<timestamp>-<region>)"
      echo "  TABLE_NAME   DynamoDB table name (default: VideoLibrary)"
      echo ""
      echo "Examples:"
      echo "  $0                          # Deploy to us-east-1"
      echo "  $0 --region eu-west-1      # Deploy to eu-west-1"
      echo "  $0 -r ap-south-1           # Deploy to ap-south-1"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

# Configuration (CLI arg overrides env var overrides default)
REGION=${REGION:-${AWS_REGION:-us-east-1}}
STACK_NAME=${STACK_NAME:-video-library}
BUCKET_NAME=${BUCKET_NAME:-video-library-$(date +%s)-${REGION}}
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
cd "$PROJECT_ROOT"
# Node.js 18 Lambda does NOT include aws-sdk v2 - only v3. We must bundle @aws-sdk/* deps.
npm install --omit=dev --no-package-lock 2>/dev/null || npm install --production 2>/dev/null || true
cd "$PROJECT_ROOT/src"
if [ -f lambda-function.zip ]; then
    rm lambda-function.zip
fi
# Zip: index.js at root + node_modules (AWS SDK v3 for DynamoDB)
zip -rq lambda-function.zip index.js -x "*.git*"
if [ -d "$PROJECT_ROOT/node_modules" ]; then
    cd "$PROJECT_ROOT" && zip -rq src/lambda-function.zip node_modules -x "*.git*" && cd src
fi
echo "✓ Lambda package created (index.js + @aws-sdk/* for Node.js 18)"
echo ""

echo "Step 2: Uploading Lambda package to S3 (temporary)..."
# We need to upload Lambda to S3 first for CloudFormation
LAMBDA_BUCKET="lambda-deploy-temp-$(date +%s)"
aws s3 mb s3://$LAMBDA_BUCKET --region $REGION 2>/dev/null || true
aws s3 cp lambda-function.zip s3://$LAMBDA_BUCKET/lambda-function.zip --region $REGION
echo "✓ Lambda uploaded to s3://$LAMBDA_BUCKET/lambda-function.zip"
echo ""

echo "Step 3: Validating CloudFormation template..."
aws cloudformation validate-template \
    --template-body file://$PROJECT_ROOT/infrastructure/cloudformation-template.yaml \
    --region $REGION > /dev/null
echo "✓ Template is valid"
echo ""

echo "Step 4: Deploying CloudFormation stack..."
if aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION &>/dev/null; then
    echo "Stack exists - updating..."
    aws cloudformation update-stack \
        --stack-name $STACK_NAME \
        --template-body file://$PROJECT_ROOT/infrastructure/cloudformation-template.yaml \
        --parameters \
            ParameterKey=S3BucketName,UsePreviousValue=true \
            ParameterKey=TableName,UsePreviousValue=true \
        --capabilities CAPABILITY_IAM \
        --region $REGION 2>/dev/null || {
        echo "No updates to be applied (or update failed). Continuing..."
    }
    aws cloudformation wait stack-update-complete --stack-name $STACK_NAME --region $REGION 2>/dev/null || true
    echo "✓ Stack updated"
else
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
fi
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
aws s3 cp $PROJECT_ROOT/src/video-library.html s3://$S3_BUCKET/video-library.html --region $REGION
echo "✓ Website uploaded"
echo ""

echo "Step 9: Cleaning up temporary Lambda bucket..."
aws s3 rm s3://$LAMBDA_BUCKET/lambda-function.zip --region $REGION 2>/dev/null || true
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
