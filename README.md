# 🎬 Video Library - Complete Solution v1.1.0

## ✅ Production-Ready Serverless Video Platform

A complete serverless video streaming platform with **12 Blender Open Movies**, thumbnail support, progress tracking, and real-time API monitoring.

## 🚀 Quick Deploy (1 Command)

```bash
tar -xzf video-library-app.tar.gz
cd video-library-app
./scripts/deploy.sh
```

**Done!** Your video library is live in ~5 minutes.

**Deploy to a specific region:**
```bash
./scripts/deploy.sh --region eu-west-1

# Or via environment variable
AWS_REGION=ap-south-1 ./scripts/deploy.sh
```

---

## ✨ What's Included

- ✅ **12 Blender Open Movies** with high-quality thumbnails
- ✅ **pk/sk DynamoDB schema** (supports your exact data format)
- ✅ **Progress tracking** (auto-save every 3s, resume playback)
- ✅ **Netflix-style UI** (Continue Watching + Library sections)
- ✅ **Real-time monitoring** (status ribbon with API metrics)
- ✅ **Proper Lambda packaging** (fixed 500 error issue)
- ✅ **One-command deployment** (fully automated)
- ✅ **Cost effective** (~$0.25/month for low traffic)

---

## 🎬 Sample Videos

12 professional Blender Foundation animated shorts:
1. Sprite Fright, 2. Coffee Run, 3. Spring, 4. Hero, 5. The Daily Dweebs, 6. Agent 327, 7. Caminandes Llamigos, 8. Glass Half, 9. Cosmos Laundromat, 10. Caminandes, 11. Tears of Steel, 12. Big Buck Bunny

---

## 📋 Prerequisites

- AWS Account
- AWS CLI configured (`aws configure`)
- Bash shell
- jq (optional)

---

## 🎯 After Deployment

1. Open the website URL (displayed by script)
2. Enter API endpoint
3. Enter primary key: `Library`
4. Click "Save Configuration"
5. Click "Load Videos"

---

## 🎥 Your Schema (pk/sk)

```json
{
  "pk": "Library",
  "sk": "01",
  "title": "Video Title",
  "video": "https://video-url.mp4",
  "thumb": "https://thumbnail.jpg"
}
```

---

## 🐛 Troubleshooting

### "Failed to fetch"
- Check API endpoint format (no /prod, no /scan)
- Test: `curl "${API}/scan?pk=Library"`

### "500 Error"
- Update Lambda: `cd scripts && ./build-lambda-package.sh`
- Deploy: `aws lambda update-function-code --function-name VideoLibraryAPI --zip-file fileb://lambda-function.zip`

### "No videos"
- Check: `aws dynamodb scan --table-name VideoLibrary --select COUNT --region YOUR_REGION`
- Reload: `aws dynamodb batch-write-item --request-items file://sample-data/batch-write-items.json --region YOUR_REGION`

### S3 bucket empty / website errors
- The CloudFormation stack uploads a minimal placeholder on creation. Run the full deploy script to upload the app: `./scripts/deploy.sh`
- If the bucket stays empty, run: `aws s3 cp src/video-library.html s3://YOUR_BUCKET/video-library.html --region YOUR_REGION`

### Privacy-first browsers (Brave, Firefox Strict, Safari Private, etc.)
- **sessionStorage** is used to retain state (library, Continue Watching, playing video) across page refresh.
- Some privacy-focused browsers restrict or clear sessionStorage, which can cause:
  - Continue Watching to disappear after refresh
  - Video library to require re-loading
  - Playing video position to reset on refresh
- If you experience this, use a standard browser profile or allow storage for the site.

---

## 🔄 Switch to ScyllaDB Alternator (No Redeploy)

Use the same Lambda and zip. Set env vars in **Lambda Console → Configuration → Environment variables**:

| Variable | Value |
|----------|-------|
| `DYNAMODB_ENDPOINT` | `https://your-alternator-host:8000` |
| `DYNAMODB_ACCESS_KEY_ID` | `alternator` (optional) |
| `DYNAMODB_SECRET_ACCESS_KEY` | `secret` (optional) |

Save. All DynamoDB calls now go to Alternator—no code or zip changes.

---

## 📚 Full Documentation

See `docs/` directory for complete guides:
- DEPLOYMENT_GUIDE.md
- PROGRESS_TRACKING_GUIDE.md  
- TWO_SECTION_LAYOUT_GUIDE.md
- STATUS_RIBBON_GUIDE.md

---

## 💰 Cost: ~$0.25/month (low traffic)

## 📄 License: MIT

**Version 1.1.0** | **Ready to Deploy** ✅
