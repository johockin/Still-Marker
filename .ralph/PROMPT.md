# Still Marker - Development Instructions

> Read this file at the start of every work session. This is the project's source of truth for active development context.

## Project Overview

**Still Marker** is a native macOS app for filmmakers to extract high-quality still images from video files. Built with Swift + SwiftUI, it bundles FFmpeg for zero-setup frame extraction. Named after Chris Marker, the legendary essay filmmaker. The interface follows a "digital light table" philosophy - contemplative, precise, and beautiful without sacrificing clarity.

The app is feature-complete through M5 (visual polish). Current work focuses on addressing open GitHub issues and preparing for distribution (M6).

## Technical Stack

- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI (macOS 12+ / Monterey target)
- **Video Processing**: Bundled FFmpeg binary (Intel, Apple Silicon via Rosetta)
- **Video Metadata**: AVFoundation for duration analysis (~10ms vs 8.6s with FFmpeg)
- **State Management**: SwiftUI `@StateObject`, `@ObservedObject`, `@State`
- **Distribution**: Direct download (primary), Mac App Store (exploratory)
- **Bundle ID**: `com.johnnyhockin.stillmarker`
- **Dependencies**: Zero third-party dependencies. Only AppKit, AVFoundation, UniformTypeIdentifiers.

## Architecture Principles

1. **One thing perfectly** - This app extracts stills from video. That's it. No editing, no filters, no batch processing pipelines.
2. **Component extraction is mandatory** - SwiftUI views over 100 lines must be split into separate structs. The type system crashes otherwise (documented repeatedly in M5).
3. **Memory-first architecture** - Grid uses 200x112 thumbnails (~3.6MB). Full resolution loads on-demand for preview/export only. Never hold 40+ full-res frames in memory.
4. **File-based frame storage** - Full images stored as temp files on disk, referenced by URL. Thumbnails kept in memory.
5. **Progressive loading** - Grid loads 8 frames per 0.1s batch to prevent SwiftUI mass-initialization crashes.
6. **No main thread blocking** - All FFmpeg operations dispatched via `Task { @MainActor }`. Continuation-based async with 10s timeout protection.
7. **Guard all keyboard handlers** - Every handler that calls `resetRefinement()` must check `!isRefining` first. Spurious keyboard events are a documented issue.

## Current State of the Codebase

### What exists and works:
- Full drag-drop and file picker video import
- Adaptive frame extraction (1-40 frames depending on duration)
- Thumbnail grid with progressive loading
- Frame preview with full-resolution display
- Frame refinement: 8 directional controls (10s, 2s, 0.5s, 1-frame precision)
- Keyboard navigation (arrows for frame/time, Shift+arrows for 2s jumps, up/down for grid frames, ESC to exit)
- Individual + batch export (PNG default, JPEG 100%, TIFF)
- Source video filename prefix in exports
- Chris Marker aesthetic: lifted blacks, monospaced typography, glass morphism, Kodak Gold export buttons
- Toast notifications with cinematic styling
- Drag-drop on grid view to load new video

### What's broken / needs work (Open Issues):
1. **Vertical videos stretched in grid** (High priority) - Thumbnails display at fixed 200x112, ignoring aspect ratio
2. **No feedback when dropping video on grid** (Medium) - Drop works but no visual indication
3. **Drop zone too restrictive on opening page** (Medium) - Hit target could be larger
4. **Need end-of-file indicator** (Low) - No visual cue that last frame has been reached
5. **Frame preview should accept video drops** (Medium) - Can only drop on grid, not preview

### Key file map:
- `StillMarkerApp.swift` - Entry point, window sizing (85% of screen)
- `ContentView.swift` - Router (upload/processing/results), AppViewModel
- `FFmpegProcessor.swift` - Frame extraction engine, adaptive intervals, single-frame extraction
- `Models/Frame.swift` - Frame model with dual-resolution (thumbnail + full URL), NSImage extensions
- `Views/UploadProcessingView.swift` - Drag-drop upload + processing progress
- `Views/ResultsView.swift` - Grid view, frame preview, refinement controls, export, toast notifications, keyboard handling (~1600 lines)
- `Views/DotPatternView.swift` - Background texture (currently unused in views but available)

## Scope for This Session

### In Scope:
- Fix open GitHub issues #1-#5
- Any bug fixes discovered during issue work
- Minor UX improvements directly related to the issues

### NOT in Scope:
- Distribution/code signing (M6 - separate session)
- New features beyond the 5 issues
- Performance optimization (app is already fast)
- Adding third-party dependencies
- Changing the build system or project structure

## Do NOT Build/Change These

- **Do not refactor working code** unless a task specifically requires it
- **Do not add dependencies** - this is a zero-dependency project by design
- **Do not change the FFmpeg integration** - it works reliably after extensive debugging
- **Do not modify keyboard handling architecture** - the guard pattern was hard-won
- **Do not simplify the dual-resolution frame system** - it prevents 330MB memory crashes
- **Do not remove debug logging** - the print statements are intentional diagnostic infrastructure
- **Do not change the progressive loading system** - it prevents SwiftUI initialization crashes
- **Do not celebrate completion until user QA confirms it works**

## Key Conventions

### Naming:
- Views: `PascalCase` + descriptive suffix (`FramePreviewHeader`, `FrameNavigationView`)
- Styles: `PascalCase` + `ButtonStyle` suffix (`FilmExportButtonStyle`, `GreyNavigationButtonStyle`)
- State: `camelCase` with descriptive prefix (`hoveredFrameID`, `isRefining`, `refinedTimestamp`)
- Functions: `camelCase` verb-first (`navigateToNextFrame`, `refineByAmount`, `handleEscapeKey`)

### File Organization:
- Components extracted as top-level structs in the same file (e.g., `RefineButton`, `FramePreviewHeader` in ResultsView.swift)
- Extensions used for logical grouping (e.g., `extension ResultsView` for frame preview)
- MARK comments for section headers (`// MARK: - Frame Preview View`)

### Design Tokens:
- Background: lifted blacks `Color(red: 0.1, green: 0.1, blue: 0.11)`
- Text hierarchy: `.white.opacity(0.9)`, `.opacity(0.7)`, `.opacity(0.5)`, `.opacity(0.3)`
- Export gold: `Color(hex: "#E6A532")`
- Crimson accent: `Color(red: 0.8, green: 0.1, blue: 0.2)`
- Typography: `.system(design: .monospaced)` throughout
- Glass: `.thinMaterial` and `.ultraThinMaterial`
- Corner radius: 8 (cards), 14 (toast), 24 (drop zone)

## Quality Standards

- App launches without crashes
- All 5 views render correctly (upload, processing, grid, preview, toast)
- Frame extraction completes for videos of various durations (15s, 2min, 10min+)
- Export produces correct files in all 3 formats
- Keyboard shortcuts work in preview mode
- No SwiftUI type-checker crashes during build
- No memory pressure warnings with 40-frame videos
- Builds cleanly with `xcodebuild -scheme "Still Marker" -destination 'platform=macOS' build`
