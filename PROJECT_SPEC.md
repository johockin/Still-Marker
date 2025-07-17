# PROJECT_SPEC.md

⚠️ This is the **living god file** for FRAMESHIFT. Every architectural decision, design tradeoff, and project evolution must be documented here. This file is the source of truth for all collaborators.

---

## 🔰 PURPOSE OF THIS FILE

- Serves as the **canonical source of truth** for the FRAMESHIFT project
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

- **Project name**: FRAMESHIFT
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

## 🏗️ INITIAL TECH ARCHITECTURE

*Architecture recommendations based on requirements analysis:*

- **Framework / language**: Vanilla JavaScript + HTML5 + CSS3
  - *Rationale: Maximum performance, minimal bloat, full control over optimization*
- **Frontend architecture**: Single-page application with module-based organization
  - *Rationale: Simple, fast, no framework overhead*
- **Backend processing**: Netlify Functions with FFmpeg
  - *Rationale: Reliable server-side processing for large files, handles memory constraints*
- **File handling**: Temporary storage during processing, immediate cleanup
  - *Rationale: Privacy-first approach while maintaining performance*
- **Styling approach**: Custom CSS with CSS Grid/Flexbox
  - *Rationale: Full control over cinematic minimal aesthetic, no framework bloat*
- **State management**: Vanilla JS with custom event system
  - *Rationale: Simple, predictable, no external dependencies*
- **Directory structure plan**:
  ```
  /
  ├── index.html
  ├── src/
  │   ├── js/
  │   │   ├── main.js
  │   │   ├── upload.js
  │   │   └── processing.js
  │   ├── css/
  │   │   └── styles.css
  │   └── assets/
  └── netlify/
      └── functions/
          └── process-video.js
  ```
- **Key dependencies**: FFmpeg (server-side), minimal frontend dependencies
- **Planned dev workflow**: Simple file watching, no build tools initially
- **Testing approach**: Manual QA with user, focus on real-world filmmaker workflows

---

## 📒 CHANGELOG (REVERSE CHRONOLOGICAL)

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

- **M1**: Project skeleton scaffolded *(✅ COMPLETED)*
- **M2**: Basic upload + processing pipeline working *(✅ COMPLETED)*
- **M3**: Full MVP with UI polish *(pending)*
- **M4**: Production-ready with error handling *(pending)*

---

## 📌 OPEN QUESTIONS

*(No open questions - all clarifications received)*

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