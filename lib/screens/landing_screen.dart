import 'package:flutter/material.dart';
import 'package:moodly/screens/home_screen.dart';
import 'package:moodly/screens/sign_up_screen.dart';
import 'package:moodly/screens/sign_in_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key, this.fromSignUp = false});
  final bool fromSignUp;

  @override
  Widget build(BuildContext context) {
    // Success screen after signup
    if (fromSignUp) {
      return Scaffold(
        backgroundColor: const Color(0xFF2D7AF8),
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
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
          },
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_outline, size: 80, color: Colors.white),
                SizedBox(height: 24),
                Text(
                  'Welcome to Moodly!',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 16),
                Text('Your account is ready', style: TextStyle(fontSize: 18, color: Colors.white70)),
                SizedBox(height: 60),
                Text('Tap anywhere to continue', style: TextStyle(fontSize: 14, color: Colors.white70)),
              ],
            ),
          ),
        ),
      );
    }

    // Regular landing - show sign up/sign in options
    return Scaffold(
      backgroundColor: const Color(0xFF2D7AF8),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sentiment_satisfied_alt, size: 70, color: Colors.white),
            const SizedBox(height: 8),
            const Text('Moodly', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 32),
            const Text('Welcome to Moodly', style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.w600)),
            const SizedBox(height: 24),
            const Text('Track your mood.\nReflect.\nFeel better.', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: Colors.white)),
            const SizedBox(height: 60),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0A1F3F), padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16)),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignUpScreen())),
              child: const Text('Get Started', style: TextStyle(fontSize: 20, color: Colors.white)),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignInScreen())),
              child: const Text('Already have an account? Sign In', style: TextStyle(fontSize: 18,color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}