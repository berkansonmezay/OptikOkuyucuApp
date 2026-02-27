import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

class UserProvider with ChangeNotifier {
  UserProfile? _user;
  bool _isLoading = false;
  StreamSubscription? _statsSubscription;
  int _totalScans = 0;
  int _growthRate = 0;

  UserProfile? get user => _user;
  bool get isLoading => _isLoading;
  int get totalScans => _totalScans;
  int get growthRate => _growthRate;

  UserProvider();

  void initializeStats(String? userId, String? role) {
    _statsSubscription?.cancel();
    
    Query query = FirebaseFirestore.instance.collection('exams');
    if (role != 'admin' && userId != null) {
      query = query.where('creatorId', isEqualTo: userId);
    }

    _statsSubscription = query.snapshots().listen((snapshot) {
      final exams = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      _calculateStats(exams);
    });
  }

  void _calculateStats(List<Map<String, dynamic>> exams) {
    // Total scans
    _totalScans = exams.fold(0, (sum, exam) => sum + ((exam['studentCount'] as int?) ?? 0));

    // Weekly growth (mirroring web logic from firebase-config.js)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final currentWeekStart = today.subtract(const Duration(days: 6));
    final previousWeekStart = today.subtract(const Duration(days: 13));

    int currentTotal = 0;
    int previousTotal = 0;

    for (var exam in exams) {
      final dateStr = exam['date'] as String?;
      if (dateStr == null) continue;
      
      final examDate = DateTime.tryParse(dateStr);
      if (examDate == null) continue;

      final normalizedDate = DateTime(examDate.year, examDate.month, examDate.day);

      if (normalizedDate.isAfter(currentWeekStart.subtract(const Duration(seconds: 1))) && 
          normalizedDate.isAtSameMomentAs(today) || normalizedDate.isBefore(today)) {
        // Technically current week is [today-6, today]
        if (normalizedDate.isAfter(currentWeekStart.subtract(const Duration(seconds: 1))) && normalizedDate.isBefore(today.add(const Duration(days: 1)))) {
           currentTotal += (exam['studentCount'] as int?) ?? 0;
        }
      } 
      
      // Re-doing logic for clarity to match JS exactly
      // JS currentWeekStart = today - 6 days
      // JS currentWeekExams = examDate >= currentWeekStart && examDate <= today
      // JS previousWeekStart = today - 13 days
      // JS previousWeekExams = examDate >= previousWeekStart && examDate < currentWeekStart
    }
    
    // Exact JS Match:
    currentTotal = 0;
    previousTotal = 0;
    for (var exam in exams) {
      final dateStr = exam['date'] as String?;
      if (dateStr == null) continue;
      final examDate = DateTime.tryParse(dateStr);
      if (examDate == null) continue;
      final d = DateTime(examDate.year, examDate.month, examDate.day);
      
      if (d.isAtSameMomentAs(currentWeekStart) || (d.isAfter(currentWeekStart) && (d.isBefore(today) || d.isAtSameMomentAs(today)))) {
        currentTotal += (exam['studentCount'] as int?) ?? 0;
      } else if (d.isAtSameMomentAs(previousWeekStart) || (d.isAfter(previousWeekStart) && d.isBefore(currentWeekStart))) {
        previousTotal += (exam['studentCount'] as int?) ?? 0;
      }
    }

    if (previousTotal > 0) {
      _growthRate = (((currentTotal - previousTotal) / previousTotal) * 100).round();
    } else if (currentTotal > 0) {
      _growthRate = 100;
    } else {
      _growthRate = 0;
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _statsSubscription?.cancel();
    super.dispose();
  }

  Future<void> loadUser(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final docSnap = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (docSnap.exists && docSnap.data() != null) {
        final data = docSnap.data()!;
        _user = UserProfile.fromJson({...data, 'id': docSnap.id});
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> logout() async {
    _user = null;
    notifyListeners();
  }

  Future<List<UserProfile>> fetchAllInstitutions() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'institution')
          .get();
      return snapshot.docs.map((doc) => UserProfile.fromJson({...doc.data(), 'id': doc.id})).toList();
    } catch (e) {
      debugPrint('Error fetching institutions: $e');
      return [];
    }
  }

  Future<bool> addInstitution(String username, String password, String name) async {
    try {
      // Check if username already exists
      final existing = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .get();
      if (existing.docs.isNotEmpty) return false;

      await FirebaseFirestore.instance.collection('users').add({
        'username': username,
        'password': password,
        'role': 'institution',
        'name': name,
        'createdAt': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      debugPrint('Error adding institution: $e');
      return false;
    }
  }

  Future<bool> deleteInstitution(String id) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(id).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting institution: $e');
      return false;
    }
  }

  Future<UserProfile?> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .where('password', isEqualTo: password)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        _user = UserProfile.fromJson({...data, 'id': snapshot.docs.first.id});
        _isLoading = false;
        notifyListeners();
        return _user;
      }
    } catch (e) {
      debugPrint('Login error: $e');
    }
    _isLoading = false;
    notifyListeners();
    return null;
  }

  Future<void> updateUser(UserProfile newUser) async {
    if (newUser.id == null) return;
    _user = newUser;
    try {
      await FirebaseFirestore.instance.collection('users').doc(newUser.id).set({
        'name': newUser.name,
        'email': newUser.email,
        'phone': newUser.phone,
        'profileImageUrl': newUser.profileImageUrl,
        'institution': newUser.institution,
        'role': newUser.role,
      }, SetOptions(merge: true));
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating user profile: $e');
    }
  }
}
