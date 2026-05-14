import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'user_chat_screen.dart';

class AvailableExpertsPage extends StatelessWidget {
  final Color primaryColor;

  const AvailableExpertsPage({super.key, required this.primaryColor});

  User? get currentUser => FirebaseAuth.instance.currentUser;

  String _chatId(String a, String b) {
    final ids = [a, b];
    ids.sort();
    return "${ids[0]}_${ids[1]}";
  }

  Future<String> _createOrGetChatRoom({
    required String currentUserId,
    required String receiverId,
    required String receiverName,
    required String receiverRole,
  }) async {
    final chatId = _chatId(currentUserId, receiverId);

    final chatRef = FirebaseFirestore.instance.collection("chats").doc(chatId);
    final chatDoc = await chatRef.get();

    if (!chatDoc.exists) {
      await chatRef.set({
        "chatId": chatId,
        "members": [currentUserId, receiverId],
        "createdBy": currentUserId,
        "receiverId": receiverId,
        "receiverName": receiverName,
        "receiverRole": receiverRole,
        "lastMessage": "",
        "lastSenderId": "",
        "lastMessageTime": FieldValue.serverTimestamp(),
        "unreadCounts": {
          currentUserId: 0,
          receiverId: 0,
        },
        "createdAt": FieldValue.serverTimestamp(),
      });
    }

    return chatId;
  }

  @override
  Widget build(BuildContext context) {
    final user = currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("User not logged in")),
      );
    }

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
              final expertDoc = experts[index];
              final data = expertDoc.data() as Map<String, dynamic>? ?? {};

              final expertId = expertDoc.id;
              final name = data["name"]?.toString() ??
                  data["expertName"]?.toString() ??
                  "Expert";

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
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            skill,
                            style: const TextStyle(
                              color: Color(0xff64748B),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.circle,
                                color: Colors.green,
                                size: 10,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                "Online",
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 17,
                              ),
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
                      onPressed: () async {
                        final chatId = await _createOrGetChatRoom(
                          currentUserId: user.uid,
                          receiverId: expertId,
                          receiverName: name,
                          receiverRole: "Expert",
                        );

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatDetailScreen(
                              chatId: chatId,
                              receiverId: expertId,
                              receiverName: name,
                              receiverRole: "Expert",
                            ),
                          ),
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