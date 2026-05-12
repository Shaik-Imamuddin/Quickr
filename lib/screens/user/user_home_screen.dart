import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import './user_notification.dart';
import '../ask_question.dart';
import './available_experts_page.dart';
import './services_page.dart';
import './guides_page.dart';
import './events_page.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  final Color primaryColor = const Color(0xffA020F0);
  final TextEditingController searchController = TextEditingController();

  User? get currentUser => FirebaseAuth.instance.currentUser;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
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
            top: 18,
            bottom: 100,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(context, user.uid),
              const SizedBox(height: 20),
              _searchBar(),
              const SizedBox(height: 24),
              _helpCard(context),
              const SizedBox(height: 30),
              _categorySection(context),
              const SizedBox(height: 28),
              _dynamicStatsSection(user.uid),
              const SizedBox(height: 28),
              _recentHeader(context),
              const SizedBox(height: 14),
              _recentRequests(user.uid),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, String uid) {
    return Row(
      children: [
        Expanded(
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection("users")
                .doc(uid)
                .snapshots(),
            builder: (context, snapshot) {
              String name = "User";

              if (snapshot.hasData && snapshot.data!.exists) {
                final data =
                    snapshot.data!.data() as Map<String, dynamic>? ?? {};
                final fetchedName = data["name"]?.toString().trim() ?? "";
                name = fetchedName.isNotEmpty ? fetchedName : "User";
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Hello $name 👋",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Find expert help instantly",
                    style: TextStyle(
                      color: Color(0xff64748B),
                      fontSize: 15,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        IconButton(
          icon: const Icon(Icons.notifications_none, size: 29),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const UserNotificationsScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _searchBar() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: const Color(0xffF1F2F6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: searchController,
        decoration: const InputDecoration(
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search, color: Color(0xff94A3B8)),
          hintText: "What do you need help with?",
          hintStyle: TextStyle(color: Color(0xff94A3B8)),
        ),
      ),
    );
  }

  Widget _helpCard(BuildContext context) {
    return Container(
      height: 205,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xffB347FF), Color(0xff9700FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(25, 18, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Get help in\nunder 5 minutes",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                height: 1.25,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Connect with verified\nexperts whenever you need them",
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.35,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AskQuestionScreen(),
                  ),
                );
              },
              child: Container(
                height: 40,
                width: 156,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat_bubble_outline,
                        color: primaryColor, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      "Get help now",
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _categorySection(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _category(
          context,
          Icons.support_agent,
          "Support",
          const Color(0xffF3E8FF),
          primaryColor,
          AvailableExpertsPage(primaryColor: primaryColor),
        ),
        _category(
          context,
          Icons.grid_view_rounded,
          "Services",
          const Color(0xffE0F2FE),
          const Color(0xff2563EB),
          ServicesPage(primaryColor: primaryColor),
        ),
        _category(
          context,
          Icons.menu_book_outlined,
          "Guides",
          const Color(0xffDCFCE7),
          const Color(0xff16A34A),
          GuidesPage(primaryColor: primaryColor),
        ),
        _category(
          context,
          Icons.event_available_outlined,
          "Events",
          const Color(0xffFFE4E6),
          const Color(0xffEF4444),
          EventsPage(primaryColor: primaryColor),
        ),
      ],
    );
  }

  Widget _category(
    BuildContext context,
    IconData icon,
    String title,
    Color bg,
    Color color,
    Widget page,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));
      },
      child: Column(
        children: [
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 27),
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _dynamicStatsSection(String uid) {
    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance.collection("users").doc(uid).snapshots(),
      builder: (context, snapshot) {
        int total = 0;
        int answered = 0;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          total = _toInt(data["totalRequests"]);
          answered = _toInt(data["answeredRequests"]);
        }

        final satisfaction =
            total == 0 ? 0 : ((answered / total) * 100).round();

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _stat("$total", "Requests", primaryColor, const Color(0xffFAF5FF)),
            _stat("5m", "Avg time", const Color(0xffDB2777),
                const Color(0xffFDF2F8)),
            _stat("4.9", "Rating", const Color(0xffD97706),
                const Color(0xffFEFCE8)),
            _stat("$satisfaction%", "Satisfaction", primaryColor,
                const Color(0xffFAF5FF)),
          ],
        );
      },
    );
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  Widget _stat(String value, String title, Color color, Color bg) {
    return Container(
      height: 76,
      width: 73,
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
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: const TextStyle(color: Color(0xff64748B), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _recentHeader(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            "Recent Requests",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, "/requests");
          },
          child: Text(
            "View all",
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _recentRequests(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("requests")
          .where("userId", isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text("Error: ${snapshot.error}");
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
          return 0;
        });

        docs = docs.take(3).toList();

        if (docs.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xffE5E7EB)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                "No recent requests yet",
                style: TextStyle(color: Color(0xff64748B)),
              ),
            ),
          );
        }

        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>? ?? {};
            final title = data["title"]?.toString() ?? "Untitled";
            final skill = data["skill"]?.toString() ?? "Q";
            final expertName = data["expertName"]?.toString() ?? "";
            final status = data["status"]?.toString() ?? "In Progress";

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xffE5E7EB)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
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
                        Text(title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          expertName.isEmpty
                              ? "Waiting for expert"
                              : "by Expert $expertName",
                          style: const TextStyle(
                            color: Color(0xff64748B),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _statusChip(status),
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right, color: Color(0xff94A3B8)),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _statusChip(String status) {
    Color bg = const Color(0xffFEF3C7);
    Color color = const Color(0xffD97706);

    if (status == "Completed") {
      bg = const Color(0xffDCFCE7);
      color = const Color(0xff16A34A);
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
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}