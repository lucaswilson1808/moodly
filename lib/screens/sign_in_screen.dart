import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:moodly/screens/home_screen.dart';
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
        backgroundColor: const Color(0xFF2D7AF8),
        elevation: 0,
      ),
      body: Container(
        color: const Color(0xFF2D7AF8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 25),
            Image.asset(
              'assets/logos/moodly_light_theme_logo.png',
              width: 300,
              height: 105,
            ),
            const SizedBox(height: 100),

            // Username/Email
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _emailController,
                enableSuggestions: false,
                autocorrect: false,
                decoration: InputDecoration(
                  hintText: 'Username/Email',
                  hintStyle: const TextStyle(color: Colors.white),
                  filled: true,
                  fillColor: const Color(0xFF0A1F3F),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Colors.white,
                      width: 1.5,
                    ),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),

            // Password
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _passwordController,
                enableSuggestions: false,
                autocorrect: false,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Password',
                  hintStyle: const TextStyle(color: Colors.white),
                  filled: true,
                  fillColor: const Color(0xFF0A1F3F),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Colors.white,
                      width: 1.5,
                    ),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 50),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A1F3F),
                padding:
                    const EdgeInsets.symmetric(horizontal: 48, vertical: 10),
              ),
              onPressed: () async {
                try {
                  String emailToUse = _emailController.text;

                  // If user entered a username instead of email
                  if (!emailToUse.contains('@')) {
                    QuerySnapshot userQuery = await FirebaseFirestore.instance
                        .collection('users')
                        .where('username', isEqualTo: emailToUse)
                        .get();

                    if (userQuery.docs.isNotEmpty) {
                      emailToUse = userQuery.docs.first['email'];
                    } else {
                      throw Exception('Username not found');
                    }
                  }

                  // Sign in
                  await FirebaseAuth.instance.signInWithEmailAndPassword(
                    email: emailToUse,
                    password: _passwordController.text,
                  );

                  if (!mounted) return;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const HomeScreen()),
                  );
                } catch (e) {
                  String errorMessage;
                  if (e.toString().contains('Username not found')) {
                    errorMessage =
                        'Username not found. Please check your username or try using your email.';
                  } else if (e.toString().contains('user-not-found')) {
                    errorMessage =
                        'Account not found. Please sign up first!';
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
              child: const Text(
                'Login',
                style: TextStyle(color: Colors.white, fontSize: 25),
              ),
            ),
            const SizedBox(height: 10),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A1F3F),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SignUpScreen()),
                );
              },
              child: const Text(
                'Sign Up',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}