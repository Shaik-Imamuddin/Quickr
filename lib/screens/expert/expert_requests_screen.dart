import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
              _backButton(context),
              const SizedBox(height: 26),
              _header(context),
              const SizedBox(height: 18),
              _searchBar(),
              const SizedBox(height: 24),
              _filters(),
              const SizedBox(height: 28),
              _banner(),
              const SizedBox(height: 24),
              _recentHeader(),
              const SizedBox(height: 14),
              _requestList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _backButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushReplacementNamed(context, "/expertHome");
      },
      child: Container(
        height: 46,
        width: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Icon(
          Icons.arrow_back,
          size: 26,
          color: Color(0xff1E293B),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      children: [
        const Expanded(
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
        const Icon(Icons.search, size: 27),
        const SizedBox(width: 14),
        GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, "/expertProfile");
          },
          child: CircleAvatar(
            backgroundColor: primaryColor,
            child: const Text("🚀", style: TextStyle(fontSize: 20)),
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
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

  Widget _banner() {
    return Container(
      height: 132,
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xffFFB800), Color(0xffFF5A00)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Color(0xffffd46b),
            child: Text("🤝", style: TextStyle(fontSize: 28)),
          ),
          const SizedBox(width: 18),
          const Expanded(
            child: Text(
              "Need expert\nhelp?\nPost a new request\nand get help from experts!",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Text(
              "Find Request",
              style: TextStyle(color: Color(0xffFF5A00)),
            ),
          )
        ],
      ),
    );
  }

  Widget _recentHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            "Recent Requests",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            setState(() {
              sortBy = value;
            });
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: "Latest", child: Text("Latest")),
            PopupMenuItem(value: "Oldest", child: Text("Oldest")),
            PopupMenuItem(value: "Posted Date", child: Text("Posted Date")),
            PopupMenuItem(value: "Title A-Z", child: Text("Title A-Z")),
          ],
          child: Text(
            "Sort by: $sortBy⌄",
            style: const TextStyle(color: Color(0xff64748B)),
          ),
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
          final status = data["status"]?.toString() ?? "In Progress";

          final title = data["title"]?.toString().toLowerCase() ?? "";
          final skill = data["skill"]?.toString().toLowerCase() ?? "";

          bool matchesFilter = false;

          if (filter == "All") {
            matchesFilter = true;
          } else if (filter == "Open") {
            matchesFilter = expertId.isEmpty && status == "In Progress";
          } else if (filter == "In Progress") {
            matchesFilter = expertId == user!.uid && status == "In Progress";
          } else if (filter == "Completed") {
            matchesFilter = expertId == user!.uid && status == "Completed";
          } else if (filter == "Cancelled") {
            matchesFilter = status == "Cancelled";
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
            final status = data["status"]?.toString() ?? "In Progress";
            final acceptedByMe = expertId == user!.uid;
            final available = expertId.isEmpty;

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
                        child: Text((data["skill"] ?? "Q")[0]),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          data["title"] ?? "Untitled Request",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    data["description"] ?? "",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xff64748B)),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      _tag(data["skill"] ?? "General"),
                      _tag(status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text("💰 100 Coins"),
                      const SizedBox(width: 14),
                      Text(_getTimeText(data["createdAt"])),
                      const Spacer(),
                      if (available)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                          ),
                          onPressed: () => _acceptRequest(doc.id, data),
                          child: const Text(
                            "Accept",
                            style: TextStyle(color: Colors.white),
                          ),
                        )
                      else if (acceptedByMe && status == "In Progress")
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          onPressed: () => _completeRequest(doc.id, data),
                          child: const Text(
                            "Complete",
                            style: TextStyle(color: Colors.white),
                          ),
                        )
                      else
                        _tag(status),
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
      final userDoc =
          await FirebaseFirestore.instance.collection("users").doc(userId).get();

      final userData = userDoc.data() ?? {};
      userName = _safeText(userData["name"], "User");
    }

    await FirebaseFirestore.instance.collection("requests").doc(requestId).update({
      "expertId": user!.uid,
      "expertName": expertName,
      "status": "In Progress",
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
      "message": "Expert $expertName accepted your request: '$requestTitle'.",
      "status": "Accepted",
      "type": "accepted",
      "createdAt": FieldValue.serverTimestamp(),
      "isRead": false,
    });

    await FirebaseFirestore.instance.collection("expert_notifications").add({
      "expertId": user!.uid,
      "title": "Request Accepted 🎉",
      "requestTitle": requestTitle,
      "requestId": requestId,
      "userId": userId,
      "userName": userName,
      "problem": problem,
      "skill": skill,
      "message":
          "You accepted '$requestTitle' raised by $userName. Problem: $problem",
      "type": "accepted",
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
      final userDoc =
          await FirebaseFirestore.instance.collection("users").doc(userId).get();

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
}