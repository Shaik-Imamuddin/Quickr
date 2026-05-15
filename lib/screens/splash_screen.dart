import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'onboarding_screen1.dart';
import 'role_selection_page.dart';
import 'user_main_page.dart';
import 'expert_profile_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    checkAppStart();
  }

  Future<void> checkAppStart() async {
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const UserMainScreen(),
          ),
          (Route<dynamic> route) => false,
        );
        return;
      }

      final expertDoc = await FirebaseFirestore.instance
          .collection("experts")
          .doc(currentUser.uid)
          .get();

      if (expertDoc.exists) {
        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const ExpertProfilePage(),
          ),
          (Route<dynamic> route) => false,
        );
        return;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final bool onboardingSeen = prefs.getBool("onboardingSeen") ?? false;

    if (!mounted) return;

    if (onboardingSeen) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const RoleSelectionPage(),
        ),
        (Route<dynamic> route) => false,
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const Onboarding1(),
        ),
        (Route<dynamic> route) => false,
      );
    }
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
              maxWidth: 400,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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