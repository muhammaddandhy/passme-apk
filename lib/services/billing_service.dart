import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import '../services/premium_service.dart';

class BillingService {
  static final BillingService instance = BillingService._internal();
  final InAppPurchase _iap = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  bool _isAvailable = false;
  List<ProductDetails> _products = [];
  final String _premiumProductId = 'premium_monthly'; // Ganti dengan product ID dari Play Console

  BillingService._internal();

  /// Initialize billing service
  Future<void> initialize() async {
    try {
      // Check if billing is available
      _isAvailable = await _iap.isAvailable();
      if (!_isAvailable) {
        debugPrint('In-app purchase tidak tersedia (ini normal untuk development)');
        return;
      }

      // Listen to purchase updates
      _subscription = _iap.purchaseStream.listen(
        _handlePurchaseUpdate,
        onDone: () => _subscription.cancel(),
        onError: (error) => debugPrint('Purchase stream error: $error'),
      );

      // Load products
      await loadProducts();
    } catch (e) {
      debugPrint('Error initializing billing service: $e');
      // Don't throw, just log - app should work without billing
      _isAvailable = false;
    }
  }

  /// Load available products
  Future<void> loadProducts() async {
    if (!_isAvailable) return;

    try {
      final Set<String> productIds = {_premiumProductId};
      final ProductDetailsResponse response =
          await _iap.queryProductDetails(productIds);

      if (response.error != null) {
        debugPrint('Error loading products: ${response.error}');
        return;
      }

      _products = response.productDetails;
      debugPrint('Products loaded: ${_products.length}');
    } catch (e) {
      debugPrint('Error loading products: $e');
      // Don't throw, app should work without products loaded
    }
  }

  /// Get premium product details
  ProductDetails? getPremiumProduct() {
    try {
      return _products.firstWhere(
        (product) => product.id == _premiumProductId,
      );
    } catch (e) {
      return null;
    }
  }

  /// Purchase premium subscription
  Future<bool> purchasePremium() async {
    if (!_isAvailable) {
      throw Exception('In-app purchase tidak tersedia. Pastikan aplikasi terhubung ke Play Store dan billing sudah di-setup.');
    }

    final product = getPremiumProduct();
    if (product == null) {
      throw Exception('Produk premium tidak ditemukan. Pastikan Product ID sudah dibuat di Play Console.');
    }

    final PurchaseParam purchaseParam = PurchaseParam(
      productDetails: product,
    );

    // Handle platform-specific purchase
    // Note: For subscriptions, use buyNonConsumable or the subscription method
    // depending on your product type in Play Console
    if (Platform.isAndroid) {
      final GooglePlayPurchaseParam androidParam =
          GooglePlayPurchaseParam(
        productDetails: product,
      );
      // Use buyNonConsumable for one-time purchases
      // For subscriptions, you might need to use a different approach
      return await _iap.buyNonConsumable(purchaseParam: androidParam);
    } else if (Platform.isIOS) {
      final AppStorePurchaseParam iosParam = AppStorePurchaseParam(
        productDetails: product,
      );
      return await _iap.buyNonConsumable(purchaseParam: iosParam);
    }

    return false;
  }

  /// Restore purchases
  Future<void> restorePurchases() async {
    if (!_isAvailable) return;

    try {
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint('Error restoring purchases: $e');
      throw Exception('Gagal memulihkan pembelian: $e');
    }
  }

  /// Cancel subscription (for Android, redirect to Play Store)
  Future<void> cancelSubscription() async {
    if (!_isAvailable) {
      throw Exception('In-app purchase tidak tersedia');
    }

    try {
      // For Android, we need to redirect user to Play Store subscription management
      // For iOS, we can use the native cancel flow
      if (Platform.isAndroid) {
        // On Android, we can't directly cancel - user must go to Play Store
        // We'll just deactivate premium status locally
        await PremiumService.setPremiumUser(false);
        debugPrint('Premium subscription cancelled (user must cancel in Play Store)');
      } else if (Platform.isIOS) {
        // On iOS, we can open subscription management
        await PremiumService.setPremiumUser(false);
        debugPrint('Premium subscription cancelled');
      }
    } catch (e) {
      debugPrint('Error cancelling subscription: $e');
      throw Exception('Gagal membatalkan langganan: $e');
    }
  }

  /// Handle purchase updates
  Future<void> _handlePurchaseUpdate(
    List<PurchaseDetails> purchaseDetailsList,
  ) async {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Show pending UI
        debugPrint('Purchase pending: ${purchaseDetails.productID}');
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          // Handle error
          debugPrint('Purchase error: ${purchaseDetails.error}');
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          // Verify and activate premium
          if (purchaseDetails.productID == _premiumProductId) {
            await PremiumService.setPremiumUser(true);
            debugPrint('Premium activated');
          }
        }

        // Complete the purchase
        if (purchaseDetails.pendingCompletePurchase) {
          await _iap.completePurchase(purchaseDetails);
        }
      }
    }
  }

  /// Check if billing is available
  bool get isAvailable => _isAvailable;

  /// Dispose resources
  void dispose() {
    _subscription.cancel();
  }
}

