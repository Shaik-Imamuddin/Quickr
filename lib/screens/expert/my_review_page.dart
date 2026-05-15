import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExpertMyReviewsPage extends StatelessWidget {
  const ExpertMyReviewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final expertId = FirebaseAuth.instance.currentUser?.uid;
    final primaryColor = const Color(0xffF5A400);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("My Reviews"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: expertId == null
          ? const Center(child: Text("Expert not logged in"))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("expert_reviews")
                  .where("expertId", isEqualTo: expertId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final reviews = snapshot.data!.docs;

                reviews.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>? ?? {};
                  final bData = b.data() as Map<String, dynamic>? ?? {};

                  final aTime = aData["createdAt"];
                  final bTime = bData["createdAt"];

                  if (aTime is Timestamp && bTime is Timestamp) {
                    return bTime.compareTo(aTime);
                  }

                  return 0;
                });

                if (reviews.isEmpty) {
                  return const Center(child: Text("No reviews yet"));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(18),
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    final data =
                        reviews[index].data() as Map<String, dynamic>? ?? {};

                    final requestTitle =
                        data["requestTitle"]?.toString().trim() ?? "";

                    final reviewTitle =
                        data["reviewTitle"]?.toString().trim() ?? "";

                    final userName =
                        data["userName"]?.toString().trim() ?? "";

                    final review =
                        data["review"]?.toString().trim() ?? "";

                    final rating = int.tryParse(
                          data["overallRating"]?.toString() ?? "0",
                        ) ??
                        0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xffE5E7EB)),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            requestTitle.isNotEmpty
                                ? requestTitle
                                : "Complaint",
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff111827),
                            ),
                          ),

                          const SizedBox(height: 10),

                          if (reviewTitle.isNotEmpty)
                            Text(
                              reviewTitle,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xff475569),
                              ),
                            ),

                          const SizedBox(height: 10),

                          Row(
                            children: List.generate(5, (i) {
                              return Icon(
                                Icons.star_rounded,
                                size: 22,
                                color: i < rating
                                    ? primaryColor
                                    : const Color(0xffE5E7EB),
                              );
                            }),
                          ),

                          const SizedBox(height: 12),

                          Text(
                            review.isNotEmpty ? review : "No review message",
                            style: const TextStyle(
                              color: Color(0xff64748B),
                              height: 1.5,
                              fontSize: 14,
                            ),
                          ),

                          const SizedBox(height: 14),

                          Text(
                            userName.isNotEmpty
                                ? "Reviewed by $userName"
                                : "Reviewed by User",
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xff94A3B8),
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
}