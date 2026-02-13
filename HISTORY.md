# HISTORY.md - Archived Milestones

> Completed work archived from PROJECT_SPEC.md changelog. For active development, see [CLAUDE.md](./CLAUDE.md).

---

## M4: Production Polish & Export (January 2025)

### M4.9: Simplified Frame Refinement
- **4-button refinement controls**: `<< < timecode > >>`
- **Coarse navigation** (+-0.5s) with double chevrons
- **Fine navigation** (+-1 frame) with single chevrons
- **Visual distinction** between coarse/fine buttons
- **Preview-only refinement** (no persistence complexity)

### M4.8: Export All UX Improvements
- Enhanced Export All feedback (immediate + completion notifications)
- Fixed Export All dialog (format options always visible)
- Improved toast notifications (longer duration for batch operations)

### M4.7: Frame Refinement & Progressive Enhancement
- Complete Frame Refinement system with progressive loading
- Instant UI response with center frame appearing first
- Progressive loading pattern: +-1, +-2, +-3 frames load sequentially
- Dynamic frame rate detection from video metadata
- Eliminated all hanging issues
- **Critical Fixes**:
  - Fixed concurrent FFmpeg processes (was launching 20+ simultaneously)
  - Resolved system hanging during frame refinement
  - Implemented fast-seek FFmpeg optimization (10x speed improvement)

### M4.6: Enhanced Window & Zoom Experience
- Window size increased from 75% to 85% of screen
- Click-to-zoom functionality with simplified tap gesture
- Clean zoom toggle between fit and actual size modes

### M4.5: Final Polish Features
- Export dialog with integrated format selection
- Format defaults to PNG with JPEG/TIFF options
- Frame navigation arrows in preview mode
- Keyboard navigation with arrow keys
- Wrap-around navigation (last frame -> first frame)

### M4: Export & Preview Core
- Full export functionality with native save dialogs
- Individual frame export with timestamp filenames
- Export All with folder selection
- Frame preview modal with full resolution display

---

## M3: Project Migration (January 2025)

### Fresh Project Creation
- Created completely fresh Xcode project named "Still Marker"
- Migrated all Swift files, FFmpeg binary, resources from old FRAMESHIFT project
- Eliminated all FRAMESHIFT references
- Bundle ID: com.johnnyhockin.stillmarker
- Fixed project file corruption from rename process

### App Rename
- Renamed from FRAMESHIFT to Still Marker (Chris Marker reference)
- Updated all code references, comments, and UI text
- Cleaned up obsolete web version files

---

## M2: FFmpeg Integration (January 2025)

### Core Processing
- Bundled FFmpeg binary (Intel, works on Apple Silicon via Rosetta)
- FFmpegProcessor class with async frame extraction
- Real video processing at 3-second intervals
- JPEG 95% quality output
- Progress tracking with detailed status messages
- Offset feature - "Shift +1s" button re-extracts with timestamp offset
- Comprehensive error handling

### Entitlements
- Updated for sandbox compatibility with temporary file access

---

## M1: Mac App Skeleton (January 2025)

### Foundation
- Complete Xcode project structure with SwiftUI
- Beautiful drag & drop interface with macOS materials
- Combined UploadProcessingView with cinematic design
- Frame model struct with timestamp formatting
- ResultsView with grid foundation and hover effects
- File validation, progress tracking, sample frame generation
- CleanMyMac X inspired drop zone with frosted glass aesthetic

---

## Web Architecture (Pivoted)

### Why We Pivoted
- **Discovery**: Netlify Functions have 6MB request limit
- **Impact**: 87MB test video = impossible to process
- **Decision**: Pivot to native Mac app

### What Was Completed (Web)
- Vanilla JavaScript frontend (completed)
- Netlify Functions backend (completed)
- FFmpeg server-side processing (completed)
- **Limitation**: Architecture fundamentally limited by 6MB cap

### Original Web Stack
- Vanilla JS frontend (no frameworks)
- Netlify Functions for server-side processing
- FFmpeg for frame extraction
- Privacy-first: immediate file deletion after processing

---

## Initial Project Setup (January 2025)

- Created PROJECT_SPEC.md with complete requirements
- Defined tech architecture (vanilla JS + Netlify Functions)
- Established privacy-first, performance-focused direction
- Image format: JPEG at 95% quality
- Frame extraction: Fixed 3-second intervals for MVP
- Design sensibilities: Cinematic minimal (A24 website meets professional tool)

---

*Archived from PROJECT_SPEC.md on 2025-02-13*
