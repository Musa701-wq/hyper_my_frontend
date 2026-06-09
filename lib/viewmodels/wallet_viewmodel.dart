import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kWalletKey = 'connected_wallet';

// Testing dummy address — swap with real wallet logic later
const kDummyWallet = '0x1F3C642A7B3a52e95EAf69dBa6A0Ddf8A98f3C2';

class WalletViewModel extends ChangeNotifier {
  String? _address;

  String? get address => _address;
  bool get isConnected => _address != null && _address!.isNotEmpty;

  /// Short display form: 0x1F3C...f3C2
  String get shortAddress {
    if (_address == null || _address!.length < 10) return '';
    return '${_address!.substring(0, 6)}...${_address!.substring(_address!.length - 4)}';
  }

  WalletViewModel() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kWalletKey);
    if (saved != null && saved.isNotEmpty) {
      _address = saved;
      notifyListeners();
    }
  }

  /// Connect — for testing, always uses [kDummyWallet].
  /// In production replace with real wallet input / WalletConnect.
  Future<void> connect(String address) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kWalletKey, address);
    _address = address;
    notifyListeners();
  }

  Future<void> disconnect() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kWalletKey);
    _address = null;
    notifyListeners();
  }
}
