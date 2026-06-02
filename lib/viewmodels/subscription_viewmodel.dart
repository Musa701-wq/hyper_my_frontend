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

  static const String _isProKey = 'is_pro_user';
  static const Set<String> _kIds = {'hyper_weekly_pro', 'hyper_monthly_pro'};

  SubscriptionViewModel() {
    _loadProStatus();
    final purchaseUpdated = _iap.purchaseStream;
    _subscription = purchaseUpdated.listen(
      (purchaseList) => _listenToPurchaseUpdated(purchaseList),
      onDone: () => _subscription.cancel(),
      onError: (error) => debugPrint("IAP Error: $error"),
    );
    loadProducts();
  }

  Future<void> _loadProStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isPro = prefs.getBool(_isProKey) ?? false;
    notifyListeners();
  }

  Future<void> _saveProStatus(bool status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isProKey, status);
  }

  Future<void> loadProducts() async {
    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final bool available = await _iap.isAvailable();
      if (!available) {
        _errorMessage = "Store not available";
        _isProcessing = false;
        notifyListeners();
        return;
      }

      final ProductDetailsResponse response = await _iap.queryProductDetails(_kIds);
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint("Products not found: ${response.notFoundIDs}");
      }

      _products = response.productDetails;
      // Sort products: weekly first, monthly second
      _products.sort((a, b) => a.id.contains('weekly') ? -1 : 1);
      
    } catch (e) {
      _errorMessage = "Failed to load products: $e";
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<void> subscribe(ProductDetails product) async {
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    
    // In a real app, you might want to use buyNonConsumable for subscriptions 
    // but the IAP package handles both via appropriate methods.
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
          
          _isPro = true;
          _saveProStatus(true);
          _isProcessing = false;
          _errorMessage = null;
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
      await _iap.restorePurchases();
    } catch (e) {
      _errorMessage = "Failed to restore purchases: $e";
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  void togglePro() {
    _isPro = !_isPro;
    _saveProStatus(_isPro);
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
