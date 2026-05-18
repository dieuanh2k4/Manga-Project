import 'dart:convert';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MangaImageCacheManager {
  static const Duration maxCacheAge = Duration(days: 10);
  static const String _cacheName = 'manga_image_cache';
  static const String _metadataKey = 'manga_image_cache_entries';

  static final CacheManager instance = CacheManager(
    Config(
      _cacheName,
      stalePeriod: maxCacheAge,
      maxNrOfCacheObjects: 500,
    ),
  );

  static Future<void> markCached(String cacheKey) async {
    final prefs = await SharedPreferences.getInstance();
    final entries = _readEntries(prefs);
    entries.putIfAbsent(cacheKey, () => DateTime.now().toIso8601String());
    await prefs.setString(_metadataKey, jsonEncode(entries));
  }

  static Future<void> removeExpiredImages() async {
    final prefs = await SharedPreferences.getInstance();
    final entries = _readEntries(prefs);
    if (entries.isEmpty) {
      return;
    }

    final now = DateTime.now();
    final expiredKeys = <String>[];

    for (final entry in entries.entries) {
      final cachedAt = DateTime.tryParse(entry.value);
      if (cachedAt == null || now.difference(cachedAt) >= maxCacheAge) {
        expiredKeys.add(entry.key);
      }
    }

    for (final cacheKey in expiredKeys) {
      await instance.removeFile(cacheKey);
      entries.remove(cacheKey);
    }

    if (expiredKeys.isNotEmpty) {
      await prefs.setString(_metadataKey, jsonEncode(entries));
    }
  }

  static Map<String, String> _readEntries(SharedPreferences prefs) {
    final raw = prefs.getString(_metadataKey);
    if (raw == null || raw.isEmpty) {
      return <String, String>{};
    }

    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return <String, String>{};
    }

    return decoded.map(
      (key, value) => MapEntry(key.toString(), value.toString()),
    );
  }
}
