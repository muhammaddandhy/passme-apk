import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'billing_service.dart';

class PremiumService {
  static const String _premiumKey = 'is_premium_user';
  static final BillingService _billingService = BillingService.instance;

  /// Initialize premium service
  static Future<void> initialize() async {
    try {
      await _billingService.initialize();
      // Check for active purchases on startup
      await _checkActivePurchases();
    } catch (e) {
      // Don't throw - app should work even if billing fails to initialize
      debugPrint('Premium service initialization error (non-critical): $e');
    }
  }

  /// Check for active purchases
  static Future<void> _checkActivePurchases() async {
    // This will be called by billing service when purchases are restored
    // For now, we rely on SharedPreferences
  }

  /// Cek apakah user adalah premium user
  static Future<bool> isPremiumUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_premiumKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Set status premium user
  static Future<void> setPremiumUser(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_premiumKey, value);
    } catch (e) {
      throw Exception('Failed to set premium status: $e');
    }
  }

  /// Upgrade user ke premium melalui Play Store
  static Future<bool> upgradeToPremium() async {
    try {
      if (!_billingService.isAvailable) {
        throw Exception('In-app purchase tidak tersedia. Pastikan aplikasi terhubung ke Play Store.');
      }

      final success = await _billingService.purchasePremium();
      if (success) {
        // Premium status will be set by billing service when purchase completes
        return true;
      }
      return false;
    } catch (e) {
      throw Exception('Gagal membeli premium: $e');
    }
  }

  /// Restore purchases
  static Future<void> restorePurchases() async {
    try {
      await _billingService.restorePurchases();
    } catch (e) {
      throw Exception('Gagal memulihkan pembelian: $e');
    }
  }

  /// Get premium product details
  static Future<Map<String, dynamic>?> getPremiumProductInfo() async {
    try {
      final product = _billingService.getPremiumProduct();
      if (product != null) {
        return {
          'id': product.id,
          'title': product.title,
          'description': product.description,
          'price': product.price,
        };
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Cancel premium subscription
  static Future<void> cancelSubscription() async {
    try {
      await _billingService.cancelSubscription();
    } catch (e) {
      throw Exception('Gagal membatalkan langganan: $e');
    }
  }
}

