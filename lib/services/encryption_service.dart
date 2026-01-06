import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt_pkg;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptionService {
  static final _storage = const FlutterSecureStorage();
  static const _keyStorageKey = 'app_secure_key_v1';
  static encrypt_pkg.Key? _key;
  
  // Initialize the service by loading or creating an encryption key
  static Future<void> initialize() async {
    try {
      String? keyString = await _storage.read(key: _keyStorageKey);
      
      if (keyString == null) {
        // Generate a new 32-byte key (256 bits)
        final key = encrypt_pkg.Key.fromSecureRandom(32);
        // Store it as a base64 string
        await _storage.write(key: _keyStorageKey, value: base64Url.encode(key.bytes));
        _key = key;
      } else {
        _key = encrypt_pkg.Key(base64Url.decode(keyString));
      }
    } catch (e) {
      // Fallback for systems where secure storage might fail (dev envs)
      // In production specific error handling is needed
      print('Secure storage init error: $e');
      final key = encrypt_pkg.Key.fromUtf8('FixedKeyForDevFallback12345678'); // 32 chars
      _key = key;
    }
  }

  // Encrypt text using AES-CBC
  static String encrypt(String text) {
    if (_key == null) {
      // Auto-initialize if not done (though main should do it)
      // Note: allows synchronous usage after async init is risky but common in UI helpers
      // ideally we ensure init is done. For now, we'll throw or use temp.
       throw Exception('EncryptionService not initialized. Call initialize() first.');
    }
    
    final iv = encrypt_pkg.IV.fromSecureRandom(16);
    final encrypter = encrypt_pkg.Encrypter(encrypt_pkg.AES(_key!, mode: encrypt_pkg.AESMode.cbc));
    
    final encrypted = encrypter.encrypt(text, iv: iv);
    
    // Return format: iv:ciphertext (both base64 encoded)
    return '${iv.base64}:${encrypted.base64}';
  }

  // Decrypt text
  static String? decrypt(String encryptedText) {
    if (encryptedText.isEmpty) return null;
    
    // Check if it's the new format (contains :)
    if (encryptedText.contains(':')) {
      try {
        if (_key == null) {
           throw Exception('EncryptionService not initialized');
        }
        
        final parts = encryptedText.split(':');
        if (parts.length != 2) return null;
        
        final iv = encrypt_pkg.IV.fromBase64(parts[0]);
        final encrypter = encrypt_pkg.Encrypter(encrypt_pkg.AES(_key!, mode: encrypt_pkg.AESMode.cbc));
        
        return encrypter.decrypt64(parts[1], iv: iv);
      } catch (e) {
        print('Decryption error: $e');
        // If fail, try legacy just in case
        return _decryptLegacy(encryptedText);
      }
    } else {
      // Try legacy decryption
      return _decryptLegacy(encryptedText);
    }
  }

  // Legacy decryption for backward compatibility
  static String? _decryptLegacy(String encryptedText) {
    try {
      final parts = encryptedText.split('|');
      if (parts.length == 2) {
        final base64Str = parts[0];
        final decoded = base64Decode(base64Str);
        return utf8.decode(decoded);
      }
      // Fallback for old format (just base64)
      final decoded = base64Decode(encryptedText);
      return utf8.decode(decoded);
    } catch (e) {
      return null;
    }
  }

  // SHA-256 Hash for one-way encryption (unchanged)
  static String hash(String text) {
    final bytes = utf8.encode(text);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}

