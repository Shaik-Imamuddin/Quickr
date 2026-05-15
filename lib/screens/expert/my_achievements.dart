import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ExpertAchievementsPage extends StatefulWidget {
  final String title;

  const ExpertAchievementsPage({super.key, required this.title});

  @override
  State<ExpertAchievementsPage> createState() => _ExpertAchievementsPageState();
}

class _ExpertAchievementsPageState extends State<ExpertAchievementsPage> {
  final Color primaryColor = const Color(0xffF5A400);
  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
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
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("requests")
            .where("expertId", isEqualTo: user!.uid)
            .snapshots(),
        builder: (context, requestSnapshot) {
          final requests = requestSnapshot.data?.docs ?? [];

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection("expert_reviews").snapshots(),
            builder: (context, reviewSnapshot) {
              final allReviews = reviewSnapshot.data?.docs ?? [];

              final reviews = allReviews.where((doc) {
                final data = doc.data() as Map<String, dynamic>? ?? {};

                final expertFields = [
                  data["expertId"],
                  data["expertUid"],
                  data["toExpertId"],
                  data["reviewTo"],
                  data["reviewedExpertId"],
                  data["receiverId"],
                  data["expertUserId"],
                ];

                return expertFields.any((id) => id?.toString() == user!.uid);
              }).toList();

              final totalReviews = reviews.length;

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("events")
                    .where("expertId", isEqualTo: user!.uid)
                    .snapshots(),
                builder: (context, eventSnapshot) {
                  final events = eventSnapshot.data?.docs ?? [];

                  final completedRequests = requests.where((doc) {
                    final data = doc.data() as Map<String, dynamic>? ?? {};
                    return data["status"] == "Completed";
                  }).length;

                  final totalRequests = requests.length;
                  final totalReviews = reviews.length;
                  final totalEvents = events.length;
                  final coinsEarned = completedRequests * 100;

                  double averageRating = 0;

                  if (reviews.isNotEmpty) {
                    double totalRating = 0;

                    for (var doc in reviews) {
                      final data = doc.data() as Map<String, dynamic>? ?? {};
                      totalRating += _getDoubleValue(
                        data["rating"] ??
                            data["stars"] ??
                            data["starRating"] ??
                            data["reviewRating"],
                      );
                    }

                    averageRating = totalRating / reviews.length;
                  }

                  final achievements = _getAchievements(
                    completedRequests: completedRequests,
                    totalRequests: totalRequests,
                    totalReviews: totalReviews,
                    totalEvents: totalEvents,
                    averageRating: averageRating,
                    coinsEarned: coinsEarned,
                  );

                  final earned = achievements
                      .where((item) => item["unlocked"] == true)
                      .toList();

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Achievements Earned",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),

                        if (earned.isEmpty)
                          _emptyCard("No achievements earned yet")
                        else
                          _earnedIconsGrid(earned),

                        const SizedBox(height: 26),

                        const Text(
                          "All Achievements",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Complete goals to unlock more expert badges",
                          style: TextStyle(color: Color(0xff64748B)),
                        ),
                        const SizedBox(height: 14),

                        Column(
                          children: achievements.map((achievement) {
                            return _achievementCard(
                              achievement: achievement,
                              unlocked: achievement["unlocked"] == true,
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _earnedIconsGrid(List<Map<String, dynamic>> earned) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffE5E7EB)),
      ),
      child: Wrap(
        spacing: 14,
        runSpacing: 14,
        children: earned.map((achievement) {
          return Tooltip(
            message: achievement["title"],
            child: Container(
              height: 58,
              width: 58,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xffFFF4CC),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: primaryColor),
              ),
              child: Text(
                achievement["icon"],
                style: const TextStyle(fontSize: 27),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _achievementCard({
    required Map<String, dynamic> achievement,
    required bool unlocked,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: unlocked ? Colors.white : const Color(0xffF1F5F9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: unlocked ? primaryColor : const Color(0xffE5E7EB),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor:
                unlocked ? const Color(0xffFFF4CC) : Colors.grey.shade300,
            child: Text(
              achievement["icon"],
              style: const TextStyle(fontSize: 25),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement["title"],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: unlocked ? Colors.black : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  achievement["description"],
                  style: const TextStyle(
                    color: Color(0xff64748B),
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "How to earn: ${achievement["condition"]}",
                  style: TextStyle(
                    color: unlocked ? primaryColor : Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            unlocked ? Icons.verified_rounded : Icons.lock_outline,
            color: unlocked ? Colors.green : Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _emptyCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xffE5E7EB)),
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: Color(0xff64748B)),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getAchievements({
    required int completedRequests,
    required int totalRequests,
    required int totalReviews,
    required int totalEvents,
    required double averageRating,
    required int coinsEarned,
  }) {
    return [
      {
        "icon": "🎯",
        "title": "First Help",
        "description": "You completed your first expert request.",
        "condition": "Complete 1 request",
        "unlocked": completedRequests >= 1,
      },
      {
        "icon": "🔥",
        "title": "Fast Starter",
        "description": "You started actively helping users on Quickr.",
        "condition": "Receive 5 total requests",
        "unlocked": totalRequests >= 5,
      },
      {
        "icon": "✅",
        "title": "Problem Solver",
        "description": "You solved multiple user problems successfully.",
        "condition": "Complete 10 requests",
        "unlocked": completedRequests >= 10,
      },
      {
        "icon": "🚀",
        "title": "Rising Expert",
        "description": "You are becoming a trusted expert on the platform.",
        "condition": "Complete 25 requests",
        "unlocked": completedRequests >= 25,
      },
      {
        "icon": "💎",
        "title": "Elite Expert",
        "description": "You reached a high level of expert contribution.",
        "condition": "Complete 50 requests",
        "unlocked": completedRequests >= 50,
      },
      {
        "icon": "⭐",
        "title": "First Review",
        "description": "You received your first review from a user.",
        "condition": "Receive 1 review",
        "unlocked": totalReviews > 0,
      },
      {
        "icon": "🌟",
        "title": "Highly Rated",
        "description": "Users are giving strong ratings for your help.",
        "condition": "Maintain 4.5+ average rating with 3 reviews",
        "unlocked": averageRating >= 4.5 && totalReviews >= 3,
      },
      {
        "icon": "👑",
        "title": "Top Rated Mentor",
        "description": "You earned excellent ratings from multiple users.",
        "condition": "Maintain 4.8+ rating with 10 reviews",
        "unlocked": averageRating >= 4.8 && totalReviews >= 10,
      },
      {
        "icon": "📅",
        "title": "Event Creator",
        "description": "You created your first learning event.",
        "condition": "Create 1 event",
        "unlocked": totalEvents >= 1,
      },
      {
        "icon": "🏆",
        "title": "Community Builder",
        "description": "You are actively creating events for learners.",
        "condition": "Create 5 events",
        "unlocked": totalEvents >= 5,
      },
      {
        "icon": "🪙",
        "title": "First Coins",
        "description": "You earned your first coins on Quickr.",
        "condition": "Earn 100 coins",
        "unlocked": coinsEarned >= 100,
      },
      {
        "icon": "💰",
        "title": "Coin Collector",
        "description": "You are consistently earning from solved requests.",
        "condition": "Earn 1,000 coins",
        "unlocked": coinsEarned >= 1000,
      },
      {
        "icon": "💵",
        "title": "High Earner",
        "description": "You reached a strong earning milestone.",
        "condition": "Earn 5,000 coins",
        "unlocked": coinsEarned >= 5000,
      },
      {
        "icon": "💸",
        "title": "Money Maker",
        "description": "You became one of the high-value experts.",
        "condition": "Earn 10,000 coins",
        "unlocked": coinsEarned >= 10000,
      },
      {
        "icon": "👑",
        "title": "Quickr Royal Expert",
        "description": "You unlocked the premium expert earning milestone.",
        "condition": "Earn 25,000 coins",
        "unlocked": coinsEarned >= 25000,
      },
    ];
  }

  double _getDoubleValue(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}