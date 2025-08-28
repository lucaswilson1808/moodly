// file: lib/screens/account_screen.dart
// A self-contained, production-ready Account screen for the Moodly app.
// No external packages required. Plug into your Navigator as a route/screen.
// Pass in your current user/profile and callbacks to perform real actions.

import 'package:flutter/material.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({
    super.key,
    required this.displayName,
    required this.email,
    this.photoUrl,
    this.initialNotificationsEnabled = true,
    this.initialAppearance = Appearance.system,
    this.initialReminderTime,
    this.onEditProfile,
    this.onChangePhoto,
    this.onToggleNotifications,
    this.onChangeAppearance,
    this.onChangeReminderTime,
    this.onManageSubscriptions,
    this.onSignOut,
    this.onDeleteAccount,
  });

  final String displayName;
  final String email;
  final String? photoUrl;

  final bool initialNotificationsEnabled;
  final Appearance initialAppearance;
  final TimeOfDay? initialReminderTime;

  // Callbacks: connect these to your app logic (e.g., Firebase/Auth/Prefs)
  final Future<void> Function()? onEditProfile;
  final Future<void> Function()? onChangePhoto;
  final Future<void> Function(bool enabled)? onToggleNotifications;
  final Future<void> Function(Appearance mode)? onChangeAppearance;
  final Future<void> Function(TimeOfDay time)? onChangeReminderTime;
  final Future<void> Function()? onManageSubscriptions;
  final Future<void> Function()? onSignOut;
  final Future<void> Function()? onDeleteAccount;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late bool _notificationsEnabled;
  late Appearance _appearance;
  TimeOfDay? _reminderTime;

  @override
  void initState() {
    super.initState();
    _notificationsEnabled = widget.initialNotificationsEnabled;
    _appearance = widget.initialAppearance;
    _reminderTime = widget.initialReminderTime;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _ProfileHeader(
            name: widget.displayName,
            email: widget.email,
            photoUrl: widget.photoUrl,
            onEditProfile: widget.onEditProfile,
            onChangePhoto: widget.onChangePhoto,
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Preferences',
            children: [
              SwitchListTile.adaptive(
                title: const Text('Notifications'),
                subtitle: const Text('Mood reminders and weekly summaries'),
                value: _notificationsEnabled,
                onChanged: (val) async {
                  setState(() => _notificationsEnabled = val);
                  if (widget.onToggleNotifications != null) {
                    await widget.onToggleNotifications!(val);
                  }
                },
              ),
              const Divider(height: 0),
              ListTile(
                title: const Text('Reminder time'),
                subtitle: Text(_reminderTime != null
                    ? _formatTimeOfDay(_reminderTime!)
                    : 'Not set'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _reminderTime ?? TimeOfDay.now(),
                    helpText: 'Pick reminder time',
                  );
                  if (picked != null) {
                    setState(() => _reminderTime = picked);
                    if (widget.onChangeReminderTime != null) {
                      await widget.onChangeReminderTime!(picked);
                    }
                  }
                },
              ),
              const Divider(height: 0),
              ListTile(
                title: const Text('Appearance'),
                subtitle: Text(_appearance.label),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final chosen = await _showAppearanceSheet(context, _appearance);
                  if (chosen != null) {
                    setState(() => _appearance = chosen);
                    if (widget.onChangeAppearance != null) {
                      await widget.onChangeAppearance!(chosen);
                    }
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Billing',
            children: [
              ListTile(
                title: const Text('Manage subscription'),
                subtitle: const Text('Plan, payment method, invoices'),
                leading: const Icon(Icons.credit_card),
                trailing: const Icon(Icons.chevron_right),
                onTap: widget.onManageSubscriptions,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Security',
            children: [
              ListTile(
                title: const Text('Sign out'),
                leading: const Icon(Icons.logout),
                onTap: widget.onSignOut,
              ),
              const Divider(height: 0),
              ListTile(
                title: const Text('Delete account'),
                subtitle: const Text('Permanently remove all data'),
                leading: Icon(Icons.delete_forever, color: theme.colorScheme.error),
                titleTextStyle: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
                onTap: () async {
                  final ok = await _confirmDestructive(
                    context,
                    title: 'Delete account?',
                    message:
                        'This will permanently delete your Moodly account and all associated data. This action cannot be undone.',
                    confirmLabel: 'Delete',
                  );
                  if (ok && widget.onDeleteAccount != null) {
                    await widget.onDeleteAccount!();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Moodly v1.0.0',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.onEditProfile,
    required this.onChangePhoto,
  });

  final String name;
  final String email;
  final String? photoUrl;
  final Future<void> Function()? onEditProfile;
  final Future<void> Function()? onChangePhoto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _Avatar(photoUrl: photoUrl, name: name),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit profile'),
                        onPressed: onEditProfile,
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text('Change photo'),
                        onPressed: onChangePhoto,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.photoUrl, required this.name});

  final String? photoUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    final initials = _initialsFromName(name);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 36,
          backgroundImage: (photoUrl != null && photoUrl!.isNotEmpty)
              ? NetworkImage(photoUrl!)
              : null,
          child: (photoUrl == null || photoUrl!.isEmpty)
              ? Text(initials, style: const TextStyle(fontSize: 20))
              : null,
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Divider(height: 0),
          ...children,
        ],
      ),
    );
  }
}

enum Appearance { system, light, dark }

extension on Appearance {
  String get label => switch (this) {
        Appearance.system => 'Use system',
        Appearance.light => 'Light',
        Appearance.dark => 'Dark',
      };
}

Future<Appearance?> _showAppearanceSheet(
  BuildContext context,
  Appearance selected,
) async {
  return showModalBottomSheet<Appearance>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<Appearance>(
              title: const Text('Use system'),
              value: Appearance.system,
              groupValue: selected,
              onChanged: (v) => Navigator.pop(context, v),
            ),
            RadioListTile<Appearance>(
              title: const Text('Light'),
              value: Appearance.light,
              groupValue: selected,
              onChanged: (v) => Navigator.pop(context, v),
            ),
            RadioListTile<Appearance>(
              title: const Text('Dark'),
              value: Appearance.dark,
              groupValue: selected,
              onChanged: (v) => Navigator.pop(context, v),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}

Future<bool> _confirmDestructive(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Delete',
}) async {
  final theme = Theme.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            style: ButtonStyle(
              foregroundColor: WidgetStatePropertyAll(theme.colorScheme.error),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

String _initialsFromName(String name) {
  final parts = name.trim().split(RegExp(r"\s+"));
  if (parts.isEmpty) return '';
  if (parts.length == 1) return parts.first.characters.first.toUpperCase();
  final first = parts.first.characters.first.toUpperCase();
  final last = parts.last.characters.first.toUpperCase();
  return '$first$last';
}

String _formatTimeOfDay(TimeOfDay t) {
  final context = WidgetsBinding.instance.focusManager.primaryFocus?.context;
  // Fallback 24h formatting if context is null
  if (context == null) {
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
  final now = DateTime.now();
  final dt = DateTime(now.year, now.month, now.day, t.hour, t.minute);
  return MaterialLocalizations.of(context).formatTimeOfDay(
    t,
    alwaysUse24HourFormat: MediaQuery.maybeOf(context)?.alwaysUse24HourFormat ?? false,
  );
}
