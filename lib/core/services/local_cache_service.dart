import 'package:hive_flutter/hive_flutter.dart';

class LocalCacheService {
  LocalCacheService._();

  static late Box _settingsBox;
  static late Box _cacheBox;

  static Future<void> initialize() async {
    await Hive.initFlutter();
    _settingsBox = await Hive.openBox('settings');
    _cacheBox = await Hive.openBox('cache');
  }

  // Settings
  static T? getSetting<T>(String key) => _settingsBox.get(key) as T?;
  static Future<void> setSetting(String key, dynamic value) =>
      _settingsBox.put(key, value);

  // Cache
  static T? getCache<T>(String key) => _cacheBox.get(key) as T?;
  static Future<void> setCache(String key, dynamic value) =>
      _cacheBox.put(key, value);
  static Future<void> clearCache() => _cacheBox.clear();
}
