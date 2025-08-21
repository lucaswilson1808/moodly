import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

//import 'package:moodly/screens/home_screen.dart';
//import 'package:moodly/screens/landing_screen.dart';
import 'sign_up_screen.dart';
import 'notes_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

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
                controller: _emailController,
                enableSuggestions: false,
                autocorrect: false,
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
                controller: _passwordController,
                enableSuggestions: false,
                autocorrect: false,
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
                    horizontal: 48, vertical: 10),
              ),
              onPressed: () async {
                try {
                  String emailToUse = _emailController.text;

                  // Check if user entered a username (no @ symbol)
                  if (!_emailController.text.contains('@')) {
                    // Look up email by username in Firestore
                    QuerySnapshot userQuery = await FirebaseFirestore.instance
                        .collection('users')
                        .where('username', isEqualTo: _emailController.text)
                        .get();

                    if (userQuery.docs.isNotEmpty) {
                      emailToUse = userQuery.docs.first['email'];
                    } else {
                      throw Exception('Username not found');
                    }
                  }

                  // Sign in with email
                  await FirebaseAuth.instance.signInWithEmailAndPassword(
                    email: emailToUse,
                    password: _passwordController.text,
                  );

                  Navigator.push(context, MaterialPageRoute(builder: (context) => const NotesScreen()));
                } catch (e) {
                  String errorMessage;
                  if (e.toString().contains('Username not found')) {
                    errorMessage = 'Username not found. Please check your username or try using your email.';
                  } else if (e.toString().contains('user-not-found')) {
                    errorMessage = 'Account not found. Please sign up first!';
                  } else if (e.toString().contains('wrong-password')) {
                    errorMessage = 'Incorrect password. Please try again.';
                  } else {
                    errorMessage = 'Login failed: ${e.toString()}';
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(errorMessage)),
                  );
                }
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
                Navigator.push(context, MaterialPageRoute(builder: (context) => const SignUpScreen()));
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
