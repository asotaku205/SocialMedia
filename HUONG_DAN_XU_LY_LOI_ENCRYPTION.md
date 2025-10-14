# Hướng Dẫn Xử Lý Lỗi Encryption E2EE

## 📋 Tổng Quan

Document này giải thích các lỗi encryption thường gặp và cách xử lý, đặc biệt là lỗi **"Invalid argument(s): Unsupported block type for private key"** khi người mới gửi tin nhắn cho người cũ.

---

## 🔍 Nguyên Nhân Lỗi

### Lỗi: "Unsupported block type for private key" (Error 154)

**Nguyên nhân chính:**
- Người nhận (người cũ) **không có Private Key trong secure storage**
- Private Key có thể bị mất do:
  - Clear app data
  - Cài đặt lại ứng dụng
  - Đổi thiết bị mới
  - Lỗi khi khởi tạo keys

**Flow xảy ra lỗi:**
```
1. Người mới gửi tin nhắn
   ↓
2. Tạo Session Key mới
   ↓
3. Mã hóa Session Key bằng Public Key của người cũ (từ Firestore)
   ↓
4. Lưu tin nhắn đã mã hóa vào Firestore
   ↓
5. Người cũ nhận tin nhắn
   ↓
6. Cố gắng giải mã Session Key bằng Private Key
   ↓
7. ❌ KHÔNG TÌM THẤY PRIVATE KEY → LỖI!
```

---

## ✅ Giải Pháp

### 1. Kiểm Tra Trạng Thái Keys

Sử dụng hàm helper để kiểm tra:

```dart
final keysStatus = await EncryptionService.checkKeysStatus();

if (keysStatus['needsRestore'] == true) {
  // Có backup nhưng không có local key → cần restore
  print('⚠️ User needs to restore keys from backup');
}
```

### 2. Tự Động Nhắc Nhở Người Dùng

Thêm vào `main.dart` hoặc home screen:

```dart
import 'package:blogapp/widgets/key_restore_reminder_dialog.dart';

// Trong initState() hoặc khi app khởi động
@override
void initState() {
  super.initState();
  
  // Kiểm tra và hiển thị dialog nếu cần restore keys
  WidgetsBinding.instance.addPostFrameCallback((_) {
    KeyRestoreReminderDialog.checkAndShow(context);
  });
}
```

### 3. Xử Lý Lỗi Khi Đọc Tin Nhắn

Code đã được cải thiện trong `chat_service.dart`:

```dart
try {
  final decryptedContent = EncryptionService.decryptMessage(
    message.encryptedContent,
    message.iv!,
    message.hmac!,
    sessionKey,
  );
  message = message.copyWith(content: decryptedContent);
} catch (e) {
  // Hiển thị thông báo lỗi thân thiện
  if (e.toString().contains('Private key not found')) {
    message = message.copyWith(
      content: '🔒 [Message Encrypted - Keys Missing. Restore from Settings]'
    );
  }
}
```

### 4. Hướng Dẫn Người Dùng Restore Keys

**Bước 1:** Vào **Settings > Security > Backup Private Key**

**Bước 2:** Chọn tab **"Restore"**

**Bước 3:** Nhập password đã dùng khi backup

**Bước 4:** Nhấn **"Restore Private Key"**

**Bước 5:** Khởi động lại ứng dụng

---

## 🛠️ Cho Developer

### Cải Thiện Đã Thực Hiện

1. **Custom Exception Class**
   ```dart
   class PrivateKeyNotFoundException implements Exception {
     final String message;
     PrivateKeyNotFoundException(this.message);
   }
   ```

2. **Kiểm Tra Backup Tự Động**
   ```dart
   if (privateKeyPem == null) {
     final hasBackup = await _checkHasBackup();
     if (hasBackup) {
       throw PrivateKeyNotFoundException(
         'Please restore keys from Settings > Security'
       );
     }
   }
   ```

3. **Logging Chi Tiết**
   - ✅ Session key được tạo
   - 🔐 Mã hóa/giải mã
   - ❌ Lỗi với stack trace
   - 💡 Gợi ý khắc phục

4. **Graceful Degradation**
   - Tin nhắn không thể giải mã → hiển thị `[Encrypted Message]` thay vì crash
   - Thông báo lỗi rõ ràng cho user

### Debug Checklist

Khi gặp lỗi encryption, kiểm tra:

- [ ] User có đăng nhập không? (`_auth.currentUser?.uid`)
- [ ] Private key có trong secure storage không?
  ```dart
  final key = await _secureStorage.read(key: 'rsa_private_key_$userId');
  print('Private key exists: ${key != null}');
  ```
- [ ] Public key có trên Firestore không?
  ```dart
  final userDoc = await _firestore.collection('users').doc(userId).get();
  print('Public key: ${userDoc.data()?['publicKey']}');
  ```
- [ ] Có backup trên Firebase không?
  ```dart
  final backupDoc = await _firestore.collection('key_backups').doc(userId).get();
  print('Has backup: ${backupDoc.exists}');
  ```
- [ ] Format của Private Key có đúng không?
  ```dart
  // Phải có format: PRIVATE:modulus:exponent:privateExponent:p:q
  final parts = privateKeyPem.split(':');
  print('Key parts count: ${parts.length}'); // Phải là 6
  ```

### Testing

**Test Case 1: User mới gửi tin nhắn cho user cũ (có backup)**
```
Expected: User cũ nhận được dialog "Restore Keys"
Action: Restore keys từ backup
Result: ✅ Có thể đọc tin nhắn
```

**Test Case 2: User mới gửi tin nhắn cho user cũ (không có backup)**
```
Expected: Hiển thị "[Encrypted Message]" + warning
Action: App tự động tạo keys mới cho user cũ
Result: ⚠️ Không đọc được tin nhắn cũ, nhưng tin nhắn mới OK
```

**Test Case 3: Restore với password sai**
```
Expected: Lỗi "Mật khẩu không đúng"
Action: Nhập lại password đúng
Result: ✅ Restore thành công
```

---

## 🔒 Security Notes

1. **KHÔNG BAO GIỜ** log Private Key ra console
2. **KHÔNG BAO GIỜ** gửi Private Key qua network (trừ khi đã mã hóa bằng password)
3. **LUÔN LUÔN** sử dụng HTTPS khi giao tiếp với Firebase
4. **KHUYẾN KHÍCH** người dùng backup keys ngay sau khi tạo tài khoản

---

## 📱 User Experience

### Thông Báo Lỗi Thân Thiện

| Tình Huống | Thông Báo Cũ | Thông Báo Mới (Cải Thiện) |
|------------|---------------|---------------------------|
| Missing private key | `Exception: Private key not found` | `🔒 Message Encrypted - Keys Missing. Restore from Settings > Security` |
| Wrong password | `Exception: HMAC verification failed` | `❌ Incorrect password. Please try again.` |
| Corrupted data | `Exception: Invalid argument(s)` | `🔒 Message Corrupted - Cannot Decrypt` |
| No backup found | `Exception: User not found` | `⚠️ No backup found. New messages will work after restart.` |

---

## 🎯 Kết Luận

Với các cải thiện trên:
- ✅ Lỗi được xử lý gracefully (không crash app)
- ✅ Thông báo lỗi rõ ràng và hữu ích
- ✅ Tự động nhắc user restore keys
- ✅ Logging chi tiết để debug
- ✅ User experience tốt hơn

**Lưu ý:** Người dùng CẦN PHẢI backup keys ngay sau khi đăng ký để tránh mất khả năng đọc tin nhắn khi đổi thiết bị!
