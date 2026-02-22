import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

class UserProvider with ChangeNotifier {
  UserProfile _user = UserProfile(
    name: 'Sarah Jenkins',
    email: 'sarah@school.com',
    phone: '+90 532 123 45 67',
    profileImageUrl: '',
    institution: 'ÖĞRETMEN PORTALİ',
  );

  UserProfile get user => _user;

  UserProvider() {
    loadUser();
  }

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userJson = prefs.getString('user_profile');
    if (userJson != null) {
      _user = UserProfile.fromJson(jsonDecode(userJson));
      // Migrate from old dummy URL to initials
      if (_user.profileImageUrl == 'https://i.pravatar.cc/150?img=32') {
        _user.profileImageUrl = '';
        updateUser(_user);
      }
      notifyListeners();
    }
  }

  Future<void> updateUser(UserProfile newUser) async {
    _user = newUser;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_profile', jsonEncode(_user.toJson()));
    notifyListeners();
  }
}
