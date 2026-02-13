# Still Marker - Build & Run Commands

## Build & Run
```bash
# Open in Xcode
open "Still Marker.xcodeproj"

# Command-line build
xcodebuild -scheme "Still Marker" -destination 'platform=macOS' build

# Clean build (if caching issues)
xcodebuild -scheme "Still Marker" -destination 'platform=macOS' clean build

# Clear derived data (nuclear option)
rm -rf ~/Library/Developer/Xcode/DerivedData/Still_Marker-*
```

## Project Type
Swift 5.9+ / SwiftUI, macOS 12+ (Monterey), Xcode 15+, zero third-party dependencies

## Testing
Manual QA only - no unit test suite. Test with:
- Short video (<30s) - should produce ~15-30 frames
- Medium video (2-5min) - should produce ~30 frames
- Long video (10min+) - should cap at 40 frames
- Vertical video (9:16) - verify aspect ratio in grid and preview
- Various formats: .mp4, .mov, .avi, .mkv

## Conventions
- Views in `Still Marker/Views/`, PascalCase + View suffix
- Models in `Still Marker/Models/`
- Single processor: `FFmpegProcessor.swift`
- App entry: `StillMarkerApp.swift`
- Router: `ContentView.swift` (contains `AppViewModel`)
- Resources: `Still Marker/Resources/ffmpeg` (bundled binary)
- No third-party deps, no package manager, no CocoaPods/SPM

## Key Build Notes
- FFmpeg binary must be in `Resources/` and included in bundle's Copy Files build phase
- App requires `com.apple.security.temporary-exception.files.absolute-path.read-write` entitlement for temp file access
- Sandbox enabled with file read-write access to user-selected files
- If SwiftUI type-checker crashes during build, look for views exceeding 100 lines - extract components
