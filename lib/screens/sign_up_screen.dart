import 'package:flutter/material.dart';
//import 'package:moodly/screens/home_screen.dart';
//import 'package:moodly/screens/landing_screen.dart';
import 'notes_screen.dart';
import 'sign_in_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class SignUpScreen extends StatefulWidget  {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}
class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

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
            SizedBox(height: 50), // Space between logo and inputs

            // Email TextField
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                enableSuggestions: false,
                autocorrect: false,
                decoration: InputDecoration(
                  hintText: 'Email',
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
                  prefixIcon: Icon(Icons.email, color: Colors.white),
                ),
                style: TextStyle(color: Colors.white),
              ),
            ),
            SizedBox(height: 20), // Space between inputs

            //Username TextField
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _usernameController,
                enableSuggestions: false,
                autocorrect: false,
                decoration: InputDecoration(
                  hintText: 'Username',
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
                  prefixIcon: Icon(Icons.person, color: Colors.white), // Person icon
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
                controller: _passwordController,
                enableSuggestions: false,
                autocorrect: false,
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
                  prefixIcon: Icon(Icons.lock, color: Colors.white), // Lock icon
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
              onPressed: () async {
                try {
                  // Create user account
                  UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                    email: _emailController.text,
                    password: _passwordController.text,
                  );

                  // Save user data to Firestore
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(userCredential.user!.uid)
                      .set({
                    'username': _usernameController.text,
                    'email': _emailController.text,
                    'createdAt': FieldValue.serverTimestamp(),
                  });

                  Navigator.push(context, MaterialPageRoute(builder: (context) => const NotesScreen()));
                } catch (e) {
                  String errorMessage;
                  if (e.toString().contains('email-already-in-use')) {
                    errorMessage = 'This email is already registered. Please login instead!';
                  } else if (e.toString().contains('weak-password')) {
                    errorMessage = 'Password is too weak. Please use a stronger password.';
                  } else if (e.toString().contains('invalid-email')) {
                    errorMessage = 'Please enter a valid email address.';
                  } else {
                    errorMessage = 'Error: ${e.toString()}';
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(errorMessage)),
                  );
                }
              },
              child: const Text('Sign Up',
                  style: TextStyle(color: Colors.white, fontSize: 25)),
            ),
            SizedBox(height: 10), // Space between inputs
            //Database should look like
            /*users/
                [user-uid]/
                username: "their_username"
                email: "their_email"
                createdAt: timestamp
             */

            //Login Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF0A1F3F),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
              ),
              onPressed: () {
                // Save note logic here
                Navigator.push(context, MaterialPageRoute(builder: (context) => const SignInScreen()));
              },
              child: const Text('Login',
                  style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
