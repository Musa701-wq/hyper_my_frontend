import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kAccountsKey = 'saved_accounts';
const _kSelectedAddressKey = 'selected_wallet_address';

class SavedAccount {
  final String address;
  final String name;

  SavedAccount({required this.address, required this.name});

  Map<String, dynamic> toJson() => {'address': address, 'name': name};
  factory SavedAccount.fromJson(Map<String, dynamic> json) =>
      SavedAccount(address: json['address'], name: json['name']);
      
  String get shortAddress {
    if (address.length < 10) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }
}

class WalletViewModel extends ChangeNotifier {
  List<SavedAccount> _accounts = [];
  String? _selectedAddress;
  bool _isInitialized = false;

  List<SavedAccount> get accounts => _accounts;
  String? get address => _selectedAddress;
  bool get isConnected => _selectedAddress != null && _selectedAddress!.isNotEmpty;
  bool get isInitialized => _isInitialized;

  SavedAccount? get selectedAccount {
    if (_selectedAddress == null) return null;
    return _accounts.firstWhere((a) => a.address == _selectedAddress,
        orElse: () => SavedAccount(address: _selectedAddress!, name: 'Unknown'));
  }

  String get shortAddress => selectedAccount?.shortAddress ?? '';

  WalletViewModel({SharedPreferences? prefs}) {
    if (prefs != null) {
      _loadSync(prefs);
    } else {
      _load();
    }
  }

  void _loadSync(SharedPreferences prefs) {
    // Load accounts
    final accountsRaw = prefs.getString(_kAccountsKey);
    if (accountsRaw != null) {
      final List decoded = jsonDecode(accountsRaw);
      _accounts = decoded.map((item) => SavedAccount.fromJson(item)).toList();
    }

    // Load selected address
    _selectedAddress = prefs.getString(_kSelectedAddressKey);
    
    // Fallback: if no selected address but accounts exist, pick first
    if (_selectedAddress == null && _accounts.isNotEmpty) {
      _selectedAddress = _accounts.first.address;
    }
    
    _isInitialized = true;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _loadSync(prefs);
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAccountsKey, jsonEncode(_accounts.map((a) => a.toJson()).toList()));
    if (_selectedAddress != null) {
      await prefs.setString(_kSelectedAddressKey, _selectedAddress!);
    } else {
      await prefs.remove(_kSelectedAddressKey);
    }
  }

  Future<void> connect(String address, {String name = 'Main Wallet'}) async {
    // Check if account already exists
    final index = _accounts.indexWhere((a) => a.address.toLowerCase() == address.toLowerCase());
    if (index != -1) {
      // Update name if it's the same address
      _accounts[index] = SavedAccount(address: address, name: name);
    } else {
      _accounts.add(SavedAccount(address: address, name: name));
    }
    
    _selectedAddress = address;
    await _save();
    notifyListeners();
  }

  Future<void> selectAccount(String address) async {
    _selectedAddress = address;
    await _save();
    notifyListeners();
  }

  Future<void> removeAccount(String address) async {
    _accounts.removeWhere((a) => a.address.toLowerCase() == address.toLowerCase());
    if (_selectedAddress?.toLowerCase() == address.toLowerCase()) {
      _selectedAddress = _accounts.isNotEmpty ? _accounts.first.address : null;
    }
    await _save();
    notifyListeners();
  }

  Future<void> disconnect() async {
    // This now clear everything or just current? 
    // User requested "remove" icon for each, so disconnect usually means clearing the session.
    // Let's keep disconnect as "clear all" or just clear selected?
    // Given the "multiple accounts" request, let's make disconnect clear the selection.
    _selectedAddress = null;
    await _save();
    notifyListeners();
  }
}
