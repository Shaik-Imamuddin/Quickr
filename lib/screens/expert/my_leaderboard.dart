import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ExpertLeaderboard extends StatefulWidget {
  final String title;

  const ExpertLeaderboard({super.key, required this.title});

  @override
  State<ExpertLeaderboard> createState() => _ExpertLeaderboardState();
}

class _ExpertLeaderboardState extends State<ExpertLeaderboard> {
  final Color primaryColor = const Color(0xffF5A400);
  final user = FirebaseAuth.instance.currentUser;

  final ValueNotifier<String> selectedFilterNotifier = ValueNotifier("Day");
  final List<String> filters = ["Day", "Week", "Month", "Year"];

  @override
  void dispose() {
    selectedFilterNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        stream: FirebaseFirestore.instance.collection("experts").snapshots(),
        builder: (context, expertSnapshot) {
          if (expertSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!expertSnapshot.hasData || expertSnapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No experts found"));
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection("requests").snapshots(),
            builder: (context, requestSnapshot) {
              if (requestSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final experts = expertSnapshot.data!.docs;
              final requests = requestSnapshot.data?.docs ?? [];

              final leaderboard = _buildLeaderboard(experts, requests);

              final myCompletedRequests = requests.where((doc) {
                final data = doc.data() as Map<String, dynamic>? ?? {};
                return data["expertId"] == user?.uid &&
                    data["status"] == "Completed";
              }).toList();

              return SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Top Experts",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Ranked by rating and completed requests",
                      style: TextStyle(color: Color(0xff64748B)),
                    ),
                    const SizedBox(height: 18),

                    Column(
                      children: List.generate(
                        leaderboard.length > 10 ? 10 : leaderboard.length,
                        (index) {
                          return _leaderboardCard(
                            rank: index + 1,
                            expert: leaderboard[index],
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      "My Analytics",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),

                    _analyticsSummaryCard(
                      totalRequests: requests.length,
                      solvedRequests: myCompletedRequests.length,
                    ),

                    const SizedBox(height: 22),

                    ValueListenableBuilder<String>(
                      valueListenable: selectedFilterNotifier,
                      builder: (context, selectedFilter, _) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Requests Solved Graph",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: _filterChips(selectedFilter),
                            ),
                            const SizedBox(height: 14),
                            _solvedBarGraph(
                              completedRequests: myCompletedRequests,
                              selectedFilter: selectedFilter,
                            ),
                          ],
                        );
                      },
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

  Widget _filterChips(String selectedFilter) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: filters.map((filter) {
          final isSelected = selectedFilter == filter;

          return GestureDetector(
            onTap: () {
              selectedFilterNotifier.value = filter;
            },
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: isSelected ? primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isSelected ? primaryColor : const Color(0xffE5E7EB),
                ),
              ),
              child: Text(
                filter,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xff64748B),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _solvedBarGraph({
    required List<QueryDocumentSnapshot> completedRequests,
    required String selectedFilter,
  }) {
    final graphData = _getGraphData(completedRequests, selectedFilter);

    if (graphData.isEmpty) {
      return _emptyCard("No solved requests available");
    }

    final maxValue = graphData.values.reduce((a, b) => a > b ? a : b);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xffE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.10),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SizedBox(
        height: 285,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: graphData.entries.map((entry) {
            final barHeight =
                maxValue == 0 ? 10.0 : (entry.value / maxValue) * 170;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      height: 22,
                      child: Text(
                        "${entry.value}",
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff92400E),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Flexible(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 350),
                          height: barHeight < 10 ? 10 : barHeight,
                          width: 22,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xffFFD166),
                                Color(0xffFFB000),
                                Color(0xffFF8A00),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 38,
                      child: Text(
                        entry.key,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 9,
                          color: Color(0xff64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Map<String, int> _getGraphData(
    List<QueryDocumentSnapshot> completedRequests,
    String selectedFilter,
  ) {
    final now = DateTime.now();
    final Map<String, int> result = {};

    if (selectedFilter == "Day") {
      for (int i = 6; i >= 0; i--) {
        final day = now.subtract(Duration(days: i));
        result[_dayLabel(day)] = 0;
      }

      for (var doc in completedRequests) {
        final date = _getDate(doc);
        if (date == null) continue;

        final difference = now.difference(date).inDays;

        if (difference >= 0 && difference <= 6) {
          result[_dayLabel(date)] = (result[_dayLabel(date)] ?? 0) + 1;
        }
      }
    } else if (selectedFilter == "Week") {
      for (int i = 3; i >= 0; i--) {
        result["Week ${4 - i}"] = 0;
      }

      for (var doc in completedRequests) {
        final date = _getDate(doc);
        if (date == null) continue;

        final difference = now.difference(date).inDays;

        if (difference >= 0 && difference <= 27) {
          final weekIndex = 3 - (difference ~/ 7);
          final label = "Week ${weekIndex + 1}";
          result[label] = (result[label] ?? 0) + 1;
        }
      }
    } else if (selectedFilter == "Month") {
      for (int i = 5; i >= 0; i--) {
        final monthDate = DateTime(now.year, now.month - i, 1);
        result[_monthYearLabel(monthDate)] = 0;
      }

      for (var doc in completedRequests) {
        final date = _getDate(doc);
        if (date == null) continue;

        final label = _monthYearLabel(date);

        if (result.containsKey(label)) {
          result[label] = (result[label] ?? 0) + 1;
        }
      }
    } else {
      for (int i = 4; i >= 0; i--) {
        final year = now.year - i;
        result["$year"] = 0;
      }

      for (var doc in completedRequests) {
        final date = _getDate(doc);
        if (date == null) continue;

        final label = "${date.year}";

        if (result.containsKey(label)) {
          result[label] = (result[label] ?? 0) + 1;
        }
      }
    }

    return result;
  }

  DateTime? _getDate(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final createdAt = data["createdAt"];

    if (createdAt is Timestamp) {
      return createdAt.toDate();
    }

    return null;
  }

  String _dayLabel(DateTime date) {
    const days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    return days[date.weekday - 1];
  }

  String _monthYearLabel(DateTime date) {
    return "${_monthName(date.month)} ${date.year}";
  }

  List<Map<String, dynamic>> _buildLeaderboard(
    List<QueryDocumentSnapshot> experts,
    List<QueryDocumentSnapshot> requests,
  ) {
    final List<Map<String, dynamic>> leaderboard = [];

    for (var expertDoc in experts) {
      final expertData = expertDoc.data() as Map<String, dynamic>? ?? {};
      final expertId = expertDoc.id;

      final completedRequests = requests.where((requestDoc) {
        final requestData = requestDoc.data() as Map<String, dynamic>? ?? {};

        return requestData["expertId"] == expertId &&
            requestData["status"] == "Completed";
      }).length;

      final rating = _getDoubleValue(
        expertData["rating"] ??
            expertData["averageRating"] ??
            expertData["avgRating"] ??
            0,
      );

      leaderboard.add({
        "expertId": expertId,
        "name": expertData["name"] ??
            expertData["username"] ??
            expertData["fullName"] ??
            "Expert",
        "rating": rating,
        "completed": completedRequests,
      });
    }

    leaderboard.sort((a, b) {
      final ratingCompare =
          (b["rating"] as double).compareTo(a["rating"] as double);

      if (ratingCompare != 0) return ratingCompare;

      return (b["completed"] as int).compareTo(a["completed"] as int);
    });

    return leaderboard;
  }

  Widget _leaderboardCard({
    required int rank,
    required Map<String, dynamic> expert,
  }) {
    final bool isCurrentUser = expert["expertId"] == user?.uid;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrentUser ? const Color(0xffFFF7D6) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isCurrentUser ? primaryColor : const Color(0xffE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _rankBadge(rank),
          const SizedBox(width: 14),
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xffE0F2FE),
            child: Text(
              expert["name"].toString().isNotEmpty
                  ? expert["name"].toString()[0].toUpperCase()
                  : "E",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expert["name"],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "${expert["completed"]} requests completed",
                  style: const TextStyle(
                    color: Color(0xff64748B),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                "${expert["rating"].toStringAsFixed(1)} ⭐",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (isCurrentUser)
                const Text(
                  "You",
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rankBadge(int rank) {
    Color color = const Color(0xffE5E7EB);
    String text = "#$rank";

    if (rank == 1) {
      color = const Color(0xffFFD700);
      text = "🥇";
    } else if (rank == 2) {
      color = const Color(0xffC0C0C0);
      text = "🥈";
    } else if (rank == 3) {
      color = const Color(0xffCD7F32);
      text = "🥉";
    }

    return Container(
      height: 42,
      width: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withOpacity(0.35),
        shape: BoxShape.circle,
      ),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
    );
  }

  Widget _analyticsSummaryCard({
    required int totalRequests,
    required int solvedRequests,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xffFFF8E1),
            Color(0xffFFE8A3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xffFFD36A)),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.12),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _analyticsItem(
              icon: Icons.assignment_outlined,
              value: "$totalRequests",
              title: "Total Requests",
            ),
          ),
          Container(
            height: 58,
            width: 1,
            color: const Color(0xffD97706).withOpacity(0.35),
          ),
          Expanded(
            child: _analyticsItem(
              icon: Icons.check_circle_outline,
              value: "$solvedRequests",
              title: "Solved",
            ),
          ),
        ],
      ),
    );
  }

  Widget _analyticsItem({
    required IconData icon,
    required String value,
    required String title,
  }) {
    return Column(
      children: [
        Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: const Color(0xffD97706),
            size: 24,
          ),
        ),

        const SizedBox(height: 10),

        Text(
          value,
          style: const TextStyle(
            color: Color(0xff92400E),
            fontSize: 27,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          title,
          style: const TextStyle(
            color: Color(0xff78350F),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
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

  double _getDoubleValue(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  String _monthName(int month) {
    const months = [
      "",
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];

    return months[month];
  }
}