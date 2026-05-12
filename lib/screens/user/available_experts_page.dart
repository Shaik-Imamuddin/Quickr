import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AvailableExpertsPage extends StatelessWidget {
  final Color primaryColor;

  const AvailableExpertsPage({super.key, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Available Experts"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection("experts").snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final experts = snapshot.data?.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>? ?? {};
                return data["available"] == true ||
                    data["isOnline"] == true ||
                    data["status"]?.toString().toLowerCase() == "online";
              }).toList() ??
              [];

          if (experts.isEmpty) {
            return const Center(
              child: Text(
                "No experts are online right now",
                style: TextStyle(color: Color(0xff64748B)),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(18),
            itemCount: experts.length,
            itemBuilder: (context, index) {
              final data = experts[index].data() as Map<String, dynamic>? ?? {};

              final name = data["name"]?.toString() ?? "Expert";
              final skill = data["skill"]?.toString() ??
                  data["expertise"]?.toString() ??
                  "General Support";
              final rating = data["rating"]?.toString() ?? "4.9";

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xffE5E7EB)),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: const Color(0xffF3E8FF),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : "E",
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(skill,
                              style:
                                  const TextStyle(color: Color(0xff64748B))),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.circle,
                                  color: Colors.green, size: 10),
                              const SizedBox(width: 6),
                              const Text(
                                "Online",
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Icon(Icons.star,
                                  color: Colors.amber, size: 17),
                              Text(" $rating"),
                            ],
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Connect with $name")),
                        );
                      },
                      child: const Text("Connect"),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}