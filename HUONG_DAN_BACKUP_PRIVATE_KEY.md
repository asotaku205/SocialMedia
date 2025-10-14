# HƯỚNG DẪN BACKUP VÀ RESTORE PRIVATE KEY

## MỤC LỤC
1. [Vấn đề cần giải quyết](#1-vấn-đề-cần-giải-quyết)
2. [So sánh 3 giải pháp](#2-so-sánh-3-giải-pháp)
3. [Giải pháp 1: Cloud Backup (Đã implement)](#3-giải-pháp-1-cloud-backup-đã-implement)
4. [Giải pháp 2: Recovery Code](#4-giải-pháp-2-recovery-code)
5. [Giải pháp 3: Multi-Device Sync](#5-giải-pháp-3-multi-device-sync)
6. [Cách sử dụng](#6-cách-sử-dụng)
7. [Security Best Practices](#7-security-best-practices)

---

## 1. VẤN ĐỀ CẦN GIẢI QUYẾT

### Các trường hợp user mất Private Key:

❌ **Xóa app và cài lại**
- Private Key lưu trong Secure Storage
- Xóa app → Xóa tất cả dữ liệu local
- Khi cài lại → Không có Private Key → Không đọc được tin nhắn cũ

❌ **Đổi thiết bị mới**
- Private Key chỉ tồn tại trên thiết bị cũ
- Đăng nhập trên thiết bị mới → Tạo Private Key mới
- Private Key mới ≠ Private Key cũ → Không đọc được tin nhắn cũ

❌ **Đổi mật khẩu Firebase**
- Mật khẩu Firebase ≠ Private Key
- Đổi mật khẩu không ảnh hưởng Private Key
- **NHƯNG:** Nếu logout và login lại → có thể mất Private Key (nếu app xóa local data)

---

## 2. SO SÁNH 3 GIẢI PHÁP

| Tiêu chí | Cloud Backup | Recovery Code | Multi-Device Sync |
|----------|-------------|---------------|-------------------|
| **Độ khó implement** | ⭐⭐ Dễ | ⭐⭐⭐ Trung bình | ⭐⭐⭐⭐⭐ Khó |
| **Bảo mật** | ⭐⭐⭐⭐ Tốt | ⭐⭐⭐⭐⭐ Rất tốt | ⭐⭐⭐ Trung bình |
| **UX (Trải nghiệm)** | ⭐⭐⭐⭐⭐ Tốt nhất | ⭐⭐⭐ OK | ⭐⭐⭐⭐ Tốt |
| **Chi phí phát triển** | Thấp | Trung bình | Cao |
| **Phù hợp cho** | App cá nhân/SME | Enterprise | App lớn |

### Đề xuất:
- ✅ **Cloud Backup**: Tốt nhất cho project này (đã implement)
- ✅ **Recovery Code**: Có thể thêm như backup plan
- ❌ **Multi-Device Sync**: Không cần thiết (quá phức tạp)

---

## 3. GIẢI PHÁP 1: CLOUD BACKUP (Đã implement)

### Cách hoạt động:

```
┌─────────────────────────────────────────────────────────────────┐
│                    CLOUD BACKUP WORKFLOW                         │
└─────────────────────────────────────────────────────────────────┘

[User Device]                 [Firebase]                [New Device]
     │                            │                          │
     │ ① Nhập password backup     │                          │
     │    "MySecurePass123"       │                          │
     │                            │                          │
     │ ② Derive encryption key    │                          │
     │    PBKDF2(password, salt)  │                          │
     │    → K_encrypt             │                          │
     │                            │                          │
     │ ③ Mã hóa Private Key       │                          │
     │    Encrypted_PK = AES(     │                          │
     │      PrivateKey,            │                          │
     │      K_encrypt              │                          │
     │    )                        │                          │
     │                            │                          │
     │ ④ Upload backup             │                          │
     │───────────────────────────>│                          │
     │    POST /key_backups/{uid} │                          │
     │    {                        │                          │
     │      encryptedPrivateKey,  │                          │
     │      iv, hmac, checksum    │                          │
     │    }                        │                          │
     │                            │                          │
     │                            │ ⑤ Đổi thiết bị          │
     │                            │<─────────────────────────│
     │                            │   Login với Firebase     │
     │                            │                          │
     │                            │ ⑥ Download backup       │
     │                            │─────────────────────────>│
     │                            │   GET /key_backups/{uid} │
     │                            │                          │
     │                            │ ⑦ Nhập password         │
     │                            │<─────────────────────────│
     │                            │   "MySecurePass123"      │
     │                            │                          │
     │                            │ ⑧ Derive key & Decrypt  │
     │                            │─────────────────────────>│
     │                            │   PrivateKey restored ✓  │
```

### Ưu điểm:
✅ **Dễ implement**: Chỉ cần 1 service + 1 UI screen  
✅ **UX tốt**: User chỉ cần nhớ 1 password  
✅ **Tự động**: Backup 1 lần, restore mọi lúc  
✅ **An toàn**: Private Key được mã hóa trước khi upload  

### Nhược điểm:
⚠️ **Server có thể truy cập**: Firebase lưu backup (đã mã hóa)  
⚠️ **Phụ thuộc password**: Quên password = mất backup  
⚠️ **Single point of failure**: Nếu Firebase down thì không restore được  

### Bảo mật:

```dart
// PBKDF2 Key Derivation
Password "MyPass123" + Salt (userId)
  ↓ 10,000 iterations
  ↓ HMAC-SHA256
  ↓
K_encrypt = "x7J9mK2pQ..." (256-bit)

// AES-256 Encryption
PrivateKey (plain)
  ↓ AES-256-CBC
  ↓ Key = K_encrypt
  ↓ IV = random(128-bit)
  ↓
Encrypted_PrivateKey + HMAC

// Upload to Firebase
{
  encryptedPrivateKey: "abc123...",  ← Đã mã hóa
  iv: "xyz789...",                    ← IV để giải mã
  hmac: "def456...",                  ← Xác thực toàn vẹn
  checksum: "ghi789...",              ← Verify sau khi giải mã
}
```

**Kết luận**: Server chỉ lưu dữ liệu đã mã hóa, không thể giải mã nếu không có password.

---

## 4. GIẢI PHÁP 2: RECOVERY CODE

### Cách hoạt động:

```
┌─────────────────────────────────────────────────────────────────┐
│                   RECOVERY CODE WORKFLOW                         │
└─────────────────────────────────────────────────────────────────┘

[App Setup]                      [User]                [Recovery]
     │                              │                       │
     │ ① Tạo Private Key            │                       │
     │                              │                       │
     │ ② Tạo 12 từ ngẫu nhiên       │                       │
     │    (BIP39 Mnemonic)          │                       │
     │                              │                       │
     │    "apple banana cat dog     │                       │
     │     elephant fox goat house  │                       │
     │     island juice king lion"  │                       │
     │                              │                       │
     │ ③ Derive seed từ 12 từ      │                       │
     │    Seed = PBKDF2(words)      │                       │
     │                              │                       │
     │ ④ Mã hóa Private Key         │                       │
     │    Encrypted_PK = AES(       │                       │
     │      PrivateKey, Seed        │                       │
     │    )                          │                       │
     │                              │                       │
     │ ⑤ Hiển thị 12 từ cho user    │                       │
     │─────────────────────────────>│                       │
     │                              │                       │
     │                              │ ⑥ Ghi ra giấy ✍️      │
     │                              │   Cất an toàn 🔒      │
     │                              │                       │
     │                              │                       │
     │                              │ ⑦ Đổi thiết bị       │
     │                              │──────────────────────>│
     │                              │                       │
     │                              │ ⑧ Nhập 12 từ         │
     │<─────────────────────────────────────────────────────│
     │                              │                       │
     │ ⑨ Derive seed & Decrypt      │                       │
     │    PrivateKey restored ✓     │                       │
```

### Implementation (Optional - có thể thêm):

```dart
// lib/services/recovery_code_service.dart

import 'package:bip39/bip39.dart' as bip39;

class RecoveryCodeService {
  /// Tạo 12 từ recovery
  static String generateRecoveryPhrase() {
    // Tạo 12 từ ngẫu nhiên (BIP39)
    return bip39.generateMnemonic();
    // Ví dụ: "apple banana cat dog elephant fox goat house island juice king lion"
  }
  
  /// Mã hóa Private Key bằng recovery phrase
  static Future<String> encryptWithRecovery(
    String privateKey,
    String recoveryPhrase,
  ) async {
    // Validate recovery phrase
    if (!bip39.validateMnemonic(recoveryPhrase)) {
      throw Exception('Recovery phrase không hợp lệ');
    }
    
    // Derive seed từ recovery phrase
    final seed = bip39.mnemonicToSeedHex(recoveryPhrase);
    
    // Mã hóa Private Key bằng AES
    return EncryptionService.encryptMessage(privateKey, seed);
  }
  
  /// Giải mã Private Key từ recovery phrase
  static Future<String> decryptWithRecovery(
    String encryptedPrivateKey,
    String recoveryPhrase,
  ) async {
    // Validate
    if (!bip39.validateMnemonic(recoveryPhrase)) {
      throw Exception('Recovery phrase không hợp lệ');
    }
    
    // Derive seed
    final seed = bip39.mnemonicToSeedHex(recoveryPhrase);
    
    // Giải mã
    return EncryptionService.decryptMessage(encryptedPrivateKey, seed);
  }
}
```

### Ưu điểm:
✅ **Bảo mật cao nhất**: Không lưu gì trên server  
✅ **Offline**: Không cần internet để restore  
✅ **Standard**: BIP39 là chuẩn công nghiệp (Bitcoin wallet)  
✅ **User control**: User hoàn toàn kiểm soát  

### Nhược điểm:
⚠️ **UX kém**: User phải ghi ra giấy và cất giữ cẩn thận  
⚠️ **Dễ mất**: Giấy bị mất/hỏng = mất Private Key  
⚠️ **Phức tạp**: User có thể không hiểu cách dùng  

---

## 5. GIẢI PHÁP 3: MULTI-DEVICE SYNC

### Cách hoạt động:

```
┌─────────────────────────────────────────────────────────────────┐
│                  MULTI-DEVICE SYNC WORKFLOW                      │
└─────────────────────────────────────────────────────────────────┘

[Phone]                    [Firebase]                   [Laptop]
   │                           │                            │
   │ ① Login                   │                            │
   │──────────────────────────>│                            │
   │                           │                            │
   │ ② Tạo cặp khóa RSA       │                            │
   │    PubKey_Phone           │                            │
   │    PrivateKey_Phone       │                            │
   │                           │                            │
   │ ③ Upload PubKey           │                            │
   │──────────────────────────>│                            │
   │                           │                            │
   │                           │ ④ Login từ laptop         │
   │                           │<───────────────────────────│
   │                           │                            │
   │                           │ ⑤ Gửi notification        │
   │<──────────────────────────│                            │
   │  "Xác nhận thiết bị mới?" │                            │
   │                           │                            │
   │ ⑥ User xác nhận ✓         │                            │
   │                           │                            │
   │ ⑦ Lấy PubKey_Laptop       │                            │
   │<──────────────────────────│                            │
   │                           │                            │
   │ ⑧ Mã hóa PrivateKey_Phone │                            │
   │    Encrypted_PK = RSA(    │                            │
   │      PrivateKey_Phone,    │                            │
   │      PubKey_Laptop        │                            │
   │    )                       │                            │
   │                           │                            │
   │ ⑨ Gửi cho Laptop          │                            │
   │──────────────────────────>│───────────────────────────>│
   │                           │                            │
   │                           │ ⑩ Giải mã bằng            │
   │                           │    PrivateKey_Laptop      │
   │                           │    → PrivateKey_Phone ✓   │
```

### Ưu điểm:
✅ **Seamless**: Tự động sync giữa các thiết bị  
✅ **Secure**: Private Key mã hóa riêng cho từng thiết bị  
✅ **Flexible**: Thêm/xóa thiết bị dễ dàng  

### Nhược điểm:
⚠️ **Phức tạp**: Cần implement nhiều logic  
⚠️ **Phụ thuộc thiết bị cũ**: Phải có thiết bị cũ để sync  
⚠️ **Chi phí cao**: Tốn nhiều thời gian phát triển  

### Khi nào nên dùng:
- App có tính năng multi-device (Telegram, WhatsApp)
- User thường xuyên dùng nhiều thiết bị
- Có đội ngũ dev lớn

---

## 6. CÁCH SỬ DỤNG

### A. Backup Private Key

**Bước 1**: Mở app → Settings → "Backup Private Key"

**Bước 2**: Nhập password backup (tự chọn, không phải password Firebase)

```
💡 Lưu ý chọn password:
✅ Dễ nhớ nhưng khó đoán
✅ Ít nhất 6 ký tự
✅ Không dùng chung với password khác
✅ Ghi nhớ hoặc lưu vào password manager

Ví dụ tốt:
- "MyChat2025@Safe"
- "FamilySecrets#123"
- "Remember-This-Key"

Ví dụ tệ:
- "123456"
- "password"
- "qwerty"
```

**Bước 3**: Nhấn "Backup Private Key"

**Bước 4**: Backup thành công! 🎉

```
✅ Backup thành công!

✓ Private Key đã được mã hóa và lưu trữ an toàn
⚠️ Hãy nhớ mật khẩu này để restore khi cần

[OK]
```

---

### B. Restore Private Key

**Trường hợp**: Bạn đã xóa app, cài lại, hoặc đổi thiết bị mới

**Bước 1**: Đăng nhập Firebase như bình thường

**Bước 2**: Mở Settings → "Backup Private Key"

**Bước 3**: App hiển thị: "Đã có backup"

**Bước 4**: Nhập password backup (password bạn đã dùng khi backup)

**Bước 5**: Nhấn "Restore Private Key"

**Bước 6**: Nếu password đúng:

```
✅ Restore thành công!

✓ Private Key đã được khôi phục
💬 Bây giờ bạn có thể xem lại tin nhắn cũ

[OK]
```

**Bước 7**: Mở chat → Xem lại tin nhắn cũ ✅

---

### C. Xóa Backup (Optional)

**Khi nào cần xóa**:
- Không muốn lưu backup trên cloud
- Đổi sang dùng Recovery Code
- Muốn tạo backup mới với password khác

**Cách xóa**:
1. Settings → "Backup Private Key"
2. Nhấn "Xóa backup"
3. Xác nhận

⚠️ **Cảnh báo**: Sau khi xóa, nếu mất Private Key thì không thể khôi phục!

---

## 7. SECURITY BEST PRACTICES

### Cho User:

✅ **DO**:
- Backup Private Key ngay sau khi tạo tài khoản
- Dùng password mạnh và unique
- Test restore trước khi xóa app
- Lưu password vào password manager (1Password, Bitwarden)
- Backup định kỳ nếu thay đổi Private Key

❌ **DON'T**:
- Dùng password quá đơn giản
- Chia sẻ password backup cho người khác
- Lưu password trong tin nhắn/email không mã hóa
- Quên password backup

---

### Cho Developer:

✅ **DO**:
- Dùng PBKDF2 với ít nhất 10,000 iterations
- Luôn verify HMAC trước khi giải mã
- Kiểm tra checksum sau khi restore
- Log các lỗi để debug (không log password)
- Test trên nhiều thiết bị

❌ **DON'T**:
- Lưu password plain text
- Skip HMAC verification
- Dùng password làm encryption key trực tiếp
- Bỏ qua error handling

---

### Firestore Security Rules:

```javascript
// Cho phép user chỉ đọc/ghi backup của mình
match /key_backups/{userId} {
  allow read, write: if request.auth != null 
                     && request.auth.uid == userId;
}

// Không cho phép list tất cả backups
match /key_backups/{document=**} {
  allow list: if false;
}
```

---

## 8. TROUBLESHOOTING

### Vấn đề 1: "Mật khẩu không đúng"

**Nguyên nhân**:
- Nhập sai password
- Caps Lock đang bật
- Dùng password khác (nếu đã backup nhiều lần)

**Giải pháp**:
1. Kiểm tra Caps Lock
2. Thử các password đã từng dùng
3. Nếu quên password → Không thể restore (tạo lại từ đầu)

---

### Vấn đề 2: "Không tìm thấy backup"

**Nguyên nhân**:
- Chưa backup
- Đang dùng tài khoản khác
- Backup bị xóa

**Giải pháp**:
1. Kiểm tra đúng tài khoản Firebase
2. Tạo backup mới nếu chưa có
3. Liên hệ support nếu backup bị mất

---

### Vấn đề 3: "HMAC verification failed"

**Nguyên nhân**:
- Dữ liệu backup bị corrupt
- Network error khi download
- Backup bị can thiệp

**Giải pháp**:
1. Thử lại sau vài phút
2. Kiểm tra kết nối mạng
3. Xóa backup cũ và tạo mới

---

### Vấn đề 4: "Checksum không khớp"

**Nguyên nhân**:
- Password đúng nhưng Private Key bị corrupt
- Lỗi khi giải mã

**Giải pháp**:
1. Báo lỗi cho admin
2. Tạo backup mới từ thiết bị cũ (nếu còn)
3. Last resort: Tạo Private Key mới (mất tin nhắn cũ)

---

## 9. KẾT LUẬN

### Đề xuất sử dụng:

**Cho user thông thường**:
- ✅ Dùng Cloud Backup (đã implement)
- ✅ Backup ngay sau khi tạo tài khoản
- ✅ Test restore trước khi xóa app

**Cho user quan tâm bảo mật**:
- ✅ Dùng Recovery Code (implement thêm nếu cần)
- ✅ Không lưu gì trên cloud
- ✅ Ghi 12 từ ra giấy và cất giữ cẩn thận

**Cho enterprise/app lớn**:
- ✅ Implement Multi-Device Sync
- ✅ Tốn nhiều effort nhưng UX tốt nhất
- ✅ Phù hợp cho app có nhiều user và thiết bị

---

**🔐 Với Cloud Backup, bạn sẽ không bao giờ mất tin nhắn khi đổi thiết bị! 💬**

*Ngày cập nhật: 14/10/2025*
