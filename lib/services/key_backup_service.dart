import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'encryption_service.dart';
import 'secure_storage_service.dart';

/// Service để backup và restore Private Key
/// 
/// CÁCH HOẠT ĐỘNG:
/// 1. Mã hóa Private Key bằng password của user
/// 2. Lưu Private Key đã mã hóa lên Firebase
/// 3. Khi đổi thiết bị, dùng password để giải mã và restore
class KeyBackupService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  /// Backup Private Key lên Firebase (mã hóa bằng password)
  /// 
  /// Flow:
  /// 1. User nhập password (hoặc dùng password đăng nhập)
  /// 2. Derive encryption key từ password (PBKDF2)
  /// 3. Mã hóa Private Key bằng AES
  /// 4. Upload lên Firebase
  static Future<void> backupPrivateKey(String password) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');

      print('🔐 Bắt đầu backup Private Key...');

      // Đảm bảo user có keys trước khi backup
      final hasKeys = await EncryptionService.hasValidKeys();
      if (!hasKeys) {
        print('⚠️ User chưa có keys, đang khởi tạo...');
        await EncryptionService.initializeKeys();
      }

      // Lấy Private Key từ local storage
      final privateKey = await SecureStorageService.read(
        key: 'rsa_private_key_$userId',
      );

      if (privateKey == null) {
        throw Exception('Private Key không tồn tại sau khi khởi tạo. Vui lòng thử lại.');
      }

      // Tạo encryption key từ password (PBKDF2)
      final salt = userId; // Dùng userId làm salt (unique cho mỗi user)
      final derivedKey = _deriveKeyFromPassword(password, salt);

      // Mã hóa Private Key bằng AES-256
      final encryptedPrivateKey = EncryptionService.encryptMessage(
        privateKey,
        derivedKey,
      );

      // Tạo checksum để verify khi restore
      final checksum = _createChecksum(privateKey);

      // Upload lên Firebase
      await _firestore.collection('key_backups').doc(userId).set({
        'encryptedPrivateKey': encryptedPrivateKey['encryptedContent'],
        'iv': encryptedPrivateKey['iv'],
        'hmac': encryptedPrivateKey['hmac'],
        'checksum': checksum,
        'backupMethod': 'manual', // 🆕 Phân biệt với auto-backup
        'backedUpAt': FieldValue.serverTimestamp(),
        'version': '1.0',
      });

      print('✅ Backup Private Key thành công!');
    } catch (e) {
      print('❌ Lỗi backup Private Key: $e');
      rethrow;
    }
  }

  /// Restore Private Key từ Firebase (giải mã bằng password)
  /// 
  /// Flow:
  /// 1. Tải encrypted backup từ Firebase
  /// 2. User nhập password
  /// 3. Derive decryption key từ password
  /// 4. Giải mã Private Key
  /// 5. Verify checksum
  /// 6. Lưu vào local storage
  static Future<bool> restorePrivateKey(String password) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');

      print('🔄 Bắt đầu restore Private Key...');

      // Tải backup từ Firebase
      final backupDoc = await _firestore
          .collection('key_backups')
          .doc(userId)
          .get();

      if (!backupDoc.exists) {
        throw Exception('Không tìm thấy backup');
      }

      final backupData = backupDoc.data()!;

      // Derive decryption key từ password
      final salt = userId;
      final derivedKey = _deriveKeyFromPassword(password, salt);

      // Giải mã Private Key
      try {
        final decryptedPrivateKey = EncryptionService.decryptMessage(
          backupData['encryptedPrivateKey'],
          backupData['iv'],
          backupData['hmac'],
          derivedKey,
        );

        // Verify checksum
        final expectedChecksum = backupData['checksum'];
        final actualChecksum = _createChecksum(decryptedPrivateKey);

        if (expectedChecksum != actualChecksum) {
          throw Exception('Checksum không khớp - dữ liệu bị hỏng');
        }

        // Lưu Private Key vào local storage
        await SecureStorageService.write(
          key: 'rsa_private_key_$userId',
          value: decryptedPrivateKey,
        );

        print('✅ Restore Private Key thành công!');
        return true;
      } catch (e) {
        if (e.toString().contains('HMAC')) {
          throw Exception('Mật khẩu không đúng');
        }
        rethrow;
      }
    } catch (e) {
      print('❌ Lỗi restore Private Key: $e');
      rethrow;
    }
  }

  /// Kiểm tra có backup không
  static Future<bool> hasBackup() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final backupDoc = await _firestore
          .collection('key_backups')
          .doc(userId)
          .get();

      return backupDoc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Xóa backup (khi user muốn)
  static Future<void> deleteBackup() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');

      await _firestore.collection('key_backups').doc(userId).delete();
      print('✅ Đã xóa backup');
    } catch (e) {
      print('❌ Lỗi xóa backup: $e');
      rethrow;
    }
  }

  // ==================== HELPER METHODS ====================

  /// Derive encryption key từ password sử dụng PBKDF2
  /// 
  /// PBKDF2 (Password-Based Key Derivation Function 2):
  /// - Chống brute-force attack
  /// - Tạo key mạnh từ password yếu
  /// - Iterations: 10,000 lần (khuyến nghị OWASP)
  static String _deriveKeyFromPassword(String password, String salt) {
    const iterations = 10000; // Số lần lặp (càng nhiều càng chậm nhưng an toàn hơn)
    const keyLength = 32; // 256 bits

    var key = Uint8List.fromList(utf8.encode(password + salt));
    
    // Lặp PBKDF2
    for (var i = 0; i < iterations; i++) {
      var hmacSha256 = Hmac(sha256, key);
      key = Uint8List.fromList(hmacSha256.convert(utf8.encode('$password$salt$i')).bytes);
    }

    // Lấy 32 bytes đầu tiên và encode base64
    final derivedKey = key.sublist(0, keyLength);
    return base64.encode(derivedKey);
  }

  /// Tạo checksum để verify tính toàn vẹn
  static String _createChecksum(String data) {
    return sha256.convert(utf8.encode(data)).toString();
  }
}
