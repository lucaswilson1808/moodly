import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:moodly/screens/home_screen.dart';
import 'package:moodly/screens/sign_in_screen.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key, this.fromSignUp = false});
  final bool fromSignUp;

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  @override
  void initState() {
    super.initState();
    // If we didn’t arrive here from a fresh sign-up, use Landing as the auth gate.
    if (!widget.fromSignUp) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final user = FirebaseAuth.instance.currentUser;
        if (!mounted) return;

        if (user != null) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 400),
              pageBuilder: (_, __, ___) => const HomeScreen(),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 400),
              pageBuilder: (_, __, ___) => const SignInScreen(),
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque, // full-screen taps
        onTap: widget.fromSignUp
            ? () {
                // After sign-up: tap anywhere → Home
                Navigator.pushReplacement(
                  context,
                  PageRouteBuilder(
                    transitionDuration: const Duration(milliseconds: 1000),
                    pageBuilder: (_, __, ___) => const HomeScreen(),
                    transitionsBuilder: (_, animation, __, child) {
                      const begin = Offset(0.0, 1.0);
                      const end = Offset.zero;
                      const curve = Curves.ease;
                      final tween = Tween(begin: begin, end: end)
                          .chain(CurveTween(curve: curve));
                      final offsetAnimation = animation.drive(tween);
                      return SlideTransition(
                        position: offsetAnimation,
                        child: child,
                      );
                    },
                  ),
                );
              }
            : null, // while acting as auth gate, ignore taps
        child: const SizedBox.expand(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                  style: TextStyle(fontSize: 16, color: Colors.blueAccent),
                ),
                SizedBox(height: 60),
                Text(
                  'Click anywhere',
                  style: TextStyle(fontSize: 12, color: Colors.blue),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}