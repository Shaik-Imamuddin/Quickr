import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import './review_page.dart';
import './user_chat_screen.dart';

class UserRequestsScreen extends StatefulWidget {
  const UserRequestsScreen({super.key});

  @override
  State<UserRequestsScreen> createState() => _UserRequestsScreenState();
}

class _UserRequestsScreenState extends State<UserRequestsScreen> {
  final Color primaryColor = const Color(0xffA020F0);

  String filter = "All Requests";
  String sortBy = "Latest";

  User? get currentUser => FirebaseAuth.instance.currentUser;

  String _normalizeStatus(dynamic value) {
    final status = value?.toString().trim().toLowerCase() ?? "";

    if (status == "accepted" ||
        status == "inprogress" ||
        status == "in progress") {
      return "In Progress";
    }

    if (status == "completed") return "Completed";

    if (status == "cancelled" || status == "canceled") return "Cancelled";

    return "In Progress";
  }

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

    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: width * 0.055,
            right: width * 0.055,
            bottom: 110,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(),
              const SizedBox(height: 28),
              _filters(),
              const SizedBox(height: 26),
              _requestStats(user.uid),
              const SizedBox(height: 24),
              _historyTitle(),
              const SizedBox(height: 14),
              _requestHistory(user.uid),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return const Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "My Requests",
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 3),
              Text(
                "All requests raised by you",
                style: TextStyle(color: Color(0xff64748B)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _filters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterChip("All Requests"),
          _filterChip("In Progress"),
          _filterChip("Completed"),
        ],
      ),
    );
  }

  Widget _filterChip(String title) {
    final selected = filter == title;

    return GestureDetector(
      onTap: () => setState(() => filter = title),
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? const Color(0xffF3E8FF) : const Color(0xffF1F2F6),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: selected ? primaryColor : const Color(0xff475569),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _requestStats(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("requests")
          .where("userId", isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        int inProgress = 0;
        int completed = 0;
        int total = 0;

        if (snapshot.hasData) {
          final docs = snapshot.data!.docs;
          total = docs.length;

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>? ?? {};
            final status = _normalizeStatus(data["status"]);

            if (status == "In Progress") {
              inProgress++;
            } else if (status == "Completed") {
              completed++;
            }
          }
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _stat("$inProgress", "Progress", const Color(0xffD97706),
                const Color(0xffFEFCE8)),
            _stat("$completed", "Completed", const Color(0xff16A34A),
                const Color(0xffDCFCE7)),
            _stat("$total", "Total", primaryColor, const Color(0xffFAF5FF)),
          ],
        );
      },
    );
  }

  Widget _stat(String value, String title, Color color, Color bg) {
    return Container(
      height: 76,
      width: 105,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: const TextStyle(color: Color(0xff475569), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _historyTitle() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            "Request History",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        Row(
          children: [
            const Text(
              "Sort by",
              style: TextStyle(
                color: Color(0xff64748B),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0xffFAF5FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xffE9D5FF)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: sortBy,
                  isDense: true,
                  icon: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: primaryColor,
                    size: 20,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  dropdownColor: Colors.white,
                  style: const TextStyle(
                    color: Color(0xff1E293B),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  items: const [
                    DropdownMenuItem(value: "Latest", child: Text("Latest")),
                    DropdownMenuItem(value: "Oldest", child: Text("Oldest")),
                    DropdownMenuItem(
                      value: "Posted Date",
                      child: Text("Posted Date"),
                    ),
                    DropdownMenuItem(
                      value: "Title A-Z",
                      child: Text("Title A-Z"),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => sortBy = value);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _requestHistory(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("requests")
          .where("userId", isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Text(
              "Error: ${snapshot.error}",
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.only(top: 30),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        List<QueryDocumentSnapshot> docs = snapshot.data?.docs ?? [];

        if (filter != "All Requests") {
          docs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>? ?? {};
            final status = _normalizeStatus(data["status"]);
            return status == filter;
          }).toList();
        }

        docs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>? ?? {};
          final bData = b.data() as Map<String, dynamic>? ?? {};

          if (sortBy == "Title A-Z") {
            final aTitle = aData["title"]?.toString().toLowerCase() ?? "";
            final bTitle = bData["title"]?.toString().toLowerCase() ?? "";
            return aTitle.compareTo(bTitle);
          }

          final aTime = aData["createdAt"];
          final bTime = bData["createdAt"];

          if (aTime is Timestamp && bTime is Timestamp) {
            if (sortBy == "Oldest") return aTime.compareTo(bTime);
            return bTime.compareTo(aTime);
          }

          if (aTime is Timestamp) return -1;
          if (bTime is Timestamp) return 1;

          return 0;
        });

        if (docs.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xffE5E7EB)),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Center(
              child: Text(
                "No requests found",
                style: TextStyle(color: Color(0xff64748B)),
              ),
            ),
          );
        }

        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>? ?? {};

            final title = data["title"]?.toString() ?? "Untitled Request";
            final description = data["description"]?.toString() ?? "";
            final skill = data["skill"]?.toString() ?? "Q";
            final status = _normalizeStatus(data["status"]);

            final expertId = data["expertId"]?.toString() ?? "";
            final expertName = data["expertName"]?.toString() ?? "";

            final bool isAcceptedByExpert =
                status == "In Progress" && expertId.isNotEmpty;

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xffE5E7EB)),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xffF3E8FF),
                    child: Text(
                      skill.isNotEmpty ? skill[0].toUpperCase() : "Q",
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
                            _statusChip(status: status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xff64748B),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isAcceptedByExpert
                              ? "Expert: ${expertName.isEmpty ? "Expert" : expertName}"
                              : "Waiting for expert",
                          style: const TextStyle(
                            color: Color(0xff64748B),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  size: 16,
                                  color: Color(0xff94A3B8),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    _getTimeText(data["createdAt"]),
                                    style: const TextStyle(
                                      color: Color(0xff64748B),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            if (isAcceptedByExpert) ...[
                              const SizedBox(height: 14),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  _cancelButton(doc.id),
                                  const SizedBox(width: 10),
                                  _connectButton(data),
                                ],
                              ),
                            ] else if (status == "Completed") ...[
                              const SizedBox(height: 14),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  _reviewButton(doc.id, data),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _connectButton(Map<String, dynamic> data) {
    final expertId = data["expertId"]?.toString() ?? "";
    String expertName = data["expertName"]?.toString() ?? "";
    final user = currentUser;

    return GestureDetector(
      onTap: () async {
        if (user == null || expertId.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Expert details not found")),
          );
          return;
        }

        if (expertName.isEmpty) {
          final expertDoc = await FirebaseFirestore.instance
              .collection("experts")
              .doc(expertId)
              .get();

          final expertData = expertDoc.data() ?? {};
          expertName = expertData["name"]?.toString() ??
              expertData["expertName"]?.toString() ??
              "Expert";
        }

        final chatId = await _createOrGetChatRoom(
          currentUserId: user.uid,
          receiverId: expertId,
          receiverName: expertName,
          receiverRole: "Expert",
        );

        if (!mounted) return;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatDetailScreen(
              chatId: chatId,
              receiverId: expertId,
              receiverName: expertName,
              receiverRole: "Expert",
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          "Connect",
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _cancelButton(String requestId) {
    return GestureDetector(
      onTap: () => _showCancelConfirmation(requestId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xffFEE2E2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          "Cancel",
          style: TextStyle(
            color: Color(0xffDC2626),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showCancelConfirmation(String requestId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 74,
                  width: 74,
                  decoration: const BoxDecoration(
                    color: Color(0xffFEF2F2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xffEF4444),
                    size: 42,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Cancel Request?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff111827),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Are you sure you want to cancel this expert and open the request to other experts?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xff6B7280),
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xffE5E7EB)),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          "No",
                          style: TextStyle(
                            color: Color(0xff374151),
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xffEF4444),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () async {
                          await FirebaseFirestore.instance
                              .collection("requests")
                              .doc(requestId)
                              .update({
                            "status": "In Progress",
                            "expertId": FieldValue.delete(),
                            "expertName": FieldValue.delete(),
                            "acceptedAt": FieldValue.delete(),
                            "updatedAt": FieldValue.serverTimestamp(),
                          });

                          if (!mounted) return;

                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Request opened to other experts"),
                            ),
                          );
                        },
                        child: const Text(
                          "Yes",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _reviewButton(String requestId, Map<String, dynamic> data) {
    final bool reviewSubmitted = data["reviewSubmitted"] == true;

    return GestureDetector(
      onTap: reviewSubmitted
          ? null
          : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReviewPage(requestId: requestId),
                ),
              );
            },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: reviewSubmitted ? const Color(0xffE5E7EB) : primaryColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          reviewSubmitted ? "Reviewed" : "Review",
          style: TextStyle(
            color: reviewSubmitted ? const Color(0xff64748B) : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
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

  Widget _statusChip({required String status}) {
    Color bg = const Color(0xffFEF3C7);
    Color color = const Color(0xffD97706);

    if (status == "In Progress") {
      bg = const Color(0xffDBEAFE);
      color = const Color(0xff2563EB);
    } else if (status == "Completed") {
      bg = const Color(0xffDCFCE7);
      color = const Color(0xff16A34A);
    } else if (status == "Cancelled") {
      bg = const Color(0xffFEE2E2);
      color = const Color(0xffDC2626);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}