# Still Marker - Technical Requirements

## Frame Extraction Algorithm

### Adaptive Interval Selection
```
Video Duration    | Interval  | Result
< 30 seconds      | 1.0s      | ~15-30 frames
30s - 5 minutes   | dynamic   | ~30 frames (rounded to 0.1s)
> 5 minutes        | dynamic   | ~40 frames max (rounded to 0.1s)
```

Minimum interval: 0.33s (max 3 fps). Timestamps rounded to 1 decimal place.

### FFmpeg Command Pattern
```bash
# Fast-seek extraction (10x faster than input-seek)
ffmpeg -ss <timestamp> -i "<video_path>" -vframes 1 -q:v 2 -y "<output_path>"
```

- `-ss` BEFORE `-i` enables fast seeking
- `-q:v 2` = high quality JPEG (scale 2-31, lower is better)
- 10-second timeout per frame extraction
- Continuation-based async with `ResumeState` for thread-safe resume

## Frame Model Architecture

```
Frame
├── id: UUID
├── timestamp: Double
├── _thumbnail: NSImage (200x112, always in memory)
├── _fullImageURL: URL? (temp file on disk)
├── _cachedFullImage: NSImage? (loaded on demand)
├── formattedTimestamp: String (e.g., "00:03.2")
├── thumbnail -> NSImage (getter, returns _thumbnail)
└── image -> NSImage (getter, loads from URL or returns thumbnail)
```

Memory budget:
- 40 thumbnails @ ~90KB each = ~3.6MB
- Full image loaded only during preview/export, released after

## Export Formats

| Format | Extension | Quality | Use Case |
|--------|-----------|---------|----------|
| PNG    | .png      | Lossless | Default - archival, highest quality |
| JPEG   | .jpg      | 100%    | Smaller files, web use |
| TIFF   | .tiff     | Lossless | Professional print workflows |

Filename pattern: `<video_name>_frame_<MM-SS-d>.<ext>`
Example: `interview_final_v2_frame_00-03-2.png`

## UI State Machine

```
AppState.upload ──(video selected)──> AppState.processing
AppState.processing ──(extraction done)──> AppState.results
AppState.results ──(New Video)──> AppState.upload

ViewMode.grid ──(tap frame)──> ViewMode.framePreview
ViewMode.framePreview ──(Back/ESC)──> ViewMode.grid
```

## Keyboard Shortcuts (Frame Preview Mode)

| Key | Action | Amount |
|-----|--------|--------|
| Left Arrow | Refine backward | 1 frame (~0.033s) |
| Right Arrow | Refine forward | 1 frame (~0.033s) |
| Shift+Left | Jump backward | 2 seconds |
| Shift+Right | Jump forward | 2 seconds |
| Up Arrow | Previous grid frame | N/A |
| Down Arrow | Next grid frame | N/A |
| Escape | Return to grid | N/A |

All handlers guard against `isRefining` to prevent state conflicts.

## Supported Video Formats

Allowed extensions: `mp4`, `mov`, `avi`, `mkv`, `m4v`, `wmv`, `flv`, `webm`

No file size limit (native app, local processing).

## Window Configuration

- Size: 85% of screen dimensions
- Minimum: 800x600
- Style: Hidden title bar (`.windowStyle(.hiddenTitleBar)`)
- Title bar style: Unified toolbar

## Design System

### Colors
- Background base: `rgb(0.1, 0.1, 0.11)` (lifted black)
- Warm spotlight: `rgb(0.32, 0.28, 0.24)` centered at (0.3, 0.45)
- Crimson accent: `rgb(0.8, 0.1, 0.2)` centered at (0.85, 0.85)
- Export gold: `#E6A532`
- Success green: `rgb(0.5, 0.75, 0.55)` (film emulsion)
- Error red: `rgb(0.8, 0.2, 0.25)` (cinematic crimson)

### Typography
- All text: `.system(design: .monospaced)`
- Title: size 48, `.ultraLight`, kerning 16, tracking 8
- Body: size 14-16
- Controls: size 11-12
- Opacity hierarchy: 0.9, 0.7, 0.5, 0.3

### Materials
- Primary glass: `.thinMaterial`
- Secondary glass: `.ultraThinMaterial`
- Borders: white at 0.1-0.3 opacity, 1-2px

### Animation
- Hover enter: spring (0.35s response, 0.78 damping)
- Hover exit: easeOut (0.18s)
- State transitions: easeInOut (0.3s)
- Respects `accessibilityReduceMotion`
