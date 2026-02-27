import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/exam.dart';

class ExamProvider with ChangeNotifier {
  List<Exam> _exams = [];
  bool _isLoading = true;
  StreamSubscription? _examsSubscription;

  List<Exam> get exams => _exams;
  bool get isLoading => _isLoading;

  void initialize(String? userId, String? role) {
    _examsSubscription?.cancel();
    
    _isLoading = true;
    notifyListeners();

    Query query = FirebaseFirestore.instance.collection('exams');
    
    if (role != 'admin' && userId != null) {
      query = query.where('creatorId', isEqualTo: userId);
    }

    _examsSubscription = query.snapshots().listen((snapshot) {
      final unsortedExams = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Exam.fromJson(data, doc.id);
      }).toList();
      
      // Sort in memory to match web version and avoid composite index requirement
      unsortedExams.sort((a, b) {
        final dateCompare = b.date.compareTo(a.date);
        if (dateCompare != 0) return dateCompare;
        // Fallback to ID or creating time if you had one, else just return 0
        return 0;
      });
      
      _exams = unsortedExams;
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      debugPrint('Error in exams stream: $e');
      _isLoading = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _examsSubscription?.cancel();
    super.dispose();
  }

  Future<void> addExam(Exam exam, String creatorId) async {
    try {
      final examData = exam.toJson();
      examData['creatorId'] = creatorId;
      examData['createdAt'] = DateTime.now().toIso8601String();
      
      await FirebaseFirestore.instance.collection('exams').add(examData);
    } catch (e) {
       debugPrint('Error adding exam: $e');
       rethrow;
    }
  }

  Future<void> updateExam(String id, Exam updatedExam) async {
    try {
      final examData = updatedExam.toJson();
      examData['updatedAt'] = DateTime.now().toIso8601String();
      
      await FirebaseFirestore.instance.collection('exams').doc(id).update(examData);
    } catch (e) {
      debugPrint('Error updating exam: $e');
      rethrow;
    }
  }

  Future<void> deleteExam(String id) async {
    try {
      await FirebaseFirestore.instance.collection('exams').doc(id).delete();
    } catch (e) {
      debugPrint('Error deleting exam: $e');
      rethrow;
    }
  }

  Stream<List<StudentResult>> getStudentResultsStream(String examId) {
    return FirebaseFirestore.instance
        .collection('exams')
        .doc(examId)
        .collection('results')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return StudentResult.fromJson(doc.data(), doc.id);
      }).toList();
    });
  }

  Future<void> saveStudentResult(String examId, StudentResult result) async {
     try {
        final resultRef = FirebaseFirestore.instance.collection('exams').doc(examId).collection('results');
        
        // Prevent duplicate student numbers if necessary (matching web logic in addStudentResult)
        final existing = await resultRef.where('studentNo', isEqualTo: result.studentNo).limit(1).get();
        
        final resultData = result.toJson();
        
        if (existing.docs.isNotEmpty) {
          resultData['updatedAt'] = DateTime.now().toIso8601String();
          await existing.docs.first.reference.update(resultData);
        } else {
          resultData['createdAt'] = DateTime.now().toIso8601String();
          await resultRef.add(resultData);
          
          // Increment student count
          await FirebaseFirestore.instance.collection('exams').doc(examId).update({
            'studentCount': FieldValue.increment(1)
          });
        }
     } catch (e) {
        debugPrint('Error saving student result: $e');
        rethrow;
     }
  }
}
