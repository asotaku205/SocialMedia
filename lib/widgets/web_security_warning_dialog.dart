import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../features/auth/screens/key_backup_screen.dart';

/// Dialog cảnh báo về bảo mật trên Web
/// Hiển thị khi user đang sử dụng web version
class WebSecurityWarningDialog extends StatelessWidget {
  const WebSecurityWarningDialog({super.key});

  /// Kiểm tra và hiển thị dialog nếu đang chạy trên web
  static Future<void> checkAndShow(BuildContext context) async {
    if (!kIsWeb) return; // Chỉ hiển thị trên web
    
    // Kiểm tra xem đã hiển thị warning chưa (session này)
    // Để tránh spam user
    if (_hasShownThisSession) return;
    
    _hasShownThisSession = true;
    
    if (context.mounted) {
      await Future.delayed(Duration(seconds: 2)); // Delay 2 giây để UI load xong
      
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) => const WebSecurityWarningDialog(),
        );
      }
    }
  }

  static bool _hasShownThisSession = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      icon: Icon(
        Icons.warning_amber_rounded,
        size: 56,
        color: Colors.orange,
      ),
      title: Text(
        '⚠️ Web Security Notice',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are using the web version of this app.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.orange,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Important Information:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildBulletPoint(
                    '🔑 Your encryption keys are stored in browser storage',
                    colorScheme,
                  ),
                  _buildBulletPoint(
                    '⚠️ Keys will be lost if you clear browser data',
                    colorScheme,
                  ),
                  _buildBulletPoint(
                    '❌ Not as secure as mobile/desktop apps',
                    colorScheme,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.tips_and_updates,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Recommendations:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildBulletPoint(
                    '✅ Backup your encryption keys regularly',
                    colorScheme,
                  ),
                  _buildBulletPoint(
                    '📱 Use mobile app for better security',
                    colorScheme,
                  ),
                  _buildBulletPoint(
                    '🚫 Avoid using on public computers',
                    colorScheme,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('I Understand'),
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            // Chuyển đến màn hình backup
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const KeyBackupScreen(),
              ),
            );
          },
          icon: const Icon(Icons.backup),
          label: const Text('Backup Keys Now'),
        ),
      ],
    );
  }

  Widget _buildBulletPoint(String text, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: colorScheme.onSurface.withOpacity(0.8),
        ),
      ),
    );
  }
}
