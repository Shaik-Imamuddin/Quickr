import 'package:flutter/material.dart';

class UserProfilePage extends StatelessWidget {
  const UserProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Profile"),
        backgroundColor: Color(0xFF8B6BEF),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          "User Profile Page Dummy",
          style: TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}