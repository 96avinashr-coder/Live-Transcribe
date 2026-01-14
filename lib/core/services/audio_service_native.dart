import 'dart:async';
import 'dart:typed_data';
import 'package:record/record.dart';

/// Service for handling cross-platform audio recording.
/// Streams PCM16 audio data suitable for AssemblyAI real-time transcription.
class AudioService {
  AudioRecorder? _recorder;
  StreamSubscription<Uint8List>? _streamSubscription;
  final StreamController<Uint8List> _audioController =
      StreamController<Uint8List>.broadcast();
  final StreamController<double> _amplitudeController =
      StreamController<double>.broadcast();
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();

  bool _isRecording = false;

  /// Stream of audio data chunks (PCM16 format).
  Stream<Uint8List> get audioStream => _audioController.stream;

  /// Stream of amplitude values for visualization (0.0 to 1.0).
  Stream<double> get amplitudeStream => _amplitudeController.stream;

  /// Stream of error messages.
  Stream<String> get errorStream => _errorController.stream;

  /// Whether recording is currently active.
  bool get isRecording => _isRecording;

  AudioService() {
    _recorder = AudioRecorder();
  }

  /// Checks if microphone permission is granted.
  Future<bool> hasPermission() async {
    try {
      return await _recorder?.hasPermission() ?? false;
    } catch (e) {
      _errorController.add('Permission check failed: $e');
      return false;
    }
  }

  /// Starts recording audio and streaming PCM16 data.
  /// Returns true if recording started successfully.
  Future<bool> startRecording() async {
    if (_isRecording) return true;
    if (_recorder == null) {
      _errorController.add('Recorder not initialized');
      return false;
    }

    try {
      // Check permission first
      final hasPermission = await _recorder!.hasPermission();
      if (!hasPermission) {
        _errorController.add(
          'Microphone permission denied. Please allow microphone access.',
        );
        return false;
      }

      // Configure for AssemblyAI: PCM16, 16kHz, mono
      const config = RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
        autoGain: true,
        echoCancel: true,
        noiseSuppress: true,
      );

      // Start streaming
      final stream = await _recorder!.startStream(config);

      _isRecording = true;

      // Forward audio data to our controller
      _streamSubscription = stream.listen(
        (data) {
          _audioController.add(data);
          // Calculate amplitude from PCM16 data for visualization
          _calculateAmplitude(data);
        },
        onError: (error) {
          _errorController.add('Audio stream error: $error');
          _audioController.addError(error);
        },
        onDone: () {
          _isRecording = false;
        },
      );

      return true;
    } catch (e) {
      _isRecording = false;
      _errorController.add('Failed to start recording: $e');
      return false;
    }
  }

  /// Stops the current recording session.
  Future<String?> stopRecording() async {
    if (!_isRecording) return null;

    try {
      await _streamSubscription?.cancel();
      _streamSubscription = null;
      // In a real native implementation with file saving, we would get the path here.
      // Since we are streaming, we might not have a saved file unless we configured Record to save to file too.
      // For now, let's assume valid file path if we were recording to file.
      // To support file saving on native, we'd need to change startRecording config or
      // verify if `record` package supports simultaneous streaming and file writing.
      // Current `record` package (v5) supports `start(path: ...)` OR `startStream`.
      // It does NOT support both simultaneously easily without custom implementation.

      // Strategy: Since we are focused on web fix right now,
      // let's just make the signature compatible.
      // If native file saving is needed, we would need to accumulate bytes too
      // or use a separate isolate to write to file.

      await _recorder?.stop();
      return null; // TODO: Implement native file saving if needed
    } finally {
      _isRecording = false;
      _amplitudeController.add(0.0);
    }
  }

  /// Calculates amplitude from PCM16 audio data for visualization.
  void _calculateAmplitude(Uint8List data) {
    if (data.isEmpty) {
      _amplitudeController.add(0.0);
      return;
    }

    // PCM16 data: 2 bytes per sample, little-endian
    int maxAmplitude = 0;
    for (int i = 0; i < data.length - 1; i += 2) {
      // Combine two bytes into a 16-bit signed value
      int sample = data[i] | (data[i + 1] << 8);
      // Convert to signed
      if (sample > 32767) sample -= 65536;
      // Get absolute value
      final abs = sample.abs();
      if (abs > maxAmplitude) maxAmplitude = abs;
    }

    // Normalize to 0.0 - 1.0 range
    final normalized = maxAmplitude / 32768.0;
    _amplitudeController.add(normalized.clamp(0.0, 1.0));
  }

  /// Disposes of resources.
  Future<void> dispose() async {
    await stopRecording();
    await _audioController.close();
    await _amplitudeController.close();
    await _errorController.close();
    _recorder?.dispose();
    _recorder = null;
  }
}
