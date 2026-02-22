import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/exam.dart';

class ExamProvider with ChangeNotifier {
  List<Exam> _exams = [];
  bool _isLoading = true;

  List<Exam> get exams => _exams;
  bool get isLoading => _isLoading;

  ExamProvider() {
    loadExams();
  }

  Future<void> loadExams() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final String? examsJson = prefs.getString('exams');

    if (examsJson != null) {
      final List<dynamic> decoded = jsonDecode(examsJson);
      _exams = decoded.map((item) => Exam.fromJson(item)).toList();
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addExam(Exam exam) async {
    _exams.insert(0, exam);
    await _saveToPrefs();
    notifyListeners();
  }

  Future<void> updateExam(String id, Exam updatedExam) async {
    final index = _exams.indexWhere((e) => e.id == id);
    if (index != -1) {
      _exams[index] = updatedExam;
      await _saveToPrefs();
      notifyListeners();
    }
  }

  Future<void> deleteExam(String id) async {
    _exams.removeWhere((e) => e.id == id);
    await _saveToPrefs();
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_exams.map((e) => e.toJson()).toList());
    await prefs.setString('exams', encoded);
  }
}
