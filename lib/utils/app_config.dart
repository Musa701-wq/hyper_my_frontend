import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String _get(String key, String fallback) {
    try {
      return dotenv.env[key] ?? fallback;
    } catch (_) {
      return fallback;
    }
  }

  static String get baseUrl {
    return _get('BASE_URL', 'https://coingecko.renderonnodes.com');
  }

  static String get wsUrl {
    return _get('WS_URL', 'wss://coingecko.renderonnodes.com/ws/');
  }

  static String get hipBaseUrl {
    try {
      return dotenv.env['STATS_API_URL'] ?? dotenv.env['HIP_BASE_URL'] ?? 'https://api.hyperliquid.bubblenexus.com';
    } catch (_) {
      return 'https://api.hyperliquid.bubblenexus.com';
    }
  }

  static String get hipWsUrl {
    return _get('HIP_WS_URL', 'wss://api.hyperliquid.bubblenexus.com');
  }

  static String get defillamaUrl {
    return _get('DEFILLAMA_API_URL', 'https://api.hyperliquid.bubblenexus.com');
  }

  static String get dexVolumeUrl {
    return _get('DEX_VOLUME_API_URL', 'https://coingecko.renderonnodes.com');
  }

  static String get hip4DetailBaseUrl {
    return _get('HIP4_DETAIL_API_URL', baseUrl);
  }

  static String get hip4DetailsTabBaseUrl {
    return _get('HIP4_DETAILS_TAB_API_URL', 'https://coingecko.renderonnodes.com');
  }
}
