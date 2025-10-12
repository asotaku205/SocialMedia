import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../resource/theme_provider.dart';
// ...existing imports...

class ThemeSwitcherTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    return ListTile(
      leading: Icon(isDark ? Icons.dark_mode : Icons.light_mode, color: Theme.of(context).iconTheme.color),
      title: Text(
        isDark ? 'Dark Mode' : 'Light Mode',
        style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color),
      ),
      trailing: Switch(
        value: isDark,
        onChanged: (value) {
          themeProvider.toggleTheme(value);
        },
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: Theme.of(context).cardColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
    );
  }
}
