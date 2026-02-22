import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/scoring_config.dart';

class ScoringProvider with ChangeNotifier {
  Map<String, ScoringConfig> _configs = {};

  ScoringProvider() {
    loadConfigs();
  }

  ScoringConfig? getConfigForExam(String examId) {
    return _configs[examId];
  }

  Future<void> loadConfigs() async {
    final prefs = await SharedPreferences.getInstance();
    final String? configsJson = prefs.getString('scoring_configs');
    if (configsJson != null) {
      final Map<String, dynamic> decoded = jsonDecode(configsJson);
      _configs = decoded.map((key, value) => MapEntry(key, ScoringConfig.fromJson(value)));
      notifyListeners();
    }
  }

  Future<void> saveConfig(String examId, ScoringConfig config) async {
    _configs[examId] = config;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('scoring_configs', jsonEncode(_configs.map((key, value) => MapEntry(key, value.toJson()))));
    notifyListeners();
  }
}
