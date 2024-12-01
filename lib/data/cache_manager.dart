import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheManager {
  final SharedPreferences prefs;

  CacheManager(this.prefs);

  static const String _servicesKey = 'services';
  static const String _timestampKey = 'cache_timestamp';
  static const String _hashKey = 'cache_hash';

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

  /// Save cache hash
  Future<void> saveHash(String hash) async {
    try {
      await prefs.setString(_hashKey, hash);
    } catch (e) {
      throw Exception('Failed to save cache hash: $e');
    }
  }

  /// Get cache hash
  String? getHash() {
    try {
      return prefs.getString(_hashKey);
    } catch (e) {
      throw Exception('Failed to retrieve cache hash: $e');
    }
  }

  /// Check if the cache is expired
  bool isCacheExpired({Duration expiryDuration = const Duration(days: 1)}) {
    try {
      final cacheTimestamp = prefs.getInt(_timestampKey);
      if (cacheTimestamp == null) return true;

      final cacheAge = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(cacheTimestamp),
      );
      return cacheAge > expiryDuration;
    } catch (e) {
      throw Exception('Failed to check cache expiration: $e');
    }
  }

  /// Clear the cache
  Future<void> clearCache() async {
    try {
      await prefs.remove(_servicesKey);
      await prefs.remove(_timestampKey);
      await prefs.remove(_hashKey);
    } catch (e) {
      throw Exception('Failed to clear cache: $e');
    }
  }

  /// Get the last cache update timestamp
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
}
