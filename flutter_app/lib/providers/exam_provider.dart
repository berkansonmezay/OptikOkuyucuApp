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

    // Temporary: Add mock students for testing if none exist
    for (var exam in _exams) {
      if (exam.students.isEmpty) {
        exam.students = [
          StudentResult(
            id: '1',
            studentName: 'Zeynep Kaya',
            studentNumber: '482',
            score: 425.00,
            status: 'success',
          ),
          StudentResult(
            id: '2',
            studentName: 'Ahmet Yılmaz',
            studentNumber: '483',
            score: 390.50,
            status: 'success',
            bookType: 'B',
          ),
          StudentResult(
            id: '3',
            studentName: 'Elif Çelik',
            studentNumber: '',
            score: 0.00,
            status: 'warning',
          ),
          StudentResult(
            id: '4',
            studentName: 'Burak Özkan',
            studentNumber: '490',
            score: 310.25,
            status: 'success',
            bookType: 'B',
          ),
        ];
      }
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
