import 'package:flutter/material.dart';
import '../services/encryption_service.dart';
import '../features/auth/screens/key_backup_screen.dart';

/// Dialog nhắc người dùng restore encryption keys
/// Hiển thị khi phát hiện có backup nhưng không có local keys
class KeyRestoreReminderDialog extends StatelessWidget {
  const KeyRestoreReminderDialog({super.key});

  /// Kiểm tra và hiển thị dialog nếu cần
  static Future<void> checkAndShow(BuildContext context) async {
    try {
      final keysStatus = await EncryptionService.checkKeysStatus();
      
      // Nếu cần restore (có backup nhưng không có local key)
      if (keysStatus['needsRestore'] == true) {
        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false, // Không cho đóng bằng cách tap ngoài
            builder: (context) => const KeyRestoreReminderDialog(),
          );
        }
      }
    } catch (e) {
      print('Error checking keys status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      icon: Icon(
        Icons.key,
        size: 48,
        color: colorScheme.primary,
      ),
      title: Text(
        'Encryption Keys Missing',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'We found a backup of your encryption keys on the cloud, but they are not available on this device.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: colorScheme.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You need to restore your keys to read encrypted messages.',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Đóng dialog
          },
          child: Text(
            'Later',
            style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6)),
          ),
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.of(context).pop(); // Đóng dialog
            // Chuyển đến màn hình backup/restore
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const KeyBackupScreen(),
              ),
            );
          },
          icon: const Icon(Icons.restore),
          label: const Text('Restore Now'),
        ),
      ],
    );
  }
}
