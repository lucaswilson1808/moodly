import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_notifier.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 8, minute: 0);

  void _pickReminderTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (picked != null && picked != _reminderTime) {
      setState(() {
        _reminderTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // Notifications
          SwitchListTile(
            title: const Text('Notifications'),
            value: _notificationsEnabled,
            onChanged: (bool value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
          ),
          const Divider(),

          // Reminder Time
          ListTile(
            title: const Text('Reminder Time'),
            trailing: Text(
              _reminderTime.format(context),
              style: const TextStyle(color: Colors.blueAccent),
            ),
            onTap: _pickReminderTime,
          ),
          const Divider(),

          // Appearance
          SwitchListTile(
            title: const Text('Appearance'),
            secondary: const Icon(Icons.brightness_6),
            value: themeNotifier.isDarkMode,
            onChanged: (_) {
              themeNotifier.toggleTheme();
            },
          ),
          const Divider(),

          // Account → route to AccountScreen
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Account'),
            onTap: () {
              Navigator.pushNamed(context, '/account');
            },
          ),
          const Divider(),

          // Privacy
          const ListTile(
            leading: Icon(Icons.privacy_tip),
            title: Text('Privacy'),
          ),
          const Divider(),

          // Security
          const ListTile(
            leading: Icon(Icons.lock),
            title: Text('Security'),
          ),
          const Divider(),

          // About
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Moodly',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2025 Moodly Inc.',
              );
            },
          ),
          const Divider(),

          // Help
          const ListTile(
            leading: Icon(Icons.help_outline),
            title: Text('Help'),
          ),
          const Divider(),

          // Log Out
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Log Out'),
            onTap: () {
              // 🔒 Add log out logic here
            },
          ),

          const SizedBox(height: 40),
          Center(
            child: TextButton(
              onPressed: () {
                // 🧾 Handle terms of service navigation
              },
              child: const Text(
                'Terms of Service',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ),
        ],
      ),
    );
  }
}