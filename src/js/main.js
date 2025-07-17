// FRAMESHIFT - Main Application Logic

class FrameShift {
    constructor() {
        this.currentOffset = 0;
        this.currentVideoFile = null;
        this.extractedFrames = [];
        
        this.initializeElements();
        this.bindEvents();
    }

    initializeElements() {
        this.uploadArea = document.getElementById('uploadArea');
        this.fileInput = document.getElementById('fileInput');
        this.processingSection = document.getElementById('processingSection');
        this.resultsSection = document.getElementById('resultsSection');
        this.progressFill = document.getElementById('progressFill');
        this.progressText = document.getElementById('progressText');
        this.offsetBtn = document.getElementById('offsetBtn');
        this.downloadBtn = document.getElementById('downloadBtn');
        this.framesGrid = document.getElementById('framesGrid');
    }

    bindEvents() {
        // File upload events
        this.uploadArea.addEventListener('click', () => this.fileInput.click());
        this.fileInput.addEventListener('change', (e) => this.handleFileSelect(e));
        
        // Drag and drop events
        this.uploadArea.addEventListener('dragover', (e) => this.handleDragOver(e));
        this.uploadArea.addEventListener('dragleave', (e) => this.handleDragLeave(e));
        this.uploadArea.addEventListener('drop', (e) => this.handleFileDrop(e));
        
        // Control buttons
        this.offsetBtn.addEventListener('click', () => this.handleOffsetShift());
        this.downloadBtn.addEventListener('click', () => this.handleDownloadAll());
    }

    handleFileSelect(event) {
        const file = event.target.files[0];
        if (file) {
            this.processVideoFile(file);
        }
    }

    handleDragOver(event) {
        event.preventDefault();
        this.uploadArea.classList.add('drag-over');
    }

    handleDragLeave(event) {
        event.preventDefault();
        this.uploadArea.classList.remove('drag-over');
    }

    handleFileDrop(event) {
        event.preventDefault();
        this.uploadArea.classList.remove('drag-over');
        
        const files = event.dataTransfer.files;
        if (files.length > 0) {
            this.processVideoFile(files[0]);
        }
    }

    async processVideoFile(file) {
        // Validate file
        if (!this.validateFile(file)) {
            return;
        }

        console.log('Starting upload:', file.name, (file.size / 1024 / 1024).toFixed(2) + 'MB');
        console.log('Upload URL:', '/.netlify/functions/process-video');

        this.currentVideoFile = file;
        this.showProcessingSection();
        
        try {
            this.updateProgress(10, 'Preparing video for upload...');
            
            // Create FormData for upload
            const formData = new FormData();
            formData.append('video', file);
            formData.append('offset', this.currentOffset);

            console.log('FormData created, starting upload...');
            this.updateProgress(20, 'Uploading video...');

            // Call Netlify Function
            const response = await fetch('/.netlify/functions/process-video', {
                method: 'POST',
                body: formData
            });

            console.log('Response received:', response.status, response.statusText);
            this.updateProgress(40, 'Processing video...');

            if (!response.ok) {
                console.error('Response not ok:', response.status, response.statusText);
                const errorData = await response.json().catch(() => ({}));
                throw new Error(errorData.error || `Processing failed: ${response.statusText}`);
            }

            const result = await response.json();
            console.log('Response data:', result);
            
            // For debugging - check if we got the test response
            if (result.test) {
                console.log('Test response received:', result.message);
                this.updateProgress(100, 'Debug: Function connection successful!');
                this.showError(`Debug Success: ${result.message} at ${result.timestamp}`);
                return;
            }
            
            if (!result.frames || result.frames.length === 0) {
                throw new Error('No frames were extracted from the video');
            }

            this.updateProgress(90, 'Finalizing...');
            this.extractedFrames = result.frames;
            
            this.updateProgress(100, 'Complete!');
            setTimeout(() => this.displayResults(), 500);
            
        } catch (error) {
            console.error('Upload error:', error);
            this.updateProgress(0, 'Upload failed: ' + error.message);
            this.showError(`Failed to process video: ${error.message}`);
        }
    }

    validateFile(file) {
        // Check file type
        if (!file.type.startsWith('video/')) {
            this.showError('Please select a valid video file.');
            return false;
        }

        // Check file size (2GB limit)
        const maxSize = 2 * 1024 * 1024 * 1024; // 2GB in bytes
        if (file.size > maxSize) {
            this.showError('File size must be under 2GB. Please trim your video and try again.');
            return false;
        }

        return true;
    }

    showProcessingSection() {
        this.processingSection.style.display = 'block';
        this.resultsSection.style.display = 'none';
        this.updateProgress(0, 'Uploading video...');
    }

    updateProgress(percentage, message) {
        this.progressFill.style.width = `${percentage}%`;
        this.progressText.textContent = message;
    }

    displayResults() {
        this.processingSection.style.display = 'none';
        this.resultsSection.style.display = 'block';
        this.renderFramesGrid();
    }

    renderFramesGrid() {
        this.framesGrid.innerHTML = '';
        
        this.extractedFrames.forEach((frame, index) => {
            const frameElement = this.createFrameElement(frame, index);
            this.framesGrid.appendChild(frameElement);
        });
    }

    createFrameElement(frame, index) {
        const frameItem = document.createElement('div');
        frameItem.className = 'frame-item';
        
        frameItem.innerHTML = `
            <img src="${frame.dataUrl}" alt="Frame at ${frame.timestamp}s" loading="lazy">
            <div class="frame-info">
                <div class="frame-timestamp">${frame.timestamp}s</div>
                <a href="${frame.dataUrl}" download="frame-${frame.timestamp}s.jpg" class="frame-download">
                    Download
                </a>
            </div>
        `;
        
        // Add click to view larger functionality
        frameItem.addEventListener('click', () => this.showFrameModal(frame));
        
        return frameItem;
    }

    showFrameModal(frame) {
        // Simple modal implementation for viewing larger image
        const modal = document.createElement('div');
        modal.style.cssText = `
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0,0,0,0.8);
            display: flex;
            justify-content: center;
            align-items: center;
            z-index: 1000;
            cursor: pointer;
        `;
        
        const img = document.createElement('img');
        img.src = frame.dataUrl;
        img.style.cssText = `
            max-width: 90%;
            max-height: 90%;
            object-fit: contain;
        `;
        
        modal.appendChild(img);
        document.body.appendChild(modal);
        
        // Close on click
        modal.addEventListener('click', () => {
            document.body.removeChild(modal);
        });
    }

    async handleOffsetShift() {
        if (!this.currentVideoFile) return;
        
        this.currentOffset += 1;
        this.offsetBtn.textContent = `Shift +${this.currentOffset + 1}s`;
        
        // Re-process with new offset
        await this.processVideoFile(this.currentVideoFile);
    }

    handleDownloadAll() {
        // Create ZIP file with all frames
        this.extractedFrames.forEach((frame, index) => {
            const link = document.createElement('a');
            link.href = frame.dataUrl;
            link.download = `frameshift-${frame.timestamp}s.jpg`;
            link.click();
        });
    }

    showError(message) {
        this.processingSection.style.display = 'none';
        this.resultsSection.style.display = 'none';
        
        // Show error message
        const errorDiv = document.createElement('div');
        errorDiv.style.cssText = `
            background-color: #fee;
            color: #c33;
            padding: 1rem;
            border-radius: 4px;
            margin: 1rem 0;
            text-align: center;
        `;
        errorDiv.textContent = message;
        
        this.uploadArea.parentNode.insertBefore(errorDiv, this.uploadArea);
        
        // Remove error after 5 seconds
        setTimeout(() => {
            if (errorDiv.parentNode) {
                errorDiv.parentNode.removeChild(errorDiv);
            }
        }, 5000);
    }
}

// Initialize the application
document.addEventListener('DOMContentLoaded', () => {
    new FrameShift();
});