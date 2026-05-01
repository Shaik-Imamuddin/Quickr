import 'package:flutter/material.dart';
import 'onboarding_screen2.dart';
import 'role_selection_page.dart';
import '../widgets/dot_indicator.dart';

class Onboarding1 extends StatelessWidget {
  const Onboarding1({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RoleSelectionPage(),
                      ),
                    );
                  },
                  child: const Text("Skip"),
                ),
              ),
            ),

            const Spacer(),

            Image.asset("assets/images/user-first-slid.png",
                height: size.height * 0.3),

            const SizedBox(height: 20),

            const CircleAvatar(
              backgroundColor: Colors.purple,
              child: Text("01", style: TextStyle(color: Colors.white)),
            ),

            const SizedBox(height: 20),

            const Text(
              "Post Your Problem",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 30),
              child: Text(
                "Describe your problem in a few words and get help in minutes.",
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 20),

            const DotIndicator(currentIndex: 0),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const Onboarding2()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      colors: [Colors.purple, Colors.deepPurple],
                    ),
                  ),
                  child: const Center(
                    child: Text("Let's Get Started ⚡",
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}