import 'package:flutter/material.dart';

class AppColors {
  // Brand & Primary
  static const Color primary = Color(0xFF1E3A8A); // Deep Navy
  static const Color primaryLight = Color(0xFF3B82F6); // Blue Accent
  static const Color primaryDark = Color(0xFF172554); // Midnight Blue

  // Secondary & Accents
  static const Color secondary = Color(0xFF0D9488); // Teal
  static const Color accent = Color(0xFF6366F1); // Indigo
  static const Color accentTeal = secondary;

  // Neutrals - Light Mode
  static const Color bgLight = Color(0xFFF8FAFC); // Slate 50
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceMutedLight = Color(0xFFF1F5F9); // Slate 100
  static const Color borderLight = Color(0xFFE2E8F0); // Slate 200
  static const Color textPrimaryLight = Color(0xFF0F172A); // Slate 900
  static const Color textSecondaryLight = Color(0xFF64748B); // Slate 500
  static const Color textMutedLight = Color(0xFF94A3B8); // Slate 400

  // Neutrals - Dark Mode
  static const Color bgDark = Color(0xFF0B1120); // Very Deep Slate
  static const Color surfaceDark = Color(0xFF1E293B); // Slate 800
  static const Color surfaceMutedDark = Color(0xFF334155); // Slate 700
  static const Color borderDark = Color(0xFF334155); // Slate 700
  static const Color textPrimaryDark = Color(0xFFF8FAFC); // Slate 50
  static const Color textSecondaryDark = Color(0xFF94A3B8); // Slate 400
  static const Color textMutedDark = Color(0xFF64748B); // Slate 500

  // Semantic
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);
  static const Color error = Color(0xFFDC2626);
  static const Color errorRed = error;
  static const Color info = Color(0xFF0284C7);
}
