import 'package:flutter/material.dart';
import 'package:moodly/screens/home_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 1000),
              pageBuilder: (_, __, ___) => const HomeScreen(),
              transitionsBuilder: (_, animation, __, child) {
                const begin = Offset(0.0, 1.0); // from bottom
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
        child: Center(
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
    );
  }
}
