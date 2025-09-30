import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../services/theme_notifier.dart';
import 'landing_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _fln = FlutterLocalNotificationsPlugin();
  bool _notificationsEnabled = true;
  bool _loadingSwitch = true;

  @override
  void initState() {
    super.initState();
    _initNotificationToggle();
  }

  Future<void> _initNotificationToggle() async {
    bool enabled = true;

    final androidImpl = _fln.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null && Platform.isAndroid) {
      enabled = await androidImpl.areNotificationsEnabled() ?? true;
    }

    if (!mounted) return;
    setState(() {
      _notificationsEnabled = enabled;
      _loadingSwitch = false;
    });
  }

  Future<void> _handleNotificationsToggle(bool value) async {
    setState(() => _notificationsEnabled = value);

    if (value) {
      // Request runtime permission on Android 13+ / iOS.
      final androidImpl = _fln.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final iosImpl = _fln.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();

      bool granted = true;

      if (androidImpl != null && Platform.isAndroid) {
        granted = await androidImpl.requestNotificationsPermission() ?? false;
      }
      if (iosImpl != null && Platform.isIOS) {
        // On your plugin version this returns bool? (granted?), not a settings object.
        final bool? res = await iosImpl.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        granted = res ?? false;
      }

      if (!granted && mounted) {
        setState(() => _notificationsEnabled = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                'Notifications are disabled by the system. Enable them in Settings to receive reminders.',
              ),
              duration: Duration(milliseconds: 500)),
        );
      }
    } else {
      // Turn off: cancel all scheduled/pending notifications.
      await _fln.cancelAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('All notifications disabled.'),
            duration: Duration(milliseconds: 500)),
      );
    }
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LandingScreen()),
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to log out. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // Notifications (global)
          SwitchListTile(
            title: const Text('Notifications'),
            value: _loadingSwitch ? false : _notificationsEnabled,
            onChanged: _loadingSwitch ? null : _handleNotificationsToggle,
          ),
          const Divider(),

          // Appearance (theme)
          SwitchListTile(
            title: const Text('Appearance'),
            secondary: const Icon(Icons.brightness_6),
            value: themeNotifier.isDarkMode,
            onChanged: (_) => themeNotifier.toggleTheme(),
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
                applicationVersion: '0.1.0',
                applicationIcon: const CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.transparent,
                  child: Icon(Icons.favorite, color: Colors.purple),
                ),
                children: const [
                  SizedBox(height: 8),
                  Text(
                    'Moodly helps you track your mood, jot quick notes, and reflect over time. '
                    'Built with Flutter & Firebase.',
                  ),
                ],
              );
            },
          ),
          const Divider(),

          // Log Out
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Log Out'),
            onTap: _signOut,
          ),
        ],
      ),
    );
  }
}
