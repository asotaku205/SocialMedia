import 'package:flutter/material.dart';

/// Hiển thị overlay loading với message tùy chỉnh
class LoadingOverlay {
  static OverlayEntry? _currentOverlay;

  /// Hiển thị loading overlay
  static void show(BuildContext context, {String message = 'Loading...'}) {
    if (_currentOverlay != null) return;

    _currentOverlay = OverlayEntry(
      builder: (context) => Material(
        color: Colors.black54,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_currentOverlay!);
  }

  /// Ẩn loading overlay
  static void hide() {
    _currentOverlay?.remove();
    _currentOverlay = null;
  }
}
