# CLAUDE.md - Still Marker

> **Source of Truth** for the Still Marker project. Read this file completely before any work.

## Current Status

**Phase**: M6 - Browse-Pick-Export workflow overhaul complete
**Next**: QA testing + Distribution Preparation
**Blockers**: None

### Active Priorities
1. QA testing of browse-pick-export workflow
2. Distribution preparation (code signing, notarization)
3. Final QA across macOS versions

---

## Quick Context

**What is Still Marker?**
A native Mac app for filmmakers to extract high-quality still images from video files. Named after Chris Marker, the legendary essay filmmaker.

**Tech Stack**: Swift + SwiftUI, macOS 12+, AVFoundation (native frame extraction)
**Philosophy**: "Would a tired cinematographer appreciate this at 3am?"

---

## File Map

```
Still-Marker/
├── CLAUDE.md                 <- This file (hub)
├── PROJECT_SPEC.md           <- Detailed specs, architecture, full changelog
├── HISTORY.md                <- Archived completed milestones
├── TROUBLESHOOTING.md        <- Problem → Solution pairs
├── README.md                 <- User-facing documentation
├── _logs/                    <- Session logs for parallel work (gitignored)
│
├── Still Marker/             <- Source code
│   ├── StillMarkerApp.swift          # App entry point
│   ├── ContentView.swift             # Main view router + AppViewModel
│   ├── AVFoundationProcessor.swift   # Native video frame extraction
│   ├── FFmpegProcessor.swift         # Legacy FFmpeg processor (retained)
│   ├── Models/
│   │   └── Frame.swift               # Frame data model
│   ├── Views/
│   │   ├── UploadProcessingView.swift    # Drag-drop & processing UI
│   │   ├── ResultsView.swift             # Grid & preview (main UI)
│   │   ├── FrameCardView.swift           # Grid card with magnification + pick indicator
│   │   ├── FilmstripView.swift           # Horizontal filmstrip in preview
│   │   ├── FrameControlsView.swift       # Nudge controls, gear dial, pick/export buttons
│   │   ├── FramePreviewComponents.swift  # Preview header + navigation
│   │   ├── KeyEventHandling.swift        # Keyboard event capture (arrows, space, esc)
│   │   └── DotPatternView.swift          # Background texture
│   ├── Resources/
│   │   └── ffmpeg                    # Bundled FFmpeg binary (retained)
│   └── Assets.xcassets/              # App icons, colors
│
├── Still Marker.xcodeproj/   <- Xcode project
├── create-custom-icon.swift  <- Icon generation script
└── generate-icon.sh          <- Icon generation helper
```

---

## Action Log

### 2026-02-16 - Browse-Pick-Export Workflow Overhaul
- **Agent**: Claude Opus 4
- **Action**: Complete UX overhaul transforming Still Marker from "find one frame and export" to "browse-pick-export" workflow
- **Files Created**: AVFoundationProcessor.swift, FrameCardView.swift, FilmstripView.swift, FrameControlsView.swift, FramePreviewComponents.swift, KeyEventHandling.swift
- **Files Modified**: ResultsView.swift, ContentView.swift, FFmpegProcessor.swift, project.pbxproj
- **Details**:
  - Phase 0: Decomposed ResultsView.swift (1264 lines) into 5 extracted component files (~700 lines remain)
  - Phase 1: Scaled frame extraction - up to 600 frames for long videos (was capped at 40)
  - Phase 2: Adaptive grid sizing (80-180px minimum based on frame count) + hover magnification (1.8x scaleEffect overlay)
  - Phase 3: Adaptive header language ("48 frames - 1 every 2s" vs "320 moments - 1 every 10s across 1h 32m")
  - Phase 4: Pick system - Space/P to pick frame, returns to grid scrolled to pick location, gold dot indicator
  - Phase 5: Export picks - header button toggles between "export all" and "export N picks", batch export with clear
  - Phase 6: Preview flow polish - pick/unpick button in controls, keyboard hints updated
  - Phase 7: AVFoundation migration - replaced FFmpeg subprocesses with native AVAssetImageGenerator (10-50x faster)
- **Status**: Complete - awaiting user QA

### 2026-02-13 - Design Language Sprint
- **Agent**: Claude Opus 4
- **Action**: Applied native design language across all views
- **Files Modified**: UploadProcessingView.swift, ResultsView.swift
- **Files Created**: .ralph/specs/design-language.md
- **Details**:
  - Replaced 4-layer gradient background with `Color(nsColor: .windowBackgroundColor)`
  - Removed `Color(hex:)` extension and all custom hex/RGB colors
  - Replaced all `.design: .monospaced` typography with SF Pro system font
  - Kept `.monospacedDigit()` for timecodes only (TE level 2)
  - Simplified FilmExportButtonStyle: removed gold hex, glass morphism, `startsAsGrey` → accent color fill
  - Simplified GreyNavigationButtonStyle: removed gradient highlights, hard light edges → clean fill + border
  - Simplified FrameCard: removed brightness/saturation hover, luminous gradient border, multi-shadow → clean border + simple shadow
  - Simplified toast: removed multi-layer glass, gradient border → single `.ultraThinMaterial`
  - All colors now use `.primary/.secondary/.tertiary/.accentColor`
- **Status**: Complete - user QA confirmed

### 2026-02-13 - GitHub Issues #1-#5 Resolved
- **Agent**: Claude Opus 4
- **Action**: Fixed all 5 open GitHub issues + Ralph structure setup
- **Files Modified**: ContentView.swift, UploadProcessingView.swift, ResultsView.swift
- **Files Created**: .ralph/ structure, .ralphrc
- **Details**:
  - #1: Fixed vertical video thumbnails (aspectRatio fit + dark pillarbox container)
  - #2: Added dark scrim drop overlay on grid with "Drop to load new video" text
  - #3: Expanded drop zone to entire window on upload screen
  - #4: End-of-file indicator: forward/backward controls dim at boundaries, "(end)" label, toast notifications
  - #5: Frame preview now accepts video drops
  - Also: removed dead `currentOffset`/`shiftOffset()` code, added `videoDuration` to AppViewModel, extracted `dropOverlay` to fix SwiftUI type-checker crash
- **Status**: Complete - user QA confirmed

### 2025-02-13 - Docs-Protocol Implementation
- **Agent**: Claude Opus 4.5
- **Action**: Established docs-protocol compliance
- **Result**: Created CLAUDE.md hub, HISTORY.md, TROUBLESHOOTING.md, _logs/ infrastructure
- **Files Created**: CLAUDE.md, HISTORY.md, TROUBLESHOOTING.md, .gitignore
- **Status**: Complete

---

## Open GitHub Issues

All resolved as of 2026-02-13.

| # | Issue | Status |
|---|-------|--------|
| 1 | Vertical videos stretched in grid | Fixed |
| 2 | No feedback when dropping video on grid | Fixed |
| 3 | Drop zone too restrictive on opening page | Fixed |
| 4 | Need end-of-file indicator | Fixed |
| 5 | Frame preview should accept video drops | Fixed |

---

## Spoke Files

| File | Purpose |
|------|---------|
| [PROJECT_SPEC.md](./PROJECT_SPEC.md) | Full specs, architecture, active changelog, design philosophy |
| [HISTORY.md](./HISTORY.md) | Archived milestones (M1-M4 completed work) |
| [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) | Specific problem → solution pairs |

---

## Best Practices

- **Read PROJECT_SPEC.md** for detailed architecture decisions
- **Log every action** in the Action Log above
- **User does QA** - Never assume code works, wait for user confirmation
- **Component extraction** - SwiftUI views > 100 lines should be split
- **Test with real videos** - Various formats, lengths, aspect ratios

---

## Anti-Patterns

- Don't celebrate completion until user QA confirms it works
- Don't create views with 200+ lines (SwiftUI type system crashes)
- Don't use string interpolation in SwiftUI closures during view construction
- Don't use more than ~40 gradient stops total (stack overflow risk)
- Don't access @State directly in nested view builders (extract to locals first)

---

## Session Start Protocol

1. Read this file completely
2. Check Action Log for current state
3. Review Open GitHub Issues
4. Check `_logs/` for any pending parallel work
5. Read spoke files only when task requires them

---

## Parallel Work Mode

When running multiple Claude instances:
1. **Do NOT edit CLAUDE.md directly**
2. Write your log to: `_logs/session-[task-name].md`
3. Do NOT commit - human merges everything at end

---

*This file is the single source of truth. Preserve it at all costs.*
