import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing multiple AssemblyAI API keys with round-robin rotation.
/// Each new transcription session uses the next key in the rotation.
class ApiKeyService {
  static const String _storageKey = 'assemblyai_api_keys';
  static const String _indexKey = 'assemblyai_key_index';

  List<String> _apiKeys = [];
  int _currentIndex = 0;

  List<String> get apiKeys => List.unmodifiable(_apiKeys);
  int get currentIndex => _currentIndex;
  int get keyCount => _apiKeys.length;
  bool get hasKeys => _apiKeys.isNotEmpty;

  /// Returns the current API key without rotating.
  String? get currentKey =>
      _apiKeys.isNotEmpty ? _apiKeys[_currentIndex] : null;

  /// Returns the next API key and rotates the index for the next session.
  String? getNextKey() {
    if (_apiKeys.isEmpty) return null;

    final key = _apiKeys[_currentIndex];
    _currentIndex = (_currentIndex + 1) % _apiKeys.length;
    _saveIndex();
    return key;
  }

  /// Adds a new API key to the rotation.
  Future<void> addKey(String key) async {
    if (key.trim().isEmpty) return;
    if (_apiKeys.contains(key.trim())) return;

    _apiKeys.add(key.trim());
    await _saveKeys();
  }

  /// Removes an API key by index.
  Future<void> removeKey(int index) async {
    if (index < 0 || index >= _apiKeys.length) return;

    _apiKeys.removeAt(index);

    // Adjust current index if necessary
    if (_currentIndex >= _apiKeys.length) {
      _currentIndex = _apiKeys.isEmpty ? 0 : _apiKeys.length - 1;
    }

    await _saveKeys();
    await _saveIndex();
  }

  /// Loads API keys from persistent storage.
  /// If no keys exist, adds the default API keys.
  Future<void> loadKeys() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getStringList(_storageKey) ?? [];
    _apiKeys = keys;
    _currentIndex = prefs.getInt(_indexKey) ?? 0;

    // If no keys exist, add the default keys
    if (_apiKeys.isEmpty) {
      await addKey('f744223b55f84995a2b9dc4341160193');
      await addKey('c76af7dda9b34a0693948e0eef35ce53');
    }

    // Ensure index is valid
    if (_currentIndex >= _apiKeys.length) {
      _currentIndex = 0;
    }
  }

  /// Persists API keys to storage.
  Future<void> _saveKeys() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, _apiKeys);
  }

  /// Persists current index to storage.
  Future<void> _saveIndex() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_indexKey, _currentIndex);
  }

  /// Masks an API key for display (shows only last 4 characters).
  static String maskKey(String key) {
    if (key.length <= 4) return '****';
    return '****${key.substring(key.length - 4)}';
  }
}
