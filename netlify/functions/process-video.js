// FRAMESHIFT - Netlify Function for Video Processing

const multiparty = require('multiparty');
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

exports.handler = async (event, context) => {
    console.log('Function triggered!', new Date().toISOString());
    console.log('Event method:', event.httpMethod);
    console.log('Event body exists:', !!event.body);
    console.log('Event body length:', event.body ? event.body.length : 0);
    console.log('Content-Type:', event.headers['content-type']);
    
    // For now, just return success to test the connection
    return {
        statusCode: 200,
        headers: { 
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        body: JSON.stringify({ 
            message: 'Function reached!', 
            timestamp: new Date().toISOString(),
            test: true,
            bodyLength: event.body ? event.body.length : 0,
            method: event.httpMethod
        })
    };
};

function parseMultipartData(event) {
    return new Promise((resolve, reject) => {
        const form = new multiparty.Form();
        
        // Convert Netlify event to a format multiparty can handle
        const req = {
            method: event.httpMethod,
            headers: event.headers,
            body: event.body,
            isBase64Encoded: event.isBase64Encoded
        };
        
        // Create a temporary file for the request body
        const tempFile = path.join('/tmp', `request-${Date.now()}.tmp`);
        
        try {
            // Write the request body to a temporary file
            const bodyBuffer = event.isBase64Encoded 
                ? Buffer.from(event.body, 'base64')
                : Buffer.from(event.body);
            
            fs.writeFileSync(tempFile, bodyBuffer);
            
            // Create a readable stream from the temp file
            const stream = fs.createReadStream(tempFile);
            stream.headers = event.headers;
            
            form.parse(stream, (err, fields, files) => {
                // Clean up temp file
                if (fs.existsSync(tempFile)) {
                    fs.unlinkSync(tempFile);
                }
                
                if (err) {
                    reject(err);
                } else {
                    // Convert arrays to single values for easier access
                    const processedFields = {};
                    for (const [key, value] of Object.entries(fields)) {
                        processedFields[key] = Array.isArray(value) ? value[0] : value;
                    }
                    
                    const processedFiles = {};
                    for (const [key, value] of Object.entries(files)) {
                        processedFiles[key] = Array.isArray(value) ? value[0] : value;
                    }
                    
                    resolve({ fields: processedFields, files: processedFiles });
                }
            });
            
        } catch (error) {
            reject(error);
        }
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