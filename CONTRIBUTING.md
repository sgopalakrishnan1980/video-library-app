# Contributing to Video Library

Thank you for your interest in contributing to the Video Library project! This document provides guidelines and instructions for contributing.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [How to Contribute](#how-to-contribute)
- [Coding Standards](#coding-standards)
- [Testing](#testing)
- [Pull Request Process](#pull-request-process)
- [Project Structure](#project-structure)

## Code of Conduct

This project adheres to a code of conduct. By participating, you are expected to uphold this code. Please be respectful and constructive in all interactions.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/video-library-app.git`
3. Create a branch: `git checkout -b feature/your-feature-name`
4. Make your changes
5. Test your changes
6. Commit and push
7. Open a Pull Request

## Development Setup

### Prerequisites

- AWS Account for testing
- AWS CLI configured
- Node.js 18.x or later
- Git
- Text editor or IDE

### Local Development

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/video-library-app.git
cd video-library-app

# Test the static website locally
cd src
python3 -m http.server 8000
# Open http://localhost:8000/video-library.html

# Test Lambda function locally (optional)
# Install dependencies if needed
npm install

# Run Lambda tests
node lambda-function.js
```

### Testing Changes

1. **Frontend Changes**: Test in multiple browsers
2. **Lambda Changes**: Test with sample events
3. **CloudFormation**: Validate template before committing
4. **Documentation**: Check for typos and accuracy

## How to Contribute

### Reporting Bugs

When reporting bugs, please include:

- Clear description of the issue
- Steps to reproduce
- Expected behavior
- Actual behavior
- Browser/environment details
- Screenshots if applicable
- CloudWatch logs if relevant

### Suggesting Features

Feature requests should include:

- Clear description of the feature
- Use case and benefits
- Proposed implementation (if applicable)
- Potential challenges

### Contributing Code

Areas where contributions are welcome:

- **Frontend Improvements**
  - Video thumbnails
  - Search functionality
  - Better mobile UX
  - Accessibility improvements
  - Dark mode

- **Backend Enhancements**
  - Performance optimizations
  - Better error handling
  - Additional API endpoints
  - Caching strategies

- **Features**
  - User authentication
  - Video categories
  - Playlist support
  - Comments system
  - Video upload

- **Infrastructure**
  - CloudFront setup
  - CDN optimization
  - Security improvements
  - Monitoring enhancements

- **Documentation**
  - Tutorial videos
  - Architecture diagrams
  - API documentation
  - Troubleshooting guides

## Coding Standards

### JavaScript

```javascript
// Use async/await
async function fetchData() {
    try {
        const response = await fetch(url);
        return await response.json();
    } catch (error) {
        console.error('Error:', error);
    }
}

// Use descriptive variable names
const videoProgressData = {};  // Good
const vpd = {};                // Bad

// Use const/let, not var
const API_ENDPOINT = '...';
let currentVideoId = null;

// Add comments for complex logic
// Calculate progress percentage based on duration
const progressPercentage = (currentTime / duration) * 100;
```

### HTML/CSS

```html
<!-- Use semantic HTML -->
<section class="continue-watching">
    <h2>Continue Watching</h2>
</section>

<!-- Use descriptive class names -->
<div class="status-ribbon">  <!-- Good -->
<div class="sr">             <!-- Bad -->
```

```css
/* Use consistent spacing */
.video-card {
    padding: 20px;
    margin: 10px;
}

/* Group related properties */
.status-ribbon {
    /* Positioning */
    position: fixed;
    bottom: 0;
    
    /* Display */
    display: flex;
    align-items: center;
    
    /* Styling */
    background: #2d3748;
    color: white;
}
```

### CloudFormation

```yaml
# Use clear resource names
VideoLibraryTable:
  Type: AWS::DynamoDB::Table
  Properties:
    TableName: !Ref TableName
    
# Add comments for complex configurations
# Lambda needs PutItem for progress tracking
- Effect: Allow
  Action:
    - dynamodb:PutItem
```

## Testing

### Manual Testing Checklist

Before submitting:

- [ ] Test on Chrome, Firefox, Safari
- [ ] Test on mobile devices
- [ ] Verify all API endpoints work
- [ ] Check CloudWatch logs for errors
- [ ] Test with and without cached data
- [ ] Verify progress tracking works
- [ ] Check status ribbon updates
- [ ] Test error scenarios

### CloudFormation Validation

```bash
# Validate template
aws cloudformation validate-template \
  --template-body file://infrastructure/cloudformation-template.yaml
```

### Lambda Testing

```bash
# Test Lambda locally
aws lambda invoke \
  --function-name VideoLibraryAPI \
  --payload '{"httpMethod":"GET","path":"/scan"}' \
  response.json
```

## Pull Request Process

1. **Update Documentation**: Ensure relevant docs are updated
2. **Update CHANGELOG**: Add entry in [Unreleased] section
3. **Test Thoroughly**: Follow testing checklist
4. **Descriptive Title**: Use clear, concise PR title
5. **Detailed Description**: Explain what, why, and how

### PR Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Performance improvement
- [ ] Code refactoring

## Testing
- [ ] Tested locally
- [ ] Tested in AWS
- [ ] Added/updated tests

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] CHANGELOG updated
- [ ] No breaking changes (or documented)

## Screenshots (if applicable)
```

## Project Structure

```
video-library-app/
├── src/                 # Source code
│   ├── video-library.html
│   └── lambda-function.js
├── infrastructure/      # CloudFormation templates
├── sample-data/        # Test data
├── scripts/            # Deployment scripts
├── docs/               # Documentation
├── .gitignore
├── LICENSE
├── README.md
├── CHANGELOG.md
└── CONTRIBUTING.md
```

## Commit Message Guidelines

Use clear, descriptive commit messages:

```bash
# Good
git commit -m "Add video thumbnail support to video cards"
git commit -m "Fix progress bar percentage calculation"
git commit -m "Update deployment guide with CloudFront steps"

# Bad
git commit -m "fix bug"
git commit -m "update"
git commit -m "changes"
```

### Commit Message Format

```
<type>: <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting)
- `refactor`: Code refactoring
- `perf`: Performance improvements
- `test`: Adding tests
- `chore`: Maintenance tasks

**Example:**
```
feat: Add search functionality to video library

- Implemented search bar in header
- Added fuzzy search algorithm
- Updated status ribbon to show search operations

Closes #42
```

## Questions?

If you have questions:

1. Check existing documentation in `docs/`
2. Search existing issues
3. Open a new issue with the "question" label

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to Video Library! 🎉
