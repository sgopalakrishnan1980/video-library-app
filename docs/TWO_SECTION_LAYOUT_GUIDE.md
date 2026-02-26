# Two-Section Layout Guide

## Overview

The video library now features a two-section layout that improves the user experience by highlighting videos that users have started watching but not completed.

## Layout Structure

```
┌─────────────────────────────────────────────────────┐
│                    Header                           │
│              (API Configuration)                    │
└─────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────┐
│              Video Player Section                   │
│          (Shows when video is playing)              │
└─────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────┐
│        📺 CONTINUE WATCHING                         │
│     (Pick up where you left off)                    │
│  ┌──────┐  ┌──────┐  ┌──────┐                      │
│  │Video │  │Video │  │Video │                       │
│  │ [▶]  │  │ [▶]  │  │ [▶]  │                       │
│  │━━━━━━│  │━━━━━━│  │━━━━━━│  ← Progress bars      │
│  │75%   │  │43%   │  │12%   │                       │
│  └──────┘  └──────┘  └──────┘                       │
└─────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────┐
│           🎬 LIBRARY                                 │
│        (All available videos)                       │
│  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐           │
│  │Video │  │Video │  │Video │  │Video │           │
│  │      │  │      │  │      │  │      │           │
│  │      │  │━━━━━━│  │      │  │      │           │
│  │      │  │25%   │  │      │  │      │           │
│  └──────┘  └──────┘  └──────┘  └──────┘           │
│  ┌──────┐  ┌──────┐                                │
│  │Video │  │Video │                                │
│  │      │  │      │                                │
│  └──────┘  └──────┘                                │
└─────────────────────────────────────────────────────┘
```

## Section Details

### 1. Continue Watching Section

**Purpose**: Shows videos that users have started but not completed

**Visibility**: 
- Hidden by default (when no in-progress videos exist)
- Automatically appears when user has videos with saved progress
- Positioned at the top for easy access

**Features**:
- **Progress Bar**: Visual indicator showing how much of the video has been watched
- **Resume Badge**: "▶ Resume" badge in top-right corner
- **Progress Percentage**: Shows percentage completed (e.g., "75%")
- **Resume Text**: "Resume at 2:15" indicating exact timestamp
- **Sorted by Recency**: Most recently watched videos appear first

**Criteria for Inclusion**:
- Video has `currentTime > 0`
- Video is NOT marked as `completed: true`
- Progress data exists in DynamoDB

### 2. Library Section

**Purpose**: Shows all available videos in the library

**Visibility**: Always visible (shows all videos)

**Features**:
- **All Videos**: Displays every video in the library
- **Optional Progress Indicators**: Videos with progress show progress bars
- **No Resume Badge**: Even videos with progress don't show the resume badge here
- **Complete Collection**: Includes both watched and unwatched videos

## Visual Elements

### Video Card Components

#### Standard Video Card (No Progress)
```
┌─────────────────────────┐
│  Video Title            │
│  https://video-url.mp4  │
└─────────────────────────┘
```

#### Video Card with Progress (Continue Watching)
```
┌─────────────────────────┐
│                  ▶ Resume│ ← Badge
│  Video Title            │
│  https://video-url.mp4  │
│                         │
│  ┌───────────────────┐  │
│  │███████░░░░░░░░░░░│  │ ← Progress bar
│  └───────────────────┘  │
│  Resume at 2:15    75%  │ ← Time and percentage
└─────────────────────────┘
```

#### Video Card with Progress (Library)
```
┌─────────────────────────┐
│  Video Title            │
│  https://video-url.mp4  │
│                         │
│  ┌───────────────────┐  │
│  │███░░░░░░░░░░░░░░░│  │ ← Progress bar (no badge)
│  └───────────────────┘  │
│  Resume at 0:45    25%  │
└─────────────────────────┘
```

## CSS Styling

### Section Headers
- **Font Size**: 1.8em (bold, prominent)
- **Border**: 3px bottom border in brand color (#667eea)
- **Subtitle**: Gray text explaining the section purpose
- **Spacing**: 50px between sections

### Progress Bar
- **Container**: 6px height, light gray background
- **Bar**: Gradient fill (brand colors), animated width transition
- **Position**: Above timestamp text
- **Colors**: Purple gradient (#667eea to #764ba2)

### Resume Badge
- **Position**: Absolute, top-right corner of card
- **Style**: Gradient background, white text, rounded corners
- **Text**: "▶ Resume" with play icon
- **Shadow**: Subtle drop shadow for elevation

### Progress Indicator
- **Background**: White with 95% opacity
- **Position**: Absolute, bottom of card
- **Content**: Progress bar + text (time and percentage)
- **Shadow**: Soft shadow for legibility

## User Interaction Flow

### First Visit (No Progress)
1. User loads page
2. Only "Library" section visible
3. All videos shown without progress bars
4. User clicks a video to start watching

### Watching a Video
1. Video starts playing
2. Progress saved every 3 seconds
3. Console logs show progress updates
4. User pauses or navigates away

### Returning Visit (With Progress)
1. User reloads page
2. "Continue Watching" section appears at top
3. In-progress videos shown with progress bars
4. Same videos also appear in Library section
5. User can click from either section to resume

### Completing a Video
1. Video plays to the end
2. Marked as `completed: true` in database
3. Message: "Video completed! Updating library..."
4. Page auto-reloads after 2 seconds
5. Video removed from "Continue Watching"
6. Video remains in "Library" (without progress bar)

## Technical Implementation

### Data Flow

```javascript
// 1. Load all videos
loadVideos() 
  ↓
// 2. Fetch progress for each video
loadProgressForVideos(videos)
  ↓
// 3. Separate into two lists
continueWatching = videos.filter(v => v.progressData?.currentTime > 0 && !v.progressData?.completed)
libraryVideos = videos (all)
  ↓
// 4. Display both sections
displayContinueWatching(continueWatching)
displayLibrary(libraryVideos)
```

### Progress Calculation

```javascript
// Parse duration from string format
"9:56" → 596 seconds
"1:30:45" → 5445 seconds

// Calculate percentage
progressPercentage = (currentTime / duration) * 100

// Example:
currentTime = 150 seconds
duration = 596 seconds
progressPercentage = (150 / 596) * 100 = 25.17%
```

### Sorting Logic

**Continue Watching**:
```javascript
// Sort by most recently watched (lastUpdated timestamp)
videos.sort((a, b) => {
  const timeA = a.progressData?.lastUpdated || '';
  const timeB = b.progressData?.lastUpdated || '';
  return timeB.localeCompare(timeA); // Descending
});
```

**Library**:
```javascript
// No sorting - displays in original order (by videoId)
// Can be customized to sort by:
// - Upload date (newest first)
// - Title (alphabetically)
// - Duration (shortest/longest first)
```

## API Integration

### Loading Videos with Progress

```javascript
// 1. Fetch all videos
GET /scan?pk=Library

// 2. For each video, fetch progress
GET /progress?userId=user-12345&videoId=video-001
GET /progress?userId=user-12345&videoId=video-002
GET /progress?userId=user-12345&videoId=video-003
...

// 3. Combine data
video.progressData = {
  currentTime: 150,
  completed: false,
  lastUpdated: "2024-01-27T10:30:00Z"
}
```

### Saving Progress

```javascript
// Every 3 seconds while playing
POST /progress
{
  "userId": "user-12345",
  "videoId": "video-001",
  "currentTime": 153,
  "completed": false,
  "timestamp": "2024-01-27T10:30:03Z"
}
```

## Responsive Design

### Desktop (> 768px)
- Grid: 3 columns (auto-fill, min 300px)
- Spacing: 20px gap
- Card height: Auto (based on content)

### Mobile (≤ 768px)
- Grid: 1 column (full width)
- Section title: Slightly smaller (1.5em)
- Same progress indicators
- Touch-friendly card sizing

## Accessibility Features

- **Semantic HTML**: Proper heading hierarchy (h2 for sections)
- **Color Contrast**: Progress text readable on all backgrounds
- **Keyboard Navigation**: Cards clickable via keyboard
- **Screen Readers**: Descriptive text for progress
- **Touch Targets**: Card size meets minimum 44x44px

## Performance Considerations

### Optimization Strategies

1. **Parallel API Calls**: Fetch progress for all videos simultaneously
2. **Local Caching**: User ID stored in localStorage
3. **Lazy Loading**: Only load progress when videos loaded
4. **Debouncing**: Prevent excessive API calls

### Loading States

```
Initial Load → Show loading spinner
  ↓
Videos Loaded → Show library immediately
  ↓
Progress Loading → Show cards, add progress bars incrementally
  ↓
Complete → Both sections populated
```

## Future Enhancements

### Potential Features

1. **Continue Watching Limit**: Show top 10 most recent
2. **Filter Options**: Sort library by date, title, progress
3. **Search**: Find videos by title
4. **Categories**: Group videos by topic
5. **Watch History**: Show completed videos separately
6. **Recommendations**: "Based on what you watched"
7. **Playlist Support**: Create custom playlists
8. **Multi-user Support**: Different progress per user
9. **Continue on Another Device**: Cross-device sync
10. **Watch Together**: Shared viewing sessions

### UI Improvements

- [ ] Hover effects on progress bars
- [ ] Animated section transitions
- [ ] Skeleton loaders while fetching progress
- [ ] "Clear Continue Watching" button
- [ ] "Mark as Unwatched" option
- [ ] Video thumbnails/posters
- [ ] Grid/List view toggle
- [ ] Dark mode support

## Troubleshooting

### Continue Watching Not Showing

**Check 1**: Do videos have progress?
```javascript
// In browser console
localStorage.getItem('userId')
// Should show: user-12345...
```

**Check 2**: Is progress saved?
```bash
curl "https://API_ENDPOINT/progress?userId=USER_ID&videoId=video-001"
```

**Check 3**: Check browser console
```
// Should see progress data in console
console.log(video.progressData)
```

### Progress Bar Not Accurate

**Check**: Videos need `duration` field
```json
{
  "videoId": "video-001",
  "title": "My Video",
  "link": "https://...",
  "duration": "10:25"  ← Required for accurate percentage
}
```

Without duration:
- Progress bar shows fixed 15% (indicates progress exists)
- Time still displayed correctly ("Resume at 2:15")
- Percentage hidden

### Videos Appear in Both Sections

**This is correct behavior!**
- Continue Watching: Shows in-progress videos for quick access
- Library: Shows ALL videos for browsing
- This allows users to:
  - Resume from Continue Watching (prominent)
  - Browse all content in Library
  - Start new videos from Library

## Migration from Single-Section Layout

If updating from the previous version:

### Changes Required
- ✅ HTML structure updated (two section divs)
- ✅ CSS added (section headers, progress bars, badges)
- ✅ JavaScript updated (fetch progress, display logic)
- ⚠️ No API changes needed
- ⚠️ No database changes needed

### Backward Compatibility
- ✅ Works with existing progress data
- ✅ Works with videos without duration field
- ✅ Works if no progress exists (shows Library only)

---

**The two-section layout is now live!** Users will see their in-progress videos highlighted at the top, making it easy to continue watching.
