import 'package:flutter/material.dart';
import 'package:power_smart/features/home/presentation/pages/main_screen.dart';
import 'package:power_smart/features/auth/presentation/pages/signup_page.dart';
import 'package:power_smart/features/auth/presentation/pages/sign_in_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Spotify-like Green
    const spotifyGreen = Color(0xFF1DB954);

    return Scaffold(
      backgroundColor: Colors.black, // Deep dark background
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF121212), Colors.black],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Logo / Branding
            const Icon(Icons.music_note, size: 80, color: Colors.white),
            const SizedBox(height: 16),
            const Text(
              'Power Smart',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: -1.0,
              ),
            ),
            const SizedBox(height: 48),

            // Login Button (Spotify Style)
            ElevatedButton(
              onPressed: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const SignInPage()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: spotifyGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
              child: const Text(
                'LOG IN',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),

            // Sign Up Button (Outline)
            OutlinedButton(
              onPressed: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const SignupPage()));
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white54),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'SIGN UP FREE',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 32),

            // Skip Auth Button (Text only)
            TextButton(
              onPressed: () {
                // Save "Skip Auth" preference (TODO: Persist this)
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const MainScreen()),
                );
              },
              child: const Text(
                'Skip for now',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
