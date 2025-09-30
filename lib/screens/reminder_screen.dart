import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  final _plugin = FlutterLocalNotificationsPlugin();

  List<Reminder> _items = [];
  bool _loaded = false;

  static final _placeholders = <Reminder>[
    Reminder.sample(
      text:
          "Hey, remember to drink some water and stretch for a minute. Your future self will thank you!",
      hour: 10,
      minute: 0,
      days: {DateTime.monday, DateTime.wednesday, DateTime.friday},
    ),
    Reminder.sample(
      text:
          "When 7 o'clock rolls around, you start getting hangry! Go get some food!",
      hour: 19,
      minute: 0,
      days: {
        DateTime.monday,
        DateTime.tuesday,
        DateTime.wednesday,
        DateTime.thursday,
        DateTime.friday
      },
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initNotifications().then((_) => _load());
  }

  Future<void> _initNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin
        .initialize(const InitializationSettings(android: android, iOS: ios));

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('reminders');
    if (raw == null) {
      _items = List<Reminder>.from(_placeholders);
    } else {
      _items =
          (jsonDecode(raw) as List).map((e) => Reminder.fromJson(e)).toList();
    }
    setState(() => _loaded = true);
    await _rescheduleAll();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _items.any((e) => !e.isPlaceholder)
        ? _items.where((e) => !e.isPlaceholder).toList()
        : _items;
    await prefs.setString(
      'reminders',
      jsonEncode(list.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> _rescheduleAll() async {
    await _plugin.cancelAll();
    for (final r in _items.where((e) => e.enabled)) {
      await _scheduleReminder(r);
    }
  }

  Future<void> _scheduleReminder(Reminder r) async {
    final details = NotificationDetails(
      android: const AndroidNotificationDetails(
        'moodly_reminders',
        'Reminders',
        channelDescription: 'User-configured reminders',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: const DarwinNotificationDetails(),
    );

    for (final weekday in r.days) {
      final now = DateTime.now();
      DateTime next = DateTime(now.year, now.month, now.day, r.hour, r.minute);
      while (next.weekday != weekday || next.isBefore(now)) {
        next = next.add(const Duration(days: 1));
      }

      final id = r.idForWeekday(weekday);
      final tzTime = tz.TZDateTime.from(next, tz.local);

      await _plugin.zonedSchedule(
        id, // id
        'Reminder', // title
        r.text, // body
        tzTime, // when
        details, // notification details (positional in v17+)
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }
  }

  Future<void> _addOrEdit({Reminder? original}) async {
    final result = await showDialog<Reminder>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ReminderEditor(reminder: original),
    );
    if (result == null) return;

    setState(() {
      if (original != null) {
        final idx = _items.indexWhere((e) => e.id == original.id);
        if (idx != -1) _items[idx] = result.copyWith(isPlaceholder: false);
      } else {
        if (_items.any((e) => e.isPlaceholder)) _items = [];
        _items.add(result.copyWith(isPlaceholder: false));
      }
    });

    await _persist();
    await _rescheduleAll();
  }

  Future<void> _delete(Reminder r) async {
    setState(() {
      _items.removeWhere((e) => e.id == r.id);
    });
    await _persist();
    await _rescheduleAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[600], // match HomeScreen
      appBar: AppBar(
        title: const Text('Reminders'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(
                  child: Text(
                    'No reminders yet. Tap + to add one.',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final r = _items[i];
                    final daysLabel = r.daysLabel();
                    final time = r.timeLabel();
                    return Dismissible(
                      key: ValueKey(r.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.only(right: 16),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (_) async {
                        final ok = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Delete reminder?'),
                                content: const Text('This cannot be undone.'),
                                actions: [
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancel')),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red),
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            ) ??
                            false;
                        return ok;
                      },
                      onDismissed: (_) => _delete(r),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[300], // like the note field on Home
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          title: Text(r.text),
                          subtitle: Text('$daysLabel • $time'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Switch(
                                value: r.enabled,
                                onChanged: (v) async {
                                  _items[i] = r.copyWith(enabled: v);
                                  setState(() {});
                                  await _persist();
                                  await _rescheduleAll();
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _addOrEdit(original: r),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEdit(),
        backgroundColor: Colors.blueAccent, // match Home's accent
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.blue[900],
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        height: 12, // subtle footer cap to mirror HomeScreen bottom bar styling
      ),
    );
  }
}

class Reminder {
  final String id;
  final String text;
  final int hour;
  final int minute;
  final Set<int> days; // 1..7 (Mon..Sun)
  final bool enabled;
  final bool isPlaceholder;

  Reminder({
    required this.id,
    required this.text,
    required this.hour,
    required this.minute,
    required this.days,
    this.enabled = true,
    this.isPlaceholder = false,
  });

  factory Reminder.sample({
    required String text,
    required int hour,
    required int minute,
    required Set<int> days,
  }) =>
      Reminder(
        id: 'sample_${DateTime.now().microsecondsSinceEpoch}',
        text: text,
        hour: hour,
        minute: minute,
        days: days,
        isPlaceholder: true,
      );

  Reminder copyWith({
    String? id,
    String? text,
    int? hour,
    int? minute,
    Set<int>? days,
    bool? enabled,
    bool? isPlaceholder,
  }) =>
      Reminder(
        id: id ?? this.id,
        text: text ?? this.text,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
        days: days ?? this.days,
        enabled: enabled ?? this.enabled,
        isPlaceholder: isPlaceholder ?? this.isPlaceholder,
      );

  String timeLabel() {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final m = minute.toString().padLeft(2, '0');
    final ampm = hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }

  String daysLabel() {
    const names = {
      DateTime.monday: 'Mon',
      DateTime.tuesday: 'Tue',
      DateTime.wednesday: 'Wed',
      DateTime.thursday: 'Thu',
      DateTime.friday: 'Fri',
      DateTime.saturday: 'Sat',
      DateTime.sunday: 'Sun',
    };
    final ordered = [1, 2, 3, 4, 5, 6, 7]
        .where(days.contains)
        .map((d) => names[d]!)
        .toList();
    return ordered.isEmpty ? 'No days' : ordered.join(', ');
  }

  int idForWeekday(int weekday) => id.hashCode ^ weekday.hashCode;

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'hour': hour,
        'minute': minute,
        'days': days.toList(),
        'enabled': enabled,
        'isPlaceholder': isPlaceholder,
      };

  factory Reminder.fromJson(Map<String, dynamic> json) => Reminder(
        id: json['id'] as String,
        text: json['text'] as String,
        hour: json['hour'] as int,
        minute: json['minute'] as int,
        days: (json['days'] as List).map((e) => e as int).toSet(),
        enabled: json['enabled'] as bool? ?? true,
        isPlaceholder: json['isPlaceholder'] as bool? ?? false,
      );
}

class _ReminderEditor extends StatefulWidget {
  const _ReminderEditor({this.reminder});
  final Reminder? reminder;

  @override
  State<_ReminderEditor> createState() => _ReminderEditorState();
}

class _ReminderEditorState extends State<_ReminderEditor> {
  late TextEditingController _text;
  late TimeOfDay _time;
  final Set<int> _days = {};

  @override
  void initState() {
    super.initState();
    final r = widget.reminder;
    _text = TextEditingController(text: r?.text ?? '');
    _time = r != null
        ? TimeOfDay(hour: r.hour, minute: r.minute)
        : const TimeOfDay(hour: 9, minute: 0);
    if (r != null) _days.addAll(r.days);
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const order = [
      DateTime.monday,
      DateTime.tuesday,
      DateTime.wednesday,
      DateTime.thursday,
      DateTime.friday,
      DateTime.saturday,
      DateTime.sunday,
    ];
    const names = {
      DateTime.monday: 'Mon',
      DateTime.tuesday: 'Tue',
      DateTime.wednesday: 'Wed',
      DateTime.thursday: 'Thu',
      DateTime.friday: 'Fri',
      DateTime.saturday: 'Sat',
      DateTime.sunday: 'Sun',
    };

    return AlertDialog(
      title: Text(widget.reminder == null ? 'New Reminder' : 'Edit Reminder'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _text,
              decoration: const InputDecoration(
                labelText: 'Message',
                hintText: "e.g., 7pm = dinner time. Feed the machine!",
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Time:'),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () async {
                    final picked = await showTimePicker(
                        context: context, initialTime: _time);
                    if (picked != null) setState(() => _time = picked);
                  },
                  child: Text(_time.format(context)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: order.map((d) {
                  final selected = _days.contains(d);
                  return FilterChip(
                    label: Text(names[d]!),
                    selected: selected,
                    onSelected: (v) {
                      setState(() {
                        if (v) {
                          _days.add(d);
                        } else {
                          _days.remove(d);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (_text.text.trim().isEmpty || _days.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Please enter a message and choose day(s).')),
              );
              return;
            }
            final r = widget.reminder;
            final newR = Reminder(
              id: r?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
              text: _text.text.trim(),
              hour: _time.hour,
              minute: _time.minute,
              days: Set.of(_days),
              enabled: true,
            );
            Navigator.pop(context, newR);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}