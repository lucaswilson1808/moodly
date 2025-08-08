import 'package:flutter/material.dart';
import 'package:moodly/screens/home_screen.dart';
import 'notes_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Moodly'),
        automaticallyImplyLeading: false,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.settings, color: Colors.blueAccent),
            onSelected: (value) {
              if (value == 'settings') {
                Navigator.pushNamed(context, '/settings');
              } else if (value == 'logout') {
                // handle logout
              } else if (value == 'about') {
                // maybe show a dialog or about page
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'settings',
                child: Text('Settings'),
              ),
              const PopupMenuItem(
                value: 'about',
                child: Text('About'),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Text('Log Out'),
              ),
            ],
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            SizedBox(height: 40),
            Icon(Icons.sentiment_satisfied_alt,
                size: 60, color: Colors.blueAccent),
            SizedBox(height: 8),
            Text(
              'Moodly',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            SizedBox(height: 32),
            Text(
              'Welcome to Moodly',
              style: TextStyle(
                fontSize: 22,
                color: Colors.blueAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Track your mood.\nReflect.\nFeel better.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.blue),
            ),
            SizedBox(height: 60),
            Text(
              'Click anywhere',
              style: TextStyle(fontSize: 12, color: Colors.blueAccent),
            ),
          ],
        ),
      ),
    );
  }
}