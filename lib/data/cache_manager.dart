import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/exceptions.dart';

class CacheManager {
  final SharedPreferences prefs;

  CacheManager(this.prefs);

  static const String servicesKey = 'cached_services';
  static const String imageUrlPrefix = 'image_url_';
  static const String cacheTimestampKey = 'cache_timestamp';

  /// Save services to cache
  Future<void> saveServices(List<Map<String, dynamic>> services) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      await prefs.setString(servicesKey, jsonEncode(services));
      await prefs.setInt(cacheTimestampKey, timestamp);
    } catch (e) {
      throw CacheException('Failed to save services: ${e.toString()}');
    }
  }

  /// Get cached services
  Future<List<Map<String, dynamic>>?> getCachedServices() async {
    try {
      final cachedServices = prefs.getString(servicesKey);
      if (cachedServices != null) {
        return List<Map<String, dynamic>>.from(jsonDecode(cachedServices));
      }
    } catch (e) {
      throw CacheException('Failed to load cached services: ${e.toString()}');
    }
    return null;
  }

  /// Save image URL to cache
  Future<void> saveImageUrl(String key, String url) async {
    try {
      await prefs.setString('$imageUrlPrefix$key', url);
    } catch (e) {
      throw CacheException('Failed to save image URL for $key: ${e.toString()}');
    }
  }

  /// Get cached image URL
  Future<String?> getCachedImageUrl(String key) async {
    try {
      return prefs.getString('$imageUrlPrefix$key');
    } catch (e) {
      throw CacheException('Failed to retrieve cached image URL for $key: ${e.toString()}');
    }
  }

  /// Check if cache is expired (e.g., older than 1 day)
  bool isCacheExpired() {
    try {
      final timestamp = prefs.getInt(cacheTimestampKey);
      if (timestamp == null) return true;
      final expiryDuration = const Duration(days: 1);
      final cacheAge = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(timestamp));
      return cacheAge > expiryDuration;
    } catch (e) {
      throw CacheException('Failed to check cache expiration: ${e.toString()}');
    }
  }

  /// Clear cache
  Future<void> clearCache() async {
    await prefs.remove(servicesKey);
    await prefs.remove(cacheTimestampKey);
  }
}
