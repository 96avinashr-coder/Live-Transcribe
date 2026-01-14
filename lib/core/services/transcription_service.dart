import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

/// Model for transcription results from AssemblyAI.
class TranscriptionResult {
  final String text;
  final bool isFinal;
  final DateTime timestamp;

  TranscriptionResult({
    required this.text,
    required this.isFinal,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() => 'TranscriptionResult(text: $text, isFinal: $isFinal)';
}

/// Service for real-time transcription using AssemblyAI Universal Streaming API.
class TranscriptionService {
  // Use local proxy server to bypass CORS restrictions
  // Run the proxy_server.js with: node proxy_server.js
  static const String _tokenUrl = 'http://localhost:3001/token';
  // Universal Streaming v3 endpoint
  static const String _websocketUrl = 'wss://streaming.assemblyai.com/v3/ws';

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  final StreamController<TranscriptionResult> _transcriptionController =
      StreamController<TranscriptionResult>.broadcast();
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  bool _isConnected = false;
  bool _sessionReady =
      false; // True once we receive "Begin" message from server

  /// Stream of transcription results.
  Stream<TranscriptionResult> get transcriptionStream =>
      _transcriptionController.stream;

  /// Stream of error messages.
  Stream<String> get errorStream => _errorController.stream;

  /// Stream of connection state changes.
  Stream<bool> get connectionStream => _connectionController.stream;

  /// Whether currently connected to AssemblyAI.
  bool get isConnected => _isConnected;

  void _log(String message) {
    developer.log('[TranscriptionService] $message');
    // Also print to console for browser debugging
    print('[TranscriptionService] $message');
  }

  /// Gets a temporary authentication token from AssemblyAI via local proxy.
  Future<String?> _getTemporaryToken(String apiKey) async {
    _log('Getting temporary token from proxy...');
    try {
      final response = await http.post(
        Uri.parse(_tokenUrl),
        headers: {'Authorization': apiKey, 'Content-Type': 'application/json'},
      );

      _log('Token response status: ${response.statusCode}');
      _log(
        'Token response body: ${response.body.substring(0, response.body.length.clamp(0, 100))}...',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final token = data['token'] as String?;
        if (token != null) {
          _log('Token obtained successfully (length: ${token.length})');
        }
        return token;
      } else {
        _errorController.add(
          'Failed to get auth token: ${response.statusCode} - ${response.body}',
        );
        _log('Token request failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      _errorController.add('Token request failed: $e');
      _log('Token request exception: $e');
      return null;
    }
  }

  /// Connects to AssemblyAI Universal Streaming API with the provided API key.
  Future<bool> connect(String apiKey) async {
    _log('Connecting with API key: ${apiKey.substring(0, 8)}...');

    if (_isConnected) {
      _log('Already connected, disconnecting first...');
      await disconnect();
    }

    if (apiKey.isEmpty) {
      _errorController.add('No API key provided');
      return false;
    }

    try {
      // First, get a temporary authentication token
      final tempToken = await _getTemporaryToken(apiKey);
      if (tempToken == null) {
        _errorController.add('Failed to obtain authentication token');
        return false;
      }

      // Build WebSocket URL for Universal Streaming v3
      final wsUrl = '$_websocketUrl?sample_rate=16000&token=$tempToken';
      _log(
        'Connecting to WebSocket: ${_websocketUrl}?sample_rate=16000&token=[TOKEN]',
      );

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      // Wait for connection to be ready
      _log('Waiting for WebSocket ready...');
      await _channel!.ready;
      _log('WebSocket connection ready!');

      _isConnected = true;
      _connectionController.add(true);

      // Listen for messages
      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDone,
      );

      _log('Connected successfully, listening for messages');
      return true;
    } catch (e) {
      _errorController.add('Connection failed: $e');
      _log('Connection failed with exception: $e');
      _isConnected = false;
      _connectionController.add(false);
      return false;
    }
  }

  /// Sends audio data to the transcription service.
  void sendAudioChunk(Uint8List data) {
    if (!_isConnected || !_sessionReady || _channel == null) {
      // Wait for session to be ready before sending audio
      return;
    }

    try {
      // Universal Streaming v3 expects raw binary audio data (not base64 JSON)
      _channel!.sink.add(data);
    } catch (e) {
      _errorController.add('Failed to send audio: $e');
      _log('Failed to send audio chunk: $e');
    }
  }

  /// Handles incoming WebSocket messages.
  void _handleMessage(dynamic message) {
    _log(
      'Received message: ${message.toString().substring(0, message.toString().length.clamp(0, 200))}',
    );

    try {
      if (message is String) {
        final data = jsonDecode(message) as Map<String, dynamic>;

        final messageType = data['type'] as String?;
        _log('Message type: $messageType');

        // Universal Streaming v3 message types (capitalized)
        if (messageType == 'Turn') {
          // Final transcript for a complete turn
          final text = data['transcript'] as String? ?? '';
          final endOfTurn = data['end_of_turn'] as bool? ?? false;
          _log('Turn transcript: $text (end_of_turn: $endOfTurn)');
          if (text.isNotEmpty) {
            _transcriptionController.add(
              TranscriptionResult(text: text, isFinal: endOfTurn),
            );
          }
        } else if (messageType == 'Begin') {
          // Session started successfully - NOW we can send audio
          final sessionId = data['id'] as String? ?? 'unknown';
          _log('Session began! ID: $sessionId');
          _isConnected = true;
          _sessionReady = true; // Allow audio transmission
          _connectionController.add(true);
        } else if (messageType == 'Termination') {
          // Session terminated
          final audioDuration = data['audio_duration_seconds'];
          _log('Session terminated. Audio duration: $audioDuration seconds');
          _isConnected = false;
          _connectionController.add(false);
        } else if (messageType == 'error' || data['error'] != null) {
          final errorMsg =
              data['error'] as String? ??
              data['message'] as String? ??
              'Unknown error';
          _errorController.add(errorMsg);
          _log('Error message: $errorMsg');
        } else {
          _log('Unknown message type: $messageType');
        }
      }
    } catch (e) {
      _errorController.add('Failed to parse message: $e');
      _log('Failed to parse message: $e');
    }
  }

  /// Handles WebSocket errors.
  void _handleError(dynamic error) {
    _errorController.add('WebSocket error: $error');
    _log('WebSocket error: $error');
    _isConnected = false;
    _connectionController.add(false);
  }

  /// Handles WebSocket connection close.
  void _handleDone() {
    _log('WebSocket connection closed');
    _isConnected = false;
    _connectionController.add(false);
  }

  /// Disconnects from the transcription service.
  Future<void> disconnect() async {
    _log('Disconnecting...');
    try {
      // Send terminate message for Universal Streaming v3 (capitalized)
      if (_isConnected && _channel != null) {
        _channel!.sink.add(jsonEncode({'type': 'Terminate'}));
      }

      await _subscription?.cancel();
      _subscription = null;
      await _channel?.sink.close();
      _channel = null;
    } finally {
      _isConnected = false;
      _sessionReady = false; // Reset session state
      _connectionController.add(false);
    }
    _log('Disconnected');
  }

  /// Disposes of resources.
  Future<void> dispose() async {
    await disconnect();
    await _transcriptionController.close();
    await _errorController.close();
    await _connectionController.close();
  }
}
