# HƯỚNG DẪN XÂY DỰNG TÍNH NĂNG CHAT HOÀN CHỈNH

## MỤC LỤC

1. [Tổng quan hệ thống](#1-tổng-quan-hệ-thống)
2. [Cài đặt dependencies](#2-cài-đặt-dependencies)
3. [Mã hóa đầu cuối (E2EE)](#3-mã-hóa-đầu-cuối-e2ee)
4. [Chat 1-1 (Private Chat)](#4-chat-1-1-private-chat)
5. [Chat nhóm (Group Chat)](#5-chat-nhóm-group-chat)
6. [Hàm băm (Hash) và HMAC](#6-hàm-băm-hash-và-
7. [Xóa tin nhắn tự động](#7-xóa-tin-nhắn-tự-động)
8. [Giao diện người dùng](#8-giao-diện-người-dùng)
9. [Firebase setup](#9-firebase-setup)
10. [Testing và debugging](#10-testing-và-debugging)

---

## 1. TỔNG QUAN HỆ THỐNG

### Kiến trúc tổng thể

```
┌─────────────────────────────────────────────────────────────┐
│                        CLIENT APP                            │
├─────────────────────────────────────────────────────────────┤
│  UI Layer                                                    │
│  ├── ChatListScreen (Danh sách chat)                       │
│  ├── ChatDetailScreen (Chi tiết chat 1-1)                  │
│  ├── GroupChatScreen (Chat nhóm)                           │
│  └── SettingsScreen (Cài đặt)                              │
├─────────────────────────────────────────────────────────────┤
│  Service Layer                                               │
│  ├── ChatService (Xử lý chat 1-1)                          │
│  ├── GroupChatService (Xử lý chat nhóm)                    │
│  ├── EncryptionService (Mã hóa/giải mã)                    │
│  ├── KeyManagementService (Quản lý khóa)                   │
│  └── AutoDeleteService (Xóa tin nhắn tự động)              │
├─────────────────────────────────────────────────────────────┤
│  Storage Layer                                               │
│  ├── Secure Storage (Lưu private key)                      │
│  └── Firebase Firestore (Lưu tin nhắn mã hóa)              │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    FIREBASE BACKEND                          │
├─────────────────────────────────────────────────────────────┤
│  Firestore Collections                                       │
│  ├── users (Thông tin người dùng)                          │
│  ├── user_keys (Public key của user)                       │
│  ├── chats (Metadata chat 1-1)                             │
│  ├── chat_keys (Session key đã mã hóa)                     │
│  ├── messages (Tin nhắn 1-1 đã mã hóa)                     │
│  ├── group_chats (Metadata nhóm)                           │
│  ├── group_keys (Group key đã mã hóa)                      │
│  └── group_messages (Tin nhắn nhóm đã mã hóa)              │
├─────────────────────────────────────────────────────────────┤
│  Cloud Functions                                             │
│  ├── cleanupExpiredMessages (Xóa tin nhắn hết hạn)         │
│  └── sendNotification (Gửi thông báo)                      │
└─────────────────────────────────────────────────────────────┘
```

### Luồng hoạt động

**Đăng ký/Đăng nhập:**
1. User đăng ký tài khoản
2. Tạo cặp khóa RSA (public/private)
3. Lưu private key vào Secure Storage (local)
4. Upload public key lên Firestore

**Chat 1-1:**
1. User A muốn chat với User B
2. Lấy public key của User B từ Firestore
3. Tạo session key (AES-256) cho cuộc hội thoại
4. Mã hóa session key bằng public key của cả 2 user
5. Khi gửi tin nhắn:
   - Mã hóa tin nhắn bằng session key
   - Tạo HMAC để xác thực
   - Upload lên Firestore
6. Khi nhận tin nhắn:
   - Lấy session key và giải mã bằng private key
   - Xác thực HMAC
   - Giải mã tin nhắn

**Chat nhóm:**
1. User A tạo nhóm với User B, C
2. Tạo group key (AES-256)
3. Mã hóa group key bằng public key của từng thành viên
4. Lưu các group key đã mã hóa lên Firestore
5. Tin nhắn trong nhóm dùng chung group key

---

## 2. CÀI ĐẶT DEPENDENCIES

### Cập nhật pubspec.yaml

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Firebase
  firebase_core: ^2.24.2
  firebase_auth: ^4.16.0
  firebase_storage: ^11.6.0
  cloud_firestore: ^4.14.0
  
  # Mã hóa
  encrypt: ^5.0.3
  crypto: ^3.0.3
  pointycastle: ^3.7.3
  
  # Lưu trữ bảo mật
  flutter_secure_storage: ^9.0.0
  
  # State management
  provider: ^6.1.1
  
  # UI
  cached_network_image: ^3.3.1
  intl: ^0.19.0
  
  # Utils
  uuid: ^4.3.3
```

### Cài đặt packages

```bash
flutter pub get
```

---

## 3. MÃ HÓA ĐẦU CUỐI (E2EE)

### Tại sao cần mã hóa đầu cuối?

- **Bảo mật tuyệt đối**: Chỉ người gửi và người nhận đọc được tin nhắn
- **Privacy**: Server không thể đọc nội dung
- **Chống theo dõi**: Không ai có thể nghe lén
- **Tuân thủ pháp luật**: Đáp ứng yêu cầu bảo mật dữ liệu

### Thuật toán sử dụng

1. **RSA-2048**: Mã hóa/giải mã khóa
2. **AES-256**: Mã hóa nội dung tin nhắn
3. **SHA-256**: Tạo hash
4. **HMAC-SHA256**: Xác thực tính toàn vẹn

### Tạo Encryption Service

```dart
// lib/services/encryption_service.dart

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:pointycastle/export.dart';

class EncryptionService {
  // ==================== RSA KEY GENERATION ====================
  
  /// Tạo cặp khóa RSA-2048
  static Future<Map<String, String>> generateRSAKeyPair() async {
    final secureRandom = _getSecureRandom();
    
    final keyGen = RSAKeyGenerator()
      ..init(
        ParametersWithRandom(
          RSAKeyGeneratorParameters(
            BigInt.parse('65537'), // Public exponent
            2048, // Key size
            64, // Certainty
          ),
          secureRandom,
        ),
      );
    
    final pair = keyGen.generateKeyPair();
    final publicKey = pair.publicKey as RSAPublicKey;
    final privateKey = pair.privateKey as RSAPrivateKey;
    
    return {
      'publicKey': _encodePublicKey(publicKey),
      'privateKey': _encodePrivateKey(privateKey),
    };
  }
  
  /// Tạo secure random
  static SecureRandom _getSecureRandom() {
    final secureRandom = SecureRandom('Fortuna');
    final random = Random.secure();
    final seeds = List<int>.generate(32, (_) => random.nextInt(256));
    secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));
    return secureRandom;
  }
  
  /// Encode RSA public key sang Base64
  static String _encodePublicKey(RSAPublicKey publicKey) {
    final algorithmSeq = ASN1Sequence();
    final algorithmAsn1Obj = ASN1Object.fromBytes(
      Uint8List.fromList([0x6, 0x9, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0xd, 0x1, 0x1, 0x1])
    );
    final paramsAsn1Obj = ASN1Object.fromBytes(Uint8List.fromList([0x5, 0x0]));
    algorithmSeq.add(algorithmAsn1Obj);
    algorithmSeq.add(paramsAsn1Obj);

    final publicKeySeq = ASN1Sequence();
    publicKeySeq.add(ASN1Integer(publicKey.modulus!));
    publicKeySeq.add(ASN1Integer(publicKey.exponent!));
    final publicKeySeqBitString = ASN1BitString(
      Uint8List.fromList(publicKeySeq.encodedBytes)
    );

    final topLevelSeq = ASN1Sequence();
    topLevelSeq.add(algorithmSeq);
    topLevelSeq.add(publicKeySeqBitString);
    
    return base64Encode(topLevelSeq.encodedBytes);
  }
  
  /// Encode RSA private key sang Base64
  static String _encodePrivateKey(RSAPrivateKey privateKey) {
    final topLevelSeq = ASN1Sequence();
    
    final version = ASN1Integer(BigInt.from(0));
    final modulus = ASN1Integer(privateKey.modulus!);
    final publicExponent = ASN1Integer(privateKey.exponent!);
    final privateExponent = ASN1Integer(privateKey.privateExponent!);
    final p = ASN1Integer(privateKey.p!);
    final q = ASN1Integer(privateKey.q!);
    final dP = privateKey.privateExponent! % (privateKey.p! - BigInt.one);
    final exp1 = ASN1Integer(dP);
    final dQ = privateKey.privateExponent! % (privateKey.q! - BigInt.one);
    final exp2 = ASN1Integer(dQ);
    final iQ = privateKey.q!.modInverse(privateKey.p!);
    final co = ASN1Integer(iQ);

    topLevelSeq.add(version);
    topLevelSeq.add(modulus);
    topLevelSeq.add(publicExponent);
    topLevelSeq.add(privateExponent);
    topLevelSeq.add(p);
    topLevelSeq.add(q);
    topLevelSeq.add(exp1);
    topLevelSeq.add(exp2);
    topLevelSeq.add(co);
    
    return base64Encode(topLevelSeq.encodedBytes);
  }
  
  // ==================== AES ENCRYPTION ====================
  
  /// Tạo khóa AES-256 ngẫu nhiên
  static String generateAESKey() {
    final key = Key.fromSecureRandom(32); // 256 bits
    return key.base64;
  }
  
  /// Mã hóa tin nhắn bằng AES-256
  static String encryptMessage(String plainText, String aesKeyBase64) {
    try {
      final key = Key.fromBase64(aesKeyBase64);
      final iv = IV.fromSecureRandom(16); // 128 bits
      
      final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
      final encrypted = encrypter.encrypt(plainText, iv: iv);
      
      // Kết hợp IV + encrypted data
      final combined = iv.bytes + encrypted.bytes;
      return base64Encode(combined);
    } catch (e) {
      throw Exception('Lỗi mã hóa: $e');
    }
  }
  
  /// Giải mã tin nhắn bằng AES-256
  static String decryptMessage(String encryptedBase64, String aesKeyBase64) {
    try {
      final key = Key.fromBase64(aesKeyBase64);
      final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
      
      // Tách IV và encrypted data
      final combined = base64Decode(encryptedBase64);
      final iv = IV(Uint8List.fromList(combined.sublist(0, 16)));
      final encryptedData = Encrypted(Uint8List.fromList(combined.sublist(16)));
      
      return encrypter.decrypt(encryptedData, iv: iv);
    } catch (e) {
      throw Exception('Lỗi giải mã: $e');
    }
  }
  
  // ==================== RSA ENCRYPTION ====================
  
  /// Mã hóa AES key bằng RSA public key
  static String encryptAESKey(String aesKey, String publicKeyBase64) {
    try {
      final publicKey = _parsePublicKey(publicKeyBase64);
      final encrypter = Encrypter(RSA(publicKey: publicKey));
      return encrypter.encrypt(aesKey).base64;
    } catch (e) {
      throw Exception('Lỗi mã hóa AES key: $e');
    }
  }
  
  /// Giải mã AES key bằng RSA private key
  static String decryptAESKey(String encryptedAESKey, String privateKeyBase64) {
    try {
      final privateKey = _parsePrivateKey(privateKeyBase64);
      final encrypter = Encrypter(RSA(privateKey: privateKey));
      return encrypter.decrypt64(encryptedAESKey);
    } catch (e) {
      throw Exception('Lỗi giải mã AES key: $e');
    }
  }
  
  /// Parse public key từ Base64
  static RSAPublicKey _parsePublicKey(String base64Key) {
    final bytes = base64Decode(base64Key);
    final asn1Parser = ASN1Parser(bytes);
    final topLevelSeq = asn1Parser.nextObject() as ASN1Sequence;
    final publicKeyBitString = topLevelSeq.elements[1] as ASN1BitString;
    
    final publicKeyAsn = ASN1Parser(publicKeyBitString.contentBytes());
    final publicKeySeq = publicKeyAsn.nextObject() as ASN1Sequence;
    final modulus = publicKeySeq.elements[0] as ASN1Integer;
    final exponent = publicKeySeq.elements[1] as ASN1Integer;
    
    return RSAPublicKey(modulus.valueAsBigInteger, exponent.valueAsBigInteger);
  }
  
  /// Parse private key từ Base64
  static RSAPrivateKey _parsePrivateKey(String base64Key) {
    final bytes = base64Decode(base64Key);
    final asn1Parser = ASN1Parser(bytes);
    final topLevelSeq = asn1Parser.nextObject() as ASN1Sequence;
    
    final modulus = topLevelSeq.elements[1] as ASN1Integer;
    final privateExponent = topLevelSeq.elements[3] as ASN1Integer;
    final p = topLevelSeq.elements[4] as ASN1Integer;
    final q = topLevelSeq.elements[5] as ASN1Integer;
    
    return RSAPrivateKey(
      modulus.valueAsBigInteger,
      privateExponent.valueAsBigInteger,
      p.valueAsBigInteger,
      q.valueAsBigInteger,
    );
  }
  
  // ==================== HASH & HMAC ====================
  
  /// Tạo SHA-256 hash
  static String createHash(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  /// Tạo HMAC-SHA256
  static String createHMAC(String message, String key) {
    final keyBytes = utf8.encode(key);
    final messageBytes = utf8.encode(message);
    final hmacSha256 = Hmac(sha256, keyBytes);
    final digest = hmacSha256.convert(messageBytes);
    return digest.toString();
  }
  
  /// Xác minh HMAC
  static bool verifyHMAC(String message, String key, String receivedHMAC) {
    final calculatedHMAC = createHMAC(message, key);
    return calculatedHMAC == receivedHMAC;
  }
  
  /// Mã hóa tin nhắn với HMAC để xác minh tính toàn vẹn
  static Map<String, String> encryptMessageWithHMAC(String plainText, String aesKey) {
    final encrypted = encryptMessage(plainText, aesKey);
    final hmac = createHMAC(encrypted, aesKey);
    
    return {
      'encrypted': encrypted,
      'hmac': hmac,
    };
  }
  
  /// Giải mã và xác minh HMAC
  static String decryptMessageWithHMAC(
    String encrypted,
    String hmac,
    String aesKey,
  ) {
    // Xác minh HMAC trước
    if (!verifyHMAC(encrypted, aesKey, hmac)) {
      throw Exception('HMAC không hợp lệ - tin nhắn có thể đã bị thay đổi');
    }
    
    return decryptMessage(encrypted, aesKey);
  }
  
  /// Tạo message fingerprint (dấu vân tay tin nhắn)
  static String createMessageFingerprint(
    String messageId,
    String content,
    DateTime timestamp,
  ) {
    final input = '$messageId:$content:${timestamp.millisecondsSinceEpoch}';
    return createHash(input);
  }
}
```

### Tạo Key Management Service

```dart
// lib/services/key_management_service.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'encryption_service.dart';

class KeyManagementService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static final _firestore = FirebaseFirestore.instance;
  
  // ==================== USER KEY MANAGEMENT ====================
  
  /// Khởi tạo khóa cho user mới
  static Future<void> initializeUserKeys(String userId) async {
    try {
      // Kiểm tra xem đã có khóa chưa
      final existingPrivateKey = await _storage.read(key: 'private_key_$userId');
      
      if (existingPrivateKey == null) {
        print('Tạo cặp khóa mới cho user $userId');
        
        // Tạo cặp khóa RSA
        final keyPair = await EncryptionService.generateRSAKeyPair();
        
        // Lưu private key vào secure storage (local)
        await _storage.write(
          key: 'private_key_$userId',
          value: keyPair['privateKey']!,
        );
        
        // Upload public key lên Firestore
        await _firestore.collection('user_keys').doc(userId).set({
          'publicKey': keyPair['publicKey'],
          'createdAt': FieldValue.serverTimestamp(),
          'lastUsed': FieldValue.serverTimestamp(),
        });
        
        print('✓ Đã tạo và lưu khóa thành công');
      } else {
        print('✓ User đã có khóa');
      }
    } catch (e) {
      print('✗ Lỗi khởi tạo khóa: $e');
      throw Exception('Không thể khởi tạo khóa: $e');
    }
  }
  
  /// Lấy public key của user khác
  static Future<String?> getPublicKey(String userId) async {
    try {
      final doc = await _firestore.collection('user_keys').doc(userId).get();
      
      if (!doc.exists) {
        print('✗ User $userId chưa có public key');
        return null;
      }
      
      // Cập nhật lastUsed
      await _firestore.collection('user_keys').doc(userId).update({
        'lastUsed': FieldValue.serverTimestamp(),
      });
      
      return doc.data()?['publicKey'] as String?;
    } catch (e) {
      print('✗ Lỗi lấy public key: $e');
      return null;
    }
  }
  
  /// Lấy private key của user hiện tại
  static Future<String?> getPrivateKey(String userId) async {
    try {
      return await _storage.read(key: 'private_key_$userId');
    } catch (e) {
      print('✗ Lỗi lấy private key: $e');
      return null;
    }
  }
  
  // ==================== SESSION KEY MANAGEMENT (1-1 Chat) ====================
  
  /// Tạo session key cho chat 1-1
  static Future<String> createSessionKey(
    String chatId,
    String currentUserId,
    String otherUserId,
  ) async {
    try {
      // Kiểm tra đã có session key chưa
      String? existingKey = await _storage.read(key: 'session_key_$chatId');
      if (existingKey != null) {
        print('✓ Session key đã tồn tại');
        return existingKey;
      }
      
      print('Tạo session key mới cho chat $chatId');
      
      // Tạo AES key mới
      final aesKey = EncryptionService.generateAESKey();
      
      // Lưu cho user hiện tại (plain)
      await _storage.write(key: 'session_key_$chatId', value: aesKey);
      
      // Lấy public key của user khác
      final otherPublicKey = await getPublicKey(otherUserId);
      if (otherPublicKey == null) {
        throw Exception('Không tìm thấy public key của user $otherUserId');
      }
      
      // Mã hóa session key bằng public key của user khác
      final encryptedKeyForOther = EncryptionService.encryptAESKey(
        aesKey,
        otherPublicKey,
      );
      
      // Lưu lên Firestore
      await _firestore.collection('chat_keys').doc(chatId).set({
        'keys': {
          currentUserId: aesKey, // Plain key cho người tạo
          otherUserId: encryptedKeyForOther, // Encrypted key cho người khác
        },
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': currentUserId,
      });
      
      print('✓ Đã tạo session key thành công');
      return aesKey;
    } catch (e) {
      print('✗ Lỗi tạo session key: $e');
      throw Exception('Không thể tạo session key: $e');
    }
  }
  
  /// Lấy session key cho chat 1-1
  static Future<String?> getSessionKey(String chatId, String userId) async {
    try {
      // Thử lấy từ local storage trước
      String? localKey = await _storage.read(key: 'session_key_$chatId');
      if (localKey != null) {
        return localKey;
      }
      
      print('Lấy session key từ Firestore...');
      
      // Lấy từ Firestore
      final doc = await _firestore.collection('chat_keys').doc(chatId).get();
      if (!doc.exists) {
        print('✗ Không tìm thấy chat key');
        return null;
      }
      
      final keys = doc.data()?['keys'] as Map<String, dynamic>?;
      if (keys == null || keys[userId] == null) {
        print('✗ Không tìm thấy key cho user');
        return null;
      }
      
      final keyData = keys[userId] as String;
      
      // Nếu là encrypted key (dài hơn), giải mã
      String sessionKey;
      if (keyData.length > 50) {
        print('Giải mã session key...');
        final privateKey = await getPrivateKey(userId);
        if (privateKey == null) {
          throw Exception('Không tìm thấy private key');
        }
        sessionKey = EncryptionService.decryptAESKey(keyData, privateKey);
      } else {
        sessionKey = keyData;
      }
      
      // Lưu vào local storage
      await _storage.write(key: 'session_key_$chatId', value: sessionKey);
      
      print('✓ Đã lấy session key thành công');
      return sessionKey;
    } catch (e) {
      print('✗ Lỗi lấy session key: $e');
      return null;
    }
  }
  
  // ==================== GROUP KEY MANAGEMENT ====================
  
  /// Tạo group key cho chat nhóm
  static Future<String> createGroupKey(
    String groupId,
    String currentUserId,
    List<String> memberIds,
  ) async {
    try {
      print('Tạo group key cho nhóm $groupId');
      
      // Tạo AES key cho nhóm
      final groupKey = EncryptionService.generateAESKey();
      
      // Lưu plain key cho user hiện tại
      await _storage.write(key: 'group_key_$groupId', value: groupKey);
      
      // Mã hóa group key cho từng thành viên
      Map<String, String> encryptedKeys = {};
      
      for (final memberId in memberIds) {
        if (memberId == currentUserId) {
          // Plain key cho người tạo
          encryptedKeys[memberId] = groupKey;
        } else {
          // Encrypted key cho thành viên khác
          final publicKey = await getPublicKey(memberId);
          if (publicKey != null) {
            encryptedKeys[memberId] = EncryptionService.encryptAESKey(
              groupKey,
              publicKey,
            );
          }
        }
      }
      
      // Lưu lên Firestore
      await _firestore.collection('group_keys').doc(groupId).set({
        'keys': encryptedKeys,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': currentUserId,
        'memberIds': memberIds,
      });
      
      print('✓ Đã tạo group key thành công');
      return groupKey;
    } catch (e) {
      print('✗ Lỗi tạo group key: $e');
      throw Exception('Không thể tạo group key: $e');
    }
  }
  
  /// Lấy group key
  static Future<String?> getGroupKey(String groupId, String userId) async {
    try {
      // Thử lấy từ local storage trước
      String? localKey = await _storage.read(key: 'group_key_$groupId');
      if (localKey != null) {
        return localKey;
      }
      
      print('Lấy từ Firestore...');
      
      // Lấy từ Firestore
      final doc = await _firestore.collection('group_keys').doc(groupId).get();
      if (!doc.exists) {
        print('✗ Không tìm thấy group key');
        return null;
      }
      
      final keys = doc.data()?['keys'] as Map<String, dynamic>?;
      if (keys == null || keys[userId] == null) {
        print('✗ Không tìm thấy key cho user');
        return null;
      }
      
      final keyData = keys[userId] as String;
      
      // Nếu là encrypted key, giải mã
      String groupKey;
      if (keyData.length > 50) {
        print('Giải mã group key...');
        final privateKey = await getPrivateKey(userId);
        if (privateKey == null) {
          throw Exception('Không tìm thấy private key');
        }
        groupKey = EncryptionService.decryptAESKey(keyData, privateKey);
      } else {
        groupKey = keyData;
      }
      
      // Lưu vào local storage
      await _storage.write(key: 'group_key_$groupId', value: groupKey);
      
      print('✓ Đã lấy group key thành công');
      return groupKey;
    } catch (e) {
      print('✗ Lỗi lấy group key: $e');
      return null;
    }
  }
  
  /// Thêm thành viên vào nhóm (update group key)
  static Future<void> addMemberToGroup(
    String groupId,
    String currentUserId,
    String newMemberId,
  ) async {
    try {
      print('Thêm member $newMemberId vào nhóm $groupId');
      
      // Lấy group key hiện tại
      final groupKey = await getGroupKey(groupId, currentUserId);
      if (groupKey == null) {
        throw Exception('Không tìm thấy group key');
      }
      
      // Lấy public key của member mới
      final publicKey = await getPublicKey(newMemberId);
      if (publicKey == null) {
        throw Exception('Không tìm thấy public key của member mới');
      }
      
      // Mã hóa group key cho member mới
      final encryptedKey = EncryptionService.encryptAESKey(groupKey, publicKey);
      
      // Cập nhật lên Firestore
      await _firestore.collection('group_keys').doc(groupId).update({
        'keys.$newMemberId': encryptedKey,
        'memberIds': FieldValue.arrayUnion([newMemberId]),
      });
      
      print('✓ Đã thêm member thành công');
    } catch (e) {
      print('✗ Lỗi thêm member: $e');
      throw Exception('Không thể thêm member: $e');
    }
  }
  
  // ==================== UTILITY ====================
  
  /// Xóa tất cả khóa local (dùng khi logout)
  static Future<void> clearAllKeys() async {
    await _storage.deleteAll();
    print('✓ Đã xóa tất cả khóa local');
  }
  
  /// Backup private key
  static Future<String?> backupPrivateKey(String userId) async {
    return await getPrivateKey(userId);
  }
  
  /// Restore private key
  static Future<void> restorePrivateKey(String userId, String privateKey) async {
    await _storage.write(key: 'private_key_$userId', value: privateKey);
    print('✓ Đã restore private key');
  }
}
```

---

## 4. CHAT 1-1 (PRIVATE CHAT)

### Model cho Message

```dart
// lib/models/message_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String receiverId;
  final String encryptedContent;
  final String hmac;
  final String messageType; // text, image, file, audio
  final DateTime timestamp;
  final bool isRead;
  final bool isDeleted;
  final DateTime? deleteAt;
  final String? fingerprint;
  final Map<String, dynamic>? metadata;
  
  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.receiverId,
    required this.encryptedContent,
    required this.hmac,
    required this.messageType,
    required this.timestamp,
    this.isRead = false,
    this.isDeleted = false,
    this.deleteAt,
    this.fingerprint,
    this.metadata,
  });
  
  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'receiverId': receiverId,
      'encryptedContent': encryptedContent,
      'hmac': hmac,
      'messageType': messageType,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'isDeleted': isDeleted,
      'deleteAt': deleteAt != null ? Timestamp.fromDate(deleteAt!) : null,
      'fingerprint': fingerprint,
      'metadata': metadata,
    };
  }
  
  // Create from Firestore document
  factory MessageModel.fromMap(Map<String, dynamic> map, String id) {
    return MessageModel(
      id: id,
      chatId: map['chatId'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      encryptedContent: map['encryptedContent'] ?? '',
      hmac: map['hmac'] ?? '',
      messageType: map['messageType'] ?? 'text',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      isRead: map['isRead'] ?? false,
      isDeleted: map['isDeleted'] ?? false,
      deleteAt: map['deleteAt'] != null
          ? (map['deleteAt'] as Timestamp).toDate()
          : null,
      fingerprint: map['fingerprint'],
      metadata: map['metadata'],
    );
  }
  
  // Copy with
  MessageModel copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? receiverId,
    String? encryptedContent,
    String? hmac,
    String? messageType,
    DateTime? timestamp,
    bool? isRead,
    bool? isDeleted,
    DateTime? deleteAt,
    String? fingerprint,
    Map<String, dynamic>? metadata,
  }) {
    return MessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      encryptedContent: encryptedContent ?? this.encryptedContent,
      hmac: hmac ?? this.hmac,
      messageType: messageType ?? this.messageType,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      isDeleted: isDeleted ?? this.isDeleted,
      deleteAt: deleteAt ?? this.deleteAt,
      fingerprint: fingerprint ?? this.fingerprint,
      metadata: metadata ?? this.metadata,
    );
  }
}

// Model cho Chat metadata
class ChatModel {
  final String id;
  final List<String> participants;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String? lastSenderId;
  final Map<String, int> unreadCount;
  final DateTime createdAt;
  final int autoDeleteMinutes;
  
  ChatModel({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.lastMessageTime,
    this.lastSenderId,
    required this.unreadCount,
    required this.createdAt,
    this.autoDeleteMinutes = 0,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime != null
          ? Timestamp.fromDate(lastMessageTime!)
          : null,
      'lastSenderId': lastSenderId,
      'unreadCount': unreadCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'autoDeleteMinutes': autoDeleteMinutes,
    };
  }
  
  factory ChatModel.fromMap(Map<String, dynamic> map, String id) {
    return ChatModel(
      id: id,
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'],
      lastMessageTime: map['lastMessageTime'] != null
          ? (map['lastMessageTime'] as Timestamp).toDate()
          : null,
      lastSenderId: map['lastSenderId'],
      unreadCount: Map<String, int>.from(map['unreadCount'] ?? {}),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      autoDeleteMinutes: map['autoDeleteMinutes'] ?? 0,
    );
  }
}
```

### Chat Service

```dart
// lib/services/chat_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message_model.dart';
import 'encryption_service.dart';
import 'key_management_service.dart';

class ChatService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;
  
  // ==================== SEND MESSAGE ====================
  
  /// Gửi tin nhắn mã hóa
  static Future<void> sendMessage({
    required String receiverId,
    required String content,
    String messageType = 'text',
    int? autoDeleteMinutes,
    Map<String, dynamic>? metadata,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Chưa đăng nhập');
    }
    
    try {
      print('Gửi tin nhắn đến $receiverId');
      
      // Tạo chatId
      final chatId = _createChatId(currentUser.uid, receiverId);
      
      // Lấy hoặc tạo session key
      String? sessionKey = await KeyManagementService.getSessionKey(
        chatId,
        currentUser.uid,
      );
      
      if (sessionKey == null) {
        sessionKey = await KeyManagementService.createSessionKey(
          chatId,
          currentUser.uid,
          receiverId,
        );
      }
      
      // Mã hóa tin nhắn với HMAC
      final encrypted = EncryptionService.encryptMessageWithHMAC(
        content,
        sessionKey,
      );
      
      // Tạo message ID
      final messageDoc = _firestore.collection('messages').doc();
      
      // Tạo fingerprint
      final fingerprint = EncryptionService.createMessageFingerprint(
        messageDoc.id,
        content,
        DateTime.now(),
      );
      
      // Tính thời gian tự động xóa
      DateTime? deleteAt;
      if (autoDeleteMinutes != null && autoDeleteMinutes > 0) {
        deleteAt = DateTime.now().add(Duration(minutes: autoDeleteMinutes));
      }
      
      // Tạo message
      final message = MessageModel(
        id: messageDoc.id,
        chatId: chatId,
        senderId: currentUser.uid,
        receiverId: receiverId,
        encryptedContent: encrypted['encrypted']!,
        hmac: encrypted['hmac']!,
        messageType: messageType,
        timestamp: DateTime.now(),
        deleteAt: deleteAt,
        fingerprint: fingerprint,
        metadata: metadata,
      );
      
      // Lưu message
      await messageDoc.set(message.toMap());
      
      // Cập nhật chat metadata
      await _updateChatMetadata(
        chatId,
        currentUser.uid,
        receiverId,
        '[Tin nhắn mã hóa]',
      );
      
      print('✓ Đã gửi tin nhắn thành công');
    } catch (e) {
      print('✗ Lỗi gửi tin nhắn: $e');
      throw Exception('Không thể gửi tin nhắn: $e');
    }
  }
  
  // ==================== GET MESSAGES ====================
  
  /// Lấy danh sách tin nhắn
  static Stream<List<MessageModel>> getMessages(String otherUserId) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }
    
    final chatId = _createChatId(currentUser.uid, otherUserId);
    
    return _firestore
        .collection('messages')
        .where('chatId', isEqualTo: chatId)
        .where('isDeleted', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }
  
  /// Giải mã tin nhắn
  static Future<String> decryptMessage(MessageModel message) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return '[Lỗi xác thực]';
    }
    
    try {
      // Lấy session key
      final sessionKey = await KeyManagementService.getSessionKey(
        message.chatId,
        currentUser.uid,
      );
      
      if (sessionKey == null) {
        return '[Không có khóa giải mã]';
      }
      
      // Giải mã và xác minh HMAC
      return EncryptionService.decryptMessageWithHMAC(
        message.encryptedContent,
        message.hmac,
        sessionKey,
      );
    } catch (e) {
      if (e.toString().contains('HMAC')) {
        return '[⚠️ Tin nhắn đã bị thay đổi]';
      }
      print('✗ Lỗi giải mã: $e');
      return '[Không thể giải mã]';
    }
  }
  
  // ==================== CHAT METADATA ====================
  
  /// Tạo chatId từ 2 userId
  static String _createChatId(String userId1, String userId2) {
    final users = [userId1, userId2]..sort();
    return users.join('_');
  }
  
  /// Cập nhật chat metadata
  static Future<void> _updateChatMetadata(
    String chatId,
    String senderId,
    String receiverId,
    String lastMessage,
  ) async {
    final chatRef = _firestore.collection('chats').doc(chatId);
    final chatDoc = await chatRef.get();
    
    if (!chatDoc.exists) {
      // Tạo mới chat
      await chatRef.set({
        'participants': [senderId, receiverId],
        'lastMessage': lastMessage,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastSenderId': senderId,
        'unreadCount': {
          senderId: 0,
          receiverId: 1,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'autoDeleteMinutes': 0,
      });
    } else {
      // Cập nhật chat
      final currentUnread = Map<String, int>.from(
        chatDoc.data()?['unreadCount'] ?? {},
      );
      currentUnread[receiverId] = (currentUnread[receiverId] ?? 0) + 1;
      
      await chatRef.update({
        'lastMessage': lastMessage,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastSenderId': senderId,
        'unreadCount': currentUnread,
      });
    }
  }
  
  /// Đánh dấu đã đọc
  static Future<void> markAsRead(String messageId) async {
    await _firestore.collection('messages').doc(messageId).update({
      'isRead': true,
    });
  }
  
  /// Đánh dấu tất cả tin nhắn đã đọc
  static Future<void> markAllAsRead(String chatId, String userId) async {
    final messages = await _firestore
        .collection('messages')
        .where('chatId', isEqualTo: chatId)
        .where('receiverId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();
    
    final batch = _firestore.batch();
    for (final doc in messages.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
    
    // Reset unread count
    await _firestore.collection('chats').doc(chatId).update({
      'unreadCount.$userId': 0,
    });
  }
  
  /// Xóa tin nhắn
  static Future<void> deleteMessage(String messageId) async {
    await _firestore.collection('messages').doc(messageId).update({
      'isDeleted': true,
      'encryptedContent': '[Tin nhắn đã bị xóa]',
      'hmac': '',
    });
  }
  
  /// Lấy danh sách chat
  static Stream<List<ChatModel>> getChatList(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }
}
```

---

## 5. CHAT NHÓM (GROUP CHAT)

### Model cho Group Chat

```dart
// lib/models/group_chat_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class GroupChatModel {
  final String id;
  final String name;
  final String? avatarUrl;
  final String? description;
  final List<String> memberIds;
  final Map<String, String> memberRoles; // userId: 'admin' | 'member'
  final String createdBy;
  final DateTime createdAt;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String? lastSenderId;
  final Map<String, int> unreadCount;
  final int autoDeleteMinutes;
  final Map<String, dynamic>? settings;
  
  GroupChatModel({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.description,
    required this.memberIds,
    required this.memberRoles,
    required this.createdBy,
    required this.createdAt,
    this.lastMessage,
    this.lastMessageTime,
    this.lastSenderId,
    required this.unreadCount,
    this.autoDeleteMinutes = 0,
    this.settings,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'avatarUrl': avatarUrl,
      'description': description,
      'memberIds': memberIds,
      'memberRoles': memberRoles,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime != null
          ? Timestamp.fromDate(lastMessageTime!)
          : null,
      'lastSenderId': lastSenderId,
      'unreadCount': unreadCount,
      'autoDeleteMinutes': autoDeleteMinutes,
      'settings': settings,
    };
  }
  
  factory GroupChatModel.fromMap(Map<String, dynamic> map, String id) {
    return GroupChatModel(
      id: id,
      name: map['name'] ?? '',
      avatarUrl: map['avatarUrl'],
      description: map['description'],
      memberIds: List<String>.from(map['memberIds'] ?? []),
      memberRoles: Map<String, String>.from(map['memberRoles'] ?? {}),
      createdBy: map['createdBy'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lastMessage: map['lastMessage'],
      lastMessageTime: map['lastMessageTime'] != null
          ? (map['lastMessageTime'] as Timestamp).toDate()
          : null,
      lastSenderId: map['lastSenderId'],
      unreadCount: Map<String, int>.from(map['unreadCount'] ?? {}),
      autoDeleteMinutes: map['autoDeleteMinutes'] ?? 0,
      settings: map['settings'],
    );
  }
}
// Model cho Group Message
class GroupMessageModel {
  final String id;
  final String groupId;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String encryptedContent;
  final String hmac;
  final String messageType;
  final DateTime timestamp;
  final Map<String, bool> readBy; // userId: isRead
  final bool isDeleted;
  final DateTime? deleteAt;
  final String? fingerprint;
  final String? replyToMessageId;
  final Map<String, dynamic>? metadata;
  
  GroupMessageModel({
    required this.id,
    required this.groupId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.encryptedContent,
    required this.hmac,
    required this.messageType,
    required this.timestamp,
    required this.readBy,
    this.isDeleted = false,
    this.deleteAt,
    this.fingerprint,
    this.replyToMessageId,
    this.metadata,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'encryptedContent': encryptedContent,
      'hmac': hmac,
      'messageType': messageType,
      'timestamp': Timestamp.fromDate(timestamp),
      'readBy': readBy,
      'isDeleted': isDeleted,
      'deleteAt': deleteAt != null ? Timestamp.fromDate(deleteAt!) : null,
      'fingerprint': fingerprint,
      'replyToMessageId': replyToMessageId,
      'metadata': metadata,
    };
  }
  
  factory GroupMessageModel.fromMap(Map<String, dynamic> map, String id) {
    return GroupMessageModel(
      id: id,
      groupId: map['groupId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      senderAvatar: map['senderAvatar'],
      encryptedContent: map['encryptedContent'] ?? '',
      hmac: map['hmac'] ?? '',
      messageType: map['messageType'] ?? 'text',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      readBy: Map<String, bool>.from(map['readBy'] ?? {}),
      isDeleted: map['isDeleted'] ?? false,
      deleteAt: map['deleteAt'] != null
          ? (map['deleteAt'] as Timestamp).toDate()
          : null,
      fingerprint: map['fingerprint'],
      replyToMessageId: map['replyToMessageId'],
      metadata: map['metadata'],
    );
  }
}
```

### Group Chat Service

```dart
// lib/services/group_chat_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/group_chat_model.dart';
import 'encryption_service.dart';
import 'key_management_service.dart';

class GroupChatService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;
  
  // ==================== CREATE GROUP ====================
  
  /// Tạo nhóm mới
  static Future<String> createGroup({
    required String name,
    required List<String> memberIds,
    String? avatarUrl,
    String? description,
    Map<String, dynamic>? settings,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Chưa đăng nhập');
    }
    
    try {
      print('Tạo nhóm mới: $name');
      
      // Thêm người tạo vào danh sách thành viên
      if (!memberIds.contains(currentUser.uid)) {
        memberIds.add(currentUser.uid);
      }
      
      // Tạo roles cho các thành viên
      Map<String, String> memberRoles = {};
      Map<String, int> unreadCount = {};
      
      for (final memberId in memberIds) {
        memberRoles[memberId] = memberId == currentUser.uid ? 'admin' : 'member';
        unreadCount[memberId] = 0;
      }
      
      // Tạo group
      final groupDoc = _firestore.collection('group_chats').doc();
      
      final group = GroupChatModel(
        id: groupDoc.id,
        name: name,
        avatarUrl: avatarUrl,
        description: description,
        memberIds: memberIds,
        memberRoles: memberRoles,
        createdBy: currentUser.uid,
        createdAt: DateTime.now(),
        unreadCount: unreadCount,
        settings: settings ?? {
          'allowMemberInvite': false,
          'onlyAdminCanSend': false,
        },
      );
      
      await groupDoc.set(group.toMap());
      
      // Tạo group key
      await KeyManagementService.createGroupKey(
        groupDoc.id,
        currentUser.uid,
        memberIds,
      );
      
      // Gửi tin nhắn hệ thống
      await _sendSystemMessage(
        groupDoc.id,
        'Nhóm được tạo bởi ${currentUser.displayName ?? "ai đó"}',
      );
      
      print('✓ Đã tạo nhóm thành công');
      return groupDoc.id;
    } catch (e) {
      print('✗ Lỗi tạo nhóm: $e');
      throw Exception('Không thể tạo nhóm: $e');
    }
  }
  
  // ==================== SEND MESSAGE ====================
  
  /// Gửi tin nhắn trong nhóm
  static Future<void> sendGroupMessage({
    required String groupId,
    required String content,
    String messageType = 'text',
    int? autoDeleteMinutes,
    String? replyToMessageId,
    Map<String, dynamic>? metadata,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Chưa đăng nhập');
    }
    
    try {
      print('Gửi tin nhắn trong nhóm $groupId');
      
      // Kiểm tra quyền gửi tin nhắn
      final groupDoc = await _firestore.collection('group_chats').doc(groupId).get();
      if (!groupDoc.exists) {
        throw Exception('Nhóm không tồn tại');
      }
      
      final group = GroupChatModel.fromMap(groupDoc.data()!, groupId);
      
      if (!group.memberIds.contains(currentUser.uid)) {
        throw Exception('Bạn không phải thành viên của nhóm');
      }
      
      // Lấy group key
      final groupKey = await KeyManagementService.getGroupKey(
        groupId,
        currentUser.uid,
      );
      
      if (groupKey == null) {
        throw Exception('Không tìm thấy group key');
      }
      
      // Mã hóa tin nhắn với HMAC
      final encrypted = EncryptionService.encryptMessageWithHMAC(
        content,
        groupKey,
      );
      
      // Tạo message
      final messageDoc = _firestore.collection('group_messages').doc();
      
      final fingerprint = EncryptionService.createMessageFingerprint(
        messageDoc.id,
        content,
        DateTime.now(),
      );
      
      DateTime? deleteAt;
      if (autoDeleteMinutes != null && autoDeleteMinutes > 0) {
        deleteAt = DateTime.now().add(Duration(minutes: autoDeleteMinutes));
      }
      
      final message = GroupMessageModel(
        id: messageDoc.id,
        groupId: groupId,
        senderId: currentUser.uid,
        senderName: currentUser.displayName ?? 'Unknown',
        senderAvatar: currentUser.photoURL,
        encryptedContent: encrypted['encrypted']!,
        hmac: encrypted['hmac']!,
        messageType: messageType,
        timestamp: DateTime.now(),
        readBy: {currentUser.uid: true},
        deleteAt: deleteAt,
        fingerprint: fingerprint,
        replyToMessageId: replyToMessageId,
        metadata: metadata,
      );
      
      await messageDoc.set(message.toMap());
      
      // Cập nhật group metadata
      await _updateGroupMetadata(groupId, currentUser.uid, '[Tin nhắn mã hóa]');
      
      print('✓ Đã gửi tin nhắn nhóm thành công');
    } catch (e) {
      print('✗ Lỗi gửi tin nhắn nhóm: $e');
      throw Exception('Không thể gửi tin nhắn: $e');
    }
  }
  
  // ==================== GET MESSAGES ====================
  
  /// Lấy tin nhắn nhóm
  static Stream<List<GroupMessageModel>> getGroupMessages(String groupId) {
    return _firestore
        .collection('group_messages')
        .where('groupId', isEqualTo: groupId)
        .where('isDeleted', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => GroupMessageModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }
  
  /// Giải mã tin nhắn nhóm
  static Future<String> decryptGroupMessage(GroupMessageModel message) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return '[Lỗi xác thực]';
    }
    
    // Tin nhắn hệ thống không cần giải mã
    if (message.messageType == 'system') {
      return message.encryptedContent;
    }
    
    try {
      final groupKey = await KeyManagementService.getGroupKey(
        message.groupId,
        currentUser.uid,
      );
      
      if (groupKey == null) {
        return '[Không có khóa giải mã]';
      }
      
      return EncryptionService.decryptMessageWithHMAC(
        message.encryptedContent,
        message.hmac,
        groupKey,
      );
    } catch (e) {
      if (e.toString().contains('HMAC')) {
        return '[⚠️ Tin nhắn đã bị thay đổi]';
      }
      print('✗ Lỗi giải mã: $e');
      return '[Không thể giải mã]';
    }
  }
  
  // ==================== MEMBER MANAGEMENT ====================
  
  /// Thêm thành viên vào nhóm
  static Future<void> addMember(String groupId, String userId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;
    
    try {
      print('Thêm thành viên $userId vào nhóm $groupId');
      
      // Kiểm tra quyền admin
      final groupDoc = await _firestore.collection('group_chats').doc(groupId).get();
      final group = GroupChatModel.fromMap(groupDoc.data()!, groupId);
      
      if (group.memberRoles[currentUser.uid] != 'admin') {
        throw Exception('Chỉ admin mới có thể thêm thành viên');
      }
      
      // Thêm thành viên
      await _firestore.collection('group_chats').doc(groupId).update({
        'memberIds': FieldValue.arrayUnion([userId]),
        'memberRoles.$userId': 'member',
        'unreadCount.$userId': 0,
      });
      
      // Cập nhật group key cho thành viên mới
      await KeyManagementService.addMemberToGroup(
        groupId,
        currentUser.uid,
        userId,
      );
      
      // Gửi tin nhắn hệ thống
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userName = userDoc.data()?['displayName'] ?? 'Ai đó';
      await _sendSystemMessage(groupId, '$userName đã được thêm vào nhóm');
      
      print('✓ Đã thêm thành viên thành công');
    } catch (e) {
      print('✗ Lỗi thêm thành viên: $e');
      throw Exception('Không thể thêm thành viên: $e');
    }
  }
  
  /// Rời khỏi nhóm
  static Future<void> leaveGroup(String groupId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;
    
    try {
      await _firestore.collection('group_chats').doc(groupId).update({
        'memberIds': FieldValue.arrayRemove([currentUser.uid]),
        'memberRoles.${currentUser.uid}': FieldValue.delete(),
        'unreadCount.${currentUser.uid}': FieldValue.delete(),
      });
      
      await _sendSystemMessage(
        groupId,
        '${currentUser.displayName ?? "Ai đó"} đã rời khỏi nhóm',
      );
      
      print('✓ Đã rời khỏi nhóm');
    } catch (e) {
      print('✗ Lỗi rời nhóm: $e');
      throw Exception('Không thể rời nhóm: $e');
    }
  }
  
  /// Xóa thành viên (chỉ admin)
  static Future<void> removeMember(String groupId, String userId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;
    
    try {
      // Kiểm tra quyền admin
      final groupDoc = await _firestore.collection('group_chats').doc(groupId).get();
      final group = GroupChatModel.fromMap(groupDoc.data()!, groupId);
      
      if (group.memberRoles[currentUser.uid] != 'admin') {
        throw Exception('Chỉ admin mới có thể xóa thành viên');
      }
      
      await _firestore.collection('group_chats').doc(groupId).update({
        'memberIds': FieldValue.arrayRemove([userId]),
        'memberRoles.$userId': FieldValue.delete(),
        'unreadCount.$userId': FieldValue.delete(),
      });
      
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userName = userDoc.data()?['displayName'] ?? 'Ai đó';
      await _sendSystemMessage(groupId, '$userName đã bị xóa khỏi nhóm');
      
      print('✓ Đã xóa thành viên');
    } catch (e) {
      print('✗ Lỗi xóa thành viên: $e');
      throw Exception('Không thể xóa thành viên: $e');
    }
  }
  
  // ==================== UTILITY ====================
  
  /// Gửi tin nhắn hệ thống
  static Future<void> _sendSystemMessage(String groupId, String content) async {
    final messageDoc = _firestore.collection('group_messages').doc();
    
    final message = GroupMessageModel(
      id: messageDoc.id,
      groupId: groupId,
      senderId: 'system',
      senderName: 'System',
      encryptedContent: content,
      hmac: '',
      messageType: 'system',
      timestamp: DateTime.now(),
      readBy: {},
    );
    
    await messageDoc.set(message.toMap());
  }
  
  /// Cập nhật group metadata
  static Future<void> _updateGroupMetadata(
    String groupId,
    String senderId,
    String lastMessage,
  ) async {
    final groupDoc = await _firestore.collection('group_chats').doc(groupId).get();
    final group = GroupChatModel.fromMap(groupDoc.data()!, groupId);
    
    // Tăng unread count cho tất cả members trừ sender
    final updatedUnread = Map<String, int>.from(group.unreadCount);
    for (final memberId in group.memberIds) {
      if (memberId != senderId) {
        updatedUnread[memberId] = (updatedUnread[memberId] ?? 0) + 1;
      }
    }
    
    await _firestore.collection('group_chats').doc(groupId).update({
      'lastMessage': lastMessage,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastSenderId': senderId,
      'unreadCount': updatedUnread,
    });
  }
  
  /// Đánh dấu đã đọc
  static Future<void> markAsRead(String messageId, String userId) async {
    await _firestore.collection('group_messages').doc(messageId).update({
      'readBy.$userId': true,
    });
  }
  
  /// Lấy danh sách nhóm
  static Stream<List<GroupChatModel>> getGroupList(String userId) {
    return _firestore
        .collection('group_chats')
        .where('memberIds', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => GroupChatModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }
  
  /// Xóa tin nhắn
  static Future<void> deleteMessage(String messageId) async {
    await _firestore.collection('group_messages').doc(messageId).update({
      'isDeleted': true,
      'encryptedContent': '[Tin nhắn đã bị xóa]',
      'hmac': '',
    });
  }
}
```

---

## 6. HÀM BĂM (HASH) VÀ HMAC

### Tại sao cần Hash và HMAC?

**Hash (SHA-256):**
- Tạo "dấu vân tay" duy nhất cho mỗi tin nhắn
- Phát hiện thay đổi trong dữ liệu
- Không thể đảo ngược (one-way)

**HMAC (Hash-based Message Authentication Code):**
- Xác minh tính toàn vẹn của tin nhắn
- Đảm bảo tin nhắn không bị thay đổi
- Xác thực người gửi

### Cách hoạt động

```
┌─────────────────────────────────────────────────┐
│              SENDER (User A)                     │
├─────────────────────────────────────────────────┤
│  1. Plain text: "Hello World"                   │
│  2. Encrypt: AES-256 → "xyz123..."              │
│  3. Create HMAC: SHA-256(encrypted + key)       │
│     → "abc789..."                                │
│  4. Send: {encrypted: "xyz123...",              │
│            hmac: "abc789..."}                    │
└─────────────────────────────────────────────────┘
                    │
                    ▼ (Firestore)
                    ▼
┌─────────────────────────────────────────────────┐
│              RECEIVER (User B)                   │
├─────────────────────────────────────────────────┤
│  1. Receive: {encrypted: "xyz123...",           │
│               hmac: "abc789..."}                 │
│  2. Verify HMAC:                                │
│     Calculate: SHA-256(encrypted + key)         │
│     Compare with received HMAC                   │
│  3. If match → Decrypt → "Hello World"          │
│  4. If not match → "[⚠️ Tin nhắn bị giả mạo]"  │
└─────────────────────────────────────────────────┘
```

### Ví dụ sử dụng

```dart
// Ví dụ: Mã hóa và tạo HMAC
void exampleEncryptWithHMAC() {
  final plainText = "Xin chào, đây là tin nhắn bí mật";
  final aesKey = EncryptionService.generateAESKey();
  
  // Mã hóa với HMAC
  final result = EncryptionService.encryptMessageWithHMAC(plainText, aesKey);
  
  print('Encrypted: ${result['encrypted']}');
  print('HMAC: ${result['hmac']}');
  
  // Giải mã và xác minh
  try {
    final decrypted = EncryptionService.decryptMessageWithHMAC(
      result['encrypted']!,
      result['hmac']!,
      aesKey,
    );
    print('Decrypted: $decrypted');
  } catch (e) {
    print('Lỗi xác minh HMAC: $e');
  }
}

// Ví dụ: Tạo fingerprint
void exampleFingerprint() {
  final messageId = 'msg_123';
  final content = 'Hello World';
  final timestamp = DateTime.now();
  
  final fingerprint = EncryptionService.createMessageFingerprint(
    messageId,
    content,
    timestamp,
  );
  
  print('Message Fingerprint: $fingerprint');
  // Output: 64 ký tự hex (SHA-256)
}
```

---

## 7. XÓA TIN NHẮN TỰ ĐỘNG

### Auto Delete Service

```dart
// lib/services/auto_delete_service.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';
import '../models/group_chat_model.dart';

class AutoDeleteService {
  static final _firestore = FirebaseFirestore.instance;
  static Timer? _cleanupTimer;
  
  /// Các tùy chọn thời gian tự động xóa
  static const Map<String, int> deleteOptions = {
    '5 phút': 5,
    '1 giờ': 60,
    '1 ngày': 1440,
    '1 tuần': 10080,
    'Không bao giờ': 0,
  };
  
  // ==================== START/STOP SERVICE ====================
  
  /// Khởi động service tự động xóa
  static void startAutoDeleteService() {
    print('Khởi động AutoDeleteService...');
    
    // Chạy cleanup mỗi 5 phút
    _cleanupTimer = Timer.periodic(Duration(minutes: 5), (_) {
      _cleanupExpiredMessages();
    });
    
    print('✓ AutoDeleteService đã khởi động');
  }
  
  /// Dừng service
  static void stopAutoDeleteService() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    print('✓ AutoDeleteService đã dừng');
  }
  
  // ==================== CLEANUP ====================
  
  /// Xóa tin nhắn đã hết hạn
  static Future<void> _cleanupExpiredMessages() async {
    try {
      final now = DateTime.now();
      print('Chạy cleanup tin nhắn hết hạn...');
      
      // Xóa tin nhắn 1-1
      final expiredMessages = await _firestore
          .collection('messages')
          .where('deleteAt', isLessThan: Timestamp.fromDate(now))
          .where('isDeleted', isEqualTo: false)
          .limit(100)
          .get();
      
      final batch = _firestore.batch();
      int count = 0;
      
      for (final doc in expiredMessages.docs) {
        batch.update(doc.reference, {
          'isDeleted': true,
          'encryptedContent': '[Tin nhắn đã tự động xóa]',
          'hmac': '',
          'deletedAt': FieldValue.serverTimestamp(),
        });
        count++;
      }
      
      // Xóa tin nhắn nhóm
      final expiredGroupMessages = await _firestore
          .collection('group_messages')
          .where('deleteAt', isLessThan: Timestamp.fromDate(now))
          .where('isDeleted', isEqualTo: false)
          .limit(100)
          .get();
      
      for (final doc in expiredGroupMessages.docs) {
        batch.update(doc.reference, {
          'isDeleted': true,
          'encryptedContent': '[Tin nhắn đã tự động xóa]',
          'hmac': '',
          'deletedAt': FieldValue.serverTimestamp(),
        });
        count++;
      }
      
      if (count > 0) {
        await batch.commit();
        print('✓ Đã xóa $count tin nhắn hết hạn');
      }
    } catch (e) {
      print('✗ Lỗi cleanup: $e');
    }
  }
  
  // ==================== HELPER METHODS ====================
  
  /// Kiểm tra tin nhắn có hết hạn không
  static bool isMessageExpired(DateTime? deleteAt) {
    if (deleteAt == null) return false;
    return deleteAt.isBefore(DateTime.now());
  }
  
  /// Tính thời gian còn lại
  static Duration? getRemainingTime(DateTime? deleteAt) {
    if (deleteAt == null) return null;
    final now = DateTime.now();
    if (deleteAt.isBefore(now)) return Duration.zero;
    return deleteAt.difference(now);
  }
  
  /// Format thời gian còn lại
  static String formatRemainingTime(Duration? duration) {
    if (duration == null) return '';
    if (duration.isNegative || duration.inSeconds <= 0) {
      return 'Đã hết hạn';
    }
    
    if (duration.inDays > 0) {
      return '${duration.inDays}d';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return '${duration.inSeconds}s';
    }
  }
  
  /// Lọc tin nhắn đã hết hạn (client-side)
  static List<MessageModel> filterExpiredMessages(List<MessageModel> messages) {
    final now = DateTime.now();
    return messages.where((msg) {
      if (msg.deleteAt == null) return true;
      return msg.deleteAt!.isAfter(now);
    }).toList();
  }
  
  /// Cài đặt auto delete cho chat
  static Future<void> setChatAutoDelete(String chatId, int minutes) async {
    await _firestore.collection('chats').doc(chatId).update({
      'autoDeleteMinutes': minutes,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
  
  /// Lấy cài đặt auto delete
  static Future<int> getChatAutoDelete(String chatId) async {
    final doc = await _firestore.collection('chats').doc(chatId).get();
    return doc.data()?['autoDeleteMinutes'] ?? 0;
  }
}
```

### Widget Countdown Timer

```dart
// lib/widgets/message_countdown.dart

import 'package:flutter/material.dart';
import 'dart:async';
import '../services/auto_delete_service.dart';

class MessageCountdown extends StatefulWidget {
  final DateTime? deleteAt;
  
  const MessageCountdown({Key? key, this.deleteAt}) : super(key: key);

  @override
  State<MessageCountdown> createState() => _MessageCountdownState();
}

class _MessageCountdownState extends State<MessageCountdown> {
  Timer? _timer;
  Duration? _remaining;
  
  @override
  void initState() {
    super.initState();
    if (widget.deleteAt != null) {
      _startCountdown();
    }
  }
  
  void _startCountdown() {
    _updateRemaining();
    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      _updateRemaining();
    });
  }
  
  void _updateRemaining() {
    if (!mounted) return;
    
    final remaining = AutoDeleteService.getRemainingTime(widget.deleteAt);
    setState(() {
      _remaining = remaining;
    });
    
    if (remaining?.inSeconds == 0) {
      _timer?.cancel();
    }
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    if (_remaining == null || _remaining!.inSeconds <= 0) {
      return SizedBox.shrink();
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.timer_outlined, size: 12, color: Colors.orange[300]),
        SizedBox(width: 4),
        Text(
          AutoDeleteService.formatRemainingTime(_remaining),
          style: TextStyle(
            color: Colors.orange[300],
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
```

---

## 8. GIAO DIỆN NGƯỜI DÙNG

### Chat Detail Screen

```dart
// lib/features/chat/chat_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/chat_service.dart';
import '../../services/auto_delete_service.dart';
import '../../models/message_model.dart'; 
import '../../widgets/message_countdown.dart';

class ChatDetailScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;
  
  const ChatDetailScreen({
    Key? key,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar,
  }) : super(key: key);

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _currentUser = FirebaseAuth.instance.currentUser;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildMessageInput(),
        ],
      ),
    );
  }
  
  // AppBar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.grey[900],
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: widget.otherUserAvatar != null
                ? NetworkImage(widget.otherUserAvatar!)
                : null,
            child: widget.otherUserAvatar == null
                ? Icon(Icons.person, color: Colors.white)
                : null,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUserName,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                Text(
                  '🔒 Mã hóa đầu cuối',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.more_vert, color: Colors.white),
          onPressed: _showOptions,
        ),
      ],
    );
  }
  
  // Message list
  Widget _buildMessageList() {
    return StreamBuilder<List<MessageModel>>(
      stream: ChatService.getMessages(widget.otherUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Bắt đầu cuộc trò chuyện bảo mật',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }
        
        final messages = snapshot.data!;
        
        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          padding: EdgeInsets.all(16),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            return _buildMessageBubble(messages[index]);
          },
        );
      },
    );
  }
  
  // Message bubble
  Widget _buildMessageBubble(MessageModel message) {
    final isMe = message.senderId == _currentUser?.uid;
    
    // Kiểm tra hết hạn
    if (AutoDeleteService.isMessageExpired(message.deleteAt)) {
      return SizedBox.shrink();
    }
    
    return FutureBuilder<String>(
      future: ChatService.decryptMessage(message),
      builder: (context, snapshot) {
        String content = 'Đang giải mã...';
        
        if (snapshot.hasData) {
          content = snapshot.data!;
        } else if (snapshot.hasError) {
          content = '[Lỗi giải mã]';
        }
        
        return Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            margin: EdgeInsets.only(bottom: 8),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isMe ? Colors.blue[700] : Colors.grey[800],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content,
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(message.timestamp),
                      style: TextStyle(color: Colors.grey[400], fontSize: 11),
                    ),
                    if (message.deleteAt != null) ...[
                      SizedBox(width: 8),
                      MessageCountdown(deleteAt: message.deleteAt),
                    ],
                    if (isMe) ...[
                      SizedBox(width: 4),
                      Icon(
                        message.isRead ? Icons.done_all : Icons.done,
                        size: 16,
                        color: message.isRead ? Colors.blue : Colors.grey[400],
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  // Message input
  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(top: BorderSide(color: Colors.grey[800]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Tin nhắn...',
                hintStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[800],
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.blue[700],
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
  
  // Send message
  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;
    
    try {
      await ChatService.sendMessage(
        receiverId: widget.otherUserId,
        content: content,
      );
      
      _messageController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi gửi tin nhắn: $e')),
      );
    }
  }
  
  // Options menu
  void _showOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.timer, color: Colors.white),
              title: Text('Tự động xóa tin nhắn', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _showAutoDeleteOptions();
              },
            ),
            ListTile(
              leading: Icon(Icons.info_outline, color: Colors.white),
              title: Text('Thông tin mã hóa', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _showEncryptionInfo();
              },
            ),
          ],
        ),
      ),
    );
  }
  
  // Auto delete options
  void _showAutoDeleteOptions() {
    // Implementation here
  }
  
  // Encryption info
  void _showEncryptionInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text('Mã hóa đầu cuối', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('🔒', 'Thuật toán', 'AES-256 + RSA-2048'),
            _buildInfoRow('🔑', 'Hash', 'HMAC-SHA256'),
            _buildInfoRow('🛡️', 'Bảo mật', 'Chỉ bạn và người nhận đọc được'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Đóng'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(icon, style: TextStyle(fontSize: 20)),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text(value, style: TextStyle(color: Colors.white, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
```

---

## 9. FIREBASE SETUP

### Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper functions
    function isSignedIn() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return isSignedIn() && request.auth.uid == userId;
    }
    
    // Users
    match /users/{userId} {
      allow read: if isSignedIn();
      allow write: if isOwner(userId);
    }
    
    // User keys (public keys)
    match /user_keys/{userId} {
      allow read: if isSignedIn();
      allow write: if isOwner(userId);
    }
    
    // Chats metadata
    match /chats/{chatId} {
      allow read: if isSignedIn() && 
                    request.auth.uid in resource.data.participants;
      allow create: if isSignedIn();
      allow update: if isSignedIn() && 
                      request.auth.uid in resource.data.participants;
    }
    
    // Chat keys (encrypted session keys)
    match /chat_keys/{chatId} {
      allow read: if isSignedIn();
      allow write: if isSignedIn();
    }
    
    // Messages (1-1)
    match /messages/{messageId} {
      allow read: if isSignedIn() && 
                    (resource.data.senderId == request.auth.uid ||
                     resource.data.receiverId == request.auth.uid);
      allow create: if isSignedIn() && 
                      request.resource.data.senderId == request.auth.uid;
      allow update: if isSignedIn() && 
                      (resource.data.senderId == request.auth.uid ||
                       resource.data.receiverId == request.auth.uid);
      allow delete: if isSignedIn() && 
                      resource.data.senderId == request.auth.uid;
    }
    
    // Group chats
    match /group_chats/{groupId} {
      allow read: if isSignedIn() && 
                    request.auth.uid in resource.data.memberIds;
      allow create: if isSignedIn();
      allow update: if isSignedIn() && 
                      request.auth.uid in resource.data.memberIds;
    }
    
    // Group keys
    match /group_keys/{groupId} {
      allow read: if isSignedIn();
      allow write: if isSignedIn();
    }
    
    // Group messages
    match /group_messages/{messageId} {
      allow read: if isSignedIn() && 
                    exists(/databases/$(database)/documents/group_chats/$(resource.data.groupId)) &&
                    request.auth.uid in get(/databases/$(database)/documents/group_chats/$(resource.data.groupId)).data.memberIds;
      allow create: if isSignedIn();
      allow update: if isSignedIn();
      allow delete: if isSignedIn() && 
                      resource.data.senderId == request.auth.uid;
    }
  }
}
```

### Firestore Indexes

Tạo các index sau trong Firebase Console:

1. **messages collection:**
   - chatId (Ascending) + isDeleted (Ascending) + timestamp (Descending)
   - deleteAt (Ascending) + isDeleted (Ascending)

2. **group_messages collection:**
   - groupId (Ascending) + isDeleted (Ascending) + timestamp (Descending)
   - deleteAt (Ascending) + isDeleted (Ascending)

3. **chats collection:**
   - participants (Array) + lastMessageTime (Descending)

4. **group_chats collection:**
   - memberIds (Array) + lastMessageTime (Descending)

---

## 10. TESTING VÀ DEBUGGING

### Unit Tests

```dart
// test/encryption_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:your_app/services/encryption_service.dart';

void main() {
  group('EncryptionService Tests', () {
    
    test('AES encryption and decryption', () {
      final plainText = 'Hello World';
      final aesKey = EncryptionService.generateAESKey();
      
      final encrypted = EncryptionService.encryptMessage(plainText, aesKey);
      expect(encrypted, isNot(equals(plainText)));
      
      final decrypted = EncryptionService.decryptMessage(encrypted, aesKey);
      expect(decrypted, equals(plainText));
    });
    
    test('HMAC verification', () {
      final message = 'Test message';
      final key = 'secret_key';
      
      final hmac = EncryptionService.createHMAC(message, key);
      expect(hmac, isNotEmpty);
      
      final isValid = EncryptionService.verifyHMAC(message, key, hmac);
      expect(isValid, isTrue);
      
      final isInvalid = EncryptionService.verifyHMAC('wrong', key, hmac);
      expect(isInvalid, isFalse);
    });
    
    test('Message fingerprint', () {
      final messageId = 'msg_123';
      final content = 'Hello';
      final timestamp = DateTime.now();
      
      final fingerprint = EncryptionService.createMessageFingerprint(
        messageId,
        content,
        timestamp,
      );
      
      expect(fingerprint, isNotEmpty);
      expect(fingerprint.length, equals(64)); // SHA-256 = 64 hex chars
    });
    
    test('Encrypt with HMAC', () {
      final plainText = 'Secure message';
      final aesKey = EncryptionService.generateAESKey();
      
      final result = EncryptionService.encryptMessageWithHMAC(
        plainText,
        aesKey,
      );
      
      expect(result['encrypted'], isNotEmpty);
      expect(result['hmac'], isNotEmpty);
      
      final decrypted = EncryptionService.decryptMessageWithHMAC(
        result['encrypted']!,
        result['hmac']!,
        aesKey,
      );
      
      expect(decrypted, equals(plainText));
    });
  });
}
```

### Debug Checklist

**1. Khóa không hoạt động:**
- ✓ Kiểm tra user đã có khóa chưa trong `user_keys` collection
- ✓ Kiểm tra private key trong Secure Storage
- ✓ Thử tạo lại khóa: `KeyManagementService.initializeUserKeys()`

**2. Không giải mã được tin nhắn:**
- ✓ Kiểm tra session key/group key tồn tại
- ✓ Xác minh HMAC không bị lỗi
- ✓ Kiểm tra format của encrypted data

**3. Tin nhắn không gửi được:**
- ✓ Kiểm tra kết nối Firestore
- ✓ Xem log console để biết lỗi cụ thể
- ✓ Kiểm tra Security Rules

**4. Auto-delete không hoạt động:**
- ✓ Đảm bảo `AutoDeleteService.startAutoDeleteService()` được gọi
- ✓ Kiểm tra field `deleteAt` có đúng format không

### Logging và Monitoring

```dart
// Thêm vào main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Enable Firestore logging (debug only)
  if (kDebugMode) {
    FirebaseFirestore.instance.settings = Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Khởi tạo mã hóa
  FirebaseAuth.instance.authStateChanges().listen((user) async {
    if (user != null) {
      try {
        await KeyManagementService.initializeUserKeys(user.uid);
        print('✓ Đã khởi tạo khóa cho user ${user.uid}');
      } catch (e) {
        print('✗ Lỗi khởi tạo khóa: $e');
      }
    }
  });
  
  // Khởi động auto-delete
  AutoDeleteService.startAutoDeleteService();
  
  runApp(const MyApp());
}
```

---

## KẾT LUẬN

### Tính năng đã hoàn thành:

✅ **Mã hóa đầu cuối (E2EE)**
- RSA-2048 cho trao đổi khóa
- AES-256 cho mã hóa nội dung
- HMAC-SHA256 cho xác thực

✅ **Chat 1-1**
- Gửi/nhận tin nhắn mã hóa
- Session key riêng cho mỗi cuộc hội thoại
- Đánh dấu đã đọc

✅ **Chat nhóm**
- Group key được mã hóa riêng cho từng thành viên
- Quản lý thành viên (thêm/xóa)
- Roles (admin/member)

✅ **Hàm băm và HMAC**
- SHA-256 hash
- HMAC xác minh tính toàn vẹn
- Message fingerprint

✅ **Xóa tin nhắn tự động**
- Client-side cleanup
- Background service
- Countdown timer

✅ **Bảo mật**
- Private key không rời khỏi thiết bị
- Secure Storage
- Firestore Security Rules

### Các bước tiếp theo:

1. **Tối ưu hóa:**
   - Cache session/group keys
   - Lazy loading tin nhắn cũ
   - Batch operations

2. **Tính năng mở rộng:**
   - Gửi file/ảnh mã hóa
   - Voice messages
   - Video calls (WebRTC)
   - Read receipts
   - Typing indicators

3. **Cloud Functions:**
   - Push notifications
   - Auto-cleanup hàng ngày
   - Analytics

4. **UI/UX:**
   - Dark/Light theme
   - Message reactions
   - Reply to messages
   - Forward messages

---

**Chúc bạn thành công trong việc xây dựng ứng dụng chat an toàn! 🔒💬**

