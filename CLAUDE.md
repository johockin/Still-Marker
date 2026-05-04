# CLAUDE.md - Still Marker

> **Source of Truth** for the Still Marker project. Read this file completely before any work.

## Current Status

**Phase**: M9 — Theatrical Extraction (Phase 1+2 implemented, awaiting QA)
**Next**: M9 Phase 3 (recent strip / retro-pick), then Phase 4-5
**Blockers**: None

### Roadmap (next up)
- **M9 Theatrical extraction experience** — Full brief below. Turns extraction wait into the opening act: frames appear full-bleed as they come through, user can pick them as they pass. See "M9 — Theatrical Extraction Brief" section.
- **Resume M7 redesign batch 2** — UploadProcessingView, ResultsView header, FilmstripView, FrameCardView, SettingsView, StillMarkerApp (M7 brief lower in this file).
- **Window size/position persistence** (Issue #10).
- **Error/failure UX** (Issue #5 partial — codec coverage is solved, but extraction-time per-frame failures still print silently).

### Active Priorities
1. **UI Redesign** — Batch 1 (Theme.swift, FrameControlsView, FramePreviewComponents) implemented, awaiting QA
2. Distribution preparation (after redesign QA)

### What Happened
M7 batch 1 implemented: Liquid Glass helpers in Theme.swift, bigger controls + glass treatment in FrameControlsView and FramePreviewComponents. User confirmed: no earned presence (controls stay visible), macOS 26 beta for testing. Remaining files: ResultsView, FilmstripView, UploadProcessingView, FrameCardView, SettingsView, StillMarkerApp.

---

## Quick Context

**What is Still Marker?**
A native Mac app for filmmakers to extract high-quality still images from video files. Named after Chris Marker, the legendary essay filmmaker.

**Tech Stack**: Swift + SwiftUI, macOS 26+ primary (macOS 12+ fallbacks), AVFoundation (native frame extraction)
**Philosophy**: "Would a tired cinematographer appreciate this at 3am?"

---

## Build & Install SOP

> Johnny uses the installed `/Applications/Still Marker.app` for real work between sessions. The dev build in `build/` is for iteration only. **The installed app must always reflect the latest committed (or in-flight & QA'd) state at end of session.**

### Change discipline (apply to EVERY change, not just session boundaries)
1. **Make the change.**
2. **Update CLAUDE.md** — add an Action Log entry (date, agent, action, files modified, status) and update Known Issues / Current Status if relevant. Docs are never a separate task; they're part of the change.
3. **Commit it** — small, focused commits with a real subject line. Don't batch unrelated changes into one commit. Don't sweep `.DS_Store`, `xcuserdata/*`, or `Breakpoints_v2.xcbkptlist` into commits — those are user-state noise (and should probably be `.gitignore`d).
4. **Build + install if user-visible** — for any change that affects what johnny sees in the app, rebuild + reinstall to `/Applications` so his real-use copy stays current.

The order matters: code → docs → commit → install. Skipping the docs step means the next session has to reverse-engineer what happened. Skipping the commit means work can be lost or stranded.

What NOT to commit without explicit permission:
- `.DS_Store`, `*/xcuserdata/*`, `UserInterfaceState.xcuserstate`, `Breakpoints_v2.xcbkptlist` — user-state noise
- Other people's in-flight uncommitted work that happens to be in the working tree (e.g., M7 batch 1 changes that pre-dated the session) — leave those for the original author to commit
- Large binaries unless intentional (e.g., the bundled `ffmpeg` is fine; build artifacts are not)

### When to install
- **Session start**: confirm installed version matches current source. If not, build + install.
- **During session**: iterate via `xcodebuild` + relaunch the *dev build*, not the installed copy. Don't reinstall on every change.
- **Session end**: ALWAYS rebuild and reinstall to `/Applications` so johnny has the latest when he's away from this session.

### Build (Release)
```bash
cd "/Users/johnnyhockin/AI Playground/Still-Marker"
xcodebuild -project "Still Marker.xcodeproj" -scheme "Still Marker" \
  -configuration Release -derivedDataPath build clean build
```
Output: `build/Build/Products/Release/Still Marker.app`

### Install to /Applications
```bash
# Quit if running
pkill -f "/Applications/Still Marker.app/Contents/MacOS/Still Marker" 2>/dev/null
# Replace
rm -rf "/Applications/Still Marker.app"
cp -R "build/Build/Products/Release/Still Marker.app" "/Applications/"
# Launch (optional, to confirm)
open "/Applications/Still Marker.app"
```

### Iterate during session (dev relaunch, no install)
```bash
# After code changes:
xcodebuild -project "Still Marker.xcodeproj" -scheme "Still Marker" \
  -configuration Debug -derivedDataPath build build 2>&1 | tail -5
pkill -f "build/Build/Products/Debug/Still Marker.app" 2>/dev/null
open "build/Build/Products/Debug/Still Marker.app"
```

### Notes
- Codesign: ad-hoc ("Sign to Run Locally") — fine for personal install, not for distribution.
- Deployment target is macOS 13.0; Liquid Glass code paths gated by `if #available(macOS 26, *)`.
- If install fails with "in use," ensure you've killed the process first (LaunchServices keeps it locked).
- Don't confuse the dev build (`build/...`) with the installed copy (`/Applications/...`) — they're separate processes.

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
│   │   ├── SettingsView.swift            # Preferences window (appearance, about)
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

## M7 Redesign Brief

> **Status**: Planning complete, no code written. Pick up from here.

### User's Core Request
"The ethos of the design right now is good and the spirit of it. But it needs to be easier to use with bigger controls that are more clear." Every screen needs the same treatment — no single area is worse than others.

### Target Platform
**macOS 26+ (Liquid Glass)** with `if #available(macOS 26, *)` fallbacks to macOS 12+ using `.ultraThinMaterial`.

### Design Philosophy (from reference documents)

Three reference documents inform this redesign. The user provided these as examples of the aesthetic and interaction philosophy they want applied to Still Marker:

**1. "Earned Presence" / Disappearing Chrome**
- UI exists to serve the content (video frames), not assert its own presence
- Opacity is the primary state lever: invisible (0%) → ready (35%) → active (70%) → content (100%)
- Controls should be nearly invisible at rest, materialize on hover/need
- Every element must justify its visibility — no gratuitous dividers, borders, or decorations
- Animate state changes, not decorations

**2. Interaction Patterns**
- Hover: subtle scale (1.02–1.08x) + opacity/material changes, 120–150ms duration
- Buttons: nearly invisible base state → ultraThinMaterial/glass on hover → top-edge highlight
- Selection comes from glass `.interactive()` modifier, not background overlays
- Content-first hierarchy: content full opacity > active UI 70% > inactive UI 35% > disabled lowest

**3. Liquid Glass (macOS 26+)**
- `.glassEffect(.regular)` for buttons and controls
- `.contentShape()` MUST come before `.glassEffect()` for hit-testing
- Containers: use `.ultraThinMaterial` not `.glassEffect()` (blocks gestures)
- Selection: `.regular.interactive()` not background overlays
- `GlassEffectContainer` for grouped glass elements
- Never stack glass on glass
- Never overlay backgrounds on glass

**4. Warm Aesthetic**
- Keep the gold accent system (already in Theme.swift)
- "Rainforest lushness" — generous whitespace, breathing room, not sterile
- Dieter Rams: "Less, but better" — every element earns its place
- Swiss International Typographic Style — grid-based, clean, invisible systems

### What Needs to Change (All Screens)

**Global / Theme.swift:**
- Add Liquid Glass helper modifiers (availability-checked)
- Add material-based surface tokens alongside current solid color tokens
- Increase base font sizes across the board

**Upload Screen (UploadProcessingView.swift, 265 lines):**
- Bigger EyeView and hero text
- More generous spacing/breathing room
- Security note and instructions with earned presence (subtle until relevant)

**Grid View (ResultsView.swift header + grid):**
- Header bar: bigger text, clearer buttons, more padding — currently 44px height with 13pt text is too small
- Frame cards: current 1.8x hover magnification is good, keep it
- Grid description text needs to be larger and more readable

**Frame Preview (FramePreviewComponents.swift + FrameControlsView.swift):**
- Navigation arrows: currently 14pt chevrons with thin padding — need to be substantially larger and clearer
- Nudge buttons: currently 44px wide with 14pt icons and 9pt labels — too small, need bigger touch targets
- Gear toggle: needs to be more obvious and larger
- Pick/export buttons: currently 12pt text with thin borders — need to be proper buttons with clear affordance
- Timecode display: currently 15pt monospaced — should be larger focal element

**Filmstrip (FilmstripView.swift, 53 lines):**
- Currently 80x45 thumbnails in 55px height strip — needs to be bigger
- Active frame indicator needs stronger presence

**Settings (SettingsView.swift, 203 lines):**
- Apply Liquid Glass treatment to appearance tiles
- Bigger touch targets

**Toast System (in ResultsView.swift):**
- Use `.ultraThinMaterial` / glass background instead of solid color

### Codebase Snapshot (for reference)

| File | Lines | Key Contents |
|------|-------|-------------|
| ResultsView.swift | 852 | Grid view, frame preview, export logic, pick system, toasts |
| FrameControlsView.swift | 277 | NudgeGear enum, NudgeButton, GearToggleView, pick/export buttons |
| UploadProcessingView.swift | 265 | EyeView (Canvas), GoldRingView, drag-drop, file picker |
| FFmpegProcessor.swift | 244 | Legacy processor (retained) |
| SettingsView.swift | 203 | Appearance tiles, about, feedback |
| Frame.swift | 192 | Dual-image model (thumbnail + full-res on-demand) |
| AVFoundationProcessor.swift | 142 | Native frame extraction |
| FramePreviewComponents.swift | 129 | Preview header + frame navigation |
| Theme.swift | 108 | Semantic colors, AppAppearance enum |
| ContentView.swift | 109 | AppViewModel, state routing |
| KeyEventHandling.swift | 107 | NSViewRepresentable keyboard handler |
| FrameCardView.swift | 67 | Grid card, hover, pick dot, timecode |
| DotPatternView.swift | 63 | Canvas dot grid texture |
| StillMarkerApp.swift | 61 | App entry, window config, Settings scene |
| FilmstripView.swift | 53 | Horizontal filmstrip |
| **Total** | **2,872** | |

### Implementation Order (suggested)
1. Theme.swift — Add Liquid Glass helpers, availability-checked modifiers, material tokens
2. FrameControlsView.swift — Biggest usability problem, make controls large and clear
3. FramePreviewComponents.swift — Bigger nav arrows, clearer header
4. ResultsView.swift — Header bar sizing, toast materials
5. FilmstripView.swift — Bigger strip
6. UploadProcessingView.swift — Breathing room, bigger elements
7. FrameCardView.swift — Glass hover treatment
8. SettingsView.swift — Glass tiles
9. StillMarkerApp.swift — Any window-level changes needed

### Key Constraints
- SwiftUI views MUST stay under ~200 lines (type checker crashes)
- No more than ~40 gradient stops total
- Don't access @State directly in nested view builders
- Preserve all keyboard shortcuts (arrows, space, esc, P)
- Workflow unchanged: upload → grid → preview → pick → export
- Keep the warm gold accent and overall ethos

---

## M9 — Theatrical Extraction Brief

> **Status**: Scoped, not yet implemented. Top of roadmap.

### The Idea

During extraction, the experience itself is part of the craft. The user watches the film reveal itself frame by frame, marking shots that catch their eye as they appear — **turning waiting into spotting**.

User vision (2026-05-03): *"Could it show us frames as they're going by? In full size, like a bit of a 'theatrical experience'? You can enjoy and plan ahead on some things you'll be grabbing."*

### Why It Matters

Extraction is the slowest part of the workflow. A 1-hour HEVC MKV via FFmpeg fallback can take many minutes. Currently the user stares at an eye icon. Two costs: (a) the wait feels worse than it is, (b) the user can't be productive during the wait.

The theatrical view turns dead time into the **opening act**. Watching the film slowly emerge IS engaging if framed right — it's what film projectors do. Marking frames as they pass means picks are already half-made by the time extraction completes.

### Target Experience

A nearly-empty screen. Black background. The current frame appears full-bleed in the center of the window, slight letterboxing if the aspect doesn't match. Each new frame as it's extracted gently crossfades in (300–400ms). Subtle filename + extraction progress in a top corner. Pick count if > 0. At the bottom edge, a thin strip of the last ~10 frames sits semi-transparent — visible if you look, invisible if you don't. Press P or Space to pick the current frame; a gold dot blooms briefly on the strip to confirm. Arrow keys scrub through what's been extracted so far. Esc skips to the grid (extraction continues in the background).

When extraction completes, the screen quietly settles into the grid view, picks already in place.

### Phases (pick a stopping point per session)

**Phase 1 — MVP (~1 session)**
- New `TheaterView` shown during `.processing` state once first frame extracted
- Eye icon stays for "Analyzing video…" moment, then yields to TheaterView on first frame
- Full-bleed display of most recently extracted frame, crossfade transitions
- Top-corner: filename + "23 of 480" progress
- Bottom: thin progress line
- Esc: skip to grid (extraction continues in background)
- No picking yet

**Phase 2 — Active picking (~0.5 session)**
- P / Space picks the current frame
- "picks: N" counter top-right
- Picks survive into grid view via the existing `pickedFrames` array
- Persistence: route through `AppViewModel.persistSession` (since `ResultsView`'s onChange isn't live during theatrical)

**Phase 3 — Recent strip ("plan ahead", ~1 session)**
- Bottom strip of last 10–12 frames as thumbnails
- Click any to pick that one (not just current)
- Hover shows timestamp
- Reuses `FilmstripView` styling

**Phase 4 — Scrub control (~0.5 session)**
- Space pauses auto-advance
- ←/→ scrubs through extracted frames so far

**Phase 5 — Polish (~0.5 session)**
- Vignette + faint grain overlay (very subtle, "earned presence")
- Estimated time remaining after 30s elapsed
- **Cancel button** (also fixes Issue #7)

**Phase 6 — Audio (stretch, separate milestone)**
- Audio playback from source synced to extraction position
- Major add: AVAudioPlayer driven by extraction progress
- Likely defer

### Decisions Already Made

- **Picks made in theater are real picks** — not "tagged for review." Carry into grid view immediately. (User's "plan ahead on some things you'll be grabbing" is commitment language.)
- **Skip-to-grid keeps extraction running** — user shouldn't be punished for switching modes.
- **No artificial slowdown.** Theatrical pacing comes from natural extraction rate. For very short videos that extract in 2s, the experience is over fast — that's fine.
- **Crossfades, not hard cuts.** ~300-400ms ease.
- **Black background, no chrome by default.** Same "earned presence" ethos.

### Open Decisions (defer to implementation)

- Estimated time remaining: always / after 30s delay / never
- Recent strip default visibility: ghost-faint always, or fully invisible until hover
- Pause behavior: visual-only, or also pause the extraction subprocess

### Technical Sketch

**Extraction streaming**:
- AVFoundationProcessor.extractFrames + FFmpegProcessor.extractFrames need to invoke an `onFrame` callback for each successful frame, in addition to the existing `progressCallback`
- VideoProcessor wraps both, exposes unified `onFrame`
- AppViewModel exposes `@Published var partialFrames: [Frame] = []` that grows during extraction
- After extraction completes, partialFrames becomes extractedFrames (or already is — same array)

**View layer**:
- New `TheaterView` shown when `state == .processing && !partialFrames.isEmpty`
- Renders the latest frame full-bleed
- Subscribes to partialFrames changes for crossfade triggering

**Picks during theatrical**:
- TheaterView calls into AppViewModel.pickFrameInTheater(frame:)
- AppViewModel maintains pickedFrames + persists via SessionStore directly (not through ResultsView's onChange)
- When state transitions to .results, ResultsView reads pickedFrames as the existing restore path does

**Cancel** (Phase 5):
- Store the extraction Task reference in AppViewModel
- Cancel button sends `task?.cancel()`, returns to upload, clears partial state

**Performance / memory**:
- Don't hold all extracted frames in TheaterView memory; only need current + recent strip thumbnails + picks
- Existing thumbnail infrastructure handles this

### Estimated Effort

- Phase 1 alone: ~1 session
- Phases 1+2+3 (the "real" experience): ~2-3 sessions
- Full Phase 1-5: ~3-4 sessions
- Phase 6 (audio): separate, ~1-2 sessions

### Dependencies / Blockers

- None hard. VideoProcessor + persistence already in place. Could start next session.

---

## Known Issues (Product Audit, 2026-05-03)

Severity-ranked. #1 and #2 fixed in this session; the rest are open.

### Resolved
- ✅ **#1 Output capped at 1080p** — Fixed by removing `maximumSize` cap on the cached `AVAssetImageGenerator`. Exports now use source resolution (4K, 6K, 8K — whatever the video has). `AVFoundationProcessor.swift:120`. Batch-extraction generator (thumbnail path) still caps at 1920x1080 for performance — this only affects the on-disk preview cache, not exports.
- ✅ **#2 PNG/TIFF exports were re-encoded JPEGs** — Fixed by re-extracting from the source video at export time and encoding directly to the chosen format. The lossy 1080p JPEG cache is now used only for in-app preview, never for export. Slight cost: each exported frame triggers one extra decode (a few hundred ms via the cached generator). `ResultsView.swift` `exportSingleFrameAtSourceResolution` + `performBatchExport`.
- ✅ **#3 Session persistence** — Added `PersistedSession` + `SessionStore` (in `ContentView.swift`). On launch, if `~/Library/Application Support/Still Marker/session.json` exists and the referenced video file is still on disk, the app auto-reloads the video and restores picks (matched by saved index → fallback to closest-by-timestamp within 1.5s). Persists the video URL the moment `startProcessing` is called, so a crash mid-extraction still recovers. Persists picks / view mode / frame index / export format via SwiftUI `.onChange` hooks in `ResultsView`. "new video" button explicitly clears the session.
- ✅ **#5 Codec coverage (was: silent error states)** — Bundled FFmpeg restored as automatic fallback. New `VideoProcessor` singleton (in `ContentView.swift`) tries AVFoundation first; on failure (MKV, MXF, older AVI codecs, WebM, etc.) routes through the bundled `ffmpeg` binary. Backend choice is cached per video URL. `FFmpegProcessor.getDurationViaFFmpeg` removes the AVFoundation dependency from the FFmpeg path. File allowlist broadened to match what's actually supported. Camera RAW (R3D, ARRI, BRAW, CRM) still unsupported — needs vendor SDKs, no FOSS option.
- ✅ **#9 (partial) Finder Open With** — `Info.plist` `CFBundleDocumentTypes` updated to advertise the broader format set now that FFmpeg fallback is in place.

### Open — Significant
- **#4 Half-finished M7 redesign.** Only `Theme.swift`, `FrameControlsView`, and `FramePreviewComponents` got the "bigger + glassy" treatment. Upload screen, grid header, filmstrip, frame card, settings still old. Visual inconsistency is more jarring than the original was.
- **#5 Silent error states.** Unsupported file dropped on the upload screen → `print` only, no toast. (Note: drag onto the *grid* does show a toast — `ResultsView.swift:844`. Upload screen path doesn't.) Frames that fail to extract → silently skipped, leaving gaps. `AVFoundationProcessor.swift:85`, `UploadProcessingView.swift:252`.
- **#6 Ad-hoc signed only, not notarized.** Cannot be shared with another user without Gatekeeper friction (right-click → Open dance). Unshippable as a product.
- **#7 No way to cancel processing.** Drop a 3-hour video by mistake → no escape.

### Open — Polish
- **#8 README is stale.** Says FFmpeg (now AVFoundation), 3-second intervals (now adaptive 1–15s), macOS 12 (target is 13), describes a "Shift +1s" feature that no longer exists.
- **#9 No Finder "Open with" integration.** Info.plist doesn't declare CFBundleDocumentTypes for video formats. Can't right-click a `.mp4` → Open in Still Marker.
- **#10 Window size/position not remembered.** Every launch forces 85% of screen and re-centers. `StillMarkerApp.swift:41`.
- **#11 Pick workflow is undiscoverable.** Space/P to pick is the core action and there's no first-launch hint, tooltip, or empty-state teaching.
- **#12 Probable temp-file leak.** `Frame.createTempImageURL` writes a JPEG per extracted frame to `NSTemporaryDirectory`. No cleanup on `resetToUpload` or app quit observed. Disk grows quietly.

---

## Codec & Container Support

**The MKV failure is expected, not a bug.** AVFoundation (which Still Marker uses for native frame extraction) does not support the Matroska container format on macOS, regardless of the codec inside.

### What AVFoundation reliably handles on macOS 13+
- **Containers:** MOV, MP4, M4V
- **Codecs:** H.264, HEVC (H.265), ProRes (all flavors: 422, 4444, etc.), DNxHD/DNxHR, Animation, MJPEG, uncompressed YUV/RGB
- **Hardware-accelerated decode** for H.264 and HEVC on Apple Silicon

### What it does NOT handle (and the app currently lies about by listing in the file picker allowlist)
- **MKV / Matroska** — open-source/Handbrake/torrent default. Not supported by AVFoundation on any version.
- **WebM** — sometimes works depending on codec, usually not.
- **AVI** — partial support; many older codec variants (DivX, XviD) fail.
- **WMV** — Microsoft container, basically not supported.
- **FLV** — Flash video, not supported.
- **MXF** — broadcast format (Sony XDCAM, Avid). Not supported by base AVFoundation.
- **AVCHD `.mts` / `.m2ts`** — sometimes works, depends on encoding profile.
- **Camera RAW formats** — ARRIRAW (.ari), RED R3D, Blackmagic BRAW, Canon CRM. Each requires its own vendor SDK.

### Current behavior on unsupported containers
1. Extension passes the allowlist check (`UploadProcessingView.swift:248`) — `mkv`, `avi`, `wmv`, `flv`, `webm` are all in the list but most don't actually work.
2. `AVAsset.load(.duration)` throws.
3. Error caught, message displayed for 3 seconds, app resets to upload.
4. User has no idea **why** it failed or **what to do about it**.

### Options for fixing codec support
| Approach | Pros | Cons |
|----------|------|------|
| **Honest allowlist + clear error** | Trivial. Set expectations. | Doesn't actually expand support. |
| **Restore FFmpeg fallback** (`FFmpegProcessor.swift` is still in the project, retained as legacy) | Universal codec support. Already partially built. | Bundled binary = ~70MB app size. Codesigning the binary. License/distribution implications (FFmpeg is LGPL, fine for Mac apps but adds LICENSE obligations). |
| **VLCKit** (libvlc as a framework) | Universal, well-maintained. | Heavy dependency (~50MB). LGPL/GPL implications. Architectural change. |
| **Pre-flight conversion suggestion** | Tell user `ffmpeg -i in.mkv -c copy out.mp4` is one command (fast, lossless when codecs are already H.264/HEVC inside). | Requires user to install ffmpeg or do it themselves. |

### Recommended next step
Two-part: (a) immediately tighten the allowlist + show a useful error for unsupported files ("MKV containers aren't supported by macOS native video. Try converting to MP4: see [link]"), and (b) decide whether to re-bundle FFmpeg as a fallback for the formats your actual users care about. The latter is a real product decision — depends on whether you want Still Marker to be "ProRes/H.264 native, Apple-native ethos" (then no FFmpeg) or "extract from anything" (then FFmpeg).

---

## Action Log

### 2026-05-03 - M9 Phase 1+2: Theatrical extraction (full-bleed view + active picking)
- **Agent**: Claude Opus 4.7
- **Action**: Implemented the first two phases of the M9 Theatrical brief.
  - **Streaming infrastructure**: `AVFoundationProcessor.extractFrames` and `FFmpegProcessor.extractFrames` gained an `onFrame: ((Frame) -> Void)?` callback that fires per successfully extracted frame. `VideoProcessor.extractFrames` passes it through. `AppViewModel.processVideo` wires the callback to `extractedFrames.append(frame)` on the main thread, so frames materialize live during extraction.
  - **TheaterView (in `ContentView.swift`)**: full-bleed black-background view. Current frame fills the window with breathing-room padding (64h / 80v), crossfades on change (`id(frame.id) + .transition(.opacity)`, 0.4s). Top row shows filename (left) + "N frames extracted" (right) in faint mono. Pick count appears below filename when > 0. Bottom shows current frame's timecode (left), keyboard hint (right), and a thin gold progress bar at the very bottom edge. Brief gold flash on each pick. P / Space pick the current frame; Esc skips to grid (extraction continues in background).
  - **Pick handoff**: `AppViewModel.theatricalPicks` accumulates. `addTheatricalPick` persists session.json immediately (so quit-during-theater doesn't lose work). On state transition to `.results`, `ResultsView.onAppear` calls `consumeTheatricalPicks()` and merges them into `pickedFrames` / `pickedSourceIndices` via `applyTheatricalPicks(_:)`.
  - **Routing**: `ContentView` now shows `UploadProcessingView` (eye icon) only while `.processing` AND `extractedFrames.isEmpty`. Once first frame arrives, switches to `TheaterView`.
- **Files Modified**: `Still Marker/AVFoundationProcessor.swift`, `Still Marker/FFmpegProcessor.swift`, `Still Marker/ContentView.swift`, `Still Marker/Views/ResultsView.swift`, `CLAUDE.md`
- **Not yet implemented (deferred to next sessions)**: recent-frames strip / retro-pick (Phase 3), pause + scrub (Phase 4), polish + cancel button (Phase 5), audio sync (Phase 6).
- **Status**: Installed (PID 70689), awaiting QA. Drop a video → eye icon → first frame arrives → TheaterView. Press P/Space to pick. Esc skips to grid. Picks carry through.

### 2026-05-03 - File picker MKV failure: scope claim + better error surfacing
- **Agent**: Claude Opus 4.7
- **Symptom**: User reported MKV worked via drag-drop but failed via browse button with "Could not determine video duration."
- **Diagnosis**: SwiftUI `fileImporter` returns security-scoped URLs (even for non-sandboxed apps). In-process AVFoundation handles scope transparently; spawned FFmpeg subprocess does NOT inherit it. Drag-drop URLs come from `provider.loadItem` and aren't scoped, hence the asymmetry.
- **Fixes**: (1) `handleFileSelection` now calls `url.startAccessingSecurityScopedResource()` before processing — claim is intentionally never released for the session lifetime (small leak, fine). (2) `FFmpegError.invalidDuration` now carries the FFmpeg stderr as an associated value and surfaces the last 280 chars in the UI message, so future "could not determine duration" failures self-diagnose. (3) Console log of failing path + stderr for terminal debugging.
- **Files Modified**: `Still Marker/FFmpegProcessor.swift`, `Still Marker/Views/UploadProcessingView.swift`, `CLAUDE.md`
- **Status**: ✅ Confirmed working — user verified MKV browse-button flow.

### 2026-05-03 - FFmpeg fallback + file picker fix + early session save (Issue #5 + bug)
- **Agent**: Claude Opus 4.7
- **Action**: Restored bundled `ffmpeg` (78MB binary already present at `Still Marker/Resources/ffmpeg`, version 6.1.1 from evermeet.cx) as automatic fallback for formats AVFoundation can't read. Added `VideoProcessor` singleton (in `ContentView.swift`) that probes AVFoundation first and routes to FFmpeg on failure, caching the choice per video URL. Refactored `FFmpegProcessor`: added `getDurationViaFFmpeg` (parses `ffmpeg -i` stderr — no AVFoundation dependency), made `extractSingleFrame` PNG-by-default for lossless export. Wired `AppViewModel` and `ResultsView` to use `VideoProcessor.shared`. Broadened file extension allowlist + `Info.plist` `CFBundleDocumentTypes` to match what FFmpeg actually supports.
- **File picker fix**: The file-importer's `allowedContentTypes: [.movie, .video]` was filtering out MKV/MXF/WebM (no registered UTI). Replaced with a curated list including dynamic UTTypes from filename extensions, so the picker no longer greys these out.
- **Early session save**: `AppViewModel.startProcessing` now writes the session.json the moment a video is loaded (before extraction completes), so a crash/kill mid-extraction still recovers the video reference on next launch.
- **Same-bundle-ID gotcha (lesson learned)**: Killing the Debug build (PID 63813) also terminated the user's `/Applications` app (PID 61139) because both share `com.johnnyhockin.stillmarker`. macOS LaunchServices treats them as the same app instance. New rule in SOP: don't run dev build alongside installed app. Saved as feedback memory.
- **Files Modified**: `Still Marker/FFmpegProcessor.swift`, `Still Marker/ContentView.swift`, `Still Marker/Views/ResultsView.swift`, `Still Marker/Views/UploadProcessingView.swift`, `Still Marker/Info.plist`, `CLAUDE.md`
- **Trade-off**: App size goes from ~1.3MB to ~80MB (the FFmpeg binary). Acceptable for "won't ever fail." FFmpeg binary is GPL-build (–enable-gpl/libx264/libx265); fine for personal install, would need swap to LGPL-only build for redistribution.
- **Status**: Installed (PID 65001). User confirmed MKV now works via drag-drop AND via file picker.

### 2026-05-03 - Session persistence (Issue #3)
- **Agent**: Claude Opus 4.7
- **Action**: Added `PersistedSession` (Codable) + `SessionStore` to `ContentView.swift`. `AppViewModel.init` now restores the last session on launch if the referenced video is still accessible. `ResultsView` saves on every pick / view-mode / frame-index / export-format change via `.onChange`. `resetToUpload` clears persisted state so "new video" is a clean slate.
- **Files Modified**: `Still Marker/ContentView.swift`, `Still Marker/Views/ResultsView.swift`, `CLAUDE.md`
- **Storage**: `~/Library/Application Support/Still Marker/session.json` (atomic writes, JSON)
- **Restore strategy**: timestamps are the source of truth; saved indices are a fast-path hint. Falls back to closest-frame-by-timestamp within 1.5s tolerance. Refined picks whose timestamps don't fall on a grid frame snap to the nearest grid frame on restore (acceptable v1 — user can re-nudge).
- **Not restored**: view mode + frame index are persisted but landing on grid is enforced for safer "where am I" UX.
- **Status**: Installed (PID 61139). After this point, reinstalls don't destroy work.

### 2026-05-03 - Fix #1 (1080p cap) and #2 (lossy export); document remaining issues + codec gap
- **Agent**: Claude Opus 4.7
- **Action**: Removed 1080p `maximumSize` from cached `AVAssetImageGenerator` so nudge-refined frames and exports use source resolution. Refactored `exportFrame` and `performBatchExport` to re-extract each frame from the source video at export time (bypassing the lossy preview cache). Built, reinstalled to `/Applications`, verified launch.
- **Files Modified**: `Still Marker/AVFoundationProcessor.swift`, `Still Marker/Views/ResultsView.swift`, `CLAUDE.md` (Known Issues + Codec sections added)
- **Net effect**: PNG/TIFF exports are now genuinely lossless from source bitstream. JPEG exports are 100% quality from source. Output is no longer artificially capped at 1080p — a 4K source produces a 4K still.
- **Trade-off**: Each export triggers one extra decode via the cached generator (~100-300ms per frame). Acceptable for typical pick batches (<50 frames).
- **Status**: Installed (PID 58430), awaiting user QA on a real 4K video

### 2026-05-03 - Build + Install to /Applications, document SOP
- **Agent**: Claude Opus 4.7
- **Action**: Built Release configuration of current source (M7 batch 1 in-flight, uncommitted), installed to `/Applications/Still Marker.app`, documented Build & Install SOP in CLAUDE.md
- **Files Modified**: CLAUDE.md (added "Build & Install SOP" section)
- **Build artifact**: `build/Build/Products/Release/Still Marker.app` (~1.3 MB binary, ad-hoc signed, arm64, deployment target macOS 13.0, built against MacOSX 26.4 SDK)
- **Verified**: app launched (PID confirmed running)
- **SOP**: install at session start (if stale) and session end; iterate via Debug build during session
- **Status**: Installed and running

### 2026-03-02 - M7 UI Redesign Batch 1: Theme + Controls
- **Agent**: Claude Opus 4.6
- **Action**: Implemented Liquid Glass helpers and resized frame preview controls
- **Files Modified**: Theme.swift, FrameControlsView.swift, FramePreviewComponents.swift
- **Details**:
  - Theme.swift: Added `.glassButton(isActive:cornerRadius:)` view modifier — `.glassEffect(.regular)` on macOS 26+, `.ultraThinMaterial` fallback. `isActive` variant uses `.regular.interactive()` for selected states.
  - FrameControlsView: Nudge buttons 14→20pt icons, 9→11pt labels, 44→64px width, glass backgrounds (removed manual fill/border). Gear toggle 13→16pt icon, 12→14pt text. Timecode 15→22pt. Pick/export 12→14pt with glass (removed stroke overlays).
  - FramePreviewComponents: Header 44→56px, back button now glass pill (chevron 10→13pt, text 13→15pt), export all now glass pill (13→15pt). Nav arrows 14→28pt in 56x56 glass pills. Base arrow opacity 0.3→0.6 (always visible).
  - User decisions: no earned presence (controls stay visible), macOS 26 beta available for testing, batch approach (3 files first, QA, then remaining 6)
- **Status**: Awaiting user QA

### 2026-03-02 - M7 UI Redesign Planning
- **Agent**: Claude Opus 4
- **Action**: Explored full codebase, gathered user requirements, documented redesign brief
- **Files Modified**: CLAUDE.md (this file — added M7 Redesign Brief)
- **Details**:
  - User provided 3 design reference documents: Writer Native Design Principles, Writer Native Interface Design System, Liquid Glass Implementation Guide
  - User confirmed: target macOS 26+ with Liquid Glass, macOS 12+ fallbacks
  - User confirmed: all screens need equal treatment, not just one area
  - Full codebase explored (2,872 lines across 15 Swift files)
  - No code changes made — session interrupted during planning phase
- **Status**: Planning documented, ready for implementation

### 2026-02-17 - Light/Dark Mode + Settings Panel
- **Agent**: Claude Opus 4
- **Action**: Dynamic appearance system with Settings window, upload screen redesign
- **Files Created**: SettingsView.swift
- **Files Modified**: Theme.swift (full rewrite), StillMarkerApp.swift, UploadProcessingView.swift, FrameControlsView.swift, ResultsView.swift, FrameCardView.swift, FilmstripView.swift, FramePreviewComponents.swift, project.pbxproj
- **Details**:
  - Theme.swift: Replaced static dark-only colors with NSColor semantic system colors (labelColor, windowBackgroundColor) and NSColor(name:dynamicProvider:) for custom colors. Added surfaceHover/surfaceSubtle/borderHover/borderSubtle/overlayScrim/toastBackground/frameFill tokens.
  - AppAppearance enum: Light/Dark/System with NSApp.appearance control. Default: Light.
  - Settings window (Cmd+,): Appearance tab with segmented picker, About tab with app ethos (archival stills, speed, local processing, Chris Marker tribute).
  - Upload screen: "Show me what you saw" hero at 26pt, single instruction line, security note pushed to bottom. Removed verbose onboarding block.
  - EyeView: Appearance-aware drawing (dark strokes on light, light strokes on dark).
  - All hardcoded Color.white.opacity/Color.black.opacity replaced with Theme semantic tokens across all view files.
- **Status**: Complete - awaiting user QA

### 2026-02-17 - QA Fixes: Accessibility, Contrast, UX Polish
- **Agent**: Claude Opus 4
- **Action**: Fixed all issues from user QA testing of browse-pick-export workflow
- **Files Modified**: Theme.swift, StillMarkerApp.swift, FrameCardView.swift, ResultsView.swift, FramePreviewComponents.swift, FrameControlsView.swift, UploadProcessingView.swift
- **Details**:
  - Contrast/accessibility: Background from pure black to warm dark gray (0.10, 0.10, 0.11), raised all text opacities for WCAG AA compliance
  - Hover z-index: Moved scaleEffect/zIndex/animation to grid item Group wrapper so LazyVGrid respects z-ordering
  - Frame nudge flicker: Removed black overlay during refinement, current image persists until replacement loads
  - Gear system: Reduced from 3 gears to 2 (fine/wide), each nudge button shows keyboard shortcut inline
  - Edge magnification: Increased grid horizontal padding from 12px to 40px for edge card room
  - Upload screen: Added onboarding copy, workflow description, security reassurance ("Everything stays on your Mac")
  - Header: Back button now "< new video" with chevron, grid description bumped to 12pt, export button to 13pt
  - Text sizes increased across all views for accessibility compliance
- **Status**: Complete - awaiting user QA

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
