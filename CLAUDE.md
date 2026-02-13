# CLAUDE.md - Still Marker

> **Source of Truth** for the Still Marker project. Read this file completely before any work.

## Current Status

**Phase**: M5 Complete - Visual polish and stability achieved
**Next**: M6 Distribution Preparation
**Blockers**: None

### Active Priorities
1. Address open GitHub issues (#1-#5)
2. Distribution preparation (code signing, notarization)
3. Final QA across macOS versions

---

## Quick Context

**What is Still Marker?**
A native Mac app for filmmakers to extract high-quality still images from video files. Named after Chris Marker, the legendary essay filmmaker.

**Tech Stack**: Swift + SwiftUI, macOS 12+, bundled FFmpeg
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
│   ├── StillMarkerApp.swift      # App entry point
│   ├── ContentView.swift         # Main view router
│   ├── FFmpegProcessor.swift     # Video processing engine
│   ├── Models/
│   │   └── Frame.swift           # Frame data model
│   ├── Views/
│   │   ├── UploadProcessingView.swift  # Drag-drop & processing UI
│   │   ├── ResultsView.swift           # Grid & preview (main UI)
│   │   └── DotPatternView.swift        # Background texture
│   ├── Resources/
│   │   └── ffmpeg                # Bundled FFmpeg binary
│   └── Assets.xcassets/          # App icons, colors
│
├── Still Marker.xcodeproj/   <- Xcode project
├── create-custom-icon.swift  <- Icon generation script
└── generate-icon.sh          <- Icon generation helper
```

---

## Action Log

### 2025-02-13 - Docs-Protocol Implementation
- **Agent**: Claude Opus 4.5
- **Action**: Established docs-protocol compliance
- **Result**: Created CLAUDE.md hub, HISTORY.md, TROUBLESHOOTING.md, _logs/ infrastructure
- **Files Created**: CLAUDE.md, HISTORY.md, TROUBLESHOOTING.md, .gitignore
- **Status**: Complete

---

## Open GitHub Issues

| # | Issue | Priority |
|---|-------|----------|
| 1 | Vertical videos stretched in grid | High |
| 2 | No feedback when dropping video on grid | Medium |
| 3 | Drop zone too restrictive on opening page | Medium |
| 4 | Need end-of-file indicator | Low |
| 5 | Frame preview should accept video drops | Medium |

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
