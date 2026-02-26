# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2024-01-27

### Fixed
- **Lambda packaging issue** - Function now properly packaged as ZIP file
- **500 Internal Server Error** - Lambda deployment fixed
- **Schema compatibility** - Now uses pk/sk correctly (was videoId before)
- **Field mapping** - Updated to use `video` field instead of `link`
- **Deployment script** - Now builds and deploys Lambda automatically

### Added
- **Thumbnail support** - Videos now display thumbnail images
- **12 Blender Open Movies** - Professional sample data with real thumbnails
- **Lambda build script** - `build-lambda-package.sh` for easy updates
- **Enhanced error logging** - Better debugging in browser console
- **Automated Lambda deployment** - Included in deploy.sh

### Changed
- **DynamoDB sort key** - Changed from `videoId` to `sk`
- **Video URL field** - Changed from `link` to `video`
- **Progress storage** - Uses `PROGRESS#{userId}` as pk, videoId as sk
- **Deploy script** - Now includes Lambda packaging step
- **Sample data** - Updated to Blender movies with thumbnails

## [1.0.0] - 2024-01-27

### Added
- Initial release of Video Library application
- Serverless video streaming platform using AWS services
- Two-section layout: "Continue Watching" and "Library"
- Automatic video progress tracking (saves every 3 seconds)
- Resume playback from last watched position
- Real-time API monitoring status ribbon
- Visual progress bars and percentage indicators
- Performance metrics tracking
- CloudFormation infrastructure as code
- Automated deployment script
- Comprehensive documentation
- Sample data for testing
- Lambda function for API operations
- DynamoDB for data storage
- API Gateway HTTP API
- S3 static website hosting

### Features

#### Frontend
- Responsive HTML5 interface
- Netflix-style two-section layout
- Continue Watching section with resume badges
- Library section showing all videos
- HTML5 video player
- Progress bars with color-coded percentages
- Real-time status ribbon
- API performance monitoring
- Mobile-responsive design

#### Backend
- Node.js Lambda function
- DynamoDB on-demand tables
- API Gateway with CORS support
- Progress tracking endpoints
- Video listing endpoints
- GET and SCAN operations
- POST operations for progress saving

#### Monitoring
- Real-time API endpoint display
- Response time tracking
- Total request counter
- Rolling average response times
- Color-coded performance indicators
- Status indicator (idle/active/error)

#### Documentation
- Main README with quick start
- Detailed deployment guide
- Progress tracking documentation
- Two-section layout guide
- Status ribbon guide
- Visual mockups
- CloudFormation documentation
- Sample data examples

### Infrastructure
- CloudFormation template for full stack
- DynamoDB table with composite keys
- Lambda execution role with minimal permissions
- API Gateway HTTP API with routes
- S3 bucket for static website hosting
- Automated deployment script

### Developer Experience
- Organized repository structure
- Clean code with comments
- Comprehensive error handling
- Browser console logging
- Performance optimization
- Modular design

## [Unreleased]

### Planned Features
- Video thumbnails/posters
- Search functionality
- Video categories
- User authentication (Cognito)
- Multi-user support with login
- Video upload interface
- Comments and ratings
- Social sharing
- Playlist support
- Watch history
- Admin dashboard
- Analytics tracking
- CloudFront integration
- Custom domain support
- SSL/TLS certificates
- WAF protection
- Rate limiting
- DynamoDB encryption at rest
- VPC endpoints
- Enhanced monitoring
- Automated testing
- CI/CD pipeline

### Future Improvements
- Performance optimizations
- Better error messages
- Offline support
- Progressive Web App (PWA)
- Dark mode
- Accessibility improvements
- Internationalization (i18n)
- Video transcoding support
- Adaptive bitrate streaming
- Subtitles/captions support

## Version History

- **1.0.0** (2024-01-27) - Initial release

---

For more details on specific features, see the documentation in the `docs/` directory.
