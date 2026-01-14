import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';
import 'package:web/web.dart' as web;
import '../utils/wav_header.dart';

@JS()
external JSPromise<JSBoolean> initWebAudio();

@JS()
external JSPromise<JSBoolean> startWebAudioRecording();

@JS()
external void stopWebAudioRecording();

@JS()
external void disposeWebAudio();

@JS()
external JSPromise<JSBoolean> hasWebAudioPermission();

@JS()
external void setWebAudioCallbacks(
  JSFunction onAudioData,
  JSFunction onAmplitude,
  JSFunction onError,
);

/// Service for handling web audio recording using Web Audio API.
/// Streams PCM16 audio data suitable for AssemblyAI real-time transcription.
class AudioService {
  final StreamController<Uint8List> _audioController =
      StreamController<Uint8List>.broadcast();
  final StreamController<double> _amplitudeController =
      StreamController<double>.broadcast();
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();

  bool _isRecording = false;
  List<Uint8List> _audioChunks = [];

  /// Stream of audio data chunks (PCM16 format).
  Stream<Uint8List> get audioStream => _audioController.stream;

  /// Stream of amplitude values for visualization (0.0 to 1.0).
  Stream<double> get amplitudeStream => _amplitudeController.stream;

  /// Stream of error messages.
  Stream<String> get errorStream => _errorController.stream;

  /// Whether recording is currently active.
  bool get isRecording => _isRecording;

  AudioService() {
    _initialize();
  }

  void _initialize() {
    final onAudioData = (JSUint8Array data) {
      final dartData = data.toDart;
      _audioController.add(dartData);
      if (_isRecording) {
        _audioChunks.add(dartData);
      }
    }.toJS;

    final onAmplitude = (JSNumber amplitude) {
      _amplitudeController.add(amplitude.toDartDouble);
    }.toJS;

    final onError = (JSString error) {
      _errorController.add(error.toDart);
    }.toJS;

    setWebAudioCallbacks(onAudioData, onAmplitude, onError);
  }

  /// Checks if microphone permission is granted.
  Future<bool> hasPermission() async {
    try {
      final result = await hasWebAudioPermission().toDart;
      return result.toDart;
    } catch (e) {
      _errorController.add('Permission check failed: $e');
      return false;
    }
  }

  /// Starts recording audio and streaming PCM16 data.
  /// Returns true if recording started successfully.
  Future<bool> startRecording() async {
    if (_isRecording) return true;

    try {
      final result = await startWebAudioRecording().toDart;
      if (result.toDart) {
        _isRecording = true;
        _audioChunks = [];
        return true;
      } else {
        _errorController.add('Failed to start web audio recording');
        return false;
      }
    } catch (e) {
      _isRecording = false;
      _errorController.add('Failed to start recording: $e');
      return false;
    }
  }

  /// Stops the current recording session and triggers file download.
  Future<String?> stopRecording() async {
    if (!_isRecording) return null;

    try {
      stopWebAudioRecording();

      // Generate WAV file and trigger download
      if (_audioChunks.isNotEmpty) {
        return _generateAndDownloadWav();
      }
      return null;
    } finally {
      _isRecording = false;
      _amplitudeController.add(0.0);
    }
  }

  String _generateAndDownloadWav() {
    // 1. Calculate total size
    int totalLength = 0;
    for (var chunk in _audioChunks) {
      totalLength += chunk.length;
    }

    // 2. Create WAV header
    final header = WavHeader.createHeader(dataLength: totalLength);

    // 3. Combine header and data
    final wavBytes = Uint8List(header.length + totalLength);
    wavBytes.setAll(0, header);

    int offset = header.length;
    for (var chunk in _audioChunks) {
      wavBytes.setAll(offset, chunk);
      offset += chunk.length;
    }

    // 4. Create Blob and trigger download
    final blob = web.Blob(
      [wavBytes.toJS].toJS,
      web.BlobPropertyBag(type: 'audio/wav'),
    );
    final url = web.URL.createObjectURL(blob);

    final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
    anchor.href = url;
    anchor.download = 'recording_${DateTime.now().millisecondsSinceEpoch}.wav';
    anchor.style.display = 'none';
    web.document.body?.append(anchor);
    anchor.click();
    anchor.remove();

    web.URL.revokeObjectURL(url);

    // Return filename for metadata storage
    return anchor.download;
  }

  /// Disposes of resources.
  Future<void> dispose() async {
    await stopRecording();
    disposeWebAudio();
    await _audioController.close();
    await _amplitudeController.close();
    await _errorController.close();
  }
}
