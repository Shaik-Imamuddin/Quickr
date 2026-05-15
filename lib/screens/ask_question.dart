import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AskQuestionScreen extends StatefulWidget {
  const AskQuestionScreen({super.key});

  @override
  State<AskQuestionScreen> createState() => _AskQuestionScreenState();
}

class _AskQuestionScreenState extends State<AskQuestionScreen> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  String selectedSkill = "Java";
  bool isLoading = false;

  final Color primaryColor = const Color(0xffA020F0);

  Future<void> submitRequest() async {
    if (titleController.text.trim().isEmpty ||
        descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not logged in")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final userRef =
          FirebaseFirestore.instance.collection("users").doc(currentUser.uid);

      final requestRef =
          FirebaseFirestore.instance.collection("requests").doc();

      final questionTitle = titleController.text.trim();
      final questionDescription = descriptionController.text.trim();

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final userSnapshot = await transaction.get(userRef);

        if (!userSnapshot.exists) {
          transaction.set(userRef, {
            "uid": currentUser.uid,
            "name": currentUser.displayName ?? "User",
            "email": currentUser.email ?? "",
            "role": "user",
            "walletBalance": 0,
            "totalRequests": 0,
            "openRequests": 0,
            "completedRequests": 0,
            "createdAt": FieldValue.serverTimestamp(),
          });
        }

        transaction.set(requestRef, {
          "requestId": requestRef.id,
          "userId": currentUser.uid,
          "title": questionTitle,
          "description": questionDescription,
          "skill": selectedSkill,
          "status": "In Progress",
          "expertId": "",
          "expertName": "",
          "createdAt": FieldValue.serverTimestamp(),
          "updatedAt": FieldValue.serverTimestamp(),
        });

        transaction.update(userRef, {
          "totalRequests": FieldValue.increment(1),
          "openRequests": FieldValue.increment(1),
        });
      });

      // 🔥 Dynamic notification
      await FirebaseFirestore.instance.collection("notifications").add({
        "userId": currentUser.uid,

        // complaint title as notification title
        "title": questionTitle,

        // dynamic message
        "message":
            "$questionTitle complaint created successfully",

        "status": "In Progress",

        "createdAt": FieldValue.serverTimestamp(),

        "isRead": false,
      });

      if (!mounted) return;

      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Request submitted successfully"),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text(
          "Ask Question",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),

      body: SingleChildScrollView(
        padding: EdgeInsets.all(width * 0.06),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              "What do you need help with?",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              "Describe your issue clearly to get faster help from experts.",
              style: TextStyle(
                color: Color(0xff64748B),
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              "Question Title",
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: titleController,
              decoration: inputDecoration(
                "Enter your question title",
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Problem Description",
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: descriptionController,
              maxLines: 5,
              decoration: inputDecoration(
                "Explain your issue in detail",
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Select Skill",
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              value: selectedSkill,
              decoration: inputDecoration("Choose skill category"),

              items: [
                "Java",
                "Flutter",
                "Python",
                "SQL",
                "Design",
                "Excel",
                "React",
                "Firebase",
                "Spring Boot",
              ]
                  .map(
                    (skill) => DropdownMenuItem(
                      value: skill,
                      child: Text(skill),
                    ),
                  )
                  .toList(),

              onChanged: (value) {
                setState(() {
                  selectedSkill = value!;
                });
              },
            ),

            const SizedBox(height: 34),

            SizedBox(
              width: double.infinity,
              height: 54,

              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),

                onPressed: isLoading ? null : submitRequest,

                child: isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        "Submit Request",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,

      filled: true,
      fillColor: const Color(0xffF4F4F6),

      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 16,
      ),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: primaryColor,
          width: 1.5,
        ),
      ),
    );
  }
}