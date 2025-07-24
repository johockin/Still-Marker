# PROJECT_SPEC.md

⚠️ This is the **living god file** for Still Marker. Every architectural decision, design tradeoff, and project evolution must be documented here. This file is the source of truth for all collaborators.

---

## 🔰 PURPOSE OF THIS FILE

- Serves as the **canonical source of truth** for the Still Marker project
- Evolves over time, **growing with every decision**, mistake, fix, or insight
- **Future collaborators (human or AI)** must be able to read this file and understand how the project works, why it's built the way it is, and what to do next

---

## ✍️ ETHOS AND EXPECTATIONS

### ✅ Project Expectations:
- **Document everything** - Every architectural decision, design tradeoff, mistake made and fixed
- **Specs over assumptions** - When in doubt, ask for clarification
- **No magic** - Code must be explainable to any collaborator
- **Work in stable milestones** - Each chunk of progress must be committable and testable
- **User does the QA** - AI guides testing, user runs tests locally/in browser
- **This file is allowed to be sprawling** - It's the beating heart of the project

### 🧠 Guiding Philosophy:
- **Transparency > Cleverness**
- **Stability > Speed**
- **Performance > Convention**
- **Explicitness > DRY if it aids readability**
- **Centralization of knowledge > scattershot insight buried in files**

---

## 🔍 LEVEL SET SUMMARY

- **Project name**: Still Marker
- **Purpose**: Lightweight web tool for filmmakers to extract high-quality still images from video files
- **Audience / users**: Filmmakers who need to extract stills for marketing, thumbnails, archival, etc.
- **Most important outcome**: **High quality image extraction** - getting video to render out images PROPERLY
- **Visual vs performance vs design**: Simple and easy to use, cinematic minimal aesthetic, but not flashy/slick
- **Performance priority**: High - app should be INSANELY fast, vanilla JS for minimal bloat
- **SEO priority**: Low - single-purpose tool
- **Maintenance over time**: Single release with minor iterations - do one thing perfectly
- **Deployment target**: Netlify (Functions + Static hosting)
- **Initial feature list**:
  - [ ] Upload video file (up to 2GB)
  - [ ] Extract frames at 3-second intervals (JPEG 95% quality)
  - [ ] Display frames as thumbnail grid
  - [ ] Click thumbnails to view larger
  - [ ] Download extracted images
  - [ ] "Shift +1s" offset feature for re-extraction
  - [ ] Progress indication during processing
  - [ ] Clear privacy messaging
- **Tech constraints / requests from user**:
  - [ ] Vanilla JS frontend (reinvent wheel if needed for performance)
  - [ ] Netlify Functions for server-side processing
  - [ ] FFmpeg for frame extraction
  - [ ] Privacy-first: immediate file deletion after processing
  - [ ] No user accounts, analytics, or tracking
- **File size limits**: 2GB maximum (covers most short films, reels, demo footage)
- **Processing approach**: One file at a time, server-side via Netlify Functions
- **Privacy model**: Server-side processing with immediate deletion (within minutes)
- **Design sensibilities**: Cinematic minimal - A24 website meets professional tool. Clean, white space, beautiful typography, subtle animations. Reference: VSCO or Halide camera app elegance. Made BY filmmakers FOR filmmakers.
- **Accessibility**: Basic WCAG compliance (keyboard navigation, screen reader friendly)
- **User proficiency**: Assume they know video but not tech. Smart defaults for everything.

---

## 🏗️ TECH ARCHITECTURE (NATIVE MAC APP)

*Architecture after pivot to native Mac app:*

- **Framework / language**: Swift + SwiftUI
  - *Rationale: Native performance, modern UI framework, excellent for Mac development*
- **UI Framework**: SwiftUI with macOS 12+ (Monterey) target
  - *Rationale: Modern, declarative UI, excellent for cinematic minimal aesthetic*
- **Video processing**: Bundled FFmpeg binary
  - *Rationale: Out-of-box experience, no user setup required, consistent performance*
- **File handling**: Direct file system access via NSOpenPanel
  - *Rationale: True privacy, instant processing, no size limits*
- **State management**: SwiftUI @StateObject and @ObservableObject
  - *Rationale: Built-in reactive state management*
- **Distribution**: Local development → Direct download + Mac App Store exploration
  - *Rationale: Flexible distribution strategy, test both channels*
- **Directory structure plan**:
  ```
  Still Marker.xcodeproj/
  ├── Still Marker/
  │   ├── ContentView.swift
  │   ├── VideoProcessor.swift
  │   ├── FrameExtractor.swift
  │   ├── Models/
  │   │   └── Frame.swift
  │   └── Views/
  │       ├── UploadView.swift
  │       ├── ProcessingView.swift
  │       └── ResultsView.swift
  └── Assets.xcassets/
  ```
- **Key dependencies**: 
  - AVFoundation (built-in video analysis)
  - FFmpeg binary (bundled for frame extraction)
  - AppKit (file dialogs, native Mac integration)
- **Planned dev workflow**: Xcode with SwiftUI previews and live development
- **Testing approach**: Manual QA with user, focus on real-world filmmaker workflows

## 🗂️ LEGACY WEB ARCHITECTURE (COMPLETED BUT PIVOTED)

*Original web-based architecture (M1/M2 completed successfully):*
- Vanilla JavaScript frontend (✅ completed)
- Netlify Functions backend (✅ completed)
- FFmpeg server-side processing (✅ completed)
- **LIMITATION**: 6MB request limit made real-world use impossible

---

## 📒 CHANGELOG (REVERSE CHRONOLOGICAL)

### 2025-01-17 - 🎉 M2: FFmpeg Integration Completed ✅
- **BUNDLED**: FFmpeg binary (Intel, works on Apple Silicon via Rosetta)
- **IMPLEMENTED**: FFmpegProcessor class with async frame extraction
- **ADDED**: Real video processing at 3-second intervals with JPEG 95% quality
- **INTEGRATED**: Progress tracking with detailed status messages
- **WORKING**: Offset feature - "Shift +1s" button re-extracts with timestamp offset
- **REPLACED**: Sample frames with real video frames from FFmpeg
- **ADDED**: Comprehensive error handling for video processing failures
- **ENTITLEMENTS**: Updated for sandbox compatibility with temporary file access
- **READY**: For M3 export functionality and advanced features

### 2025-01-17 - 🎉 M1: Mac App Skeleton Completed ✅
- **CREATED**: Complete Xcode project structure with SwiftUI
- **BUILT**: Beautiful drag & drop interface with macOS materials (.ultraThinMaterial)
- **IMPLEMENTED**: Combined UploadProcessingView with cinematic design
- **ADDED**: Frame model struct with timestamp formatting
- **CREATED**: ResultsView with grid foundation and hover effects
- **FEATURES**: File validation, progress tracking, sample frame generation
- **DESIGN**: CleanMyMac X inspired drop zone with premium frosted glass feel
- **READY**: For M2 FFmpeg integration

### 2025-01-17 - Mac App Requirements Finalized ✅
- **TARGET**: macOS 12+ (Monterey) for modern SwiftUI features
- **DISTRIBUTION**: Local development first, later explore direct download + Mac App Store
- **APP NAME**: Still Marker (placeholder, will change later)
- **FFMPEG**: Bundle with app for out-of-box experience (no user setup required)
- **READY**: All requirements clarified, ready to start M1 Mac app skeleton

### 2025-01-17 - 🚀 MAJOR ARCHITECTURE PIVOT: Web to Native Mac App
- **DISCOVERY**: Netlify Functions have 6MB request limit (our 87MB video = impossible)
- **DECISION**: Pivot to native Mac app for superior filmmaker experience
- **BENEFITS**: No file size limits, instant processing, true privacy, native performance
- **TARGET**: Filmmakers predominantly on Macs, professional tool expectations
- **WEB WORK**: M1/M2 completed successfully but architecture fundamentally limited

### 2025-01-17 - Deployment Fix 🔧
- **FIXED**: Moved multiparty dependency from netlify/functions/package.json to root package.json
- **REASON**: Netlify requires dependencies in site's top-level package.json for function bundling
- **UPDATED**: Architecture maintains frontend as pure vanilla (package.json only for functions)

### 2025-01-17 - M2: Basic Upload + Processing Pipeline ✅
- **IMPLEMENTED**: Fixed file upload to Netlify Function with proper multipart parsing
- **IMPLEMENTED**: FFmpeg frame extraction at 3-second intervals
- **IMPLEMENTED**: JPEG 95% quality output with base64 encoding
- **IMPLEMENTED**: Progress tracking with detailed status messages
- **IMPLEMENTED**: Comprehensive error handling for upload/processing failures
- **IMPLEMENTED**: CORS headers for cross-origin requests
- **ENHANCED**: Frontend validation and error display
- **READY**: For deployment and testing on Netlify

### 2025-01-17 - Architecture Correction ⚠️
- **FIXED**: Removed unnecessary package.json (violated vanilla JS requirement)
- **FIXED**: Frontend now works by opening index.html directly in browser
- **FIXED**: Zero build process, zero npm involvement for frontend
- **CLARIFIED**: Only Netlify Functions need dependencies (handled by Netlify)
- Updated README.md to reflect pure vanilla approach

### 2025-01-17 - M1: Project Skeleton Scaffolded ✅
- Created complete project structure with all core files
- Built cinematic minimal UI with HTML/CSS (A24-inspired aesthetic)
- Implemented vanilla JS frontend with drag & drop upload
- Created Netlify Function for server-side FFmpeg processing
- Configured netlify.toml for deployment
- Created README.md with quick start guide

### 2025-01-17 - Initial Project Setup & Clarifications
- Created PROJECT_SPEC.md with complete requirements analysis
- Defined tech architecture approach (vanilla JS + Netlify Functions)
- Established privacy-first, performance-focused direction
- **Image format decision**: JPEG at 95% quality by default
- **Frame extraction approach**: Fixed 3-second intervals for MVP v1
- **Offset feature planned**: "Shift +1s" button to re-extract with timestamp offset
- **Display method**: Grid of thumbnails, click to view larger
- **Architecture approved** by user + advisor team

---

## 🧱 ROADMAP & PIPELINE

### NOW
- [ ] Deploy to Netlify and test M2 functionality
- [ ] Test with various video formats/sizes
- [ ] Verify frame extraction quality

### NEXT
- [ ] Polish UI styling (cinematic minimal aesthetic)
- [ ] Add accessibility features
- [ ] Performance optimization
- [ ] Enhanced error messaging

### LATER
- [ ] Browser compatibility testing
- [ ] Multiple output formats (PNG option)
- [ ] Scene detection for smart frame selection

### SOMEDAY
- [ ] Batch processing (if workflows demand it)
- [ ] Advanced compression options

---

## 📌 MILESTONE COMMITS

### 🕸️ WEB-BASED MILESTONES (COMPLETED BUT PIVOTED)
- **M1**: Project skeleton scaffolded *(✅ COMPLETED)*
- **M2**: Basic upload + processing pipeline working *(✅ COMPLETED)*
- **PIVOT**: Discovered 6MB limit, architecture fundamentally limited

### 🖥️ NATIVE MAC APP MILESTONES (NEW ROADMAP)
- **M1**: Mac app skeleton with SwiftUI *(✅ COMPLETED)*
- **M2**: FFmpeg integration and real frame extraction *(✅ COMPLETED)*
- **M3**: Export functionality and advanced features *(pending)*
- **M4**: UI polish and performance optimization *(pending)*
- **M5**: App Store preparation and distribution *(pending)*

---

## 📌 OPEN QUESTIONS

### 🖥️ MAC APP REQUIREMENTS *(ANSWERED)*
- **Minimum macOS version**: macOS 12+ *(✅ CONFIRMED)*
- **Distribution method**: Local development initially, later explore both direct download and Mac App Store *(✅ CONFIRMED)*
- **App name**: Still Marker *(✅ CONFIRMED - Final name chosen for Chris Marker connection)*
- **FFmpeg approach**: Bundle with app for out-of-box experience *(✅ CONFIRMED)*

### 🎯 FUTURE DECISIONS
- **Distribution strategy**: Direct download vs Mac App Store (evaluate both)

---

## 🤖 AI COLLABORATOR INSTRUCTIONS

- Always refer to this file first
- Before continuing any work, read this entire document top to bottom
- Never introduce dependencies or frameworks without explaining and getting approval
- Always update this spec file whenever you make a move
- Push every step to git for web-based QA before proceeding
- Prioritize: High quality images > Speed > Simplicity > Polish
- Remember: This tool does ONE thing perfectly

---

This file is sacred. Tend to it.