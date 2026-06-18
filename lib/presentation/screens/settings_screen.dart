import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/notification_provider.dart';
import '../../core/constants/theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Consumer2<ThemeProvider, NotificationProvider>(
        builder: (context, themeProv, notifProv, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Section 1: Custom Settings
              _buildSectionHeader(context, 'APP PREFERENCES'),
              Container(
                decoration: AppTheme.glassBoxDecoration(context: context),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text(
                        'Dark Mode Aesthetics',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: const Text(
                        'Vibrant dark color scheme',
                        style: TextStyle(fontSize: 12),
                      ),
                      secondary: Icon(
                        Icons.palette_outlined,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      value: themeProv.isDarkMode,
                      activeThumbColor: Theme.of(context).colorScheme.secondary,
                      onChanged: (_) => themeProv.toggleTheme(),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text(
                        'Push Notifications',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: const Text(
                        'Kickoff reminders & match alerts',
                        style: TextStyle(fontSize: 12),
                      ),
                      secondary: Icon(
                        Icons.notifications_active_outlined,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      value: notifProv.enabled,
                      activeThumbColor: Theme.of(context).colorScheme.secondary,
                      onChanged: (val) =>
                          notifProv.toggleGlobalNotifications(val),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8, top: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
          color: isDark
              ? AppTheme.darkTextSecondary
              : AppTheme.lightTextSecondary,
        ),
      ),
    );
  }
}
