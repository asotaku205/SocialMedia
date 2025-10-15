import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt hide SecureRandom;
import 'package:pointycastle/export.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'secure_storage_service.dart';
import 'web_key_backup_service.dart';

/// Custom exception khi private key không tìm thấy
class PrivateKeyNotFoundException implements Exception {
  final String message;
  PrivateKeyNotFoundException(this.message);

  @override
  String toString() => message;
}

class EncryptionService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  // 🔒 Lock để tránh race condition khi nhiều threads cùng gọi initializeKeys()
  static final Map<String, Future<void>?> _keyGenerationLocks = {};

  // Lưu khóa theo userId để mỗi user có khóa riêng
  static String _getPrivateKeyKey(String userId) => 'rsa_private_key_$userId';
  static String _getPublicKeyKey(String userId) => 'rsa_public_key_$userId';

  /// Khởi tạo RSA key pair cho user
  ///
  /// Web: Sử dụng 1024-bit key (nhanh hơn nhưng chạy trên UI thread - có thể lag)
  /// Native: Sử dụng 2048-bit key trong isolate (an toàn hơn, không block UI)
  ///
  /// Trả về true nếu cần generate key mới (để UI có thể hiển thị loading)
  static Future<bool> needsKeyGeneration() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;

    final existingPrivateKey = await SecureStorageService.read(
      key: _getPrivateKeyKey(userId),
    );
    return existingPrivateKey == null;
  }

  static Future<void> initializeKeys() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      print('❌ No user logged in');
      return;
    }

    // 🔒 Kiểm tra xem có operation đang chạy cho user này không
    if (_keyGenerationLocks[userId] != null) {
      print('⏳ Key generation already in progress for $userId, waiting...');
      await _keyGenerationLocks[userId];
      print('✅ Key generation completed (waited)');
      return;
    }

    // Tạo lock future để các lời gọi tiếp theo phải đợi
    final lockCompleter = Completer<void>();
    _keyGenerationLocks[userId] = lockCompleter.future;

    try {

      final existingPrivateKey = await SecureStorageService.read(
        key: _getPrivateKeyKey(userId),
      );
      if (existingPrivateKey != null) {
        print('✅ Keys already exist for user $userId');
        // Verify the key format is valid
        try {
          _decodePrivateKeyFromPem(existingPrivateKey);
          print('✅ Existing private key is valid');
          // 🔓 Complete lock trước khi return!
          lockCompleter.complete();
          return;
        } catch (e) {
          print('⚠️ Existing private key is invalid: $e');
          print('Will try to restore from backup or regenerate...');
          // Continue to check backup
        }
      }

      // 🆕 Thử auto-restore từ Firebase trước (TẤT CẢ platforms)
      print('🔍 Attempting auto-restore from Firebase...');
      final restoredKeys = await WebKeyBackupService.autoRestoreKeys();
      if (restoredKeys != null) {
        print('✅ Keys auto-restored from Firebase!');
        // Lưu vào local storage
        await SecureStorageService.write(
          key: _getPrivateKeyKey(userId),
          value: restoredKeys['privateKey']!,
        );
        await SecureStorageService.write(
          key: _getPublicKeyKey(userId),
          value: restoredKeys['publicKey']!,
        );
        // 🔓 Complete lock trước khi return!
        lockCompleter.complete();
        return;
      }
      print('ℹ️ No auto-backup found, will generate new keys...');

      print('🔑 Generating new RSA key pair for user $userId...');

      // Web không hỗ trợ isolates, phải chạy đồng bộ
      // Mobile/Desktop có thể dùng compute() để chạy trong background
      final Map<String, String> keyPair;
      if (kIsWeb) {
        // Trên Web: Chạy đồng bộ nhưng dùng 1024-bit cho nhanh hơn (2-3 giây)
        print('🌐 Running on Web - generating 1024-bit key pair...');
        // Thêm delay nhỏ để UI có thể render loading indicator
        await Future.delayed(Duration(milliseconds: 100));
        keyPair = _generateRSAKeyPair(keySize: 1024);
      } else {
        // Trên Mobile/Desktop: Chạy trong isolate với 2048-bit (5-10 giây)
        print(
          '📱 Running on native platform - generating 2048-bit key pair in isolate...',
        );
        keyPair = await compute(_generateRSAKeyPairIsolate, 2048);
      }

      // Verify generated keys before saving
      try {
        _decodePrivateKeyFromPem(keyPair['privateKey']!);
        _decodePublicKeyFromPem(keyPair['publicKey']!);
        print('✅ Generated keys are valid');
      } catch (e) {
        print('❌ Generated keys are invalid: $e');
        throw Exception('Failed to generate valid encryption keys');
      }

      // Lưu khóa theo userId
      await SecureStorageService.write(
        key: _getPrivateKeyKey(userId),
        value: keyPair['privateKey']!,
      );
      await SecureStorageService.write(
        key: _getPublicKeyKey(userId),
        value: keyPair['publicKey']!,
      );

      await _firestore.collection('users').doc(userId).update({
        'publicKey': keyPair['publicKey']!,
        'publicKeyUpdatedAt': FieldValue.serverTimestamp(),
      });

      // 🆕 Tự động backup keys lên Firebase cho TẤT CẢ platforms
      // Điều này bảo vệ user khỏi mất keys khi xóa app (Mobile) hoặc clear cache (Web)
      print('🔐 Auto-backing up keys to Firebase...');
      try {
        await WebKeyBackupService.autoBackupKeys(
          privateKey: keyPair['privateKey']!,
          publicKey: keyPair['publicKey']!,
        );
        print('✅ Keys auto-backed up successfully!');
      } catch (e) {
        print('⚠️ Failed to auto-backup keys: $e');
        // Không throw error - backup tự động không nên block quá trình đăng ký
      }

      print(
        '✅ RSA key pair generated and saved successfully for user $userId!',
      );

      // 🔓 Hoàn thành lock - cho phép các threads khác tiếp tục
      lockCompleter.complete();
    } catch (e) {
      print('❌ Error initializing keys: $e');
      // 🔓 Nếu có lỗi, vẫn phải complete để không lock vĩnh viễn
      lockCompleter.completeError(e);
      rethrow;
    } finally {
      // 🧹 Cleanup lock sau khi hoàn thành
      _keyGenerationLocks.remove(userId);
    }
  }

  /// Kiểm tra xem user hiện tại có encryption keys hợp lệ chưa
  static Future<bool> hasValidKeys() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final privateKeyPem = await SecureStorageService.read(
        key: _getPrivateKeyKey(userId),
      );
      final publicKeyPem = await SecureStorageService.read(
        key: _getPublicKeyKey(userId),
      );

      if (privateKeyPem == null || publicKeyPem == null) {
        return false;
      }

      // Verify keys can be decoded
      _decodePrivateKeyFromPem(privateKeyPem);
      _decodePublicKeyFromPem(publicKeyPem);

      return true;
    } catch (e) {
      print('❌ Keys validation failed: $e');
      return false;
    }
  }

  // Top-level function để chạy trong isolate (chỉ dùng cho native platforms)
  static Map<String, String> _generateRSAKeyPairIsolate(int keySize) {
    return _generateRSAKeyPair(keySize: keySize);
  }

  static Map<String, String> _generateRSAKeyPair({int keySize = 2048}) {
    final secureRandom = _getSecureRandom();
    final rsaKeyGenerator = RSAKeyGenerator()
      ..init(
        ParametersWithRandom(
          RSAKeyGeneratorParameters(BigInt.from(65537), keySize, 64),
          secureRandom,
        ),
      );

    final pair = rsaKeyGenerator.generateKeyPair();
    final publicKey = pair.publicKey as RSAPublicKey;
    final privateKey = pair.privateKey as RSAPrivateKey;

    return {
      'publicKey': _encodePublicKeyToPem(publicKey),
      'privateKey': _encodePrivateKeyToPem(privateKey),
    };
  }

  static String _encodePublicKeyToPem(RSAPublicKey publicKey) {
    final modulus = base64.encode(_encodeBigInt(publicKey.modulus!));
    final exponent = base64.encode(_encodeBigInt(publicKey.exponent!));
    return 'PUBLIC:$modulus:$exponent';
  }

  static String _encodePrivateKeyToPem(RSAPrivateKey privateKey) {
    final modulus = base64.encode(_encodeBigInt(privateKey.modulus!));
    final exponent = base64.encode(_encodeBigInt(privateKey.exponent!));
    final privateExponent = base64.encode(
      _encodeBigInt(privateKey.privateExponent!),
    );
    final p = base64.encode(_encodeBigInt(privateKey.p!));
    final q = base64.encode(_encodeBigInt(privateKey.q!));
    return 'PRIVATE:$modulus:$exponent:$privateExponent:$p:$q';
  }

  static RSAPublicKey _decodePublicKeyFromPem(String pem) {
    final parts = pem.split(':');
    final modulus = _decodeBigInt(base64.decode(parts[1]));
    final exponent = _decodeBigInt(base64.decode(parts[2]));
    return RSAPublicKey(modulus, exponent);
  }

  static RSAPrivateKey _decodePrivateKeyFromPem(String pem) {
    try {
      final parts = pem.split(':');
      if (parts.length < 6) {
        throw Exception(
          'Invalid private key format: expected 6 parts, got ${parts.length}',
        );
      }

      final modulus = _decodeBigInt(base64.decode(parts[1]));
      // parts[2] is public exponent - not needed for RSAPrivateKey constructor
      final privateExponent = _decodeBigInt(base64.decode(parts[3]));
      final p = _decodeBigInt(base64.decode(parts[4]));
      final q = _decodeBigInt(base64.decode(parts[5]));

      return RSAPrivateKey(modulus, privateExponent, p, q);
    } catch (e) {
      print('Error decoding private key from PEM: $e');
      print('PEM format: ${pem.substring(0, min(50, pem.length))}...');
      rethrow;
    }
  }

  static Uint8List _encodeBigInt(BigInt number) {
    final bytes = (number.toRadixString(16).length / 2).ceil();
    final result = Uint8List(bytes);
    for (var i = 0; i < bytes; i++) {
      result[bytes - 1 - i] = (number & BigInt.from(0xff)).toInt();
      number = number >> 8;
    }
    return result;
  }

  static BigInt _decodeBigInt(List<int> bytes) {
    var result = BigInt.zero;
    for (var byte in bytes) {
      result = (result << 8) | BigInt.from(byte);
    }
    return result;
  }

  static SecureRandom _getSecureRandom() {
    final secureRandom = FortunaRandom();
    final random = Random.secure();
    final seeds = List<int>.generate(32, (_) => random.nextInt(256));
    secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));
    return secureRandom;
  }

  static String generateSessionKey() {
    final random = Random.secure();
    final key = List<int>.generate(32, (_) => random.nextInt(256));
    return base64.encode(key);
  }

  static Future<String> getOrCreateSessionKey(
    String chatId,
    String otherUserId,
  ) async {
    try {
      print('📱 Getting or creating session key for chat: $chatId');
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();

      if (chatDoc.exists) {
        final data = chatDoc.data();
        if (data != null && data.containsKey('sessionKeys')) {
          final sessionKeys = data['sessionKeys'] as Map<String, dynamic>;
          final userId = _auth.currentUser?.uid;

          if (userId != null && sessionKeys.containsKey(userId)) {
            print('🔓 Found existing session key, decrypting...');
            try {
              return await _decryptSessionKey(sessionKeys[userId] as String);
            } catch (e) {
              print('⚠️ Failed to decrypt existing session key: $e');
              print(
                'This might be because private key is missing or corrupted',
              );
              print('Will try to regenerate session key if possible...');

              // Nếu không giải mã được, thử tạo lại session key
              // Nhưng chỉ nếu người dùng hiện tại có private key
              final privateKey = await SecureStorageService.read(
                key: _getPrivateKeyKey(userId),
              );
              if (privateKey == null) {
                print('❌ Cannot decrypt: Private key is missing');
                throw Exception(
                  'Cannot read messages: Your encryption key is missing. Please:\n'
                  '1. Go to Settings > Backup Private Key\n'
                  '2. Restore your key from backup\n'
                  'If you don\'t have a backup, you won\'t be able to read old messages.',
                );
              }
              // Nếu có private key nhưng vẫn lỗi, có thể do format key sai
              rethrow;
            }
          } else {
            print(
              '⚠️ Session key exists but not for current user - will create new one',
            );
          }
        }
      }

      print('🆕 Creating new session key...');
      final sessionKey = generateSessionKey();
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) {
        throw Exception('User not logged in');
      }

      // Đảm bảo user hiện tại có keys
      final currentUserPrivateKey = await SecureStorageService.read(
        key: _getPrivateKeyKey(currentUserId),
      );
      if (currentUserPrivateKey == null) {
        print('⚠️ Current user does not have private key, initializing...');
        await initializeKeys();
      }

      // Lấy public key của người dùng khác
      final otherUserDoc = await _firestore
          .collection('users')
          .doc(otherUserId)
          .get();
      final otherUserPublicKey = otherUserDoc.data()?['publicKey'] as String?;

      // Lấy public key của user hiện tại
      final currentUserPublicKey = await SecureStorageService.read(
        key: _getPublicKeyKey(currentUserId),
      );

      if (otherUserPublicKey == null) {
        print('❌ Other user ($otherUserId) does not have a public key');
        throw Exception(
          'Recipient has not set up encryption keys yet. Please ask them to open the app first.',
        );
      }

      if (currentUserPublicKey == null) {
        print(
          '❌ Current user ($currentUserId) does not have a public key after initialization',
        );
        throw Exception(
          'Failed to initialize encryption keys. Please try again or contact support.',
        );
      }

      print('🔐 Encrypting session key for both users...');
      final encryptedForCurrentUser = _encryptWithPublicKey(
        sessionKey,
        currentUserPublicKey,
      );
      final encryptedForOtherUser = _encryptWithPublicKey(
        sessionKey,
        otherUserPublicKey,
      );

      print('💾 Saving encrypted session keys to Firestore...');
      await _firestore.collection('chats').doc(chatId).set({
        'sessionKeys': {
          currentUserId: encryptedForCurrentUser,
          otherUserId: encryptedForOtherUser,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'participants': [currentUserId, otherUserId],
      }, SetOptions(merge: true));

      print('✅ Session key created and saved successfully');
      return sessionKey;
    } catch (e) {
      print('❌ Error getting/creating session key: $e');
      print('Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  static String _encryptWithPublicKey(String data, String publicKeyPem) {
    try {
      print('🔐 Encrypting with public key...');
      final publicKey = _decodePublicKeyFromPem(publicKeyPem);
      final encrypter = encrypt.Encrypter(encrypt.RSA(publicKey: publicKey));
      final encrypted = encrypter.encrypt(data).base64;
      print('✅ Data encrypted successfully');
      return encrypted;
    } catch (e) {
      print('❌ Error encrypting with public key: $e');
      print(
        'Public key format: ${publicKeyPem.substring(0, min(50, publicKeyPem.length))}...',
      );
      rethrow;
    }
  }

  static Future<String> _decryptSessionKey(String encryptedData) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) {
        throw Exception('User not logged in');
      }

      final privateKeyPem = await SecureStorageService.read(
        key: _getPrivateKeyKey(currentUserId),
      );
      if (privateKeyPem == null) {
        print('❌ Private key not found for user $currentUserId');

        // Kiểm tra xem có backup không
        final hasBackup = await _checkHasBackup();
        if (hasBackup) {
          print(
            '💡 Found backup on Firebase - User needs to restore their private key',
          );
          throw PrivateKeyNotFoundException(
            'Your encryption keys are missing. Please restore them from Settings > Security > Backup Private Key to read encrypted messages.',
          );
        } else {
          print('⚠️ No backup found - Keys may have been lost permanently');
          throw PrivateKeyNotFoundException(
            'Your encryption keys are missing and no backup was found. You may not be able to read old encrypted messages. New messages will work after app restart.',
          );
        }
      }

      print('🔑 Decrypting session key for user $currentUserId...');
      final privateKey = _decodePrivateKeyFromPem(privateKeyPem);
      final encrypter = encrypt.Encrypter(encrypt.RSA(privateKey: privateKey));
      final decrypted = encrypter.decrypt64(encryptedData);
      print('✅ Session key decrypted successfully');
      return decrypted;
    } catch (e) {
      if (e is PrivateKeyNotFoundException) {
        rethrow;
      }
      print('❌ Error decrypting session key: $e');
      rethrow;
    }
  }

  /// Kiểm tra xem user có backup trên Firebase không
  static Future<bool> _checkHasBackup() async {
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

  static Map<String, String> encryptMessage(
    String plainText,
    String sessionKey,
  ) {
    try {
      final keyBytes = base64.decode(sessionKey);
      final key = encrypt.Key(Uint8List.fromList(keyBytes));
      final iv = encrypt.IV.fromSecureRandom(16);

      final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.cbc),
      );
      final encrypted = encrypter.encrypt(plainText, iv: iv);

      final hmacKey = Hmac(sha256, keyBytes);
      final hmacData = hmacKey.convert(
        utf8.encode(encrypted.base64 + iv.base64),
      );

      return {
        'encryptedContent': encrypted.base64,
        'iv': iv.base64,
        'hmac': hmacData.toString(),
      };
    } catch (e) {
      print('Error encrypting message: $e');
      rethrow;
    }
  }

  static String decryptMessage(
    String encryptedContent,
    String ivString,
    String hmac,
    String sessionKey,
  ) {
    try {
      final keyBytes = base64.decode(sessionKey);
      final key = encrypt.Key(Uint8List.fromList(keyBytes));

      final hmacKey = Hmac(sha256, keyBytes);
      final expectedHmac = hmacKey.convert(
        utf8.encode(encryptedContent + ivString),
      );

      if (expectedHmac.toString() != hmac) {
        throw Exception('HMAC verification failed');
      }

      final iv = encrypt.IV.fromBase64(ivString);
      final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.cbc),
      );
      final encrypted = encrypt.Encrypted.fromBase64(encryptedContent);
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      print('Error decrypting message: $e');
      rethrow;
    }
  }

  static String generateFingerprint(String content, String timestamp) {
    final combined = '$content:$timestamp';
    final bytes = utf8.encode(combined);
    return sha256.convert(bytes).toString();
  }

  /// XÓA KHÓA CHỈ KHI CẦN THIẾT (không nên xóa khi logout thông thường)
  /// Chỉ xóa khi: reset account, xóa thiết bị tin cậy, etc.
  static Future<void> clearKeys({String? userId}) async {
    // Đã vô hiệu hóa: Không bao giờ xóa khóa mã hóa để đảm bảo luôn xem được tin nhắn cũ
    // final targetUserId = userId ?? _auth.currentUser?.uid;
    // if (targetUserId == null) return;
    // print('WARNING: Clearing encryption keys for user $targetUserId');
    // await _secureStorage.delete(key: _getPrivateKeyKey(targetUserId));
    // await _secureStorage.delete(key: _getPublicKeyKey(targetUserId));
    return;
  }

  static Future<String?> getMyPublicKey() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;
    return await SecureStorageService.read(key: _getPublicKeyKey(userId));
  }

  static Future<String?> getPublicKey(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      return userDoc.data()?['publicKey'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// Kiểm tra trạng thái encryption keys của user hiện tại
  /// Trả về Map với các thông tin:
  /// - hasPrivateKey: có private key trong local storage không
  /// - hasPublicKey: có public key trong local storage không
  /// - hasBackup: có backup trên Firebase không
  /// - needsRestore: cần restore key không (có backup nhưng không có local key)
  static Future<Map<String, bool>> checkKeysStatus() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return {
        'hasPrivateKey': false,
        'hasPublicKey': false,
        'hasBackup': false,
        'needsRestore': false,
      };
    }

    final privateKey = await SecureStorageService.read(
      key: _getPrivateKeyKey(userId),
    );
    final publicKey = await SecureStorageService.read(key: _getPublicKeyKey(userId));
    final hasBackup = await _checkHasBackup();

    return {
      'hasPrivateKey': privateKey != null,
      'hasPublicKey': publicKey != null,
      'hasBackup': hasBackup,
      'needsRestore': hasBackup && privateKey == null,
    };
  }

  /// 🆕 Migrate old users: Tự động backup keys nếu user cũ chưa có backup
  /// Được gọi mỗi lần login để đảm bảo user cũ cũng có backup
  /// Hoạt động trên TẤT CẢ platforms (Web, Mobile, Desktop)
  static Future<void> migrateOldUserKeys() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      // Kiểm tra xem đã có backup chưa
      final hasBackup = await WebKeyBackupService.hasAutoBackup();
      if (hasBackup) {
        print('✅ User already has backup, no migration needed');
        return;
      }

      // Kiểm tra xem có keys trong local storage không
      final privateKey = await SecureStorageService.read(
        key: _getPrivateKeyKey(userId),
      );
      final publicKey = await SecureStorageService.read(
        key: _getPublicKeyKey(userId),
      );

      if (privateKey == null || publicKey == null) {
        print('ℹ️ No local keys to migrate');
        return;
      }

      // User cũ có keys nhưng chưa có backup → Tự động backup
      print('🔄 Migrating old user keys to Firebase...');
      await WebKeyBackupService.autoBackupKeys(
        privateKey: privateKey,
        publicKey: publicKey,
      );
      print('✅ Old user keys migrated successfully!');
    } catch (e) {
      print('⚠️ Failed to migrate old user keys: $e');
      // Không throw error vì đây chỉ là migration tự động
    }
  }
}
