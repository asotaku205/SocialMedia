# 🔐 Hướng dẫn Quản lý Encryption Keys

## ❓ Tại sao mỗi lần đăng nhập lại phải tạo keys mới?

### 📱 Trên Native Apps (Android/iOS):
- ✅ Keys được lưu vĩnh viễn trong `Secure Storage`
- ✅ **KHÔNG** bị mất khi đăng xuất/đăng nhập lại
- ✅ Chỉ mất khi: xóa app hoặc xóa dữ liệu app

### 🌐 Trên Web Browser:
- ⚠️ Keys được lưu trong `localStorage` (giả lập secure storage)
- ⚠️ **CÓ THỂ** bị mất khi:
  - Xóa cookies/cache
  - Dùng chế độ incognito
  - Chuyển trình duyệt khác
  - Clear site data

## 🔧 Giải pháp: Backup & Restore System

### 1️⃣ Backup Private Key (Lần đầu tiên)
```
Sau khi đăng ký/đăng nhập lần đầu:
1. Vào Settings → "Backup Private Key"
2. Nhập password để mã hóa
3. Private Key được mã hóa và lưu lên Firebase
```

**⚠️ LƯU Ý QUAN TRỌNG:**
- Password này **KHÔNG PHẢI** password đăng nhập
- Đây là password riêng để mã hóa backup
- **PHẢI NHỚ** password này để restore!

### 2️⃣ Khi nào cần Restore?
```
Restore khi gặp các tình huống:
- Đổi trình duyệt mới
- Xóa cookies/cache
- Đăng nhập trên thiết bị khác
- Web báo: "No local keys found"
```

### 3️⃣ Cách Restore Private Key
```
1. Đăng nhập vào app
2. Vào Settings → "Restore Private Key"
3. Nhập password đã dùng khi backup
4. Keys được restore → Xem lại tin nhắn cũ ✅
```

## 🔄 Flow hoàn chỉnh

### 📝 Đăng ký tài khoản mới:
```
1. User đăng ký với email/password
2. App tự động tạo RSA-2048 key pair
3. Private Key lưu vào Secure Storage
4. Public Key lưu lên Firebase
5. App nhắc: "Hãy backup Private Key"
6. User backup với password riêng
```

### 🔓 Đăng nhập lại (cùng thiết bị):
```
1. User đăng nhập
2. App kiểm tra: Có Private Key local? → ✅ Có
3. Dùng key cũ → Xem được tin nhắn cũ
```

### 🌐 Đăng nhập lại (thiết bị mới/browser mới):
```
1. User đăng nhập
2. App kiểm tra: Có Private Key local? → ❌ Không
3. App kiểm tra: Có backup trên Firebase? → ✅ Có
4. App nhắc: "Bạn có backup, hãy restore"
5. User restore với password backup
6. Keys được restore → Xem được tin nhắn cũ ✅
```

### 🆘 Quên password backup:
```
❌ KHÔNG THỂ KHÔI PHỤC!
- Password backup không lưu ở đâu cả
- Đây là tính năng bảo mật (zero-knowledge)
- Giải pháp: Tạo keys mới → Mất tin nhắn cũ
```

## 🛡️ Bảo mật

### Encryption Stack:
```
┌─────────────────────────────────────┐
│  Message (Plain Text)               │
└──────────────┬──────────────────────┘
               ↓
         [AES-256-CBC]
         (Session Key)
               ↓
┌─────────────────────────────────────┐
│  Encrypted Message                  │
│  + IV + HMAC-SHA256                 │
└──────────────┬──────────────────────┘
               ↓
         [Firestore]

Session Key được bảo vệ bởi:
┌─────────────────────────────────────┐
│  Session Key (256-bit)              │
└──────────────┬──────────────────────┘
               ↓
         [RSA-2048]
         (Public Key)
               ↓
┌─────────────────────────────────────┐
│  Encrypted Session Key              │
└──────────────┬──────────────────────┘
               ↓
         [Firestore]

Private Key được bảo vệ bởi:
┌─────────────────────────────────────┐
│  Private Key (RSA-2048)             │
└──────────────┬──────────────────────┘
               ↓
         [Secure Storage]
         (Local Device)

Backup được bảo vệ bởi:
┌─────────────────────────────────────┐
│  Private Key (RSA-2048)             │
└──────────────┬──────────────────────┘
               ↓
    [PBKDF2 10,000 iterations]
    (User Password)
               ↓
         [AES-256-CBC]
               ↓
┌─────────────────────────────────────┐
│  Encrypted Backup                   │
│  + IV + HMAC + Checksum             │
└──────────────┬──────────────────────┘
               ↓
         [Firestore]
```

## 📊 So sánh Platforms

| Tính năng | Native Apps | Web Browser |
|-----------|-------------|-------------|
| Keys lưu vĩnh viễn | ✅ | ⚠️ (phụ thuộc cache) |
| Tự động backup | ❌ (cần password) | ❌ (cần password) |
| Restore dễ dàng | ✅ | ✅ (nếu có backup) |
| Mất keys khi logout | ❌ | ❌ |
| Mất keys khi xóa cache | ❌ | ✅ (cần restore) |

## 💡 Best Practices

### Cho Users:
1. ✅ **Backup ngay sau đăng ký**
2. ✅ **Ghi nhớ password backup** (khác password đăng nhập)
3. ✅ **Không share password backup** với ai
4. ⚠️ **Trên Web**: Đừng xóa cookies/cache nếu chưa backup

### Cho Developers:
1. ✅ Keys **KHÔNG BAO GIỜ** bị xóa khi logout (đã disable)
2. ✅ Nhắc user backup sau đăng nhập (BackupReminderDialog)
3. ✅ Nhắc restore nếu phát hiện có backup nhưng không có local keys
4. ✅ Log rõ ràng để debug: "Keys exist" / "No keys found" / "Backup available"

## 🐛 Troubleshooting

### "Mỗi lần đăng nhập lại phải tạo keys mới"

**Nguyên nhân:**
- Web browser: Đã xóa cache/cookies
- Chưa backup keys

**Giải pháp:**
1. Backup keys ngay lập tức
2. Lần sau có vấn đề → Restore từ backup
3. Không xóa cache nếu chưa backup

### "Không xem được tin nhắn cũ"

**Nguyên nhân:**
- Keys đã thay đổi (tạo mới)
- Tin nhắn cũ encrypted với key cũ

**Giải pháp:**
1. Restore keys từ backup
2. Nếu không có backup → Không thể khôi phục

### "Quên password backup"

**Giải pháp:**
- ❌ Không có cách nào khôi phục
- 🔄 Tạo keys mới → Bắt đầu lại từ đầu
- 💾 Backup lại với password mới và **GHI NHỚ**

## 📚 References

- [Flutter Secure Storage](https://pub.dev/packages/flutter_secure_storage)
- [PBKDF2](https://en.wikipedia.org/wiki/PBKDF2)
- [AES-256-CBC](https://en.wikipedia.org/wiki/Advanced_Encryption_Standard)
- [RSA-2048](https://en.wikipedia.org/wiki/RSA_(cryptosystem))
- [E2EE Best Practices](https://www.eff.org/deeplinks/2013/11/what-encryption-and-why-should-i-care)
