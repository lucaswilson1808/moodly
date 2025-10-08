import 'package:flutter/material.dart';
import 'package:moodly/screens/mood_chart.dart';
import 'package:moodly/screens/reminder_screen.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'services/theme_notifier.dart';
import 'screens/landing_screen.dart';
import 'screens/home_screen.dart';
import 'screens/notes_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/account_screen.dart';
import 'services/auth_service.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // uses platform configs already in your project
  await FirebaseAppCheck.instance.activate(
  androidProvider: AndroidProvider.debug,
  appleProvider: AppleProvider.debug,
);
tz.initializeTimeZones();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return MaterialApp(
      title: 'Moodly',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: themeNotifier.currentTheme,

      // Auth gate lives inside LandingScreen (routes to SignIn or Home)
      home: const AuthWrapper(),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/notes': (context) => const NotesScreen(),
        '/account': (context) =>
            const AccountScreen(displayName: "Name", email: "email"),
        '/reminders': (context) => const ReminderScreen(),    
        '/mood_chart': (context) => const MoodChart(),
      },
    );
  }
}