# 📱 Hướng dẫn Backup/Restore cho User

## 🎯 TẠI SAO CẦN BACKUP?

Bạn có thể **MẤT TẤT CẢ TIN NHẮN CŨ** nếu:
- ❌ Xóa app và cài lại
- ❌ Mua điện thoại mới
- ❌ Factory reset điện thoại

**Giải pháp**: Backup Private Key ngay bây giờ! (Chỉ mất 30 giây)

---

## ✅ CÁCH BACKUP (30 giây)

### Bước 1: Mở Settings

```
Vào app → Menu (☰) → Settings → "Backup Private Key"
```

### Bước 2: Nhập password

```
┌─────────────────────────────────────────┐
│  🔒 Password backup                     │
│  ┌───────────────────────────────────┐ │
│  │ MySecurePass123                   │ │
│  └───────────────────────────────────┘ │
│                                         │
│  💡 Chọn password dễ nhớ nhưng khó đoán│
│     VÍ DỤ: MyChat2025@Safe             │
│                                         │
│  ⚠️  KHÔNG dùng password Firebase!     │
│                                         │
│  [ Backup Private Key ]                │
└─────────────────────────────────────────┘
```

### Bước 3: Nhấn "Backup"

```
✅ Backup thành công!

✓ Private Key đã được mã hóa và lưu trữ an toàn
⚠️ Hãy nhớ mật khẩu này để restore khi cần

[ OK ]
```

### ✍️ GHI NHỚ PASSWORD:

**Option 1**: Ghi vào sổ tay (an toàn nhất)
```
App: Social Media Chat
Password backup: _________________
Ngày tạo: __/__/____
```

**Option 2**: Lưu vào password manager
- 1Password
- Bitwarden  
- LastPass

⚠️ **ĐỪNG BAO GIỜ**:
- ❌ Gửi qua tin nhắn
- ❌ Lưu trong Notes không mã hóa
- ❌ Chia sẻ cho người khác

---

## 🔄 CÁCH RESTORE (1 phút)

### Khi nào cần restore?
- Cài lại app
- Đổi điện thoại mới
- Sau khi factory reset

### Bước 1: Đăng nhập

```
Mở app → Đăng nhập với tài khoản Firebase như thường
```

### Bước 2: App tự động phát hiện

```
┌─────────────────────────────────────────┐
│  🔄 Restore Private Key                 │
│                                         │
│  Phát hiện có backup Private Key.       │
│  Bạn có muốn restore để đọc tin nhắn    │
│  cũ không?                              │
│                                         │
│  [ Bỏ qua ]  [ Restore ]               │
└─────────────────────────────────────────┘
```

### Bước 3: Nhấn "Restore"

```
┌─────────────────────────────────────────┐
│  Nhập password backup                   │
│  ┌───────────────────────────────────┐ │
│  │ MySecurePass123                   │ │
│  └───────────────────────────────────┘ │
│                                         │
│  💡 Password bạn đã dùng khi backup    │
│                                         │
│  [ Hủy ]  [ Restore ]                  │
└─────────────────────────────────────────┘
```

### Bước 4: Xong!

```
✅ Restore thành công!

✓ Private Key đã được khôi phục
💬 Bây giờ bạn có thể xem lại tin nhắn cũ

[ OK ]
```

### Bước 5: Kiểm tra

Mở chat → Xem tin nhắn cũ → ✅ Đọc được hết!

---

## ⚠️ LỖI THƯỜNG GẶP

### Lỗi 1: "Mật khẩu không đúng"

**Nguyên nhân**: Nhập sai password

**Giải pháp**:
1. Kiểm tra Caps Lock có đang bật không
2. Thử các password khác đã từng dùng
3. Kiểm tra ghi chú đã lưu

### Lỗi 2: "Không tìm thấy backup"

**Nguyên nhân**: 
- Chưa backup
- Đang dùng tài khoản khác

**Giải pháp**:
1. Kiểm tra đúng tài khoản Firebase
2. Nếu chưa backup → Tạo backup mới

### Lỗi 3: Quên password backup

**Giải pháp**: 
- ❌ Không có cách nào khôi phục
- 💡 Phải tạo Private Key mới
- 😢 Mất tất cả tin nhắn cũ

**Phòng tránh**: 
- Ghi password ngay sau khi backup
- Lưu vào password manager
- Test restore 1 lần trước khi xóa app

---

## 🔐 BẢO MẬT

### Q: Password backup có an toàn không?

**A**: CÓ! ✅
- Private Key được mã hóa bằng AES-256
- Không ai giải mã được nếu không có password
- Kể cả admin Firebase cũng không đọc được

### Q: Password backup có giống password đăng nhập không?

**A**: KHÔNG! ❌
- Password đăng nhập = vào Firebase
- Password backup = mã hóa Private Key
- NÊN dùng 2 password KHÁC NHAU

### Q: Có thể backup nhiều lần không?

**A**: CÓ! ✅
- Backup mới ghi đè backup cũ
- Có thể đổi password backup

---

## 📝 CHECKLIST

### ✅ Sau khi tạo tài khoản:
- [ ] Backup Private Key ngay
- [ ] Ghi password vào sổ tay
- [ ] Test restore 1 lần

### ✅ Trước khi xóa app:
- [ ] Kiểm tra đã backup chưa
- [ ] Verify password còn nhớ
- [ ] Test restore trước khi xóa

### ✅ Khi đổi điện thoại:
- [ ] Đăng nhập tài khoản cũ
- [ ] Restore Private Key
- [ ] Kiểm tra đọc được tin nhắn cũ

---

## 🆘 CẦN TRỢ GIÚP?

### Bước 1: Đọc FAQ
- [HUONG_DAN_BACKUP_PRIVATE_KEY.md](./HUONG_DAN_BACKUP_PRIVATE_KEY.md)
- Phần "Troubleshooting"

### Bước 2: Liên hệ support
- Email: support@yourapp.com
- In-app: Settings → Help & Support
- Cung cấp:
  - User ID
  - Lỗi gặp phải
  - Screenshot (nếu có)

---

## 📊 THỐNG KÊ

```
┌────────────────────────────────────────┐
│  🎯 Thống kê backup của bạn           │
├────────────────────────────────────────┤
│                                        │
│  ✅ Đã backup: Có                     │
│  📅 Lần backup cuối: 14/10/2025       │
│  🔐 Password: ********* (đã mã hóa)   │
│                                        │
│  💡 TIP: Nên test restore 1 lần       │
│      mỗi 3 tháng để đảm bảo           │
│      password còn nhớ                  │
│                                        │
└────────────────────────────────────────┘
```

---

## 🎬 VIDEO HƯỚNG DẪN

### Backup:
```
1. Mở Settings                    (0:00-0:05)
2. Chọn "Backup Private Key"      (0:05-0:10)
3. Nhập password                  (0:10-0:20)
4. Nhấn Backup                    (0:20-0:25)
5. Ghi password ra giấy           (0:25-0:30)
```

### Restore:
```
1. Đăng nhập app                  (0:00-0:10)
2. App hiện "Restore?"            (0:10-0:15)
3. Nhấn Restore                   (0:15-0:20)
4. Nhập password                  (0:20-0:30)
5. Xong! Xem tin nhắn cũ          (0:30-0:40)
```

---

## ⭐ TIPS & TRICKS

### Tip 1: Chọn password tốt
```
❌ Tệ:     123456, password, qwerty
⚠️  OK:     MyPassword123
✅ Tốt:    MyChat2025@Safe
✅ Xuất sắc: Remember-This-Key-2025!
```

### Tip 2: Nhớ password lâu dài
```
1. Liên kết với câu chuyện
   VD: "My dog Fluffy is 7 years old"
       → MdFi7yo

2. Dùng cụm từ dễ nhớ
   VD: "I love chatting with my friends"
       → ILCwMF2025

3. Lưu vào password manager
   → 100% an toàn và không quên
```

### Tip 3: Test restore định kỳ
```
Mỗi 3 tháng:
1. Mở Settings → Backup
2. Nhấn "Test Restore"
3. Nhập password
4. Kiểm tra OK → Yên tâm
```

---

**🔐 Hãy backup ngay để bảo vệ kỷ niệm của bạn! 💕**

*Cập nhật: 14/10/2025 | Version 1.0*
