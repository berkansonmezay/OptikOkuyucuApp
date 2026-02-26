import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

class UserProvider with ChangeNotifier {
  UserProfile _user = UserProfile(
    name: 'Ahmet Bakır',
    email: 'ahmet.bakir@example.com',
    phone: '+90 532 123 45 67',
    profileImageUrl: '',
    institution: 'ÖĞRETMEN PORTALİ',
  );

  UserProfile get user => _user;

  UserProvider() {
    loadUser();
  }

  Future<void> loadUser() async {
    try {
      final docSnap = await FirebaseFirestore.instance.collection('users').doc('user_123').get();
      if (docSnap.exists && docSnap.data() != null) {
        final data = docSnap.data()!;
        _user = UserProfile(
          name: data['name'] ?? _user.name,
          email: data['email'] ?? _user.email,
          phone: data['phone'] ?? _user.phone,
          profileImageUrl: data['profileImageUrl'] ?? _user.profileImageUrl,
          institution: data['institution'] ?? _user.institution,
        );
        notifyListeners();
      } else {
        // Save default if not exists
        await updateUser(_user);
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
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
      }, SetOptions(merge: true));
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating user profile: $e');
    }
  }
}
