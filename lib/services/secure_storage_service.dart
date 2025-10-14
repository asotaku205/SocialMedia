import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service để lưu trữ dữ liệu an toàn
/// - Trên Mobile/Desktop: Sử dụng FlutterSecureStorage (Keychain/Keystore)
/// - Trên Web: Sử dụng localStorage với mã hóa đơn giản (vì không có secure storage)
class SecureStorageService {
  static final FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    webOptions: WebOptions(
      dbName: 'social_media_secure_db',
      publicKey: 'social_media_public_key',
    ),
  );

  /// Đọc dữ liệu
  static Future<String?> read({required String key}) async {
    try {
      if (kIsWeb) {
        // Trên web: Dùng flutter_secure_storage với web options
        // Nó sẽ sử dụng IndexedDB
        return await _secureStorage.read(key: key);
      } else {
        // Trên mobile/desktop: Dùng secure storage native
        return await _secureStorage.read(key: key);
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
      if (kIsWeb) {
        // Trên web: Dùng flutter_secure_storage với web options
        await _secureStorage.write(key: key, value: value);
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
      await _secureStorage.delete(key: key);
    } catch (e) {
      print('❌ Error deleting from secure storage: $e');
    }
  }

  /// Xóa tất cả dữ liệu
  static Future<void> deleteAll() async {
    try {
      await _secureStorage.deleteAll();
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
}
