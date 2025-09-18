import 'package:flutter/material.dart';

/// 🎨 Centralized theme for your app
class AppTheme {
  // Base colors
  static const Color background = Color(0xFF0D0D0D); // almost black
  static const Color lightBackground = Color.fromARGB(255, 255, 251, 251);
  static const Color card = Colors.white;
  static const Color fill = Color(0xFFF5F5F5);

  // New card colors
  static const Color cardBackground = Color(0xFFFFFFFF); // subtle white
  static const Color shadow = Color(0xFF000000); // black shadow with opacity

  // Buttons
  static const Color button = Color(0xFF9C27B0); // purple
  static const Color buttonText = Colors.white;

  // Text
  static const Color title = Color(0xFF222222);
  static const Color subtitle = Color(0xFF555555);
  static const Color whiteSubtitle = Color.fromARGB(255, 255, 255, 255);

  static const Color link = Color(0xFFE91E63); // pink accent

  // Gradient for main buttons
  static const List<Color> buttonGradient = [
    Color(0xFFE91E63), // pink
    Color(0xFF9C27B0), // purple
  ];

  // Common card style
  static CardTheme get cardTheme => CardTheme(
    elevation: 6,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    shadowColor: shadow.withOpacity(0.3),
  );

  // Common input decoration style
  static InputDecoration inputDecoration({
    required String label,
    required IconData icon,
    bool isPassword = false,
    VoidCallback? togglePassword,
    bool passwordVisible = false,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: isPassword
          ? IconButton(
              icon: Icon(
                passwordVisible ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: togglePassword,
            )
          : null,
      filled: true,
      fillColor: fill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}
