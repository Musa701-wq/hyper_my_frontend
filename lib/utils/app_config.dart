import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get baseUrl {
    return dotenv.env['BASE_URL'] ?? 'https://coingecko.renderonnodes.com';
  }

  static String get wsUrl {
    return dotenv.env['WS_URL'] ?? 'wss://coingecko.renderonnodes.com/ws/';
  }

  static String get hipBaseUrl {
    return dotenv.env['STATS_API_URL'] ?? dotenv.env['HIP_BASE_URL'] ?? 'https://api.hyperliquid.bubblenexus.com';
  }

  static String get hipWsUrl {
    return dotenv.env['HIP_WS_URL'] ?? 'wss://api.hyperliquid.bubblenexus.com';
  }
}
