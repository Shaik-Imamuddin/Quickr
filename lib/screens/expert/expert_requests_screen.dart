import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../user/user_chat_screen.dart';

class ExpertRequestsScreen extends StatefulWidget {
  const ExpertRequestsScreen({super.key});

  @override
  State<ExpertRequestsScreen> createState() => _ExpertRequestsScreenState();
}

class _ExpertRequestsScreenState extends State<ExpertRequestsScreen> {
  final Color primaryColor = const Color(0xffF5A400);
  final user = FirebaseAuth.instance.currentUser;

  String filter = "All";
  String searchText = "";
  String sortBy = "Latest";

  final TextEditingController searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  String _safeText(dynamic value, String fallback) {
    final text = value?.toString().trim() ?? "";
    return text.isEmpty ? fallback : text;
  }

  String _normalizeStatus(dynamic value) {
    final status = _safeText(value, "In Progress").toLowerCase();

    if (status == "accepted" ||
        status == "inprogress" ||
        status == "in progress") {
      return "In Progress";
    }

    if (status == "completed") return "Completed";

    if (status == "cancelled" || status == "canceled") return "Cancelled";

    if (status == "open") return "Open";

    return "In Progress";
  }

  bool _isAvailableForExpert({
    required String expertId,
    required String status,
    required bool cancelledForMe,
  }) {
    return expertId.isEmpty &&
        !cancelledForMe &&
        status != "Completed" &&
        status != "Cancelled";
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
    if (user == null) {
      return const Scaffold(body: Center(child: Text("Expert not logged in")));
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
              const SizedBox(height: 18),
              _searchBar(),
              const SizedBox(height: 24),
              _filters(),
              const SizedBox(height: 34),
              _recentHeader(),
              const SizedBox(height: 14),
              _requestList(),
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
              SizedBox(height: 4),
              Text(
                "Manage your jobs, all in one place",
                style: TextStyle(color: Color(0xff64748B)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _searchBar() {
    return TextField(
      controller: searchController,
      onChanged: (value) {
        setState(() {
          searchText = value.toLowerCase().trim();
        });
      },
      decoration: InputDecoration(
        hintText: "Search by skill or request title...",
        prefixIcon: Icon(Icons.search, color: primaryColor),
        suffixIcon: searchText.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  searchController.clear();
                  setState(() {
                    searchText = "";
                  });
                },
              )
            : null,
        filled: true,
        fillColor: const Color(0xffF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xffE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xffE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: primaryColor, width: 1.5),
        ),
      ),
    );
  }

  Widget _filters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _chip("All"),
          _chip("Open"),
          _chip("In Progress"),
          _chip("Completed"),
          _chip("Cancelled"),
        ],
      ),
    );
  }

  Widget _chip(String title) {
    final selected = filter == title;

    return GestureDetector(
      onTap: () => setState(() => filter = title),
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? const Color(0xffFFF4CC) : const Color(0xffF1F2F6),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: selected ? primaryColor : const Color(0xff475569),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _recentHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            "Recent Requests",
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
                color: const Color(0xffFFF8E6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xffFFE4A3)),
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
                      setState(() {
                        sortBy = value;
                      });
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

  Widget _requestList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("requests").snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text("Unable to load requests");
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        List<QueryDocumentSnapshot> docs = snapshot.data!.docs;

        docs = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>? ?? {};

          final expertId = data["expertId"]?.toString() ?? "";
          final status = _normalizeStatus(data["status"]);

          final cancelledExpertIds =
              List<String>.from(data["cancelledExpertIds"] ?? []);

          final cancelledForMe =
              cancelledExpertIds.contains(user!.uid) && status != "Completed";

          final available = _isAvailableForExpert(
            expertId: expertId,
            status: status,
            cancelledForMe: cancelledForMe,
          );

          final title = data["title"]?.toString().toLowerCase() ?? "";
          final skill = data["skill"]?.toString().toLowerCase() ?? "";

          bool matchesFilter = false;

          if (filter == "All") {
            matchesFilter =
                available || expertId == user!.uid || cancelledForMe;
          } else if (filter == "Open") {
            matchesFilter = available;
          } else if (filter == "In Progress") {
            matchesFilter = expertId == user!.uid && status == "In Progress";
          } else if (filter == "Completed") {
            matchesFilter = expertId == user!.uid && status == "Completed";
          } else if (filter == "Cancelled") {
            matchesFilter = cancelledForMe;
          }

          final matchesSearch = searchText.isEmpty ||
              title.contains(searchText) ||
              skill.contains(searchText);

          return matchesFilter && matchesSearch;
        }).toList();

        docs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>? ?? {};
          final bData = b.data() as Map<String, dynamic>? ?? {};

          final aTime = aData["createdAt"];
          final bTime = bData["createdAt"];

          if (sortBy == "Title A-Z") {
            final aTitle = aData["title"]?.toString().toLowerCase() ?? "";
            final bTitle = bData["title"]?.toString().toLowerCase() ?? "";
            return aTitle.compareTo(bTitle);
          }

          if (aTime is Timestamp && bTime is Timestamp) {
            if (sortBy == "Oldest") {
              return aTime.compareTo(bTime);
            }
            return bTime.compareTo(aTime);
          }

          return 0;
        });

        if (docs.isEmpty) {
          return const Center(child: Text("No requests found"));
        }

        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>? ?? {};

            final expertId = data["expertId"]?.toString() ?? "";
            final status = _normalizeStatus(data["status"]);

            final cancelledExpertIds =
                List<String>.from(data["cancelledExpertIds"] ?? []);

            final cancelledForMe =
                cancelledExpertIds.contains(user!.uid) && status != "Completed";

            final available = _isAvailableForExpert(
              expertId: expertId,
              status: status,
              cancelledForMe: cancelledForMe,
            );

            final acceptedByMe = expertId == user!.uid;

            final displayStatus = cancelledForMe
                ? "Cancelled"
                : available
                    ? "Open"
                    : status;

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xffE5E7EB)),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xffE0F2FE),
                        child: Text(
                          _safeText(data["skill"], "Q")[0].toUpperCase(),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          _safeText(data["title"], "Untitled Request"),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      _statusChip(displayStatus),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _safeText(data["description"], ""),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xff64748B)),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _tag(_safeText(data["skill"], "General")),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text("💰 100 Coins"),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              _getTimeText(data["createdAt"]),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      if (available) ...[
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _smallButton(
                              text: "Accept",
                              color: primaryColor,
                              onTap: () => _acceptRequest(doc.id, data),
                            ),
                          ],
                        ),
                      ] else if (acceptedByMe && status == "In Progress") ...[
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _actionButton(
                              text: "Cancel",
                              bg: const Color(0xffFEE2E2),
                              color: const Color(0xffDC2626),
                              onTap: () => _showCancelConfirmation(doc.id, data),
                            ),
                            const SizedBox(width: 8),
                            _actionButton(
                              text: "Connect",
                              bg: const Color(0xffFFF4CC),
                              color: primaryColor,
                              onTap: () => _connectToUser(data),
                            ),
                            const SizedBox(width: 8),
                            _actionButton(
                              text: "Complete",
                              bg: const Color(0xffDCFCE7),
                              color: const Color(0xff16A34A),
                              onTap: () => _completeRequest(doc.id, data),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _smallButton({
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xffFFF4CC),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _actionButton({
    required String text,
    required Color bg,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _tag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xffFFF4CC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(color: primaryColor, fontSize: 12),
      ),
    );
  }

  Future<void> _connectToUser(Map<String, dynamic> data) async {
    final currentExpertId = user!.uid;
    final receiverId = _safeText(data["userId"], "");

    String receiverName = _safeText(
      data["userName"] ?? data["name"] ?? data["createdByName"],
      "",
    );

    if (receiverId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User details not found")),
      );
      return;
    }

    if (receiverName.isEmpty) {
      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(receiverId)
          .get();

      final userData = userDoc.data() ?? {};
      receiverName = _safeText(userData["name"], "User");
    }

    final chatId = await _createOrGetChatRoom(
      currentUserId: currentExpertId,
      receiverId: receiverId,
      receiverName: receiverName,
      receiverRole: "User",
    );

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatDetailScreen(
          chatId: chatId,
          receiverId: receiverId,
          receiverName: receiverName,
          receiverRole: "User",
        ),
      ),
    );
  }

  void _showCancelConfirmation(String requestId, Map<String, dynamic> data) {
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
                  "This request will be opened to other experts, but it will show as cancelled for you.",
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
                          Navigator.pop(context);
                          await _cancelAcceptedRequest(requestId, data);
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

  Future<void> _cancelAcceptedRequest(
    String requestId,
    Map<String, dynamic> data,
  ) async {
    final requestTitle = _safeText(data["title"], "Untitled Request");
    final userId = _safeText(data["userId"], "");

    await FirebaseFirestore.instance.collection("requests").doc(requestId).update({
      "expertId": FieldValue.delete(),
      "expertName": FieldValue.delete(),
      "status": "In Progress",
      "acceptedAt": FieldValue.delete(),
      "cancelledExpertIds": FieldValue.arrayUnion([user!.uid]),
      "cancelledExperts.${user!.uid}": "Cancelled",
      "updatedAt": FieldValue.serverTimestamp(),
    });

    if (userId.isNotEmpty) {
      await FirebaseFirestore.instance.collection("notifications").add({
        "userId": userId,
        "title": requestTitle,
        "requestTitle": requestTitle,
        "requestId": requestId,
        "expertId": user!.uid,
        "message":
            "The expert cancelled your request. It is open to other experts again.",
        "status": "In Progress",
        "type": "expert_cancelled",
        "createdAt": FieldValue.serverTimestamp(),
        "isRead": false,
      });
    }

    await FirebaseFirestore.instance.collection("expert_notifications").add({
      "expertId": user!.uid,
      "title": "Request Cancelled",
      "requestTitle": requestTitle,
      "requestId": requestId,
      "message": "You cancelled '$requestTitle'. It is now open to other experts.",
      "type": "cancelled",
      "status": "Cancelled",
      "createdAt": FieldValue.serverTimestamp(),
      "isRead": false,
    });
  }

  Future<void> _acceptRequest(
    String requestId,
    Map<String, dynamic> data,
  ) async {
    final expertDoc = await FirebaseFirestore.instance
        .collection("experts")
        .doc(user!.uid)
        .get();

    final expertData = expertDoc.data() ?? {};
    final expertName = _safeText(expertData["name"], "Expert");

    final requestTitle = _safeText(data["title"], "Untitled Request");
    final problem = _safeText(data["description"], "No problem description");
    final skill = _safeText(data["skill"], "General");
    final userId = _safeText(data["userId"], "");

    String userName = _safeText(
      data["userName"] ?? data["name"] ?? data["createdByName"],
      "",
    );

    if (userName.isEmpty && userId.isNotEmpty) {
      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .get();

      final userData = userDoc.data() ?? {};
      userName = _safeText(userData["name"], "User");
    }

    await FirebaseFirestore.instance.collection("requests").doc(requestId).update({
      "expertId": user!.uid,
      "expertName": expertName,
      "status": "In Progress",
      "acceptedAt": FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance.collection("notifications").add({
      "userId": userId,
      "title": requestTitle,
      "requestTitle": requestTitle,
      "requestId": requestId,
      "expertId": user!.uid,
      "expertName": expertName,
      "problem": problem,
      "skill": skill,
      "message":
          "Expert $expertName started working on your request: '$requestTitle'.",
      "status": "In Progress",
      "type": "in_progress",
      "createdAt": FieldValue.serverTimestamp(),
      "isRead": false,
    });

    await FirebaseFirestore.instance.collection("expert_notifications").add({
      "expertId": user!.uid,
      "title": "Request In Progress 🔄",
      "requestTitle": requestTitle,
      "requestId": requestId,
      "userId": userId,
      "userName": userName,
      "problem": problem,
      "skill": skill,
      "message":
          "You are working on '$requestTitle' raised by $userName. Problem: $problem",
      "type": "in_progress",
      "status": "In Progress",
      "createdAt": FieldValue.serverTimestamp(),
      "isRead": false,
    });
  }

  Future<void> _completeRequest(
    String requestId,
    Map<String, dynamic> data,
  ) async {
    final userId = _safeText(data["userId"], "");
    final requestTitle = _safeText(data["title"], "Untitled Request");
    final problem = _safeText(data["description"], "No problem description");
    final skill = _safeText(data["skill"], "General");

    String userName = _safeText(
      data["userName"] ?? data["name"] ?? data["createdByName"],
      "",
    );

    if (userName.isEmpty && userId.isNotEmpty) {
      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .get();

      final userData = userDoc.data() ?? {};
      userName = _safeText(userData["name"], "User");
    }

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final requestRef =
          FirebaseFirestore.instance.collection("requests").doc(requestId);
      final userRef = FirebaseFirestore.instance.collection("users").doc(userId);

      transaction.update(requestRef, {
        "status": "Completed",
        "updatedAt": FieldValue.serverTimestamp(),
      });

      transaction.set(userRef, {
        "openRequests": FieldValue.increment(-1),
        "completedRequests": FieldValue.increment(1),
      }, SetOptions(merge: true));
    });

    await FirebaseFirestore.instance.collection("notifications").add({
      "userId": userId,
      "title": requestTitle,
      "requestTitle": requestTitle,
      "requestId": requestId,
      "expertId": user!.uid,
      "problem": problem,
      "skill": skill,
      "message": "Your request '$requestTitle' has been completed successfully.",
      "status": "Completed",
      "type": "completed",
      "createdAt": FieldValue.serverTimestamp(),
      "isRead": false,
    });

    await FirebaseFirestore.instance.collection("expert_notifications").add({
      "expertId": user!.uid,
      "title": "Request Completed & Coins Earned 💰",
      "requestTitle": requestTitle,
      "requestId": requestId,
      "userId": userId,
      "userName": userName,
      "problem": problem,
      "skill": skill,
      "coins": 100,
      "message":
          "You completed '$requestTitle' raised by $userName and earned 100 coins. Problem solved: $problem",
      "type": "completed_coins",
      "status": "Completed",
      "createdAt": FieldValue.serverTimestamp(),
      "isRead": false,
    });

    await FirebaseFirestore.instance.collection("experts").doc(user!.uid).set({
      "coins": FieldValue.increment(100),
    }, SetOptions(merge: true));
  }

  String _getTimeText(dynamic timestamp) {
    if (timestamp == null) return "Recently";

    try {
      final date = (timestamp as Timestamp).toDate();
      final diff = DateTime.now().difference(date);

      if (diff.inMinutes < 1) return "Just now";
      if (diff.inMinutes < 60) return "${diff.inMinutes} mins ago";
      if (diff.inHours < 24) return "${diff.inHours} hours ago";
      if (diff.inDays == 1) return "Yesterday";
      return "${diff.inDays} days ago";
    } catch (_) {
      return "Recently";
    }
  }

  Widget _statusChip(String status) {
    Color bg = const Color(0xffFEF3C7);
    Color color = const Color(0xffD97706);

    if (status == "In Progress") {
      bg = const Color(0xffFFF4CC);
      color = primaryColor;
    } else if (status == "Completed") {
      bg = const Color(0xffDCFCE7);
      color = const Color(0xff16A34A);
    } else if (status == "Cancelled") {
      bg = const Color(0xffFEE2E2);
      color = const Color(0xffDC2626);
    } else if (status == "Open") {
      bg = const Color(0xffE0F2FE);
      color = const Color(0xff0284C7);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}