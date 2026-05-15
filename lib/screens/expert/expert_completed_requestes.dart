import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExpertCompletedActivityPage extends StatefulWidget {
  const ExpertCompletedActivityPage({super.key});

  @override
  State<ExpertCompletedActivityPage> createState() =>
      _ExpertCompletedActivityPageState();
}

class _ExpertCompletedActivityPageState
    extends State<ExpertCompletedActivityPage> {
  final Color primaryColor = const Color(0xffF5A400);

  String selectedFilter = "All";

  final List<String> filters = ["All", "Completed", "Cancelled"];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Expert not logged in")),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text(
          "My Activity",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          _filterSection(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("requests")
                  .where("expertId", isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text("No activity found"),
                  );
                }

                List<QueryDocumentSnapshot> docs =
                    snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>? ?? {};
                  final status =
                      (data["status"] ?? "").toString().toLowerCase();

                  final cancelledExpertIds =
                      List<String>.from(data["cancelledExpertIds"] ?? []);

                  final cancelledForMe =
                      cancelledExpertIds.contains(user.uid) ||
                          status == "cancelled";

                  final completedForMe = status == "completed";

                  if (selectedFilter == "Completed") {
                    return completedForMe && !cancelledForMe;
                  }

                  if (selectedFilter == "Cancelled") {
                    return cancelledForMe;
                  }

                  return completedForMe || cancelledForMe;
                }).toList();

                if (docs.isEmpty) {
                  return Center(
                    child: Text(
                      selectedFilter == "All"
                          ? "No completed or cancelled requests yet"
                          : "No ${selectedFilter.toLowerCase()} requests yet",
                    ),
                  );
                }

                docs.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>? ?? {};
                  final bData = b.data() as Map<String, dynamic>? ?? {};

                  final aTime = aData["createdAt"];
                  final bTime = bData["createdAt"];

                  if (aTime is Timestamp && bTime is Timestamp) {
                    return bTime.compareTo(aTime);
                  }

                  return 0;
                });

                return ListView.builder(
                  padding: const EdgeInsets.all(18),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data =
                        docs[index].data() as Map<String, dynamic>? ?? {};

                    final title = data["title"] ?? "Untitled Request";
                    final skill = data["skill"] ?? "General";
                    final description =
                        data["description"] ?? "No description";

                    final userId = data["userId"] ??
                        data["raisedBy"] ??
                        data["createdBy"] ??
                        data["senderId"];

                    final status =
                        (data["status"] ?? "").toString().toLowerCase();

                    final cancelledExpertIds =
                        List<String>.from(data["cancelledExpertIds"] ?? []);

                    final isCancelled =
                        cancelledExpertIds.contains(user.uid) ||
                            status == "cancelled";

                    final displayStatus =
                        isCancelled ? "Cancelled" : "Completed";

                    String dateText = "";

                    if (data["createdAt"] is Timestamp) {
                      final date = (data["createdAt"] as Timestamp).toDate();
                      dateText =
                          "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
                    }

                    return _activityCard(
                      title: title,
                      skill: skill,
                      description: description,
                      userId: userId,
                      dateText:
                          dateText.isEmpty ? "Not available" : dateText,
                      status: displayStatus,
                      isCancelled: isCancelled,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterSection() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Row(
        children: filters.map((filter) {
          final bool isSelected = selectedFilter == filter;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () {
                setState(() {
                  selectedFilter = filter;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? primaryColor : const Color(0xffF1F5F9),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isSelected ? primaryColor : const Color(0xffE2E8F0),
                  ),
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xff475569),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _activityCard({
    required String title,
    required String skill,
    required String description,
    required dynamic userId,
    required String dateText,
    required String status,
    required bool isCancelled,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xffE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor:
                    isCancelled ? Colors.red.shade50 : const Color(0xffFFF4CC),
                child: Icon(
                  isCancelled
                      ? Icons.cancel_outlined
                      : Icons.check_circle_outline,
                  color: isCancelled ? Colors.red : primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _statusBadge(status, isCancelled),
            ],
          ),
          const SizedBox(height: 14),
          _infoRow("Skill", skill),
          FutureBuilder<DocumentSnapshot>(
            future: userId == null
                ? null
                : FirebaseFirestore.instance
                    .collection("users")
                    .doc(userId)
                    .get(),
            builder: (context, userSnapshot) {
              String username = "Unknown User";

              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                final userData =
                    userSnapshot.data!.data() as Map<String, dynamic>? ?? {};

                username = userData["username"] ??
                    userData["name"] ??
                    userData["fullName"] ??
                    "Unknown User";
              }

              return _infoRow("Username", username);
            },
          ),
          _infoRow("Date", dateText),
          const SizedBox(height: 10),
          const Text(
            "Description",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Text(
            description,
            style: const TextStyle(
              color: Color(0xff64748B),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status, bool isCancelled) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: isCancelled ? Colors.red.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: isCancelled ? Colors.red : Colors.green,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          SizedBox(
            width: 85,
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xff64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}