import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserNotificationsScreen extends StatelessWidget {
  const UserNotificationsScreen({super.key});

  final Color primaryColor = const Color(0xffA020F0);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("User not logged in")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Notifications",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("notifications")
            .where("userId", isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                "Error: ${snapshot.error}",
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          List<QueryDocumentSnapshot> docs = snapshot.data?.docs ?? [];

          docs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>? ?? {};
            final bData = b.data() as Map<String, dynamic>? ?? {};
            final aTime = aData["createdAt"];
            final bTime = bData["createdAt"];

            if (aTime is Timestamp && bTime is Timestamp) {
              return bTime.compareTo(aTime);
            }

            if (aTime is Timestamp) return -1;
            if (bTime is Timestamp) return 1;

            return 0;
          });

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "No notifications yet",
                style: TextStyle(
                  color: Color(0xff64748B),
                  fontSize: 15,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>? ?? {};

              final title = data["title"]?.toString() ?? "Notification";
              final message = data["message"]?.toString() ?? "";
              final status = data["status"]?.toString() ?? "In Progress";
              final type = data["type"]?.toString().toLowerCase() ?? "";

              final bool isCompleted =
                  status.toLowerCase() == "completed" || type == "completed";

              final bool isAccepted =
                  status.toLowerCase() == "accepted" || type == "accepted";

              final String displayStatus = isCompleted
                  ? "Completed"
                  : isAccepted
                      ? "Accepted"
                      : status;

              final IconData notificationIcon = isCompleted
                  ? Icons.check_circle
                  : isAccepted
                      ? Icons.lightbulb
                      : Icons.notifications_active;

              final Color iconColor = isCompleted
                  ? const Color(0xff16A34A)
                  : isAccepted
                      ? const Color(0xffF59E0B)
                      : primaryColor;

              final Color badgeBgColor = isCompleted
                  ? const Color(0xffDCFCE7)
                  : isAccepted
                      ? const Color(0xffFEF3C7)
                      : const Color(0xffFEF3C7);

              final Color badgeTextColor = isCompleted
                  ? const Color(0xff16A34A)
                  : isAccepted
                      ? const Color(0xffD97706)
                      : const Color(0xffD97706);

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xffFAF5FF),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xffE9D5FF)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: iconColor.withOpacity(0.15),
                      child: Icon(
                        notificationIcon,
                        color: iconColor,
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
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: badgeBgColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  displayStatus,
                                  style: TextStyle(
                                    color: badgeTextColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            message,
                            style: const TextStyle(
                              color: Color(0xff64748B),
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                size: 14,
                                color: Color(0xff94A3B8),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getTimeText(data["createdAt"]),
                                style: const TextStyle(
                                  color: Color(0xff94A3B8),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          )
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

  String _getTimeText(dynamic timestamp) {
    if (timestamp == null) return "Recently";

    try {
      final date = (timestamp as Timestamp).toDate();
      final difference = DateTime.now().difference(date);

      if (difference.inMinutes < 1) return "Just now";
      if (difference.inMinutes < 60) return "${difference.inMinutes} mins ago";
      if (difference.inHours < 24) return "${difference.inHours} hours ago";
      if (difference.inDays == 1) return "Yesterday";

      return "${difference.inDays} days ago";
    } catch (e) {
      return "Recently";
    }
  }
}