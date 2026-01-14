import 'dart:convert';

/// Model representing a completed recording session.
class RecordingSession {
  final String id;
  final DateTime dateTime;
  final Duration duration;
  final String transcript;
  final String? audioPath; // Local path (native) or null (web)

  RecordingSession({
    required this.id,
    required this.dateTime,
    required this.duration,
    required this.transcript,
    this.audioPath,
  });

  /// Creates a session from a Map (for storage/serialization).
  factory RecordingSession.fromJson(Map<String, dynamic> json) {
    return RecordingSession(
      id: json['id'] as String,
      dateTime: DateTime.tryParse(json['dateTime'] as String) ?? DateTime.now(),
      duration: Duration(milliseconds: json['durationMs'] as int),
      transcript: json['transcript'] as String,
      audioPath: json['audioPath'] as String?,
    );
  }

  /// Converts session to a Map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dateTime': dateTime.toIso8601String(),
      'durationMs': duration.inMilliseconds,
      'transcript': transcript,
      'audioPath': audioPath,
    };
  }
}
