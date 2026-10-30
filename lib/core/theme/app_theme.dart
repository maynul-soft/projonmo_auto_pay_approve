import 'package:flutter/material.dart';

class AppColors {
  static const Color bkashPink = Color(0xFFE2136E);
  static const Color nagadOrange = Color(0xFFF7941D);

  static const Color primary = Color(0xFF1E293B);
  static const Color accent = Color(0xFF0284C7);

  static const Color statusUnmatched = Color(0xFF64748B);
  static const Color statusMatched = Color(0xFF0284C7);
  static const Color statusApproved = Color(0xFF16A34A);
  static const Color statusFailed = Color(0xFFDC2626);
  static const Color statusMismatch = Color(0xFFD97706);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0284C7),
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        filled: true,
      ),
    );
  }
}
