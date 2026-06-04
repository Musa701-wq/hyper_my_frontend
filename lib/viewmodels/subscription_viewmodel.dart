import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionViewModel extends ChangeNotifier {
  final InAppPurchase _iap = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  bool _isPro = false;
  bool _isProcessing = false;
  List<ProductDetails> _products = [];
  String? _errorMessage;


  bool get isPro => _isPro;
  bool get isProcessing => _isProcessing;
  List<ProductDetails> get products => _products;
  String? get errorMessage => _errorMessage;

  static const Set<String> _kIds = {
    'com.vectorlabs.hyperscreener.premiumweekly',
    'com.vectorlabs.hyperscreener.premiummonthly'
  };

  SubscriptionViewModel() {
    final purchaseUpdated = _iap.purchaseStream;
    _subscription = purchaseUpdated.listen(
      (purchaseList) => _listenToPurchaseUpdated(purchaseList),
      onDone: () => _subscription.cancel(),
      onError: (error) => debugPrint("IAP Error: $error"),
    );
    loadProducts();
    // Initial restoration check happens via the stream if the platform handles it, 
    // but explicit restore call can be made if needed by the user tapping Restore.
  }

  Future<void> loadProducts() async {
    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint("IAP DEBUG: Checking availability...");
      final bool available = await _iap.isAvailable();
      debugPrint("IAP DEBUG: Store available: $available");
      
      if (!available) {
        _errorMessage = "Store not available";
        _isProcessing = false;
        notifyListeners();
        return;
      }

      debugPrint("IAP DEBUG: Querying products for IDs: $_kIds");
      final ProductDetailsResponse response = await _iap.queryProductDetails(_kIds);
      
      if (response.error != null) {
        debugPrint("IAP DEBUG: Query error: ${response.error!.code} - ${response.error!.message}");
      }
      
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint("IAP DEBUG: Products NOT FOUND: ${response.notFoundIDs}");
      }

      debugPrint("IAP DEBUG: Products FOUND: ${response.productDetails.length}");
      for (var p in response.productDetails) {
        debugPrint("IAP DEBUG: Found product: ${p.id} - ${p.title} - ${p.price}");
      }

      _products = response.productDetails;
      // Sort products: weekly first, monthly second
      _products.sort((a, b) => a.id.contains('weekly') ? -1 : 1);
      
    } catch (e) {
      debugPrint("IAP DEBUG: Exception in loadProducts: $e");
      _errorMessage = "Failed to load products: $e";
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<void> subscribe(ProductDetails product) async {
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    try {
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      debugPrint("Purchase error: $e");
    }
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    for (var purchase in purchaseDetailsList) {
      if (purchase.status == PurchaseStatus.pending) {
        _isProcessing = true;
      } else {
        if (purchase.status == PurchaseStatus.error) {
          _errorMessage = purchase.error?.message ?? "Purchase failed";
          _isProcessing = false;
        } else if (purchase.status == PurchaseStatus.purchased || 
                   purchase.status == PurchaseStatus.restored) {
          
          // Verify that the purchase is for one of our products
          if (_kIds.contains(purchase.productID)) {
             _isPro = true;
          }
          _isProcessing = false;
          _errorMessage = null;
        } else if (purchase.status == PurchaseStatus.canceled) {
           _isProcessing = false;
        }

        if (purchase.pendingCompletePurchase) {
          _iap.completePurchase(purchase);
        }
      }
      notifyListeners();
    }
  }

  Future<void> restorePurchases() async {
    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint("IAP DEBUG: Starting restorePurchases...");
      await _iap.restorePurchases();
      debugPrint("IAP DEBUG: restorePurchases call completed. (Listen to stream for updates)");
    } catch (e) {
      debugPrint("IAP DEBUG: restorePurchases exception: $e");
      _errorMessage = "Failed to restore purchases: $e";
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
