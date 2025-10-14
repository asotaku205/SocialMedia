# Hướng Dẫn Deploy Flutter Web với E2EE lên Vercel

## ⚠️ Cảnh Báo Quan Trọng

**Encryption trên Web có giới hạn bảo mật!**

- ❌ Web **KHÔNG** có Secure Enclave/Keychain như mobile
- ❌ Private keys được lưu trong **IndexedDB** (có thể truy cập được từ browser)
- ❌ Keys có thể bị mất khi **clear browser data**
- ⚠️ Không an toàn bằng mobile/desktop app

### So Sánh Bảo Mật

| Platform | Storage | Security Level | Recommendation |
|----------|---------|----------------|----------------|
| iOS | Keychain | 🔒🔒🔒🔒🔒 (Excellent) | ✅ An toàn tuyệt đối |
| Android | KeyStore | 🔒🔒🔒🔒 (Very Good) | ✅ Rất an toàn |
| Desktop | OS Keyring | 🔒🔒🔒 (Good) | ✅ An toàn |
| **Web** | IndexedDB | 🔒🔒 (Limited) | ⚠️ Hạn chế, backup thường xuyên |

---

## 📋 Chuẩn Bị Deploy

### 1. Cài Đặt Dependencies Cho Web

Kiểm tra `pubspec.yaml` có các dependencies cần thiết:

```yaml
dependencies:
  flutter_secure_storage: ^9.0.0
  flutter_secure_storage_web: ^2.0.0  # Quan trọng cho web!
```

### 2. Cấu Hình Web Options

File `lib/services/secure_storage_service.dart` đã được cấu hình:

```dart
static final FlutterSecureStorage _secureStorage = FlutterSecureStorage(
  webOptions: WebOptions(
    dbName: 'social_media_secure_db',
    publicKey: 'social_media_public_key',
  ),
);
```

### 3. Build Flutter Web

```bash
# Build với profile release
flutter build web --release

# Hoặc build với web-renderer canvaskit (tốt hơn cho UI)
flutter build web --release --web-renderer canvaskit

# Hoặc dùng html renderer (nhẹ hơn, load nhanh hơn)
flutter build web --release --web-renderer html
```

**Kết quả:** Tạo folder `build/web/` chứa các file HTML, JS, CSS

---

## 🚀 Deploy lên Vercel

### Option 1: Deploy qua Vercel CLI

```bash
# Cài đặt Vercel CLI
npm i -g vercel

# Deploy
cd build/web
vercel
```

### Option 2: Deploy qua Vercel Dashboard

1. Tạo repository trên GitHub
2. Push code lên GitHub
3. Vào https://vercel.com/dashboard
4. Click **"New Project"**
5. Import repository
6. Cấu hình:
   - **Framework Preset**: Other
   - **Build Command**: `flutter build web --release`
   - **Output Directory**: `build/web`
   - **Install Command**: (leave empty)

---

## ⚙️ File Cấu Hình Vercel

Tạo file `vercel.json` trong root project:

```json
{
  "buildCommand": "flutter build web --release",
  "outputDirectory": "build/web",
  "devCommand": "flutter run -d web-server --web-port 3000",
  "installCommand": "if ! command -v flutter &> /dev/null; then git clone https://github.com/flutter/flutter.git -b stable --depth 1 /usr/local/flutter && export PATH=\"$PATH:/usr/local/flutter/bin\" && flutter doctor; fi",
  "framework": null,
  "regions": ["sin1"],
  "routes": [
    {
      "src": "/(.*)",
      "dest": "/index.html"
    }
  ],
  "headers": [
    {
      "source": "/(.*)",
      "headers": [
        {
          "key": "Cross-Origin-Opener-Policy",
          "value": "same-origin"
        },
        {
          "key": "Cross-Origin-Embedder-Policy",
          "value": "require-corp"
        }
      ]
    }
  ]
}
```

---

## 🔐 Encryption Trên Web

### Cách Hoạt Động

1. **Key Generation**
   - Web sử dụng RSA 1024-bit (nhanh hơn 2048-bit)
   - Chạy đồng bộ trên main thread (có thể lag 2-3 giây)
   
2. **Key Storage**
   - Private key lưu trong IndexedDB
   - Public key lưu trên Firestore
   
3. **Backup Keys**
   - **BẮT BUỘC** backup keys ngay sau khi tạo tài khoản
   - Lưu encrypted backup lên Firebase
   - Dùng password để mã hóa

### Hạn Chế

❌ **Keys bị mất khi:**
- Clear browser data/cookies
- Sử dụng Incognito mode
- Đổi browser
- Reinstall browser

✅ **Giải pháp:**
- Backup keys ngay sau khi đăng ký
- Reminder users backup thường xuyên
- Hiển thị warning rõ ràng

---

## 🎯 Best Practices

### 1. Nhắc Nhở User Backup

```dart
// Trong home screen hoặc main.dart
@override
void initState() {
  super.initState();
  
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (kIsWeb) {
      _showWebSecurityWarning();
    }
    KeyRestoreReminderDialog.checkAndShow(context);
  });
}

void _showWebSecurityWarning() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('⚠️ Web Security Notice'),
      content: Text(
        'You are using the web version. Your encryption keys are stored in browser storage.\n\n'
        'Please backup your keys to avoid losing access to encrypted messages!'
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('OK'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            // Navigate to backup screen
          },
          child: Text('Backup Now'),
        ),
      ],
    ),
  );
}
```

### 2. Kiểm Tra Platform

```dart
import 'package:flutter/foundation.dart';

if (kIsWeb) {
  // Web-specific code
  print('⚠️ Running on web - limited security');
} else {
  // Mobile/Desktop code
  print('✅ Running on native platform - full security');
}
```

### 3. Logging Cho Debug

```dart
// Trong encryption_service.dart
if (kIsWeb) {
  print('🌐 WEB: Keys stored in IndexedDB');
  print('⚠️ WEB: Backup recommended!');
}
```

---

## 🐛 Troubleshooting

### Lỗi: "Keys not found after page refresh"

**Nguyên nhân:** IndexedDB bị clear hoặc không accessible

**Giải pháp:**
1. Kiểm tra browser có block third-party cookies không
2. Kiểm tra user có dùng Incognito mode không
3. Nhắc user restore keys từ backup

### Lỗi: "Cannot decrypt messages on web"

**Nguyên nhân:** Private key không có trong IndexedDB

**Giải pháp:**
1. Restore keys từ Firebase backup
2. Hoặc tạo keys mới (sẽ mất tin nhắn cũ)

### Lỗi: "Key generation takes too long"

**Nguyên nhân:** Web sử dụng 1024-bit keys nhưng vẫn chậm

**Giải pháp:**
1. Hiển thị loading indicator
2. Thông báo user "Generating encryption keys..."
3. Consider sử dụng Web Workers (advanced)

---

## 📱 Recommendation

### Cho Users:

✅ **Nên:**
- Sử dụng mobile app cho bảo mật tốt nhất
- Backup keys ngay sau khi đăng ký
- Không sử dụng Incognito mode
- Không clear browser data thường xuyên

❌ **Không nên:**
- Tin tưởng hoàn toàn vào web version
- Quên backup keys
- Sử dụng shared/public computers

### Cho Developers:

✅ **Nên:**
- Hiển thị warning rõ ràng cho web users
- Tự động nhắc backup keys
- Implement key restore flow tốt
- Monitor key loss rate

❌ **Không nên:**
- Quảng cáo web version là "fully secure"
- Ẩn giấu hạn chế của web platform
- Bỏ qua backup mechanism

---

## 🔗 Links

- [Flutter Secure Storage Web](https://pub.dev/packages/flutter_secure_storage)
- [Vercel Documentation](https://vercel.com/docs)
- [IndexedDB API](https://developer.mozilla.org/en-US/docs/Web/API/IndexedDB_API)

---

## 📊 Security Comparison

```
Mobile App (iOS/Android):
🔒🔒🔒🔒🔒 Highly Secure
✅ Hardware-backed encryption
✅ Secure Enclave/KeyStore
✅ Biometric protection
✅ Keys survive app reinstall

Desktop App:
🔒🔒🔒🔒 Very Secure
✅ OS-level keyring
✅ Keys survive app reinstall
⚠️ Depends on OS security

Web App (Vercel):
🔒🔒 Limited Security
⚠️ Browser storage only
⚠️ Keys lost on data clear
⚠️ Accessible via DevTools
❌ No hardware protection
```

**Kết luận:** Web version nên được coi là **convenience option**, không phải **primary secure platform**.
