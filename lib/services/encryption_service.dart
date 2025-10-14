import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt hide SecureRandom;
import 'package:pointycastle/export.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class EncryptionService {
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
    
    final existingPrivateKey = await _secureStorage.read(key: _getPrivateKeyKey(userId));
    return existingPrivateKey == null;
  }

  static Future<void> initializeKeys() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        print('No user logged in');
        return;
      }

      final existingPrivateKey = await _secureStorage.read(key: _getPrivateKeyKey(userId));
      if (existingPrivateKey != null) {
        print('Keys already exist for user $userId');
        return;
      }

      // Kiểm tra có backup trên Firebase không
      print('Checking for existing backup on Firebase...');
      final backupDoc = await _firestore.collection('key_backups').doc(userId).get();
      if (backupDoc.exists) {
        print('⚠️ Found backup on Firebase but no local keys!');
        print('💡 User needs to restore keys manually from Settings > Backup Private Key');
        // Không tự động restore vì cần password
        // User sẽ được nhắc qua BackupReminderDialog
        return;
      }

      print('Generating new RSA key pair for user $userId...');
      
      // Web không hỗ trợ isolates, phải chạy đồng bộ
      // Mobile/Desktop có thể dùng compute() để chạy trong background
      final Map<String, String> keyPair;
      if (kIsWeb) {
        // Trên Web: Chạy đồng bộ nhưng dùng 1024-bit cho nhanh hơn (2-3 giây)
        print('Running on Web - generating 1024-bit key pair...');
        // Thêm delay nhỏ để UI có thể render loading indicator
        await Future.delayed(Duration(milliseconds: 100));
        keyPair = _generateRSAKeyPair(keySize: 1024);
      } else {
        // Trên Mobile/Desktop: Chạy trong isolate với 2048-bit (5-10 giây)
        print('Running on native platform - generating 2048-bit key pair in isolate...');
        keyPair = await compute(_generateRSAKeyPairIsolate, 2048);
      }
      
      // Lưu khóa theo userId
      await _secureStorage.write(key: _getPrivateKeyKey(userId), value: keyPair['privateKey']!);
      await _secureStorage.write(key: _getPublicKeyKey(userId), value: keyPair['publicKey']!);

      await _firestore.collection('users').doc(userId).update({
        'publicKey': keyPair['publicKey']!,
        'publicKeyUpdatedAt': FieldValue.serverTimestamp(),
      });
      print('RSA key pair generated successfully for user $userId!');
    } catch (e) {
      print('Error initializing keys: $e');
      rethrow;
    }
  }

  // Top-level function để chạy trong isolate (chỉ dùng cho native platforms)
  static Map<String, String> _generateRSAKeyPairIsolate(int keySize) {
    return _generateRSAKeyPair(keySize: keySize);
  }

  static Map<String, String> _generateRSAKeyPair({int keySize = 2048}) {
    final secureRandom = _getSecureRandom();
    final rsaKeyGenerator = RSAKeyGenerator()
      ..init(ParametersWithRandom(
        RSAKeyGeneratorParameters(BigInt.from(65537), keySize, 64),
        secureRandom,
      ));

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
    final privateExponent = base64.encode(_encodeBigInt(privateKey.privateExponent!));
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
    final parts = pem.split(':');
    final modulus = _decodeBigInt(base64.decode(parts[1]));
    // Skip exponent (parts[2]) - not needed for private key operations
    final privateExponent = _decodeBigInt(base64.decode(parts[3]));
    final p = _decodeBigInt(base64.decode(parts[4]));
    final q = _decodeBigInt(base64.decode(parts[5]));
    return RSAPrivateKey(modulus, privateExponent, p, q);
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

  static Future<String> getOrCreateSessionKey(String chatId, String otherUserId) async {
    try {
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      
      if (chatDoc.exists) {
        final data = chatDoc.data();
        if (data != null && data.containsKey('sessionKeys')) {
          final sessionKeys = data['sessionKeys'] as Map<String, dynamic>;
          final userId = _auth.currentUser?.uid;
          
          if (userId != null && sessionKeys.containsKey(userId)) {
            return await _decryptSessionKey(sessionKeys[userId] as String);
          }
        }
      }

      final sessionKey = generateSessionKey();
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) throw Exception('User not logged in');

      final otherUserDoc = await _firestore.collection('users').doc(otherUserId).get();
      final otherUserPublicKey = otherUserDoc.data()?['publicKey'] as String?;
      final currentUserPublicKey = await _secureStorage.read(key: _getPublicKeyKey(currentUserId));

      if (otherUserPublicKey == null || currentUserPublicKey == null) {
        throw Exception('Public keys not found');
      }

      final encryptedForCurrentUser = _encryptWithPublicKey(sessionKey, currentUserPublicKey);
      final encryptedForOtherUser = _encryptWithPublicKey(sessionKey, otherUserPublicKey);

      await _firestore.collection('chats').doc(chatId).set({
        'sessionKeys': {
          currentUserId: encryptedForCurrentUser,
          otherUserId: encryptedForOtherUser,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'participants': [currentUserId, otherUserId],
      }, SetOptions(merge: true));

      return sessionKey;
    } catch (e) {
      print('Error getting/creating session key: $e');
      rethrow;
    }
  }

  static String _encryptWithPublicKey(String data, String publicKeyPem) {
    final publicKey = _decodePublicKeyFromPem(publicKeyPem);
    final encrypter = encrypt.Encrypter(encrypt.RSA(publicKey: publicKey));
    return encrypter.encrypt(data).base64;
  }

  static Future<String> _decryptSessionKey(String encryptedData) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) throw Exception('User not logged in');
    
    final privateKeyPem = await _secureStorage.read(key: _getPrivateKeyKey(currentUserId));
    if (privateKeyPem == null) throw Exception('Private key not found');
    
    final privateKey = _decodePrivateKeyFromPem(privateKeyPem);
    final encrypter = encrypt.Encrypter(encrypt.RSA(privateKey: privateKey));
    return encrypter.decrypt64(encryptedData);
  }

  static Map<String, String> encryptMessage(String plainText, String sessionKey) {
    try {
      final keyBytes = base64.decode(sessionKey);
      final key = encrypt.Key(Uint8List.fromList(keyBytes));
      final iv = encrypt.IV.fromSecureRandom(16);
      
      final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
      final encrypted = encrypter.encrypt(plainText, iv: iv);
      
      final hmacKey = Hmac(sha256, keyBytes);
      final hmacData = hmacKey.convert(utf8.encode(encrypted.base64 + iv.base64));
      
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

  static String decryptMessage(String encryptedContent, String ivString, String hmac, String sessionKey) {
    try {
      final keyBytes = base64.decode(sessionKey);
      final key = encrypt.Key(Uint8List.fromList(keyBytes));
      
      final hmacKey = Hmac(sha256, keyBytes);
      final expectedHmac = hmacKey.convert(utf8.encode(encryptedContent + ivString));
      
      if (expectedHmac.toString() != hmac) {
        throw Exception('HMAC verification failed');
      }
      
      final iv = encrypt.IV.fromBase64(ivString);
      final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
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
    return await _secureStorage.read(key: _getPublicKeyKey(userId));
  }

  static Future<String?> getPublicKey(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      return userDoc.data()?['publicKey'] as String?;
    } catch (e) {
      return null;
    }
  }
}
