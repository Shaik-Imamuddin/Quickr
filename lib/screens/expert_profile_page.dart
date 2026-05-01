import 'package:flutter/material.dart';

class ExpertProfilePage extends StatelessWidget {
  const ExpertProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Expert Profile"),
        backgroundColor: Color(0xFFFFAF28),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          "Expert Profile Page Dummy",
          style: TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}