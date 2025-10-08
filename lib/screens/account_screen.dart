import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:moodly/services/auth_service.dart';
import 'package:moodly/services/user_service.dart';
import 'package:moodly/models/user_model.dart';

import '../services/theme_notifier.dart';
import 'landing_screen.dart';

class AccountScreen extends StatefulWidget {
  final String? displayName;
  final String? email;

  const AccountScreen({super.key, this.displayName, this.email});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  String? _username;
  String? _email;
  DateTime? _createdAt;
  String? _photoUrl; // Firebase Storage URL
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = _authService.currentUser;
    if (user == null) return;

    _email = user.email;
    _createdAt = user.metadata.creationTime;

    // Load user data from Firestore using UserService
    try {
      final userModel = await _userService.getUser(user.uid);
      if (userModel != null) {
        _username = userModel.username;
        _photoUrl = userModel.profilePictureUrl;
      } else {
        _username = user.displayName;
      }
    } catch (e) {
      _username = user.displayName;
    }

    if (mounted) setState(() {});
  }

  Future<void> _pickAndSavePhoto() async {
    try {
      setState(() => _busy = true);
      final user = _authService.currentUser;
      if (user == null) return;

      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 85,
      );
      if (picked == null) {
        setState(() => _busy = false);
        return;
      }

      // Convert XFile to File
      final file = File(picked.path);

      // Upload to Firebase Storage using UserService
      final downloadUrl = await _userService.updateProfilePicture(user.uid, file);

      if (!mounted) return;
      setState(() => _photoUrl = downloadUrl);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile picture updated!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update photo: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _fmtDate(DateTime? dt) {
    if (dt == null) return '—';
    return '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _signOut() async {
    try {
      setState(() => _busy = true);
      await _authService.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LandingScreen()),
            (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to sign out. Try again.')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteAccount() async {
    final user = _authService.currentUser;
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      setState(() => _busy = true);

      // Delete user data from Firestore (includes profile picture)
      await _userService.deleteUser(user.uid);

      // Delete Auth account
      await _authService.deleteAccount();

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LandingScreen()),
            (route) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete account: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final shownName =
    (_username != null && _username!.isNotEmpty) ? _username! : (widget.displayName ?? 'Anonymous');
    final shownEmail =
    (_email != null && _email!.isNotEmpty) ? _email! : (widget.email ?? '—');
    final createdStr = _fmtDate(_createdAt);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
      ),
      body: AbsorbPointer(
        absorbing: _busy,
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: _busy ? null : _pickAndSavePhoto,
                      child: CircleAvatar(
                        radius: 28,
                        backgroundImage: (_photoUrl != null && _photoUrl!.isNotEmpty)
                            ? NetworkImage(_photoUrl!)
                            : null,
                        child: (_photoUrl == null || _photoUrl!.isEmpty)
                            ? const Icon(Icons.person, size: 30)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(shownName,
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(
                            shownEmail,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),

                ListTile(
                  leading: const Icon(Icons.badge_outlined),
                  title: const Text('Username'),
                  subtitle: Text((_username?.isNotEmpty ?? false) ? _username! : '—'),
                ),
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('Email'),
                  subtitle: Text(shownEmail),
                ),
                ListTile(
                  leading: const Icon(Icons.schedule_outlined),
                  title: const Text('Member since'),
                  subtitle: Text(createdStr),
                ),
                const Divider(),

                SwitchListTile(
                  title: const Text('Appearance'),
                  subtitle: Text(themeNotifier.isDarkMode ? 'Dark' : 'Light'),
                  secondary: const Icon(Icons.brightness_6),
                  value: themeNotifier.isDarkMode,
                  onChanged: (_) => themeNotifier.toggleTheme(),
                ),
                const SizedBox(height: 12),

                ElevatedButton.icon(
                  onPressed: _signOut,
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign out'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey.shade700,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _deleteAccount,
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('Delete account'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            if (_busy)
              const Positioned.fill(
                child: ColoredBox(
                  color: Color(0x66000000),
                  child: Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}