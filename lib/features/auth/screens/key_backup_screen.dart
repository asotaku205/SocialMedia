import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../services/key_backup_service.dart';
import '../../../utils/loading_overlay.dart';

/// Màn hình backup và restore Private Key
/// 
/// Các tính năng:
/// - Backup Private Key lên Firebase
/// - Restore Private Key từ Firebase
/// - Xóa backup
class KeyBackupScreen extends StatefulWidget {
  const KeyBackupScreen({Key? key}) : super(key: key);

  @override
  State<KeyBackupScreen> createState() => _KeyBackupScreenState();
}

class _KeyBackupScreenState extends State<KeyBackupScreen> {
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _hasBackup = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkBackup();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkBackup() async {
    setState(() => _isLoading = true);
    try {
      final hasBackup = await KeyBackupService.hasBackup();
      setState(() => _hasBackup = hasBackup);
    } catch (e) {
      _showError('${'General.Error'.tr()}: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _backupKey() async {
    if (!_formKey.currentState!.validate()) return;

    LoadingOverlay.show(context);
    try {
      await KeyBackupService.backupPrivateKey(_passwordController.text);
      LoadingOverlay.hide();
      
      _showSuccess('Backup.Backup Success'.tr() + '\n\n' + 'Backup.Backup Success desc'.tr());
      
      await _checkBackup();
      _passwordController.clear();
    } catch (e) {
      LoadingOverlay.hide();
      _showError('Backup.Backup Error'.tr() + ': $e');
    }
  }

  Future<void> _restoreKey() async {
    if (!_formKey.currentState!.validate()) return;

    LoadingOverlay.show(context);
    try {
      final success = await KeyBackupService.restorePrivateKey(_passwordController.text);
      LoadingOverlay.hide();
      
      if (success) {
        _showSuccess('Backup.Restore Success'.tr() + '\n\n' + 'Backup.Restore Success desc'.tr());
        _passwordController.clear();
      }
    } catch (e) {
      LoadingOverlay.hide();
      if (e.toString().contains('Mật khẩu không đúng')) {
        _showError('Backup.Wrong Password'.tr());
      } else {
        _showError('Backup.Restore Error'.tr() + ': $e');
      }
    }
  }

  Future<void> _deleteBackup() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Backup.Delete Backup Confirm'.tr()),
        content: Text('Backup.Delete Backup Desc'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('General.Cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('General.Delete'.tr()),
          ),
        ],
      ),
    );

    if (confirm == true) {
      LoadingOverlay.show(context);
      try {
        await KeyBackupService.deleteBackup();
        LoadingOverlay.hide();
        _showSuccess('Backup.Delete Backup Success'.tr());
        await _checkBackup();
      } catch (e) {
        LoadingOverlay.hide();
        _showError('General.Error'.tr() + ': $e');
      }
    }
  }

  void _showSuccess(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('✅ ' + 'General.Success'.tr()),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('General.OK'.tr()),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('❌ ' + 'General.Error'.tr()),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('General.OK'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textColor = theme.textTheme.bodyLarge?.color;
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Backup.Backup Private Key'.tr()),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Info Card
                    Card(
                      color: isDark ? colorScheme.surface : Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline, color: isDark ? Colors.blue : Colors.blue.shade700),
                                const SizedBox(width: 8),
                                Text(
                                  'Backup.Why backup title'.tr(),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.blue : Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Backup.Why backup desc'.tr(),
                              style: TextStyle(fontSize: 14, color: textColor),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Backup Status
                    Card(
                      color: isDark 
                        ? colorScheme.surface
                        : (_hasBackup ? Colors.green.shade50 : Colors.orange.shade50),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              _hasBackup ? Icons.check_circle : Icons.warning,
                              color: _hasBackup ? Colors.green : Colors.orange,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _hasBackup ? 'Backup.Has backup'.tr() : 'Backup.No backup'.tr(),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: _hasBackup ? Colors.green : Colors.orange,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _hasBackup
                                        ? 'Backup.Has backup desc'.tr()
                                        : 'Backup.No backup desc'.tr(),
                                    style: TextStyle(fontSize: 12, color: textColor?.withOpacity(0.8)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Backup.Backup Password'.tr(),
                        hintText: 'Backup.Password hint'.tr(),
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Authentication.Please enter password'.tr();
                        }
                        if (value.length < 6) {
                          return 'Backup.Password must be at least 6 characters'.tr();
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Backup.Password tip'.tr(),
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.secondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Backup Button
                    ElevatedButton.icon(
                      onPressed: _backupKey,
                      icon: const Icon(Icons.backup),
                      label: Text('Backup.Backup Private Key'.tr()),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Restore Button
                    if (_hasBackup)
                      OutlinedButton.icon(
                        onPressed: _restoreKey,
                        icon: const Icon(Icons.restore),
                        label: Text('Backup.Restore Private Key'.tr()),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),

                    // Delete Backup Button
                    if (_hasBackup)
                      TextButton.icon(
                        onPressed: _deleteBackup,
                        icon: const Icon(Icons.delete_outline),
                        label: Text('Backup.Delete Backup'.tr()),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),

                    const SizedBox(height: 32),

                    // Security Info
                    Card(
                      color: isDark ? colorScheme.surface : Colors.grey.shade100,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.security, color: colorScheme.secondary),
                                const SizedBox(width: 8),
                                Text(
                                  'Backup.Security Title'.tr(),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Backup.Security Info'.tr(),
                              style: TextStyle(fontSize: 13, color: textColor?.withOpacity(0.8)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
