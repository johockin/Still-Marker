// FRAMESHIFT - Netlify Function for Video Processing

// Dependencies managed by Netlify's build process
const multiparty = require('multiparty');
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

exports.handler = async (event, context) => {
    // Only allow POST requests
    if (event.httpMethod !== 'POST') {
        return {
            statusCode: 405,
            body: JSON.stringify({ error: 'Method not allowed' })
        };
    }

    try {
        // Parse multipart form data
        const form = new multiparty.Form();
        const { fields, files } = await parseForm(form, event);
        
        const videoFile = files.video[0];
        const offset = parseInt(fields.offset?.[0] || '0', 10);
        
        // Validate video file
        if (!videoFile || !videoFile.path) {
            return {
                statusCode: 400,
                body: JSON.stringify({ error: 'No video file provided' })
            };
        }

        // Process video with FFmpeg
        const frames = await extractFrames(videoFile.path, offset);
        
        // Clean up temporary files
        cleanupTempFiles(videoFile.path);
        
        return {
            statusCode: 200,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            body: JSON.stringify({ frames })
        };
        
    } catch (error) {
        console.error('Error processing video:', error);
        return {
            statusCode: 500,
            body: JSON.stringify({ error: 'Internal server error' })
        };
    }
};

function parseForm(form, event) {
    return new Promise((resolve, reject) => {
        form.parse(event, (err, fields, files) => {
            if (err) reject(err);
            else resolve({ fields, files });
        });
    });
}

async function extractFrames(videoPath, offset = 0) {
    const frames = [];
    const tempDir = '/tmp/frameshift';
    
    // Create temporary directory
    if (!fs.existsSync(tempDir)) {
        fs.mkdirSync(tempDir, { recursive: true });
    }
    
    try {
        // Get video duration
        const durationCmd = `ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "${videoPath}"`;
        const durationOutput = execSync(durationCmd, { encoding: 'utf8' });
        const duration = parseFloat(durationOutput.trim());
        
        // Extract frames every 3 seconds starting from offset
        const interval = 3;
        const frameCount = Math.floor((duration - offset) / interval);
        
        for (let i = 0; i < frameCount; i++) {
            const timestamp = offset + (i * interval);
            const outputPath = path.join(tempDir, `frame_${timestamp}.jpg`);
            
            // FFmpeg command to extract frame at specific timestamp
            const ffmpegCmd = `ffmpeg -i "${videoPath}" -ss ${timestamp} -vframes 1 -q:v 2 -y "${outputPath}"`;
            
            try {
                execSync(ffmpegCmd, { stdio: 'ignore' });
                
                // Read the extracted frame and convert to base64
                if (fs.existsSync(outputPath)) {
                    const imageBuffer = fs.readFileSync(outputPath);
                    const base64Image = imageBuffer.toString('base64');
                    const dataUrl = `data:image/jpeg;base64,${base64Image}`;
                    
                    frames.push({
                        timestamp: timestamp.toFixed(1),
                        dataUrl: dataUrl
                    });
                    
                    // Clean up individual frame file
                    fs.unlinkSync(outputPath);
                }
            } catch (frameError) {
                console.warn(`Failed to extract frame at ${timestamp}s:`, frameError.message);
            }
        }
        
        return frames;
        
    } catch (error) {
        console.error('Error during frame extraction:', error);
        throw error;
    } finally {
        // Clean up temp directory
        if (fs.existsSync(tempDir)) {
            fs.rmSync(tempDir, { recursive: true, force: true });
        }
    }
}

function cleanupTempFiles(filePath) {
    try {
        if (fs.existsSync(filePath)) {
            fs.unlinkSync(filePath);
        }
    } catch (error) {
        console.warn('Failed to cleanup temp file:', error.message);
    }
}