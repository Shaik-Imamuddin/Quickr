import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExpertNotificationsPage extends StatelessWidget {
  const ExpertNotificationsPage({super.key});

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
        title: const Text(
          "Notifications",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("expert_notifications")
            .where("expertId", isEqualTo: expert.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Unable to load notifications"));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          List<QueryDocumentSnapshot> notifications = snapshot.data!.docs;

          notifications.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>? ?? {};
            final bData = b.data() as Map<String, dynamic>? ?? {};

            final aTime = aData["createdAt"];
            final bTime = bData["createdAt"];

            if (aTime is Timestamp && bTime is Timestamp) {
              return bTime.compareTo(aTime);
            }

            return 0;
          });

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 90,
                    width: 90,
                    decoration: const BoxDecoration(
                      color: Color(0xffFFF4CC),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.notifications_none,
                      size: 42,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "No notifications yet",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Expert activities and updates\nwill appear here",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xff64748B),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final data =
                  notifications[index].data() as Map<String, dynamic>? ?? {};

              final type =
                  data["type"]?.toString().toLowerCase() ?? "info";

              final status =
                  data["status"]?.toString().toLowerCase() ?? "";

              final title =
                  data["title"]?.toString() ?? "New Notification";

              final message = data["message"]?.toString() ?? "";
              final createdAt = data["createdAt"];

              final requestTitle =
                  data["requestTitle"]?.toString() ??
                  data["complaintTitle"]?.toString() ??
                  data["titleText"]?.toString() ??
                  "";

              final userName =
                  data["userName"]?.toString() ??
                  data["senderName"]?.toString() ??
                  data["fromName"]?.toString() ??
                  "";

              final problem = data["problem"]?.toString() ?? "";
              final skill = data["skill"]?.toString() ?? "";
              final coins = data["coins"];

              final bool isCompleted =
                  status == "completed" ||
                  type == "completed" ||
                  type == "completed_coins";

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xffE5E7EB)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 52,
                      width: 52,
                      decoration: BoxDecoration(
                        color: isCompleted ? const Color(0xffDCFCE7) : _bgColor(type),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        isCompleted ? Icons.check_circle : _icon(type),
                        color: isCompleted ? const Color(0xff16A34A) : _iconColor(type),
                        size: 27,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              Text(
                                _timeAgo(createdAt),
                                style: const TextStyle(
                                  color: Color(0xff94A3B8),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          if (userName.isNotEmpty)
                            _detailChip(
                              icon: Icons.person_outline,
                              text: "Raised by: $userName",
                            ),

                          if (requestTitle.isNotEmpty)
                            _detailChip(
                              icon: Icons.assignment_outlined,
                              text: "Request: $requestTitle",
                            ),

                          if (skill.isNotEmpty)
                            _detailChip(
                              icon: Icons.psychology_outlined,
                              text: "Skill: $skill",
                            ),

                          if (coins != null)
                            _detailChip(
                              icon: Icons.monetization_on,
                              text: "$coins coins earned",
                            ),

                          if (problem.isNotEmpty)
                            _detailChip(
                              icon: Icons.task_alt,
                              text: "Problem: $problem",
                            ),

                          if (message.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              message,
                              style: const TextStyle(
                                color: Color(0xff64748B),
                                height: 1.4,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ],
                      ),
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

  Widget _detailChip({
    required IconData icon,
    required String text,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xffF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xff64748B)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xff475569),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _icon(String type) {
    switch (type) {
      case "accepted":
      case "request":
        return Icons.notifications_active;
      case "coins":
        return Icons.monetization_on;
      case "message":
        return Icons.chat_bubble_outline;
      case "rating":
        return Icons.star;
      case "completed":
      case "completed_coins":
        return Icons.check_circle;
      default:
        return Icons.notifications_none;
    }
  }

  Color _iconColor(String type) {
    switch (type) {
      case "accepted":
      case "request":
        return Colors.orange;
      case "coins":
        return Colors.green;
      case "message":
        return Colors.blue;
      case "rating":
        return Colors.amber;
      case "completed":
      case "completed_coins":
        return Colors.green;
      default:
        return primaryColor;
    }
  }

  Color _bgColor(String type) {
    switch (type) {
      case "accepted":
      case "request":
        return const Color(0xffFFF4CC);
      case "coins":
      case "completed":
      case "completed_coins":
        return const Color(0xffDCFCE7);
      case "message":
        return const Color(0xffDBEAFE);
      case "rating":
        return const Color(0xffFEF3C7);
      default:
        return const Color(0xffFFF4CC);
    }
  }

  String _timeAgo(dynamic timestamp) {
    if (timestamp == null) return "";

    try {
      final date = (timestamp as Timestamp).toDate();
      final diff = DateTime.now().difference(date);

      if (diff.inSeconds < 60) return "now";
      if (diff.inMinutes < 60) return "${diff.inMinutes}m";
      if (diff.inHours < 24) return "${diff.inHours}h";
      if (diff.inDays < 7) return "${diff.inDays}d";

      return "${date.day}/${date.month}/${date.year}";
    } catch (_) {
      return "";
    }
  }
}