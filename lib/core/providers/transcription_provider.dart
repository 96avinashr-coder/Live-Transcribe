import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_key_service.dart';
import '../services/audio_service.dart';
import '../services/transcription_service.dart';
import '../models/recording_session.dart';
import '../services/recording_storage_service.dart';

/// State management provider for the transcription session.
class TranscriptionProvider extends ChangeNotifier {
  final ApiKeyService _apiKeyService = ApiKeyService();
  final AudioService _audioService = AudioService();
  final TranscriptionService _transcriptionService = TranscriptionService();
  final RecordingStorageService _storageService = RecordingStorageService();

  // State
  bool _isRecording = false;
  bool _isConnected = false;
  bool _isInitialized = false;
  String? _error;
  double _amplitude = 0.0;
  final List<TranscriptionResult> _transcriptions = [];
  String _partialTranscript = '';
  List<RecordingSession> _savedSessions = [];
  DateTime? _sessionStartTime;

  // Subscriptions
  StreamSubscription? _audioSubscription;
  StreamSubscription? _amplitudeSubscription;
  StreamSubscription? _transcriptionSubscription;
  StreamSubscription? _connectionSubscription;
  StreamSubscription? _errorSubscription;
  StreamSubscription? _audioErrorSubscription;

  // Getters
  bool get isRecording => _isRecording;
  bool get isConnected => _isConnected;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  double get amplitude => _amplitude;
  List<TranscriptionResult> get transcriptions =>
      List.unmodifiable(_transcriptions);
  String get partialTranscript => _partialTranscript;
  ApiKeyService get apiKeyService => _apiKeyService;
  bool get hasApiKeys => _apiKeyService.hasKeys;
  List<RecordingSession> get savedSessions => List.unmodifiable(_savedSessions);

  /// Full transcript text combining all final results.
  String get fullTranscript {
    final buffer = StringBuffer();
    for (final result in _transcriptions) {
      if (result.isFinal) {
        if (buffer.isNotEmpty) buffer.write(' ');
        buffer.write(result.text);
      }
    }
    return buffer.toString();
  }

  /// Initializes the provider and loads API keys.
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _apiKeyService.loadKeys();
    await _loadSavedSessions();

    _setupListeners();
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _loadSavedSessions() async {
    _savedSessions = await _storageService.getSessions();
    notifyListeners();
  }

  /// Sets up stream listeners.
  void _setupListeners() {
    _amplitudeSubscription = _audioService.amplitudeStream.listen((amp) {
      _amplitude = amp;
      notifyListeners();
    });

    _audioErrorSubscription = _audioService.errorStream.listen((error) {
      _error = error;
      notifyListeners();
    });

    _transcriptionSubscription = _transcriptionService.transcriptionStream
        .listen((result) {
          if (result.isFinal) {
            _transcriptions.add(result);
            _partialTranscript = '';
          } else {
            _partialTranscript = result.text;
          }
          notifyListeners();
        });

    _connectionSubscription = _transcriptionService.connectionStream.listen((
      connected,
    ) {
      _isConnected = connected;
      notifyListeners();
    });

    _errorSubscription = _transcriptionService.errorStream.listen((error) {
      _error = error;
      notifyListeners();
      // Clear error after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        if (_error == error) {
          _error = null;
          notifyListeners();
        }
      });
    });
  }

  /// Starts a new transcription session.
  Future<void> startSession() async {
    if (_isRecording) return;

    _error = null;
    notifyListeners();

    // Check for API keys
    if (!_apiKeyService.hasKeys) {
      _error =
          'No API keys configured. Please add an AssemblyAI API key in settings.';
      notifyListeners();
      return;
    }

    // Get next API key (rotation)
    final apiKey = _apiKeyService.getNextKey();
    if (apiKey == null) {
      _error = 'Failed to get API key';
      notifyListeners();
      return;
    }

    // Check audio permission
    final hasPermission = await _audioService.hasPermission();
    if (!hasPermission) {
      _error = 'Microphone permission denied';
      notifyListeners();
      return;
    }

    // Connect to transcription service
    final connected = await _transcriptionService.connect(apiKey);
    if (!connected) {
      _error = 'Failed to connect to transcription service';
      notifyListeners();
      return;
    }

    // Start recording
    final started = await _audioService.startRecording();
    if (!started) {
      await _transcriptionService.disconnect();
      _error = 'Failed to start recording';
      notifyListeners();
      return;
    }

    // Forward audio to transcription service
    _audioSubscription = _audioService.audioStream.listen((data) {
      _transcriptionService.sendAudioChunk(data);
    });

    _isRecording = true;
    _sessionStartTime = DateTime.now();
    _transcriptions.clear(); // Clear previous session transcript
    _partialTranscript = '';
    notifyListeners();
  }

  /// Stops the current transcription session.
  Future<void> stopSession() async {
    if (!_isRecording) return;

    await _audioSubscription?.cancel();
    _audioSubscription = null;

    final audioPath = await _audioService.stopRecording();
    await _transcriptionService.disconnect();

    // Create and save session
    if (_sessionStartTime != null) {
      final endTime = DateTime.now();
      final duration = endTime.difference(_sessionStartTime!);
      final fullText = fullTranscript;

      if (fullText.isNotEmpty || audioPath != null) {
        final session = RecordingSession(
          id: endTime.millisecondsSinceEpoch.toString(),
          dateTime: _sessionStartTime!,
          duration: duration,
          transcript: fullText.isNotEmpty ? fullText : '(No transcript)',
          audioPath: audioPath,
        );

        await _storageService.saveSession(session);
        await _loadSavedSessions();
      }
    }

    _isRecording = false;
    _sessionStartTime = null;
    _amplitude = 0.0;
    notifyListeners();
  }

  /// Deletes a saved session.
  Future<void> deleteSession(String id) async {
    await _storageService.deleteSession(id);
    await _loadSavedSessions();
  }

  /// Clears the transcript history.
  void clearTranscript() {
    _transcriptions.clear();
    _partialTranscript = '';
    notifyListeners();
  }

  /// Adds a new API key.
  Future<void> addApiKey(String key) async {
    await _apiKeyService.addKey(key);
    notifyListeners();
  }

  /// Removes an API key.
  Future<void> removeApiKey(int index) async {
    await _apiKeyService.removeKey(index);
    notifyListeners();
  }

  @override
  void dispose() {
    _audioSubscription?.cancel();
    _amplitudeSubscription?.cancel();
    _audioErrorSubscription?.cancel();
    _transcriptionSubscription?.cancel();
    _connectionSubscription?.cancel();
    _errorSubscription?.cancel();
    _audioService.dispose();
    _transcriptionService.dispose();
    super.dispose();
  }
}
