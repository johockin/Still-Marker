# Still Marker - Fix Plan

## Phase 1: Critical Display Bugs
- [x] P0: Fix vertical video thumbnails stretched to 200x112 in grid - use `.aspectRatio(contentMode: .fit)` on thumbnail `Image` in `FrameCard` instead of fixed `.frame(width: 200, height: 112)`, and wrap in a fixed-size container to maintain grid alignment
- [x] P0: Verify vertical video full-resolution preview also respects aspect ratio in `FrameNavigationView` (already uses `.aspectRatio(contentMode: .fit)` - confirmed)

## Phase 2: Drop Zone Improvements
- [x] P0: Expand drop zone hit target on opening page - make the entire `UploadProcessingView` respond to drops, not just the 480x280 button area
- [x] P1: Add visual feedback when dropping video on grid view - dark scrim overlay with "Drop to load new video" text
- [x] P1: Enable video drop on frame preview mode - add `.onDrop` handler to `framePreviewView` that triggers new video processing

## Phase 3: Navigation & UX Polish
- [x] P0: Add end-of-file indicator in frame preview - forward controls dim at end, "(end)" label appears, toast notification on boundary hit
- [x] P1: Add visual indicator when at first frame (timestamp 0) - backward controls dim, toast on boundary hit
- [ ] P1: Show frame position indicator in grid view (e.g., "Frame 12 of 34" below grid or in header) - deferred, header already shows frame count

## Phase 4: Code Cleanup
- [x] P1: Remove unused `shiftOffset()` method and `currentOffset` property from `AppViewModel` in `ContentView.swift`
- [ ] P1: DotPatternView confirmed unused but kept (removing requires .xcodeproj edit, compiles harmlessly)
- [ ] P2: Clean up excessive debug print statements - deferred, diagnostic prints are intentional per project guidelines

## Phase 5: Build Verification
- [x] P0: Build verified clean - user QA confirmed all 5 GitHub issues resolved
- [x] P1: No SwiftUI type-checker issues (one type-checker crash fixed by extracting dropOverlay)

## Notes
- All 5 GitHub issues (#1-#5) resolved and user-confirmed
- Phase 5 passed via user QA on 2026-02-13
