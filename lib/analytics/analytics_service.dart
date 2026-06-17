import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Log Tab Clicks
  static Future<void> logTabClick(String tabName) async {
    await _analytics.logEvent(
      name: 'tab_click',
      parameters: {'tab_name': tabName},
    );
  }

  // Log Category Clicks
  static Future<void> logCategoryClick(String categoryName) async {
    await _analytics.logEvent(
      name: 'category_click',
      parameters: {'category_name': categoryName},
    );
  }

  // Log Ticker Clicks
  static Future<void> logTickerClick(String symbol) async {
    await _analytics.logEvent(
      name: 'ticker_click',
      parameters: {'symbol': symbol},
    );
  }

  // Log Order Book Access
  static Future<void> logOrderBookAccess(String symbol) async {
    await _analytics.logEvent(
      name: 'order_book_access',
      parameters: {'symbol': symbol},
    );
  }

  // Log Recent Activity Access for Ticker Details
  static Future<void> logTickerRecentActivity(String symbol) async {
    await _analytics.logEvent(
      name: 'ticker_recent_activity_access',
      parameters: {'symbol': symbol},
    );
  }

  // Log Coming Soon Feature Clicks
  static Future<void> logFeatureClick(String featureName) async {
    await _analytics.logEvent(
      name: 'feature_click',
      parameters: {'feature_name': featureName},
    );
  }

  // Log Search Queries
  static Future<void> logSearch(String query) async {
    if (query.isEmpty) return;
    await _analytics.logSearch(searchTerm: query);
  }
}
