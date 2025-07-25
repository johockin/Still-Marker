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

### 🎨 VISUAL DESIGN PRINCIPLES FOR STILL MARKER:

#### Typography & Identity:
- Make "STILL MARKER" an architectural element, not just a label
- Consider unconventional placement: vertical stacking, extreme letter spacing (S T I L L   M A R K E R), or using individual letters as design elements
- Think gallery signage or editorial design - this is for cinematographers who understand visual language

#### Interface Atmosphere:
- Design with cinematic lighting in mind - subtle gradients, atmospheric depth
- Use lifted blacks (#1a1a1d instead of #000000) - filmmakers know pure black is amateur
- Glass morphism done right: panels that feel like high-end camera filters
- Multiple subtle "light sources" creating depth without distraction

#### Hierarchy & Restraint:
- Create hierarchy through opacity (0.9, 0.7, 0.5, 0.3) not garish colors
- One prominent action at a time - respect the user's focus
- Generous space around primary actions - this isn't a cluttered NLE

#### The Key Test:
**"Would a tired cinematographer appreciate this at 3am after a 14-hour shoot?"** Beautiful but NEVER at the expense of clarity. These are professionals who need tools that work.

### 🎬 Chris Marker Aesthetic References:

#### Essay Film Sensibility:
- Interface as visual essay - thoughtful, contemplative pacing
- La Jetée inspired: Still frames are the star - present them like museum pieces, each one precious
- Typography as narrative: Text that feels hand-typed, documentary-like - consider monospace fonts or subtle typewriter aesthetics

#### Black & White Emphasis:
- While we use color, consider a mode or elements that reference Marker's B&W work
- Perhaps frame previews could have a B&W option for artistic evaluation

#### Time as Texture:
- The "Shift +1s" feature is very Marker - make time manipulation feel poetic, not just functional
- Observational clarity: Marker's work was never cluttered - every element had purpose and breathing room

#### Digital Light Table Philosophy:
Think of the interface as a digital light table where a film essayist might examine their work. This isn't just extracting frames - it's studying moments, finding the punctum in the footage.

**Apply this sensibility especially to:**
- How frames are presented in the grid (gallery-like, contemplative)
- The typography treatment (could reference typewriter/documentary aesthetics)  
- The overall pacing and space of the interface

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

### 2025-01-25 - ✨ M4.9: Simplified Frame Refinement Complete ✅
- **IMPLEMENTED**: 4-button refinement controls: `<< < timecode > >>`
- **ADDED**: Coarse navigation (±0.5s) with double chevrons (`<<` `>>`)
- **ADDED**: Fine navigation (±1 frame ~0.033s) with single chevrons (`<` `>`)
- **ENHANCED**: Visual distinction - darker blue for coarse, lighter for fine
- **IMPROVED**: Moved Export button to control panel for better prominence
- **ENHANCED**: Timestamp display with "Original" vs "Refined" labels
- **SIMPLIFIED**: Preview-only refinement (no persistence complexity)
- **POLISHED**: Clean reset when navigating or returning to grid

### 2025-01-25 - 🔧 M4.8: Export All UX Improvements Complete ✅
- **ENHANCED**: Export All feedback with immediate "Exporting..." notification
- **IMPROVED**: Completion feedback with ✅ checkmark and destination folder name
- **FIXED**: Export All dialog format options always visible (no hidden "Show Options" button)
- **WIDENED**: Format dropdown from 90px to 180px for better readability
- **ADDED**: Longer toast duration (5 seconds) for batch operations vs single exports (3 seconds)
- **POLISHED**: Professional export workflow with clear feedback at every step

### 2025-01-24 - 🎉 M4.7: Frame Refinement & Progressive Enhancement Complete ✅
- **IMPLEMENTED**: Complete Frame Refinement system with progressive enhancement
- **ENHANCED**: Instant UI response - interface appears immediately with center frame
- **OPTIMIZED**: Progressive loading pattern: ±1, ±2, ±3 frames load sequentially
- **SIMPLIFIED**: Clean 7-frame system (-3 to +3) with no viewport complexity
- **PERFORMANCE**: Dynamic frame rate detection from video asset metadata
- **RESOLVED**: Eliminated all hanging issues by removing conflicting loading systems
- **UX**: Professional filmmaker workflow with immediate feedback and smooth enhancement
- **TECHNICAL**: Complete code cleanup - removed all legacy viewport and batch loading code
- **ADAPTIVE EXTRACTION**: Implemented 3fps limit and 1 decimal precision for timestamps
- **CRITICAL FIXES**: 
  - Fixed concurrent FFmpeg processes (was launching 20+ simultaneously)
  - Resolved system hanging during frame refinement loading
  - Stripped out ALL old viewport-based loading code causing conflicts
  - Fixed interface showing 10+ frames instead of intended 7-frame system
  - Implemented fast-seek FFmpeg optimization (-ss before -i for 10x speed improvement)

### 2025-01-24 - 🚀 M4.6: Enhanced Window & Zoom Experience ✅
- **ENHANCED**: Window size increased from 75% to 85% of screen for better viewing experience
- **FIXED**: Click-to-zoom functionality restored with simplified tap gesture implementation
- **IMPROVED**: Removed complex coordinate-based zoom positioning (moved to known issues)
- **STREAMLINED**: Clean zoom toggle between fit and actual size modes with smooth animation
- **DOCUMENTED**: Comprehensive roadmap restructure with M4.6-M6 detailed planning
- **ESTABLISHED**: Known Issues section for tracking acceptable limitations

### 2025-01-24 - 🚀 M4.5: QA Issues Completely Resolved ✅
- **FIXED**: Export All dialog "Show Options" button issue with `isAccessoryViewDisclosed`
- **REBUILT**: Click-to-zoom with pure SwiftUI approach (removed buggy NSView implementation)
- **ELIMINATED**: Grey bar display issues and layout conflicts in frame preview
- **ADDED**: Proper zoom state reset when navigating between frames (always start in fit mode)
- **ENHANCED**: Clean SwiftUI HoverOverlay with "Click to zoom" / "Click to fit" feedback
- **SIMPLIFIED**: Removed complex NSScrollView implementation for reliable SwiftUI components
- **VERIFIED**: Working click detection, hover feedback, and smooth zoom transitions
- **PRODUCTION READY**: All critical QA issues resolved with stable, simple implementation

### 2025-01-24 - 🚀 M4.6: Performance & UX Issues Resolved ✅
- **FIXED**: Performance regression completely resolved - now instant launch (~10ms vs 8.6s)
- **SOLUTION**: Replaced FFmpeg duration analysis with AVFoundation metadata reading
- **OPTIMIZED**: Pre-warmed FFmpeg path during app initialization
- **CLEANED**: Removed debug timing logs for production-ready experience

### 2025-01-24 - 🎉 M4.5: Final Polish Features Implemented ✅
- **ENHANCED**: Export dialog redesigned with integrated format selection in NSSavePanel accessory view
- **IMPROVED**: Format defaults to PNG (lossless) with options for JPEG (100% quality) and TIFF
- **ADDED**: Frame navigation arrows in preview mode (appear on hover, positioned outside image)
- **IMPLEMENTED**: Keyboard navigation with left/right arrow keys for frame browsing
- **ENHANCED**: "Full Size" button replaced with click-to-zoom on image
- **IMPROVED**: New Video button contrast with subtle background and border
- **OPTIMIZED**: Wrap-around navigation (last frame → first frame) for seamless workflow
- **TECHNICAL**: Custom NSObject coordinator for Objective-C compatibility with popup actions
- **COMPATIBILITY**: Fixed macOS 12+ compatibility (removed macOS 14+ onTapGesture)

### 2025-01-24 - 🎉 M4: Production Polish & Export Complete ✅
- **IMPLEMENTED**: Full export functionality with native save dialogs
- **ADDED**: Individual frame export with timestamp filenames (frame_00-03-15.jpg)
- **ADDED**: Export All functionality with folder selection
- **CREATED**: Frame preview modal with full resolution display
- **FIXED**: Shift button icon (clockwise arrow for "forward +1s")
- **ENHANCED**: Eye icon interaction - click for full preview
- **POLISHED**: Opening screen - removed taglines for minimal focus
- **ADDED**: Fade-in animations for frame appearance (staggered timing)
- **DEBUGGED**: FFmpeg integration - fixed duration parsing command
- **READY**: Production-ready with all core functionality complete

### 2025-01-24 - 🎉 M3: Fresh Project Creation & Launch Prep ✅
- **CREATED**: Completely fresh Xcode project named "Still Marker" from scratch
- **MIGRATED**: All Swift files, FFmpeg binary, resources, entitlements from old FRAMESHIFT project
- **ELIMINATED**: All FRAMESHIFT references throughout entire codebase and project structure
- **VERIFIED**: Clean project structure with no nested/duplicate folders
- **BUNDLE ID**: com.johnnyhockin.stillmarker properly configured
- **APP DISPLAY**: "Still Marker" appears correctly in title bar and throughout UI
- **REMOVED**: Old FRAMESHIFT project files completely for clean workspace
- **TESTED**: Project opens successfully in Xcode without parse errors
- **READY**: For final QA testing and launch

### 2025-01-24 - ✨ App Renamed to Still Marker ✅
- **RENAMED**: App from FRAMESHIFT to Still Marker (Chris Marker reference)
- **UPDATED**: Bundle identifier to com.johnnyhockin.stillmarker
- **UPDATED**: All code references, comments, and UI text
- **CLEANED**: Removed all obsolete web version files (index.html, netlify/, src/, etc.)
- **PRESERVED**: Project history and architecture pivot documentation
- **COMMITS**: Two clean commits pushed with full rename and cleanup
- **ISSUE**: Project file corruption during rename process required fresh project creation

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

### 🎉 CORE + FRAME REFINEMENT COMPLETE ✅
**Current State:** M4.7 completed - Core functionality + Frame Refinement system ready for QA

### COMPLETED FOUNDATION (M1-M4.7)
- [x] **M1**: Mac app skeleton with SwiftUI *(✅ COMPLETED)*
- [x] **M2**: FFmpeg integration and real frame extraction *(✅ COMPLETED)*
- [x] **M3**: Fresh project creation and launch preparation *(✅ COMPLETED)*
- [x] **M4**: Export functionality and production polish *(✅ COMPLETED)*
- [x] **M4.5**: Final polish features implemented *(✅ COMPLETED)*
- [x] **M4.6**: Enhanced window & zoom experience *(✅ COMPLETED)*
- [x] **M4.7**: Frame Refinement & Progressive Enhancement *(✅ COMPLETED)*
- [x] **PERFORMANCE**: Instant app launch (~10ms) with AVFoundation duration analysis
- [x] **EXPORT SYSTEM**: Complete export functionality with format selection
- [x] **CLICK-TO-ZOOM**: Working zoom toggle with smooth animations
- [x] **FRAME PREVIEW**: Clean image display and navigation
- [x] **KEYBOARD NAV**: Arrow key navigation between frames
- [x] **FRAME REFINEMENT**: 7-frame timeline system with progressive loading
- [x] **ADAPTIVE EXTRACTION**: Dynamic frame intervals (3fps limit, 1 decimal precision)
- [x] **PROFESSIONAL UX**: Stable, filmmaker-ready interface

### ⚠️ KNOWN ISSUES
- **Click-to-zoom location**: Currently zooms to upper-left instead of clicked location
  - *Status*: Acceptable for current release, enhancement for future milestone
  - *Impact*: Low - zoom functionality works, just not precisely positioned
- **Keyboard navigation in zoom**: Arrow keys may lose focus after clicking in zoomed view
  - *Status*: Under investigation
  - *Workaround*: Click away from image then use arrows

---

## 🚀 GO-FORWARD ROADMAP

### M4.8: Export All UX Improvements *(✅ COMPLETED)*
- [x] **Enhanced Export All feedback** (immediate + completion notifications)
- [x] **Fixed Export All dialog** (format options always visible, properly sized)
- [x] **Improved toast notifications** (longer duration for batch operations)
- [x] **Professional export workflow** (clear feedback at every step)

### M4.9: Simplified Frame Refinement *(✅ COMPLETED)*
- [x] **4-button refinement controls** (`<< < timecode > >>` layout)
- [x] **Coarse navigation** (±0.5s with double chevrons)
- [x] **Fine navigation** (±1 frame with single chevrons)
- [x] **Visual distinction** (darker/lighter blue for coarse/fine)
- [x] **Enhanced control panel** (moved Export button for prominence)
- [x] **Preview-only refinement** (no persistence complexity)

### M5.0: Enhanced File Naming *(CURRENT)*
**Target**: Improve export file naming with source video context

- [ ] **Add source video filename prefix** to exported frames
- [ ] **Format**: `[video_name]_frame_[timestamp].[ext]`
- [ ] **Example**: `interview_final_v2_frame_00-03-2.png`
- [ ] **Benefits**: Better organization, context preservation, multi-video workflows

### M5.1: Visual Identity & Dark Mode *(AESTHETIC TRANSFORMATION)*
**Target**: Chris Marker aesthetic - contemplative, precise, beautiful

#### **Complete Visual Overhaul**
- [ ] **Permanent dark theme** - filmmakers work in dark edit suites
  - [ ] Lifted blacks (#1a1a1d not #000000) throughout interface
  - [ ] High-end color grading suite aesthetic
  - [ ] Professional dark mode hierarchy with opacity levels (0.9, 0.7, 0.5, 0.3)

#### **Typography Redesign: "STILL MARKER" as Architecture**
- [ ] **Chris Marker aesthetic** (La Jetée inspired)
  - [ ] Think gallery signage or film credits
  - [ ] Vertical stacking exploration: **S T I L L** / **M A R K E R**
  - [ ] Extreme letter spacing refinements  
  - [ ] Make app name architectural element, not just label
  - [ ] Remove generic appearance completely

#### **Selection System Enhancement**
- [ ] **Checkboxes on frame cards** for multi-selection
  - [ ] Eye icon → preview (existing behavior)
  - [ ] Checkbox → select for export  
  - [ ] "Export Selected" vs "Export All" button states
  - [ ] Visual indicator for selected frames (subtle glow)
  - [ ] Multi-select workflow integration

#### **App Icon Design**
- [ ] **Professional icon** reflecting filmmaker's tool
- [ ] **Chris Marker inspired** visual language
- [ ] **macOS Big Sur+ compatibility** (rounded corners, materials)

### M6: Distribution Preparation *(PRODUCTION READY)*
**Target**: Professional distribution and final polish

#### **Code Signing & Distribution**
- [ ] **Apple Developer Program** setup and certificates
- [ ] **Code signing and notarization** for security
- [ ] **App Store preparation** (if chosen as distribution path)
- [ ] **Direct download preparation** (primary distribution method)

#### **Marketing & Documentation**
- [ ] **Website/landing page** for Still Marker
- [ ] **Professional screenshots** and demo videos
- [ ] **User documentation** and filmmaker workflow guides
- [ ] **Press kit** for film industry publications

#### **Final QA & Dogfooding**
- [ ] **Extensive testing** across different macOS versions
- [ ] **Real filmmaker workflows** testing with actual projects
- [ ] **Performance optimization** for various video formats and sizes
- [ ] **Accessibility compliance** (WCAG guidelines)

---

## 🎬 DESIGN PHILOSOPHY EVOLUTION

**Core Vision**: Tool Chris Marker himself might have appreciated
- **Contemplative**: Interface respects the filmmaker's craft and creative process
- **Precise**: Every element serves the core purpose of extracting perfect stills
- **Beautiful**: Not flashy, but thoughtfully designed with cinematic sensibility

**La Jetée Influence**: 
- Still frames are the star - present them like museum pieces
- Typography feels hand-typed, documentary-like
- Time manipulation (Shift +1s) feels poetic, not just functional
- Digital light table where film essayist examines their work

**Professional Context**:
- **"Would a tired cinematographer appreciate this at 3am after a 14-hour shoot?"**
- Beautiful but NEVER at expense of clarity
- These are professionals who need tools that work

---

## 🧠 TECHNICAL IMPLEMENTATION NOTES

### Architecture Decisions Made

**Performance Optimization (RESOLVED):**
- **Issue**: Original 8.6s delay in video duration analysis using FFmpeg
- **Solution**: Replaced with AVFoundation metadata reading (~10ms)
- **Impact**: Instant app launch, dramatically improved UX

**macOS Compatibility:**
- **Target**: macOS 12+ (Monterey) for broad compatibility
- **SwiftUI**: Pure SwiftUI approach chosen over NSView hybrids for reliability
- **Gesture Handling**: Custom tap gesture implementation for macOS 12+ compatibility

**FFmpeg Integration:**
- **Bundled Binary**: Intel FFmpeg binary included (works on Apple Silicon via Rosetta)
- **Processing**: Async frame extraction with progress tracking
- **Quality**: JPEG 95% quality for optimal file size/quality balance

### Adaptive Frame Extraction Algorithm

```swift
func calculateFrameInterval(videoDuration: Double) -> Double {
    let targetFrames = 30
    let maxFrames = 40
    let minInterval = 0.5  // Don't extract more than 2 frames per second
    
    // Very short videos (< 30s): every 1 second
    if videoDuration < 30 {
        return 1.0
    }
    
    // Medium videos (30s - 5min): aim for ~30 frames
    if videoDuration <= 300 {  // 5 minutes
        let interval = videoDuration / Double(targetFrames)
        // Round to nearest 0.5 second for cleaner timestamps
        return max(round(interval * 2) / 2, minInterval)
    }
    
    // Long videos (> 5min): cap at 40 frames
    let interval = videoDuration / Double(maxFrames)
    return max(round(interval * 2) / 2, minInterval)
}

// Usage example:
let interval = calculateFrameInterval(videoDuration: 48.92)
// Returns: 1.5 seconds (giving ~32 frames for a 49s video)
```

**Benefits:**
- **15-second commercial**: 15 frames at 1s intervals
- **2-minute music video**: ~30 frames at 4s intervals 
- **10-minute short film**: 40 frames at 15s intervals
- **Consistent filmmaker experience** across content lengths
- **Performance optimization** for long-form content

---

## 📌 MILESTONE COMMITS

### 🕸️ WEB-BASED MILESTONES (COMPLETED BUT PIVOTED)
- **M1**: Project skeleton scaffolded *(✅ COMPLETED)*
- **M2**: Basic upload + processing pipeline working *(✅ COMPLETED)*
- **PIVOT**: Discovered 6MB limit, architecture fundamentally limited

### 🖥️ NATIVE MAC APP MILESTONES (NEW ROADMAP)
- **M1**: Mac app skeleton with SwiftUI *(✅ COMPLETED)*
- **M2**: FFmpeg integration and real frame extraction *(✅ COMPLETED)*
- **M3**: Fresh project creation and launch preparation *(✅ COMPLETED)*
- **M4**: Export functionality and production polish *(✅ COMPLETED)*
- **M5**: Visual identity and dark mode aesthetic *(pending)*
- **M6**: Advanced features and optimization *(pending)*
- **M7**: App Store preparation and distribution *(pending)*

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