# TROUBLESHOOTING.md - Problem -> Solution Pairs

> Specific issues encountered and their solutions. For general guidance, see [CLAUDE.md](./CLAUDE.md).

---

## SwiftUI Crashes

### View Construction Crash (No Logs, Just `(lldb)`)
**Symptom**: App crashes immediately when building a view, no error logs, just debugger.

**Cause**: SwiftUI type inference system hitting complexity limits with deeply nested view hierarchies.

**Solutions**:
1. **Extract components** - Break 200+ line view functions into smaller components
2. **Remove string interpolation from closures** - Never use `\(variable)` in closures during view construction
3. **Simplify gradients** - Keep under ~40 gradient stops total across nested views
4. **Extract @State to locals** - Before view construction, extract all @State values to local constants

**Example Fix**:
```swift
// BEFORE (crashes)
Button(action: { print("\(isRefining)"); doThing() }) { ... }

// AFTER (works)
Button(action: doThing) { ... }
```

**Code Locations**: See M5.7 in PROJECT_SPEC.md for full component extraction pattern.

---

### FrameCard Init Crash with Many Frames
**Symptom**: App crashes when loading 40+ frames, crash at FrameCard.init().

**Cause**: SwiftUI attempting to initialize all views simultaneously, memory pressure.

**Solution**:
1. Implement progressive loading (8 frames at 0.1s intervals)
2. Use stateless FrameCard architecture (no @State variables)
3. Use LazyVGrid for batch rendering
4. Store full images to disk, keep only thumbnails in memory

**Result**: Handles 40+ frames, 59MB memory usage (down from 330MB).

---

## FFmpeg Issues

### Frame Refinement Hangs Indefinitely
**Symptom**: App hangs when pressing refinement buttons (< > << >>).

**Causes**:
1. Process.terminationHandler set AFTER process.run() (race condition)
2. Main thread blocking in button callback
3. No timeout protection

**Solutions**:
1. Move terminationHandler setup BEFORE process.run()
2. Add 10-second timeout with hasResumed flag
3. Wrap refineToTimestamp in `Task { @MainActor }`
4. Add concurrent request guard

**Code Location**: `FFmpegProcessor.swift`

---

### Spurious Escape Key Interrupting Refinement
**Symptom**: Refinement appears to hang, but actually Escape key fires during operation.

**Cause**: System-generated synthetic keyboard events during view updates.

**Solution**: Add guard to Escape handler:
```swift
guard !isRefining else {
    print("Escape blocked - refinement in progress")
    return
}
```

**Extended Fix**: All keyboard handlers (Escape, Left, Right) must check `isRefining` before calling `resetRefinement()`.

---

## Export Issues

### Export Overwrites Same File
**Symptom**: Multiple exports save to same filename, overwriting previous exports.

**Cause**: Save panel initialized without file extension, macOS reuses base path.

**Solution**:
```swift
// BEFORE (broken)
savePanel.nameFieldStringValue = generateFilename(for: frame)

// AFTER (fixed)
savePanel.nameFieldStringValue = "\(generateFilename(for: frame)).\(selectedExportFormat.fileExtension)"
```

---

### Export All "Show Options" Hidden
**Symptom**: Format selection not visible in Export All dialog.

**Solution**: Set `isAccessoryViewDisclosed = true` on NSSavePanel.

---

## App Icons

### Icons Not Appearing After Generation
**Symptom**: New icons don't show in built app.

**Causes**:
1. Missing 1024x1024 entry in Contents.json
2. Icon files have incorrect dimensions (2x their expected size)

**Solutions**:
1. Update Contents.json to include 1024x1024 entry
2. Resize all icons to correct dimensions using `sips`:
   ```bash
   sips -z 128 128 icon_128x128.png
   ```
3. Clear caches:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/Still_Marker-*
   rm -rf ~/Library/Caches/com.apple.iconservices
   killall Dock && killall Finder
   ```

---

## Performance

### Slow App Launch (8+ seconds)
**Symptom**: App takes 8.6 seconds to become responsive.

**Cause**: FFmpeg-based video duration analysis.

**Solution**: Replace with AVFoundation metadata reading (~10ms).

---

### Memory Pressure with Full Resolution Images
**Symptom**: Grid view crashes or becomes unresponsive with many frames.

**Cause**: Loading 40 full-resolution frames (1920x1080) = ~330MB memory.

**Solution**: Dual-resolution frame system:
- Thumbnails (200x112) for grid display (~3.6MB total)
- Full resolution loaded only for preview/export

**Result**: 98% memory reduction.

---

## Toast Notifications

### Toast Covering UI Elements
**Symptom**: Success toast covers refinement buttons during export workflow.

**Solution**: Increase bottom margin from 80px to 180px.

---

## Thread Safety

### Swift 6 Concurrency Warnings
**Symptom**: Warnings about non-Sendable types crossing actor boundaries.

**Solution**: Move shared classes to file-level scope with `@unchecked Sendable`:
```swift
final class ResumeState: @unchecked Sendable {
    // ...
}
```

---

## Keyboard Navigation

### Arrow Keys Lose Focus After Zoom Click
**Symptom**: After clicking in zoomed view, arrow keys stop working.

**Status**: Known issue, acceptable for current release.

**Workaround**: Click away from image, then use arrows.

---

*Add new problems and solutions as they're discovered.*
