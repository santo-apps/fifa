import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/schedule_provider.dart';
import '../../core/constants/theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Consumer3<ThemeProvider, NotificationProvider, ScheduleProvider>(
        builder: (context, themeProv, notifProv, scheduleProv, _) {
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

              const SizedBox(height: 24),

              // Section 2: Reset
              _buildSectionHeader(context, 'DATABASE ACTIONS'),
              Container(
                decoration: AppTheme.glassBoxDecoration(context: context),
                child: ListTile(
                  title: const Text(
                    'Reset Tournament Schedule',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: const Text(
                    'Reverts all simulated scores and timeline events.',
                    style: TextStyle(fontSize: 11),
                  ),
                  trailing: const Icon(
                    Icons.restart_alt_rounded,
                    color: Colors.redAccent,
                  ),
                  onTap: () async {
                    await scheduleProv.resetSchedule();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Database reset to defaults successfully.',
                        ),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
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
