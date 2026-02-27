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

  Future<void> loadExams([String? userId, String? role]) async {
    _isLoading = true;
    notifyListeners();

    try {
      Query query = FirebaseFirestore.instance.collection('exams').orderBy('date', descending: true);
      
      // Role-based filtering
      if (role != 'admin' && userId != null) {
        query = query.where('creatorId', isEqualTo: userId);
      }

      final snapshot = await query.get();
      _exams = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Exam.fromJson(data);
      }).toList();

      // Fetch results for each exam
      for (var exam in _exams) {
        final resultsSnap = await FirebaseFirestore.instance.collection('exams').doc(exam.id).collection('results').get();
        exam.students = resultsSnap.docs.map((rDoc) {
          final rData = rDoc.data();
          return StudentResult(
            id: rDoc.id,
            studentName: rData['name'] ?? 'Bilinmeyen',
            studentNumber: rData['studentNo'] ?? '',
            score: (rData['score'] as num?)?.toDouble() ?? 0.0,
            status: 'success',
            bookType: rData['booklet'] ?? 'A',
            rawStats: rData,
          );
        }).toList();
        exam.studentCount = exam.students.length;
      }

    } catch (e) {
      debugPrint('Error loading exams: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addExam(Exam exam, String creatorId) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('exams').doc();
      final examData = exam.toJson();
      examData['id'] = docRef.id;
      examData['creatorId'] = creatorId;
      examData['createdAt'] = DateTime.now().toIso8601String();
      examData.remove('students'); 
      
      await docRef.set(examData);
      
      final finalExam = Exam.fromJson(examData);
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
      examData['updatedAt'] = DateTime.now().toIso8601String();
      
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
        final resultData = {
           'name': result.studentName,
           'studentNo': result.studentNumber,
           'score': result.score,
           'booklet': result.bookType,
           'createdAt': DateTime.now().toIso8601String(),
        };
        
        await resultDoc.set(resultData);
        
        // Update exam student count
        final examRef = FirebaseFirestore.instance.collection('exams').doc(examId);
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final snapshot = await transaction.get(examRef);
          if (snapshot.exists) {
            final currentCount = snapshot.data()?['studentCount'] ?? 0;
            transaction.update(examRef, {'studentCount': currentCount + 1});
          }
        });

        // Update local state
        final index = _exams.indexWhere((e) => e.id == examId);
        if (index != -1) {
           _exams[index].students.add(result);
           _exams[index].studentCount++;
           notifyListeners();
        }
     } catch (e) {
        debugPrint('Error saving student result: $e');
     }
  }
}
