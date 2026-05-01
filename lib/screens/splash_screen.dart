import 'dart:async';
import 'package:flutter/material.dart';
import 'onboarding_screen1.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Onboarding1()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFDAD0F5),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 400, // 🔥 important for web
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                
                // 🔥 Title FIRST
                const Text(
                  "Quickr",
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  "Don’t Wait. Quickr It.",
                  style: TextStyle(fontSize: 16),
                ),

                const SizedBox(height: 40),

                // 🔥 Image AFTER text
                Image.asset(
                  "assets/images/logo.png",
                  height: size.height * 0.25,
                  fit: BoxFit.contain,
                ),

                const SizedBox(height: 40),

                const CircularProgressIndicator(),

                const SizedBox(height: 20),

                const Text("Connecting you to experts..."),
              ],
            ),
          ),
        ),
      ),
    );
  }
}