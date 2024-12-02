import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheManager {
  final SharedPreferences prefs;

  CacheManager(this.prefs);

  static const String _servicesKey = 'cached_services';
  static const String _timestampKey = 'cache_timestamp';
  static const String _currentPageKey = 'current_page';

  /// Save services to cache
  Future<void> saveServices(List<Map<String, dynamic>> services) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final jsonData = jsonEncode(services);

      await prefs.setString(_servicesKey, jsonData);
      await prefs.setInt(_timestampKey, timestamp);
    } catch (e) {
      throw Exception('Failed to save services to cache: $e');
    }
  }

  /// Get cached services
  List<Map<String, dynamic>>? getCachedServices() {
    try {
      final cachedData = prefs.getString(_servicesKey);
      if (cachedData != null) {
        return List<Map<String, dynamic>>.from(jsonDecode(cachedData));
      }
      return null;
    } catch (e) {
      throw Exception('Failed to retrieve cached services: $e');
    }
  }

  /// Save the current page to cache
  Future<void> saveCurrentPage(int currentPage) async {
    try {
      await prefs.setInt(_currentPageKey, currentPage);
    } catch (e) {
      throw Exception('Failed to save current page to cache: $e');
    }
  }

  /// Get the current page from cache
  int getCurrentPage() {
    try {
      return prefs.getInt(_currentPageKey) ?? 0; // Default to 0 if no page is cached
    } catch (e) {
      throw Exception('Failed to retrieve current page from cache: $e');
    }
  }

  /// Save the last update timestamp
  Future<void> saveTimestamp() async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      await prefs.setInt(_timestampKey, timestamp);
    } catch (e) {
      throw Exception('Failed to save cache timestamp: $e');
    }
  }

  /// Get the last update timestamp
  DateTime? getLastCacheTimestamp() {
    try {
      final timestamp = prefs.getInt(_timestampKey);
      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to retrieve cache timestamp: $e');
    }
  }

  /// Check if the cache is expired
  bool isCacheExpired({Duration expiryDuration = const Duration(days: 1)}) {
    try {
      final cacheTimestamp = prefs.getInt(_timestampKey);
      if (cacheTimestamp == null) {
        // No timestamp indicates no cache exists; consider it expired
        return true;
      }

      final cacheAge = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(cacheTimestamp),
      );
      return cacheAge > expiryDuration;
    } catch (e) {
      throw Exception('Failed to check cache expiration: ${e.toString()}');
    }
  }
  /// Clear the cache
  Future<void> clearCache() async {
    try {
      await prefs.remove(_servicesKey);
      await prefs.remove(_timestampKey);
      await prefs.remove(_currentPageKey);
    } catch (e) {
      throw Exception('Failed to clear cache: $e');
    }
  }
}
