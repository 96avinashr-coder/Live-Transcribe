// Audio Worklet Processor for capturing raw PCM audio samples
// This runs in a separate audio thread for low-latency processing

class PCMAudioProcessor extends AudioWorkletProcessor {
    constructor() {
        super();
        this.bufferSize = 4096; // Samples to accumulate before sending
        this.buffer = new Float32Array(this.bufferSize);
        this.bufferIndex = 0;
    }

    process(inputs, outputs, parameters) {
        const input = inputs[0];
        if (!input || !input[0]) return true;

        const samples = input[0]; // Mono channel

        for (let i = 0; i < samples.length; i++) {
            this.buffer[this.bufferIndex++] = samples[i];

            if (this.bufferIndex >= this.bufferSize) {
                // Convert Float32 to Int16 (PCM16)
                const pcm16 = new Int16Array(this.bufferSize);
                for (let j = 0; j < this.bufferSize; j++) {
                    // Clamp to [-1, 1] and scale to 16-bit range
                    const s = Math.max(-1, Math.min(1, this.buffer[j]));
                    pcm16[j] = s < 0 ? s * 0x8000 : s * 0x7FFF;
                }

                // Send PCM16 data to main thread
                this.port.postMessage({
                    type: 'audio',
                    samples: pcm16.buffer
                }, [pcm16.buffer]);

                // Reset buffer
                this.buffer = new Float32Array(this.bufferSize);
                this.bufferIndex = 0;
            }
        }

        return true; // Keep processor alive
    }
}

registerProcessor('pcm-audio-processor', PCMAudioProcessor);
