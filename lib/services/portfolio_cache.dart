import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/portfolio_history_model.dart';
import '../models/portfolio_summary_model.dart';

/// Persists portfolio API responses locally per wallet.
class PortfolioCache {
  static String _summaryKey(String wallet) => 'portfolio_summary_${wallet.toLowerCase()}';
  static String _historyKey(String wallet) => 'portfolio_history_${wallet.toLowerCase()}';
  static String _cachedAtKey(String wallet) => 'portfolio_cached_at_${wallet.toLowerCase()}';

  static Future<void> save({
    required String wallet,
    required PortfolioSummaryModel summary,
    required PortfolioHistoryModel history,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_summaryKey(wallet), jsonEncode(_summaryToMap(summary)));
    await prefs.setString(_historyKey(wallet), jsonEncode(_historyToMap(history)));
    await prefs.setInt(_cachedAtKey(wallet), DateTime.now().millisecondsSinceEpoch);
  }

  static Future<({PortfolioSummaryModel summary, PortfolioHistoryModel history})?> load(
    String wallet,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final summaryRaw = prefs.getString(_summaryKey(wallet));
    final historyRaw = prefs.getString(_historyKey(wallet));
    if (summaryRaw == null || historyRaw == null) return null;

    try {
      return (
        summary: PortfolioSummaryModel.fromJson(jsonDecode(summaryRaw) as Map<String, dynamic>),
        history: PortfolioHistoryModel.fromJson(jsonDecode(historyRaw) as Map<String, dynamic>),
      );
    } catch (_) {
      return null;
    }
  }

  static Future<DateTime?> cachedAt(String wallet) async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getInt(_cachedAtKey(wallet));
    if (ts == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ts);
  }

  static Map<String, dynamic> _summaryToMap(PortfolioSummaryModel s) => {
        'walletAddress': s.walletAddress,
        'totalBalance': s.totalBalance,
        'perpAccountValue': s.perpAccountValue,
        'spotUSDValue': s.spotUSDValue,
        'unrealizedPnl': s.unrealizedPnl,
        'unrealizedPnlPct': s.unrealizedPnlPct,
        'buyingPower': s.buyingPower,
        'withdrawable': s.withdrawable,
        'marginUsed': s.marginUsed,
        'totalMarginUsed': s.totalMarginUsed,
        'positions': s.positions.map(_positionToMap).toList(),
        'spotBalances': s.spotBalances.map(_spotToMap).toList(),
        'openOrders': s.openOrders.map(_orderToMap).toList(),
        'fetchedAt': s.fetchedAt,
        'isStale': s.isStale,
      };

  static Map<String, dynamic> _positionToMap(PerpPosition p) => {
        'coin': p.coin,
        'side': p.side,
        'size': p.size,
        'entryPx': p.entryPx,
        'markPx': p.markPx,
        'liqPx': p.liqPx,
        'liqDistancePct': p.liqDistancePct,
        'liqRisk': p.liqRisk,
        'unrealizedPnl': p.unrealizedPnl,
        'unrealizedPnlPct': p.unrealizedPnlPct,
        'leverage': p.leverage,
        'marginUsed': p.marginUsed,
        'maxLeverage': p.maxLeverage,
      };

  static Map<String, dynamic> _spotToMap(SpotBalance b) => {
        'coin': b.coin,
        'iconUrl': b.iconUrl,
        'total': b.total,
        'hold': b.hold,
        'available': b.available,
        'markPx': b.markPx,
        'usdValue': b.usdValue,
        'allocationPct': b.allocationPct,
      };

  static Map<String, dynamic> _orderToMap(OpenOrder o) => {
        'coin': o.coin,
        'side': o.side,
        'size': o.size,
        'limitPx': o.limitPx,
        'orderType': o.orderType,
        'oid': o.oid,
        'timestamp': o.timestamp,
      };

  static Map<String, dynamic> _historyToMap(PortfolioHistoryModel h) => {
        'walletAddress': h.walletAddress,
        'fills': h.fills.map(_fillToMap).toList(),
        'totalFills': h.totalFills,
        'fetchedAt': h.fetchedAt,
        'isStale': h.isStale,
      };

  static Map<String, dynamic> _fillToMap(TradeFill f) => {
        'time': f.time,
        'coin': f.coin,
        'side': f.side,
        'px': f.px,
        'sz': f.sz,
        'fee': f.fee,
        'closedPnl': f.closedPnl,
        'dir': f.dir,
        'hash': f.hash,
      };
}
