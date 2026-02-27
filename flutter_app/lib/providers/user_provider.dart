import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

class UserProvider with ChangeNotifier {
  UserProfile? _user;
  bool _isLoading = false;

  UserProfile? get user => _user;
  bool get isLoading => _isLoading;

  UserProvider() {
    loadUser();
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
    _user = newUser;
    try {
      await FirebaseFirestore.instance.collection('users').doc('user_123').set({
        'name': _user.name,
        'email': _user.email,
        'phone': _user.phone,
        'profileImageUrl': _user.profileImageUrl,
        'institution': _user.institution,
        'role': _user.role,
      }, SetOptions(merge: true));
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating user profile: $e');
    }
  }
}
