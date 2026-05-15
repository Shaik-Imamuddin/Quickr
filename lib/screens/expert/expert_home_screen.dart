import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import './my_review_page.dart';
import './my_events_page.dart';
import 'my_leaderboard.dart';
import 'my_achievements.dart';

class ExpertHomeScreen extends StatefulWidget {
  const ExpertHomeScreen({super.key});

  @override
  State<ExpertHomeScreen> createState() => _ExpertHomeScreenState();
}

class _ExpertHomeScreenState extends State<ExpertHomeScreen> {
  final Color primaryColor = const Color(0xffF5A400);
  final user = FirebaseAuth.instance.currentUser;

  Future<void> updateAvailability(bool value) async {
    await FirebaseFirestore.instance.collection("experts").doc(user!.uid).set({
      "available": value,
      "isOnline": value,
      "status": value ? "Online" : "Offline",
      "updatedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  double _getDoubleValue(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
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
              const SizedBox(height: 26),
              _availabilityCard(),
              const SizedBox(height: 26),
              _overviewHeader(),
              const SizedBox(height: 14),
              _overviewStats(),
              const SizedBox(height: 24),
              const Text(
                "What would you like to do?",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 18),
              _actions(),
              const SizedBox(height: 28),
              _hackathonCard(),
              const SizedBox(height: 24),
              _recentHeader(),
              const SizedBox(height: 12),
              _recentRequests(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection("experts")
          .doc(user!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final name = data["name"] ?? "Expert";

        return Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: primaryColor,
              child: const Text("👨‍💻", style: TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Hello, $name! 👋",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Ready to help and earn some coins!",
                    style: TextStyle(color: Color(0xff64748B)),
                  ),
                ],
              ),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("expert_notifications")
                  .where("expertId", isEqualTo: user!.uid)
                  .where("isRead", isEqualTo: false)
                  .snapshots(),
              builder: (context, snapshot) {
                final hasUnread =
                    snapshot.hasData && snapshot.data!.docs.isNotEmpty;

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final unreadDocs = snapshot.data?.docs ?? [];

                        for (var doc in unreadDocs) {
                          await FirebaseFirestore.instance
                              .collection("expert_notifications")
                              .doc(doc.id)
                              .update({
                            "isRead": true,
                          });
                        }

                        if (!context.mounted) return;

                        Navigator.pushNamed(context, "/expertNotifications");
                      },
                      child: const Icon(
                        Icons.notifications_none,
                        size: 27,
                      ),
                    ),

                    if (hasUnread)
                      Positioned(
                        right: -1,
                        top: -1,
                        child: Container(
                          height: 10,
                          width: 10,
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _availabilityCard() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection("experts")
          .doc(user!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final available = data["available"] ?? data["isOnline"] ?? true;

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xffFFF7C2), Color(0xffFFE7C2)],
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.circle,
                  color: available ? Colors.green : Colors.grey,
                  size: 15,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      available ? "You're Available" : "You're Offline",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      available
                          ? "You can receive and view requests"
                          : "You won't receive new requests",
                      style: const TextStyle(color: Color(0xff64748B)),
                    ),
                  ],
                ),
              ),
              Switch(
                value: available,
                activeColor: Colors.green,
                onChanged: (value) async {
                  await updateAvailability(value);
                },
              )
            ],
          ),
        );
      },
    );
  }

  Widget _overviewHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            "Overview",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, "/expertCoins");
          },
          child: Text(
            "View All",
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _overviewStats() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("requests")
          .where("expertId", isEqualTo: user!.uid)
          .snapshots(),
      builder: (context, requestSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("expert_reviews")
              .snapshots(),
          builder: (context, reviewSnapshot) {
            int today = 0;
            int completed = 0;
            double rating = 0.0;

            if (requestSnapshot.hasData) {
              final docs = requestSnapshot.data!.docs;
              today = docs.length;

              for (var doc in docs) {
                final data = doc.data() as Map<String, dynamic>? ?? {};

                if (data["status"] == "Completed") {
                  completed++;
                }
              }
            }

            if (reviewSnapshot.hasData) {
              final myReviews = reviewSnapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>? ?? {};

                final reviewExpertId = data["expertId"] ??
                    data["expertUid"] ??
                    data["toExpertId"] ??
                    data["reviewTo"] ??
                    data["reviewedExpertId"] ??
                    data["receiverId"];

                return reviewExpertId?.toString() == user!.uid;
              }).toList();

              if (myReviews.isNotEmpty) {
                double totalRating = 0;

                for (var doc in myReviews) {
                  final data = doc.data() as Map<String, dynamic>? ?? {};

                  totalRating += _getDoubleValue(
                    data["overallRating"] ??
                      data["rating"] ??
                      data["stars"] ??
                      data["starRating"] ??
                      data["reviewRating"] ??
                      data["rate"] ??
                      data["ratingValue"],
                  );
                }

                rating = totalRating / myReviews.length;
              }
            }

            return Row(
              children: [
                Expanded(
                  child: _statBox(
                    "💰",
                    "\$${today * 100}+",
                    "Today",
                  ),
                ),
                const SizedBox(width: 6),

                Expanded(
                  child: _statBox(
                    "💵",
                    "\$${completed * 100}+",
                    "Week",
                  ),
                ),
                const SizedBox(width: 6),

                Expanded(
                  child: _statBox(
                    "⭐",
                    rating == 0.0 ? "0.0" : rating.toStringAsFixed(1),
                    "Rating",
                  ),
                ),
                const SizedBox(width: 6),

                Expanded(
                  child: _statBox(
                    "📊",
                    "\$${completed * 100}",
                    "Earned",
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _statBox(String emoji, String value, String title) {
    return Container(
      height: 92,
      padding: const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xffE5E7EB),
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            emoji,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xff64748B),
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _action(
          Icons.reviews_outlined,
          "My\nReviews",
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ExpertMyReviewsPage(),
              ),
            );
          },
        ),

        _action(
          Icons.event_available_outlined,
          "My\nEvents",
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ExpertMyEventsPage(),
              ),
            );
          },
        ),

        _action(
          Icons.leaderboard_outlined,
          "My\nLeaderboard",
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ExpertLeaderboard(
                  title: "My Leaderboard",
                ),
              ),
            );
          },
        ),

        _action(
          Icons.emoji_events_outlined,
          "My\nAchievements",
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ExpertAchievementsPage(
                  title: "Achievements",
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _action(IconData icon, String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              color: const Color(0xffFFF4CC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: primaryColor),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _hackathonCard() {
    return Container(
      height: 180,
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xffFFB800), Color(0xffFF5A00)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 35,
            backgroundColor: Color(0xffffd46b),
            child: Text("🏆", style: TextStyle(fontSize: 34)),
          ),
          const SizedBox(width: 18),
          const Expanded(
            child: Text(
              "Quantum/Algo\nHackathon\n2025\nBe a part of something big.",
              style: TextStyle(
                color: Colors.white,
                height: 1.4,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, "/createEvent");
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Text(
                "Create",
                style: TextStyle(
                  color: Color(0xffFF5A00),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
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
        GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, "/expertRequests");
          },
          child: Text(
            "View All",
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
          ),
        )
      ],
    );
  }

  Widget _recentRequests() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("requests").snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();

        List<QueryDocumentSnapshot> docs = snapshot.data!.docs;

        docs = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          final expertId = data["expertId"]?.toString() ?? "";
          final status = data["status"]?.toString() ?? "";
          return expertId.isEmpty && status == "In Progress";
        }).toList();

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
          return const Text("No recent requests available");
        }

        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>? ?? {};

            return GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, "/expertRequests");
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xffE5E7EB)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xffE0F2FE),
                      child: Text((data["skill"] ?? "Q")[0]),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        data["title"] ?? "Untitled Request",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}