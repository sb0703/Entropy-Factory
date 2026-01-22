import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../game/game_state.dart';

class SaveService {
  static const _boxName = 'save';
  static const _stateKey = 'game_state';
  static const _lastSeenKey = 'game_last_seen';
  static const _migratedKey = 'save_migrated';

  static Future<void> init() async {
    await Hive.openBox(_boxName);
    final service = SaveService();
    await service._migrateFromSharedPreferences();
  }

  Box get _box => Hive.box(_boxName);

  Future<void> _migrateFromSharedPreferences() async {
    try {
      if (_box.get(_migratedKey) == true) {
        return;
      }
      if (_box.get(_stateKey) != null) {
        await _box.put(_migratedKey, true);
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      final jsonText = prefs.getString(_stateKey);
      final lastSeen = prefs.getInt(_lastSeenKey);
      if (jsonText != null && jsonText.isNotEmpty) {
        await _box.put(_stateKey, jsonText);
      }
      if (lastSeen != null) {
        await _box.put(_lastSeenKey, lastSeen);
      }
      await _box.put(_migratedKey, true);
    } on PlatformException {
      return;
    }
  }

  String exportState(GameState state) {
    return jsonEncode(state.toJson());
  }

  GameState? importState(String jsonText) {
    try {
      final data = jsonDecode(jsonText);
      if (data is! Map<String, dynamic>) {
        return null;
      }
      return GameState.fromJson(data);
    } on FormatException {
      return null;
    }
  }

  Future<void> saveState(GameState state) async {
    try {
      final jsonText = exportState(state);
      await _box.put(_stateKey, jsonText);
      await _box.put(
        _lastSeenKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    } on PlatformException {
      return;
    }
  }

  Future<GameState?> loadState() async {
    try {
      final jsonText = _box.get(_stateKey) as String?;
      if (jsonText == null || jsonText.isEmpty) {
        return null;
      }
      return importState(jsonText);
    } on PlatformException {
      return null;
    }
  }

  Future<int?> loadLastSeenMs() async {
    try {
      final value = _box.get(_lastSeenKey);
      if (value is int) {
        return value;
      }
      return null;
    } on PlatformException {
      return null;
    }
  }
}
