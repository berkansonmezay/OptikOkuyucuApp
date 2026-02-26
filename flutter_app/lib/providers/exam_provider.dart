import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

    try {
      final snapshot = await FirebaseFirestore.instance.collection('exams').orderBy('date', descending: true).get();
      _exams = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Override ID with doc ID if missing
        return Exam.fromJson(data);
      }).toList();

      // For cross-platform compatibility, fetch results subcollection
      for (var exam in _exams) {
        final resultsSnap = await FirebaseFirestore.instance.collection('exams').doc(exam.id).collection('results').get();
        if (resultsSnap.docs.isNotEmpty) {
           exam.students = resultsSnap.docs.map((rDoc) {
             final rData = rDoc.data();
             rData['id'] = rDoc.id;
             // mapping web fields to flutter fields
             return StudentResult(
               id: rDoc.id,
               studentName: rData['name'] ?? rData['studentName'] ?? 'Bilinmeyen',
               studentNumber: rData['studentNo'] ?? rData['studentNumber'] ?? '',
               score: double.tryParse(rData['score'].toString()) ?? 0.0,
               status: 'success',
               bookType: rData['booklet'] ?? rData['bookType'] ?? 'A',
             );
           }).toList();
        }
      }

    } catch (e) {
      debugPrint('Error loading exams: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addExam(Exam exam) async {
    try {
      // Create a doc reference first to get an ID if it's new
      final docRef = FirebaseFirestore.instance.collection('exams').doc();
      final finalExam = Exam(
         id: docRef.id,
         name: exam.name,
         type: exam.type,
         date: exam.date,
         studentCount: exam.studentCount,
         status: exam.status,
         subjects: exam.subjects,
         students: exam.students,
      );
      
      final examData = finalExam.toJson();
      // Remove students from exam doc if we want to store them in subcollection, but keeping it simple for now
      examData.remove('students'); 
      await docRef.set(examData);

      _exams.insert(0, finalExam);
      notifyListeners();
    } catch (e) {
       debugPrint('Error adding exam: $e');
    }
  }

  Future<void> updateExam(String id, Exam updatedExam) async {
    try {
      final examData = updatedExam.toJson();
      examData.remove('students');
      await FirebaseFirestore.instance.collection('exams').doc(id).set(examData, SetOptions(merge: true));
      
      final index = _exams.indexWhere((e) => e.id == id);
      if (index != -1) {
        _exams[index] = updatedExam;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating exam: $e');
    }
  }

  Future<void> deleteExam(String id) async {
    try {
      await FirebaseFirestore.instance.collection('exams').doc(id).delete();
      _exams.removeWhere((e) => e.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting exam: $e');
    }
  }

  Future<void> saveStudentResult(String examId, StudentResult result) async {
     try {
        final resultDoc = FirebaseFirestore.instance.collection('exams').doc(examId).collection('results').doc();
        await resultDoc.set({
           'name': result.studentName,
           'studentNo': result.studentNumber,
           'score': result.score,
           'booklet': result.bookType,
           'tcNo': '', // default
           'rawAnswers': '', // default
        });
        
        // Find exam and update state
        final index = _exams.indexWhere((e) => e.id == examId);
        if (index != -1) {
           _exams[index].students.add(result);
           _exams[index].studentCount = _exams[index].students.length;
           await updateExam(examId, _exams[index]); // This updates studentCount in DB
        }
     } catch (e) {
        debugPrint('Error saving student result: $e');
     }
  }
}
