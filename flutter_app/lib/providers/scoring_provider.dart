import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
    try {
      final snapshot = await FirebaseFirestore.instance.collection('scoring_configs').get();
      _configs = {};
      for (var doc in snapshot.docs) {
        _configs[doc.id] = ScoringConfig.fromJson(doc.data());
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading scoring configs: $e');
    }
  }

  Future<void> saveConfig(String examId, ScoringConfig config) async {
    _configs[examId] = config;
    try {
      await FirebaseFirestore.instance.collection('scoring_configs').doc(examId).set(config.toJson());
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving scoring config: $e');
    }
  }
}
