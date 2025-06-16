import 'package:flutter/material.dart';

class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  // Primary colors
  static const Color primaryPurple = Color(0xFF667EEA);
  static const Color primaryPurpleDark = Color(0xFF764BA2);

  // Background colors
  static const Color backgroundLight = Color(0xFFF9FAFB);
  static const Color backgroundWhite = Colors.white;
  static const Color backgroundDark = Color(0xFF1F2937);

  // Text colors
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textLight = Colors.white;
  static const Color textHint = Color(0xFF9CA3AF);

  // Accent colors
  static const Color accentGold = Color(0xFFFBBF24);
  static const Color accentGreen = Color(0xFF10B981);
  static const Color accentRed = Color(0xFFEF4444);
  static const Color accentBlue = Color(0xFF3B82F6);

  // Category colors
  static const Map<String, Color> categoryColors = {
    'Science': Color(0xFF3B82F6),
    'History': Color(0xFF8B5CF6),
    'Geography': Color(0xFF10B981),
    'Sports': Color(0xFFF59E0B),
    'Movies & TV': Color(0xFFEC4899),
    'Music': Color(0xFFEF4444),
    'Technology': Color(0xFF6366F1),
    'Literature': Color(0xFF14B8A6),
  };

  // Status colors
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Neutral colors
  static const Color grey100 = Color(0xFFF3F4F6);
  static const Color grey200 = Color(0xFFE5E7EB);
  static const Color grey300 = Color(0xFFD1D5DB);
  static const Color grey400 = Color(0xFF9CA3AF);
  static const Color grey500 = Color(0xFF6B7280);

  // Shadow color
  static const Color shadow = Color(0x1A000000);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryPurple, primaryPurpleDark],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
  );

  static const LinearGradient silverGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE5E7EB), Color(0xFF9CA3AF)],
  );

  static const LinearGradient bronzeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF59E0B), Color(0xFFDC2626)],
  );
}
