import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/password_model.dart';
import '../models/user_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('passwords.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, filePath);

      return await openDatabase(
        path,
        version: 5, // Increment version for migration
        onCreate: _createDB,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      throw Exception('Failed to initialize database: $e');
    }
  }

  Future<void> _createDB(Database db, int version) async {
    try {
      // Create users table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          email TEXT NOT NULL UNIQUE,
          password TEXT NOT NULL,
          createdAt TEXT NOT NULL
        )
      ''');

      // Create passwords table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS passwords (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          username TEXT NOT NULL,
          password TEXT NOT NULL,
          url TEXT,
          notes TEXT,
          createdAt TEXT NOT NULL,
          iconType TEXT NOT NULL DEFAULT 'default',
          category TEXT NOT NULL DEFAULT 'Lainnya',
          passwordHistory TEXT
        )
      ''');
    } catch (e) {
      throw Exception('Failed to create table: $e');
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Version 2 upgrades...
      await db.execute('''
        CREATE TABLE IF NOT EXISTS users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          email TEXT NOT NULL UNIQUE,
          password TEXT NOT NULL,
          createdAt TEXT NOT NULL
        )
      ''');
    }

    // Check for columns and add if missing
    try {
      final tableInfo = await db.rawQuery('PRAGMA table_info(passwords)');
      final columnNames = tableInfo.map((c) => c['name'] as String).toList();

      if (!columnNames.contains('iconType')) {
        await db.execute('ALTER TABLE passwords ADD COLUMN iconType TEXT DEFAULT \'default\'');
        await _updateExistingPasswordsIconType(db);
      }
      
      if (!columnNames.contains('url')) {
        await db.execute('ALTER TABLE passwords ADD COLUMN url TEXT');
      }
      
      if (!columnNames.contains('notes')) {
        await db.execute('ALTER TABLE passwords ADD COLUMN notes TEXT');
      }

      if (!columnNames.contains('category')) {
        await db.execute('ALTER TABLE passwords ADD COLUMN category TEXT NOT NULL DEFAULT \'Lainnya\'');
      }

      if (!columnNames.contains('passwordHistory')) {
        await db.execute('ALTER TABLE passwords ADD COLUMN passwordHistory TEXT');
      }
      
    } catch (e) {
      debugPrint('Migration error: $e');
    }
  }

  /// Update existing passwords with iconType based on their title
  Future<void> _updateExistingPasswordsIconType(Database db) async {
    try {
      final passwords = await db.query('passwords');
      for (final password in passwords) {
        final title = password['title'] as String? ?? '';
        final username = password['username'] as String? ?? '';
        final id = password['id'] as int?;
        
        if (id != null) {
          // Import icon helper logic inline to avoid circular dependency
          final iconType = _detectIconType(title, username);
          await db.update(
            'passwords',
            {'iconType': iconType},
            where: 'id = ?',
            whereArgs: [id],
          );
        }
      }
    } catch (e) {
      debugPrint('Error updating existing passwords iconType: $e');
    }
  }

  /// Detect icon type from title and username (inline version to avoid import)
  String _detectIconType(String title, String username) {
    final lowerTitle = title.toLowerCase();
    final lowerUsername = username.toLowerCase();

    if (lowerTitle.contains('gmail') || lowerTitle.contains('google') || lowerUsername.contains('@gmail.com')) {
      return 'gmail';
    }
    if (lowerTitle.contains('facebook') || lowerTitle.contains('fb')) {
      return 'facebook';
    }
    if (lowerTitle.contains('instagram') || lowerTitle.contains('ig')) {
      return 'instagram';
    }
    if (lowerTitle.contains('twitter') || lowerTitle.contains('x.com')) {
      return 'twitter';
    }
    if (lowerTitle.contains('whatsapp') || lowerTitle.contains('wa ')) {
      return 'whatsapp';
    }
    if (lowerTitle.contains('linkedin')) {
      return 'linkedin';
    }
    if (lowerTitle.contains('youtube') || lowerTitle.contains('yt ')) {
      return 'youtube';
    }
    if (lowerTitle.contains('tiktok')) {
      return 'tiktok';
    }
    if (lowerTitle.contains('telegram') || lowerTitle.contains('tg ')) {
      return 'telegram';
    }
    if (lowerTitle.contains('discord')) {
      return 'discord';
    }
    if (lowerTitle.contains('github')) {
      return 'github';
    }
    if (lowerTitle.contains('amazon')) {
      return 'amazon';
    }
    if (lowerTitle.contains('netflix')) {
      return 'netflix';
    }
    if (lowerTitle.contains('spotify')) {
      return 'spotify';
    }
    if (lowerTitle.contains('paypal')) {
      return 'paypal';
    }
    return 'default';
  }

  Future<int> insertPassword(PasswordModel password) async {
    try {
      final db = await database;
      return await db.insert('passwords', password.toMap());
    } catch (e) {
      throw Exception('Failed to insert password: $e');
    }
  }

  Future<List<PasswordModel>> getAllPasswords() async {
    try {
      final db = await database;
      final result = await db.query(
        'passwords',
        orderBy: 'createdAt DESC',
      );
      final passwords = <PasswordModel>[];
      for (final map in result) {
        // Ensure iconType exists, if not, detect it
        final iconTypeValue = map['iconType'] as String?;
        if (iconTypeValue == null || iconTypeValue.isEmpty) {
          final iconType = _detectIconType(
            map['title'] as String? ?? '',
            map['username'] as String? ?? '',
          );
          map['iconType'] = iconType;
          // Update in database
          if (map['id'] != null) {
            db.update(
              'passwords',
              {'iconType': iconType},
              where: 'id = ?',
              whereArgs: [map['id']],
            );
          }
        }
        passwords.add(PasswordModel.fromMap(map));
      }
      return passwords;
    } catch (e) {
      throw Exception('Failed to get passwords: $e');
    }
  }

  Future<PasswordModel?> getPasswordById(int id) async {
    try {
      final db = await database;
      final result = await db.query(
        'passwords',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (result.isEmpty) return null;
      return PasswordModel.fromMap(result.first);
    } catch (e) {
      throw Exception('Failed to get password: $e');
    }
  }

  Future<int> updatePassword(PasswordModel password) async {
    try {
      final db = await database;
      return await db.update(
        'passwords',
        password.toMap(),
        where: 'id = ?',
        whereArgs: [password.id],
      );
    } catch (e) {
      throw Exception('Failed to update password: $e');
    }
  }

  Future<int> deletePassword(int id) async {
    try {
      final db = await database;
      return await db.delete(
        'passwords',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw Exception('Failed to delete password: $e');
    }
  }

  // User methods
  Future<int> insertUser(UserModel user) async {
    try {
      final db = await database;
      return await db.insert('users', user.toMap());
    } catch (e) {
      throw Exception('Failed to insert user: $e');
    }
  }

  Future<UserModel?> getUserByEmail(String email) async {
    try {
      final db = await database;
      final result = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email],
        limit: 1,
      );
      if (result.isEmpty) return null;
      return UserModel.fromMap(result.first);
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  Future<bool> hasUsers() async {
    final db = await database;
    final result = await db.query('users', limit: 1);
    return result.isNotEmpty;
  }

  Future<bool> emailExists(String email) async {
    try {
      final user = await getUserByEmail(email);
      return user != null;
    } catch (e) {
      return false;
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
