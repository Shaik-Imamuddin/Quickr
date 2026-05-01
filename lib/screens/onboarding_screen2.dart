import 'package:flutter/material.dart';
import 'onboarding_screen3.dart';
import 'role_selection_page.dart';
import '../widgets/dot_indicator.dart';

class Onboarding2 extends StatelessWidget {
  const Onboarding2({super.key});

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

            Image.asset("assets/images/export.png",
                height: size.height * 0.3),

            const SizedBox(height: 20),

            const CircleAvatar(
              backgroundColor: Colors.purple,
              child: Text("02", style: TextStyle(color: Colors.white)),
            ),

            const SizedBox(height: 20),

            const Text(
              "Connect With Verified Experts",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 30),
              child: Text(
                "We match you with the best experts for fast and reliable solutions.",
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 20),

            const DotIndicator(currentIndex: 1),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const Onboarding3()),
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