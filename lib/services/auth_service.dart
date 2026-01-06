import '../models/user_model.dart';
import '../services/database_helper.dart';
import '../services/encryption_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _currentUserKey = 'current_user_email';
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Register new user
  Future<bool> register(String email, String password) async {
    try {
      // Check if email already exists
      final exists = await _dbHelper.emailExists(email);
      if (exists) {
        throw Exception('Email sudah terdaftar');
      }

      // Hash password
      final hashedPassword = EncryptionService.hash(password);

      // Create user
      final user = UserModel(
        email: email,
        password: hashedPassword,
        createdAt: DateTime.now().toIso8601String(),
      );

      // Save to database
      await _dbHelper.insertUser(user);
      return true;
    } catch (e) {
      throw Exception('Gagal mendaftar: $e');
    }
  }

  /// Login user
  Future<bool> login(String email, String password) async {
    try {
      // Get user from database
      final user = await _dbHelper.getUserByEmail(email);
      if (user == null) {
        throw Exception('Email tidak terdaftar');
      }

      // Verify password
      final hashedPassword = EncryptionService.hash(password);
      if (user.password != hashedPassword) {
        throw Exception('Password salah');
      }

      // Save current user email
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentUserKey, email);
      return true;
    } catch (e) {
      throw Exception('Gagal login: $e');
    }
  }

  /// Get current logged in user email
  static Future<String?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_currentUserKey);
    } catch (e) {
      return null;
    }
  }

  /// Logout user
  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_currentUserKey);
    } catch (e) {
      throw Exception('Gagal logout: $e');
    }
  }

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final email = await getCurrentUser();
    return email != null && email.isNotEmpty;
  }
}

