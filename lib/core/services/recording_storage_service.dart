import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recording_session.dart';

/// Service for persisting recording session metadata.
class RecordingStorageService {
  static const String _storageKey = 'recording_sessions';

  /// Saves a new recording session to storage.
  Future<void> saveSession(RecordingSession session) async {
    final prefs = await SharedPreferences.getInstance();
    final sessions = await getSessions();
    sessions.insert(0, session); // Add to top of list

    final jsonList = sessions.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList(_storageKey, jsonList);
  }

  /// Retrieves all saved recording sessions.
  Future<List<RecordingSession>> getSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_storageKey) ?? [];

    return jsonList
        .map((jsonStr) {
          try {
            return RecordingSession.fromJson(jsonDecode(jsonStr));
          } catch (e) {
            return null;
          }
        })
        .whereType<RecordingSession>()
        .toList();
  }

  /// Deletes a session by ID.
  Future<void> deleteSession(String id) async {
    final prefs = await SharedPreferences.getInstance();
    var sessions = await getSessions();
    sessions.removeWhere((s) => s.id == id);

    final jsonList = sessions.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList(_storageKey, jsonList);
  }

  /// Clears all saved sessions.
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
