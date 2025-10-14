import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt hide SecureRandom;
import 'package:pointycastle/export.dart';
import 'package:asn1lib/asn1lib.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'secure_storage_service.dart';

/// Custom exception khi private key không tìm thấy
class PrivateKeyNotFoundException implements Exception {
  final String message;
  PrivateKeyNotFoundException(this.message);

  @override
  String toString() => message;
}

class EncryptionService {

  /// Hàm migrate key cũ (custom) sang chuẩn PEM cho user hiện tại
  /// Gọi hàm này một lần sau khi cập nhật code để đảm bảo user cũ không bị lỗi mã hóa/giải mã
  static Future<void> migrateKeysIfNeeded() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    // Đọc private key cũ
    final privateKeyRaw = await _secureStorage.read(key: _getPrivateKeyKey(userId));
    final publicKeyRaw = await _secureStorage.read(key: _getPublicKeyKey(userId));
    if (privateKeyRaw == null || publicKeyRaw == null) return;

    // Nếu đã là PEM thì bỏ qua
    if (privateKeyRaw.startsWith('-----BEGIN PRIVATE KEY-----') && publicKeyRaw.startsWith('-----BEGIN PUBLIC KEY-----')) {
      print('🔑 Keys đã ở định dạng PEM, không cần migrate.');
      return;
    }

    // Nếu là custom format thì migrate
    try {
      // Parse custom private key
      final parts = privateKeyRaw.split(':');
      if (parts.length < 6) {
        print('❌ Private key không đúng định dạng custom, bỏ qua migrate.');
        return;
      }
      final modulus = base64.decode(parts[1]);
      final exponent = base64.decode(parts[2]);
      final privateExponent = base64.decode(parts[3]);
      final p = base64.decode(parts[4]);
      final q = base64.decode(parts[5]);
      final modulusInt = _bytesToBigInt(modulus);
      final exponentInt = _bytesToBigInt(exponent);
      final privateExponentInt = _bytesToBigInt(privateExponent);
      final pInt = _bytesToBigInt(p);
      final qInt = _bytesToBigInt(q);
      final privKey = RSAPrivateKey(modulusInt, privateExponentInt, pInt, qInt);
      final pubKey = RSAPublicKey(modulusInt, exponentInt);

      // Encode lại sang PEM
      final privateKeyPem = _encodePrivateKeyToPem(privKey);
      final publicKeyPem = _encodePublicKeyToPem(pubKey);

      // Ghi đè lại vào storage
      await _secureStorage.write(key: _getPrivateKeyKey(userId), value: privateKeyPem);
      await _secureStorage.write(key: _getPublicKeyKey(userId), value: publicKeyPem);

      // Update Firestore nếu cần
      await _firestore.collection('users').doc(userId).update({'publicKey': publicKeyPem});

      print('✅ Đã migrate key sang PEM cho user $userId');
    } catch (e) {
      print('❌ Lỗi migrate key: $e');
    }
  }

  static BigInt _bytesToBigInt(List<int> bytes) {
    var result = BigInt.zero;
    for (var byte in bytes) {
      result = (result << 8) | BigInt.from(byte);
    }
    return result;
  }
  static final _secureStorage = FlutterSecureStorage();
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

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
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        print('❌ No user logged in');
        return;
      }

      final existingPrivateKey = await SecureStorageService.read(
        key: _getPrivateKeyKey(userId),
      );
      if (existingPrivateKey != null) {
        print('✅ Keys already exist for user $userId');
        // Verify the key format is valid
        try {
          _decodePrivateKeyFromPem(existingPrivateKey);
          print('✅ Existing private key is valid');
          return;
        } catch (e) {
          print('⚠️ Existing private key is invalid: $e');
          print('Will regenerate new keys...');
          // Continue to generate new keys
        }
      }

      // Kiểm tra có backup trên Firebase không
      print('🔍 Checking for existing backup on Firebase...');
      final backupDoc = await _firestore
          .collection('key_backups')
          .doc(userId)
          .get();
      if (backupDoc.exists) {
        print('⚠️ Found backup on Firebase but no local keys!');
        print(
          '💡 User needs to restore keys manually from Settings > Backup Private Key',
        );
        // Không tự động restore vì cần password
        // User sẽ được nhắc qua BackupReminderDialog
        return;
      }

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
      print(
        '✅ RSA key pair generated and saved successfully for user $userId!',
      );
    } catch (e) {
      print('❌ Error initializing keys: $e');
      rethrow;
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
    final algorithmSeq = ASN1Sequence()
      ..add(ASN1ObjectIdentifier.fromName('rsaEncryption'))
      ..add(ASN1Null());
    final publicKeySeq = ASN1Sequence()
      ..add(ASN1Integer(publicKey.modulus!))
      ..add(ASN1Integer(publicKey.exponent!));
    final publicKeyBitString = ASN1BitString(Uint8List.fromList(publicKeySeq.encodedBytes));
    final topLevelSeq = ASN1Sequence()
      ..add(algorithmSeq)
      ..add(publicKeyBitString);
    final dataBase64 = base64.encode(topLevelSeq.encodedBytes);
    return '-----BEGIN PUBLIC KEY-----\n$dataBase64\n-----END PUBLIC KEY-----';
  }

  static String _encodePrivateKeyToPem(RSAPrivateKey privateKey) {
    final privateKeySeq = ASN1Sequence()
      ..add(ASN1Integer(BigInt.from(0)))
      ..add(ASN1Integer(privateKey.modulus!))
      ..add(ASN1Integer(privateKey.publicExponent!))
      ..add(ASN1Integer(privateKey.privateExponent!))
      ..add(ASN1Integer(privateKey.p!))
      ..add(ASN1Integer(privateKey.q!))
      ..add(ASN1Integer(privateKey.privateExponent! % (privateKey.p! - BigInt.one)))
      ..add(ASN1Integer(privateKey.privateExponent! % (privateKey.q! - BigInt.one)))
      ..add(ASN1Integer(privateKey.q!.modInverse(privateKey.p!)));
    final dataBase64 = base64.encode(privateKeySeq.encodedBytes);
    return '-----BEGIN PRIVATE KEY-----\n$dataBase64\n-----END PRIVATE KEY-----';
  }

  static RSAPublicKey _decodePublicKeyFromPem(String pem) {
  final lines = pem.split('\n');
  final base64Str = lines.sublist(1, lines.length - 1).join('');
  final asn1Parser = ASN1Parser(base64.decode(base64Str));
  final topLevelSeq = asn1Parser.nextObject() as ASN1Sequence;
  final publicKeyBitString = topLevelSeq.elements[1] as ASN1BitString;
  final publicKeyAsn = ASN1Parser(publicKeyBitString.valueBytes());
  final publicKeySeq = publicKeyAsn.nextObject() as ASN1Sequence;
  final modulus = (publicKeySeq.elements[0] as ASN1Integer).valueAsBigInteger;
  final exponent = (publicKeySeq.elements[1] as ASN1Integer).valueAsBigInteger;
  return RSAPublicKey(modulus, exponent);
  }

  static RSAPrivateKey _decodePrivateKeyFromPem(String pem) {
  final lines = pem.split('\n');
  final base64Str = lines.sublist(1, lines.length - 1).join('');
  final asn1Parser = ASN1Parser(base64.decode(base64Str));
  final seq = asn1Parser.nextObject() as ASN1Sequence;
  final modulus = (seq.elements[1] as ASN1Integer).valueAsBigInteger;
  // final publicExponent = (seq.elements[2] as ASN1Integer).valueAsBigInteger; // not used
  final privateExponent = (seq.elements[3] as ASN1Integer).valueAsBigInteger;
  final p = (seq.elements[4] as ASN1Integer).valueAsBigInteger;
  final q = (seq.elements[5] as ASN1Integer).valueAsBigInteger;
  return RSAPrivateKey(modulus, privateExponent, p, q);
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
}
