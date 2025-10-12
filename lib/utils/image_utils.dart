import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';

/// Utility class để xử lý avatar images, hỗ trợ cả URL và base64
class ImageUtils {
  /// Tạo ImageProvider phù hợp cho avatar
  /// Hỗ trợ cả network URL và data URL (base64)
  static ImageProvider? getAvatarImageProvider(String? imageUrl, {String? fallbackUrl}) {
    // Nếu không có URL, return null để hiển thị nền trắng
    if (imageUrl == null || imageUrl.isEmpty) {
      if (fallbackUrl != null && fallbackUrl.isNotEmpty) {
        return NetworkImage(fallbackUrl);
      }
      return null; // Sẽ hiển thị nền trắng với child text
    }

    // Nếu là data URL (base64), sử dụng MemoryImage
    if (imageUrl.startsWith('data:image/')) {
      try {
        // Extract base64 string from data URL
        final base64String = imageUrl.split(',')[1];
        final Uint8List bytes = base64Decode(base64String);
        return MemoryImage(bytes);
      } catch (e) {
        print('Error parsing base64 image: $e');
        return null; // Fallback về nền trắng thay vì random image
      }
    }

    // Nếu là network URL, sử dụng NetworkImage
    return NetworkImage(imageUrl);
  }

  /// Widget helper để tạo CircleAvatar với logic xử lý image phù hợp
  static Widget buildAvatar({
    required String? imageUrl,
    double radius = 20,
    String? fallbackUrl,
    Widget? child,
    Color? backgroundColor,
    BuildContext? context,
  }) {
    final ImageProvider? imageProvider = getAvatarImageProvider(imageUrl, fallbackUrl: fallbackUrl);

    // Lấy màu nền mặc định theo theme nếu chưa truyền backgroundColor
    Color? resolvedBgColor = backgroundColor;
    if (resolvedBgColor == null && context != null) {
      final brightness = Theme.of(context).brightness;
      resolvedBgColor = brightness == Brightness.dark
          ? const Color(0xFF23272F) // màu nền avatar dark
          : const Color(0xFFF0F1F6); // màu nền avatar light
    }
    resolvedBgColor ??= Colors.white;

    return CircleAvatar(
      radius: radius,
      backgroundColor: resolvedBgColor,
      backgroundImage: imageProvider,
      child: child,
    );
  }

  /// Kiểm tra xem string có phải là data URL không
  static bool isDataUrl(String? url) {
    return url != null && url.startsWith('data:image/');
  }

  /// Kiểm tra xem string có phải là network URL không
  static bool isNetworkUrl(String? url) {
    return url != null && (url.startsWith('http://') || url.startsWith('https://'));
  }
}