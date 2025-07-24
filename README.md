# Still Marker

A native Mac app for filmmakers to extract high-quality still images from video files.

## Quick Start

1. **Build and Run in Xcode:**
   - Open FRAMESHIFT.xcodeproj in Xcode
   - Build and run (⌘R)
   - Drag and drop a video file or click to browse

2. **Features:**
   - Extract frames at 3-second intervals
   - High-quality JPEG output (95% quality)
   - "Shift +1s" feature to re-extract with offset
   - Export individual frames or all at once
   - Beautiful cinematic minimal interface

## Tech Stack

- **Language**: Swift + SwiftUI
- **Target**: macOS 12+ (Monterey)
- **Video Processing**: Bundled FFmpeg binary
- **Architecture**: Native Mac app with local processing

## Privacy

All processing happens locally on your Mac. Your videos never leave your computer.

## Development

For complete project context, architecture decisions, and development workflow, see [PROJECT_SPEC.md](./PROJECT_SPEC.md).