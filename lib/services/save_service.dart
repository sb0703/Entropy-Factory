import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../game/game_state.dart';

class SaveService {
  static const _stateKey = 'game_state';
  static const _lastSeenKey = 'game_last_seen';

  String exportState(GameState state) {
    // 将状态序列化为 JSON，供导出与持久化使用。
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
    // 同步保存游戏状态与最后活跃时间戳。
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonText = exportState(state);
      await prefs.setString(_stateKey, jsonText);
      await prefs.setInt(
        _lastSeenKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    } on PlatformException {
      return;
    }
  }

  Future<GameState?> loadState() async {
    // 读取并反序列化存档。
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonText = prefs.getString(_stateKey);
      if (jsonText == null || jsonText.isEmpty) {
        return null;
      }
      return importState(jsonText);
    } on PlatformException {
      return null;
    }
  }

  Future<int?> loadLastSeenMs() async {
    // 用于离线收益补算的时间戳。
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_lastSeenKey);
    } on PlatformException {
      return null;
    }
  }
}
