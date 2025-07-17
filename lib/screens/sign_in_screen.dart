import 'package:flutter/material.dart';
import 'package:moodly/screens/home_screen.dart';

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
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children:  [
            const Text(
              'Sign In',
              style: TextStyle(
                fontSize: 46,
                fontFamily: 'Cursive',
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo[900],
                padding: const EdgeInsets.symmetric(
                    horizontal: 30, vertical: 10),
              ),
              onPressed: () {
                // Save note logic here
                Navigator.pop(context);
              },
              child: const Text('Login',
                  style: TextStyle(color: Colors.white, fontSize: 25)),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo[500],
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
              ),
              onPressed: () {
                // Save note logic here
                Navigator.push(context, MaterialPageRoute(builder: (context) => const NotesScreen()));
              },
              child: const Text('Sign Up',
                  style: TextStyle(color: Colors.grey, fontSize: 18)),
            ),
        ],
        ),
      ),
    );
  }
}
