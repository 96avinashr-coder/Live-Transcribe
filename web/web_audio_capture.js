// Web Audio API interface for Flutter interop
// Provides raw PCM16 audio capture for AssemblyAI streaming

class WebAudioCapture {
    constructor() {
        this.audioContext = null;
        this.workletNode = null;
        this.mediaStream = null;
        this.sourceNode = null;
        this.isRecording = false;
        this.onAudioData = null;
        this.onAmplitude = null;
        this.onError = null;
    }

    async initialize() {
        try {
            // Request microphone permission
            this.mediaStream = await navigator.mediaDevices.getUserMedia({
                audio: {
                    sampleRate: 16000,
                    channelCount: 1,
                    echoCancellation: true,
                    noiseSuppression: true,
                    autoGainControl: true
                }
            });

            // Create AudioContext at 16kHz sample rate
            this.audioContext = new AudioContext({ sampleRate: 16000 });

            // Load the audio worklet processor
            await this.audioContext.audioWorklet.addModule('pcm_audio_processor.js');

            console.log('[WebAudioCapture] Initialized successfully');
            return true;
        } catch (error) {
            console.error('[WebAudioCapture] Initialization failed:', error);
            if (this.onError) this.onError(error.message);
            return false;
        }
    }

    async start() {
        if (this.isRecording) return true;
        if (!this.audioContext) {
            const initialized = await this.initialize();
            if (!initialized) return false;
        }

        try {
            // Resume AudioContext if suspended (browser autoplay policy)
            if (this.audioContext.state === 'suspended') {
                await this.audioContext.resume();
            }

            // Create source from microphone stream
            this.sourceNode = this.audioContext.createMediaStreamSource(this.mediaStream);

            // Create worklet node for PCM processing
            this.workletNode = new AudioWorkletNode(this.audioContext, 'pcm-audio-processor');

            // Handle audio data from worklet
            this.workletNode.port.onmessage = (event) => {
                if (event.data.type === 'audio') {
                    const pcm16Data = new Uint8Array(event.data.samples);

                    // Calculate amplitude for visualization
                    const int16View = new Int16Array(event.data.samples);
                    let maxAmp = 0;
                    for (let i = 0; i < int16View.length; i++) {
                        const abs = Math.abs(int16View[i]);
                        if (abs > maxAmp) maxAmp = abs;
                    }
                    const normalizedAmp = maxAmp / 32768;

                    // Send to Flutter
                    if (this.onAudioData) this.onAudioData(pcm16Data);
                    if (this.onAmplitude) this.onAmplitude(normalizedAmp);
                }
            };

            // Connect: microphone -> worklet
            this.sourceNode.connect(this.workletNode);
            // Don't connect to destination (we don't want to play the audio)

            this.isRecording = true;
            console.log('[WebAudioCapture] Recording started');
            return true;
        } catch (error) {
            console.error('[WebAudioCapture] Start failed:', error);
            if (this.onError) this.onError(error.message);
            return false;
        }
    }

    stop() {
        if (!this.isRecording) return;

        try {
            if (this.sourceNode) {
                this.sourceNode.disconnect();
                this.sourceNode = null;
            }

            if (this.workletNode) {
                this.workletNode.disconnect();
                this.workletNode = null;
            }

            this.isRecording = false;
            console.log('[WebAudioCapture] Recording stopped');
        } catch (error) {
            console.error('[WebAudioCapture] Stop failed:', error);
            if (this.onError) this.onError(error.message);
        }
    }

    dispose() {
        this.stop();

        if (this.mediaStream) {
            this.mediaStream.getTracks().forEach(track => track.stop());
            this.mediaStream = null;
        }

        if (this.audioContext) {
            this.audioContext.close();
            this.audioContext = null;
        }

        console.log('[WebAudioCapture] Disposed');
    }

    async hasPermission() {
        try {
            const result = await navigator.permissions.query({ name: 'microphone' });
            return result.state === 'granted';
        } catch {
            // Fallback: try to get stream
            try {
                const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
                stream.getTracks().forEach(track => track.stop());
                return true;
            } catch {
                return false;
            }
        }
    }
}

// Global instance for Flutter interop
window.webAudioCapture = new WebAudioCapture();

// Flutter interop functions
window.initWebAudio = async function () {
    return await window.webAudioCapture.initialize();
};

window.startWebAudioRecording = async function () {
    return await window.webAudioCapture.start();
};

window.stopWebAudioRecording = function () {
    window.webAudioCapture.stop();
};

window.disposeWebAudio = function () {
    window.webAudioCapture.dispose();
};

window.hasWebAudioPermission = async function () {
    return await window.webAudioCapture.hasPermission();
};

window.setWebAudioCallbacks = function (onAudioData, onAmplitude, onError) {
    window.webAudioCapture.onAudioData = onAudioData;
    window.webAudioCapture.onAmplitude = onAmplitude;
    window.webAudioCapture.onError = onError;
};

console.log('[WebAudioCapture] Script loaded');
