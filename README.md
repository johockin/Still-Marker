# FRAMESHIFT

A lightweight web tool for filmmakers to extract high-quality still images from video files.

## Quick Start

1. **Local Development:**
   ```bash
   # Simply open index.html in your browser
   open index.html
   ```

2. **For Netlify Functions (deployment only):**
   ```bash
   # Netlify handles dependencies automatically
   netlify dev  # if you have Netlify CLI installed
   ```

3. **Usage:**
   - Upload a video file (up to 2GB)
   - Extract frames at 3-second intervals
   - Download individual frames or use offset feature

## Features

- **High-quality extraction**: JPEG at 95% quality
- **Privacy-first**: Files processed and immediately deleted
- **Simple interface**: Drag & drop or click to upload
- **Offset feature**: Shift extraction timestamps by 1-second increments
- **Fast processing**: Server-side FFmpeg for reliability

## Tech Stack

- **Frontend**: Pure vanilla JavaScript, HTML5, CSS3 (no build process)
- **Backend**: Netlify Functions with FFmpeg
- **Deployment**: Netlify
- **Dependencies**: Zero for frontend, Netlify handles function dependencies

## Project Structure

```
/
├── index.html              # Main application
├── src/
│   ├── js/main.js         # Application logic
│   ├── css/styles.css     # Cinematic minimal styles
│   └── assets/            # Static assets
├── netlify/
│   └── functions/
│       └── process-video.js # Video processing function
├── netlify.toml             # Deployment config only
└── PROJECT_SPEC.md        # Complete project documentation
```

## Development

For complete project context, architecture decisions, and development workflow, see [PROJECT_SPEC.md](./PROJECT_SPEC.md).

## Privacy

Your footage is processed server-side and immediately deleted. No data is stored or tracked.