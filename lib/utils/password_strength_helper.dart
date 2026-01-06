import 'package:flutter/material.dart';

enum PasswordStrength { weak, medium, strong, veryStrong }

class PasswordStrengthHelper {
  static PasswordStrength checkStrength(String password) {
    if (password.isEmpty) return PasswordStrength.weak;
    
    int score = 0;
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;

    if (score <= 2) return PasswordStrength.weak;
    if (score == 3) return PasswordStrength.medium;
    if (score == 4) return PasswordStrength.strong;
    return PasswordStrength.veryStrong;
  }

  static Color getColor(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.weak:
        return Colors.red;
      case PasswordStrength.medium:
        return Colors.orange;
      case PasswordStrength.strong:
        return Colors.blue;
      case PasswordStrength.veryStrong:
        return Colors.green;
    }
  }

  static String getLabel(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.weak:
        return 'Lemah';
      case PasswordStrength.medium:
        return 'Sedang';
      case PasswordStrength.strong:
        return 'Kuat';
      case PasswordStrength.veryStrong:
        return 'Sangat Kuat';
    }
  }

  static double getPercent(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.weak:
        return 0.25;
      case PasswordStrength.medium:
        return 0.5;
      case PasswordStrength.strong:
        return 0.75;
      case PasswordStrength.veryStrong:
        return 1.0;
    }
  }
}
