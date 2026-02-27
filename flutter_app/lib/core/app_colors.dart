import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF7C3AED);
  static const Color secondary = Color(0xFFF3F4F6);
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Colors.white;
  static const Color textMain = Color(0xFF111827);
  static const Color textMuted = Color(0xFF6B7280);
  
  static const Color green = Color(0xFF10B981);
  static const Color orange = Color(0xFFF59E0B);
  static const Color blue = Color(0xFF3B82F6);
  
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)], // Violet-600 to Indigo-600
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 20,
      offset: const Offset(0, 4),
      spreadRadius: -2,
    ),
  ];
}
