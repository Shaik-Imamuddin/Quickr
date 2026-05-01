import 'package:flutter/material.dart';
import 'role_selection_page.dart';
import '../widgets/dot_indicator.dart';

class Onboarding3 extends StatelessWidget {
  const Onboarding3({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),

            const Spacer(),

            Image.asset("assets/images/wallet.png",
                height: size.height * 0.3),

            const SizedBox(height: 20),

            const CircleAvatar(
              backgroundColor: Colors.purple,
              child: Text("03", style: TextStyle(color: Colors.white)),
            ),

            const SizedBox(height: 20),

            const Text(
              "Solve & Pay Securely",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 30),
              child: Text(
                "Get your solution and pay securely with our trusted escrow system.",
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 20),

            const DotIndicator(currentIndex: 2),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RoleSelectionPage(),
                    ),
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