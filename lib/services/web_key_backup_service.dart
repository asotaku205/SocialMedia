import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

/// Service tự động backup encryption keys cho Web
/// Vì Web không có secure storage đáng tin cậy, keys được tự động backup lên Firebase
/// với mã hóa dựa trên user password
class WebKeyBackupService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  /// Tự động backup keys lên Firebase khi user tạo keys
  /// Password = hash của email + uid (deterministic)
  /// Hoạt động trên TẤT CẢ platforms (Web, Mobile, Desktop)
  static Future<void> autoBackupKeys({
    required String privateKey,
    required String publicKey,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        print('⚠️ Cannot auto-backup: User or email is null');
        return;
      }

      final userId = user.uid;
      final password = _generateDeterministicPassword(user.email!, userId);

      final platform = kIsWeb ? 'Web' : 'Mobile/Desktop';
      print('🔐 Auto-backing up keys to Firebase for $platform...');

      // Mã hóa private key với password
      final encryptedPrivateKey = _encryptWithPassword(privateKey, password);

      // Lưu lên Firebase
      await _firestore.collection('key_backups').doc(userId).set({
        'encryptedPrivateKey': encryptedPrivateKey,
        'publicKey': publicKey,
        'backupMethod': 'auto', // Đổi từ 'auto_web' thành 'auto' (hỗ trợ tất cả platforms)
        'platform': platform, // Thêm thông tin platform
        'createdAt': FieldValue.serverTimestamp(),
        'lastRestoredAt': null,
      });

      print('✅ Keys auto-backed up successfully for $platform');
    } catch (e) {
      print('❌ Failed to auto-backup keys: $e');
      // Không throw error vì đây chỉ là backup tự động
    }
  }

  /// Auto restore keys từ Firebase khi user login
  /// Hoạt động trên TẤT CẢ platforms (Web, Mobile, Desktop)
  static Future<Map<String, String>?> autoRestoreKeys() async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        print('⚠️ Cannot auto-restore: User or email is null');
        return null;
      }

      final userId = user.uid;
      final password = _generateDeterministicPassword(user.email!, userId);

      print('🔍 Checking for auto-backup on Firebase...');

      final backupDoc = await _firestore
          .collection('key_backups')
          .doc(userId)
          .get();

      if (!backupDoc.exists) {
        print('ℹ️ No auto-backup found on Firebase');
        return null;
      }

      final data = backupDoc.data()!;
      final backupMethod = data['backupMethod'] as String?;
      
      // Kiểm tra loại backup - chấp nhận cả 'auto' và 'auto_web' (backward compatible)
      if (backupMethod != 'auto' && backupMethod != 'auto_web') {
        print('⚠️ Found manual backup (not auto), cannot auto-restore');
        print('💡 User should restore manually from Settings > Backup Private Key');
        return null;
      }

      final encryptedPrivateKey = data['encryptedPrivateKey'] as String?;
      final publicKey = data['publicKey'] as String?;

      if (encryptedPrivateKey == null || publicKey == null) {
        print('⚠️ Backup data is incomplete');
        return null;
      }

      print('🔓 Auto-restoring keys from auto-backup...');

      try {
        // Giải mã private key với deterministic password
        final privateKey = _decryptWithPassword(encryptedPrivateKey, password);

        // Update lastRestoredAt
        await _firestore.collection('key_backups').doc(userId).update({
          'lastRestoredAt': FieldValue.serverTimestamp(),
        });

        print('✅ Keys auto-restored successfully from Firebase');

        return {
          'privateKey': privateKey,
          'publicKey': publicKey,
        };
      } catch (e) {
        print('❌ Failed to decrypt auto-backup: $e');
        print('⚠️ Backup may be corrupted or from different encryption');
        return null;
      }
    } catch (e) {
      print('❌ Failed to auto-restore keys: $e');
      return null;
    }
  }

  /// Tạo password deterministic từ email + uid
  /// Điều này cho phép tự động restore mà không cần user nhập password
  static String _generateDeterministicPassword(String email, String uid) {
    final combined = '$email:$uid:social_media_app_v1';
    final bytes = utf8.encode(combined);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  /// Mã hóa private key với password (PBKDF2 + AES-256)
  static String _encryptWithPassword(String privateKey, String password) {
    // Tạo salt từ password (deterministic)
    final saltBytes = utf8.encode(password.substring(0, 16));
    final salt = Uint8List.fromList(saltBytes);

    // PBKDF2 - derive key từ password
    final key = _deriveKeyFromPassword(password, salt);

    // AES encryption
    final encrypter = encrypt.Encrypter(
      encrypt.AES(encrypt.Key(key)),
    );
    final iv = encrypt.IV.fromLength(16);
    final encrypted = encrypter.encrypt(privateKey, iv: iv);

    return '${encrypted.base64}:${iv.base64}';
  }

  /// Giải mã private key với password
  static String _decryptWithPassword(String encryptedData, String password) {
    final parts = encryptedData.split(':');
    if (parts.length != 2) {
      throw Exception('Invalid encrypted data format');
    }

    final encryptedContent = parts[0];
    final ivBase64 = parts[1];

    // Tạo salt từ password (deterministic)
    final saltBytes = utf8.encode(password.substring(0, 16));
    final salt = Uint8List.fromList(saltBytes);

    // PBKDF2 - derive key từ password
    final key = _deriveKeyFromPassword(password, salt);

    // AES decryption
    final encrypter = encrypt.Encrypter(
      encrypt.AES(encrypt.Key(key)),
    );
    final iv = encrypt.IV.fromBase64(ivBase64);
    final encrypted = encrypt.Encrypted.fromBase64(encryptedContent);

    return encrypter.decrypt(encrypted, iv: iv);
  }

  /// Derive encryption key từ password sử dụng PBKDF2
  static Uint8List _deriveKeyFromPassword(String password, Uint8List salt) {
    final passwordBytes = Uint8List.fromList(utf8.encode(password));
    
    // Simple PBKDF2 implementation using SHA256
    var result = passwordBytes;
    for (var i = 0; i < 10000; i++) {
      final hmac = Hmac(sha256, salt);
      result = Uint8List.fromList(hmac.convert(result).bytes);
    }
    
    // Return first 32 bytes for AES-256
    return Uint8List.fromList(result.take(32).toList());
  }

  /// Kiểm tra xem có auto-backup trên Firebase không
  /// Hoạt động trên TẤT CẢ platforms
  static Future<bool> hasAutoBackup() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final backupDoc = await _firestore
          .collection('key_backups')
          .doc(userId)
          .get();

      final backupMethod = backupDoc.data()?['backupMethod'] as String?;
      
      // Chấp nhận cả 'auto' và 'auto_web' (backward compatible)
      return backupDoc.exists && 
             (backupMethod == 'auto' || backupMethod == 'auto_web');
    } catch (e) {
      return false;
    }
  }
}
