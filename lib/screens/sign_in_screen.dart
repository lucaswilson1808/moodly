import 'package:flutter/material.dart';
import 'package:moodly/screens/home_screen.dart';
import 'package:moodly/screens/landing_screen.dart';

import 'notes_screen.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.blueAccent),
            onPressed: () {
              // Optional: Show about dialog or tooltip
            },
          ),
        ],
        backgroundColor: Color(0xFF2D7AF8),
        elevation: 0,
      ),
      body: Container(
        color: Color(0xFF2D7AF8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children:  [
            SizedBox(height: 25), // Space from top

            Image.asset(
              'assets/logos/moodly_light_theme_logo.png',
              width: 300, // Adjust width as needed
              height: 105,  // Adjust height as needed
            ),
            SizedBox(height: 100), // Space between logo and inputs

            // Username/Email TextField
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Username/Email',
                  hintStyle: TextStyle(color: Colors.white),
                  filled: true,
                  fillColor: Color(0xFF0A1F3F),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: Colors.white,
                      width: 10.5, // Slightly thicker when focused
                  ),
                  ),
                ),
                style: TextStyle(color: Colors.white),
              ),
            ),
            SizedBox(height: 20), // Space between inputs

            // Password TextField
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                obscureText: true, // Hides password text
                decoration: InputDecoration(
                  hintText: 'Password',
                  hintStyle: TextStyle(color: Colors.white),
                  filled: true,
                  fillColor: Color(0xFF0A1F3F),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: Colors.white,
                      width: 10.5, // Match your Username field
                    ),
                  ),
                ),
                style: TextStyle(color: Colors.white),
              ),
            ),

            SizedBox(height: 50), // Space between inputs

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF0A1F3F),
                padding: const EdgeInsets.symmetric(
                    horizontal: 30, vertical: 10),
              ),
              onPressed: () {
                // Save note logic here
                Navigator.push(context, MaterialPageRoute(builder: (context) => const LandingScreen()));
              },
              child: const Text('Login',
                  style: TextStyle(color: Colors.white, fontSize: 25)),
            ),
            SizedBox(height: 10), // Space between inputs

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF0A1F3F),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
              ),
              onPressed: () {
                // Save note logic here
                Navigator.push(context, MaterialPageRoute(builder: (context) => const NotesScreen()));
              },
              child: const Text('Sign Up',
                  style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
        ],
        ),
      ),
    );
  }
}
