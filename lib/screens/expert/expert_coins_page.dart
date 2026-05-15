import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ExpertCoinsPage extends StatelessWidget {
  const ExpertCoinsPage({super.key});

  final Color primaryColor = const Color(0xffF5A400);

  @override
  Widget build(BuildContext context) {
    final expert = FirebaseAuth.instance.currentUser;

    if (expert == null) {
      return const Scaffold(
        body: Center(child: Text("Expert not logged in")),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "Coins Overview",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("requests")
            .where("expertId", isEqualTo: expert.uid)
            .where("status", isEqualTo: "Completed")
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          int totalCoins = 0;

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>? ?? {};
            final coins = data["coins"] ?? data["amount"] ?? 100;
            totalCoins += coins is int ? coins : int.tryParse(coins.toString()) ?? 0;
          }

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xffFFB800), Color(0xffFF5A00)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Total Coins Earned",
                      style: TextStyle(color: Colors.white70, fontSize: 15),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "$totalCoins Coins",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${docs.length} completed requests",
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                "Earning Breakdown",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 14),

              if (docs.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Text("No completed tasks yet"),
                  ),
                ),

              ...docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>? ?? {};

                final title = data["title"] ?? "Completed Request";
                final skill = data["skill"] ?? "General";
                final coins = data["coins"] ?? data["amount"] ?? 100;

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xffE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xffFFF4CC),
                        child: Icon(Icons.monetization_on, color: primaryColor),
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              skill,
                              style: const TextStyle(
                                color: Color(0xff64748B),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Text(
                        "+$coins",
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}