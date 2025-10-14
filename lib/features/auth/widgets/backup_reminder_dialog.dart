import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../screens/key_backup_screen.dart';
import '../../../services/key_backup_service.dart';

/// Dialog nhắc nhở user backup Private Key
/// Hiển thị sau khi:
/// - Đăng nhập lần đầu
/// - Chưa có backup
class BackupReminderDialog {
  
  /// Kiểm tra và hiển thị reminder nếu cần
  static Future<void> showIfNeeded(BuildContext context) async {
    try {
      // Kiểm tra đã có backup chưa
      final hasBackup = await KeyBackupService.hasBackup();
      
      // Nếu đã có backup thì không hiện
      if (hasBackup) return;
      
      // Hiển thị dialog nhắc nhở
      if (context.mounted) {
        _showReminderDialog(context);
      }
    } catch (e) {
      print('Error checking backup: $e');
    }
  }
  
  /// Hiển thị dialog
  static void _showReminderDialog(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textColor = theme.textTheme.bodyLarge?.color;
    final isDark = theme.brightness == Brightness.dark;
    
    showDialog(
      context: context,
      barrierDismissible: false, // Bắt buộc user phải chọn
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.backup, color: Colors.blue, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Backup.Backup Private Key'.tr(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Backup.Why backup desc'.tr(),
              style: TextStyle(fontSize: 14, color: textColor),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? colorScheme.surface : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? Colors.orange : Colors.orange.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Backup.No backup desc'.tr(),
                      style: TextStyle(
                        fontSize: 13,
                        color: textColor,
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
            onPressed: () => Navigator.pop(context),
            child: Text(
              'General.Cancel'.tr(),
              style: TextStyle(color: colorScheme.secondary),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              // Chuyển đến màn hình backup
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const KeyBackupScreen(),
                ),
              );
            },
            icon: const Icon(Icons.backup),
            label: Text('Backup.Backup'.tr()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
