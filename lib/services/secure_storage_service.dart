import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service để lưu trữ dữ liệu an toàn
/// - Trên Mobile/Desktop: Sử dụng FlutterSecureStorage (Keychain/Keystore)
/// - Trên Web: Sử dụng SharedPreferences (persistent) + FlutterSecureStorage (fallback)
class SecureStorageService {
  static final FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    webOptions: WebOptions(
      dbName: 'social_media_secure_db',
      publicKey: 'social_media_public_key',
    ),
  );

  // Cache in-memory để tránh đọc nhiều lần (đặc biệt trên Web)
  static final Map<String, String> _memoryCache = {};

  /// Đọc dữ liệu
  static Future<String?> read({required String key}) async {
    try {
      // Kiểm tra memory cache trước
      if (_memoryCache.containsKey(key)) {
        print('📦 Reading from memory cache: $key');
        return _memoryCache[key];
      }

      if (kIsWeb) {
        // Trên Web: Thử nhiều phương pháp
        // 1. Thử đọc từ SharedPreferences (persistent hơn IndexedDB)
        try {
          final prefs = await SharedPreferences.getInstance();
          final value = prefs.getString(key);
          if (value != null && value.isNotEmpty) {
            print('✅ Read from SharedPreferences: $key');
            _memoryCache[key] = value; // Cache vào memory
            return value;
          }
        } catch (e) {
          print('⚠️ SharedPreferences read failed: $e');
        }

        // 2. Fallback: Thử đọc từ FlutterSecureStorage (IndexedDB)
        try {
          final value = await _secureStorage.read(key: key);
          if (value != null && value.isNotEmpty) {
            print('✅ Read from SecureStorage (IndexedDB): $key');
            _memoryCache[key] = value; // Cache vào memory
            // Backup vào SharedPreferences
            try {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString(key, value);
            } catch (_) {}
            return value;
          }
        } catch (e) {
          print('⚠️ SecureStorage read failed: $e');
        }

        print('❌ Key not found in any Web storage: $key');
        return null;
      } else {
        // Trên mobile/desktop: Dùng secure storage native
        final value = await _secureStorage.read(key: key);
        if (value != null) {
          _memoryCache[key] = value; // Cache vào memory
        }
        return value;
      }
    } catch (e) {
      print('❌ Error reading from secure storage: $e');
      return null;
    }
  }

  /// Ghi dữ liệu
  static Future<void> write({
    required String key,
    required String value,
  }) async {
    try {
      // Lưu vào memory cache ngay lập tức
      _memoryCache[key] = value;

      if (kIsWeb) {
        // Trên Web: Lưu vào CẢ HAI nơi để đảm bảo persistence
        bool writeSuccess = false;

        // 1. Lưu vào SharedPreferences (ưu tiên - persistent nhất)
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(key, value);
          print('✅ Written to SharedPreferences: $key');
          writeSuccess = true;
        } catch (e) {
          print('⚠️ SharedPreferences write failed: $e');
        }

        // 2. Lưu vào FlutterSecureStorage (backup)
        try {
          await _secureStorage.write(key: key, value: value);
          print('✅ Written to SecureStorage: $key');
          writeSuccess = true;
        } catch (e) {
          print('⚠️ SecureStorage write failed: $e');
        }

        if (!writeSuccess) {
          throw Exception('Failed to write to any Web storage');
        }
      } else {
        // Trên mobile/desktop: Dùng secure storage native
        await _secureStorage.write(key: key, value: value);
      }
    } catch (e) {
      print('❌ Error writing to secure storage: $e');
      rethrow;
    }
  }

  /// Xóa dữ liệu
  static Future<void> delete({required String key}) async {
    try {
      // Xóa khỏi memory cache
      _memoryCache.remove(key);

      if (kIsWeb) {
        // Xóa khỏi cả hai nơi trên Web
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove(key);
        } catch (_) {}
        
        try {
          await _secureStorage.delete(key: key);
        } catch (_) {}
      } else {
        await _secureStorage.delete(key: key);
      }
    } catch (e) {
      print('❌ Error deleting from secure storage: $e');
    }
  }

  /// Xóa tất cả dữ liệu
  static Future<void> deleteAll() async {
    try {
      // Xóa memory cache
      _memoryCache.clear();

      if (kIsWeb) {
        // Xóa khỏi cả hai nơi trên Web
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.clear();
        } catch (_) {}
        
        try {
          await _secureStorage.deleteAll();
        } catch (_) {}
      } else {
        await _secureStorage.deleteAll();
      }
    } catch (e) {
      print('❌ Error deleting all from secure storage: $e');
    }
  }

  /// Kiểm tra xem key có tồn tại không
  static Future<bool> containsKey({required String key}) async {
    try {
      final value = await read(key: key);
      return value != null;
    } catch (e) {
      return false;
    }
  }

  /// 🆕 Clear memory cache cho specific user (khi logout)
  /// Điều này quan trọng khi có nhiều accounts trên cùng thiết bị
  static void clearMemoryCacheForUser(String userId) {
    final keysToRemove = <String>[];
    
    // Tìm tất cả keys liên quan đến userId
    for (final key in _memoryCache.keys) {
      if (key.contains(userId)) {
        keysToRemove.add(key);
      }
    }
    
    // Xóa khỏi cache
    for (final key in keysToRemove) {
      _memoryCache.remove(key);
      print('🗑️ Cleared memory cache for key: $key');
    }
    
    print('✅ Cleared ${keysToRemove.length} cached items for user $userId');
  }

  /// 🆕 Clear toàn bộ memory cache (khi logout tất cả)
  static void clearAllMemoryCache() {
    final count = _memoryCache.length;
    _memoryCache.clear();
    print('✅ Cleared all memory cache ($count items)');
  }
}
