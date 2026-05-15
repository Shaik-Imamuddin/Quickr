import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReviewPage extends StatefulWidget {
  final String requestId;

  const ReviewPage({
    super.key,
    required this.requestId,
  });

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  final Color primaryColor = const Color(0xffA020F0);

  int overallRating = 5;
  int qualityRating = 4;
  int communicationRating = 3;
  int timelinessRating = 5;

  bool isConfirmed = true;
  bool isLoading = true;
  bool isSubmitting = false;

  String expertId = "";
  String expertName = "Expert";
  String expertSkill = "Expert";
  String requestTitle = "";

  final TextEditingController titleController = TextEditingController();
  final TextEditingController reviewController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRequestData();
  }

  Future<void> _loadRequestData() async {
    try {
      final requestDoc = await FirebaseFirestore.instance
          .collection("requests")
          .doc(widget.requestId)
          .get();

      final data = requestDoc.data() ?? {};

      expertId = data["expertId"]?.toString() ?? "";
      expertName = data["expertName"]?.toString() ?? "Expert";
      requestTitle = data["title"]?.toString() ?? "";

      if (expertId.isNotEmpty) {
        final expertDoc = await FirebaseFirestore.instance
            .collection("experts")
            .doc(expertId)
            .get();

        final expertData = expertDoc.data() ?? {};
        expertName = expertData["name"]?.toString() ?? expertName;
        expertSkill =
            expertData["skill"]?.toString() ??
            expertData["profession"]?.toString() ??
            "Expert";
      }
    } catch (e) {
      debugPrint(e.toString());
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _submitReview() async {
    if (!isConfirmed) {
      _showMessage("Please confirm your review");
      return;
    }

    if (expertId.isEmpty) {
      _showMessage("Expert not found");
      return;
    }

    try {
      setState(() => isSubmitting = true);

      final user = FirebaseAuth.instance.currentUser;

      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user!.uid)
          .get();

      final userData = userDoc.data() ?? {};

      final userName = userData["name"]?.toString().trim().isNotEmpty == true
          ? userData["name"].toString().trim()
          : "User";

      final reviewText = reviewController.text.trim();
      final reviewTitle = titleController.text.trim();

      final reviewRef =
          FirebaseFirestore.instance.collection("expert_reviews").doc();

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final expertRef =
            FirebaseFirestore.instance.collection("experts").doc(expertId);

        final requestRef =
            FirebaseFirestore.instance.collection("requests").doc(widget.requestId);

        final expertSnap = await transaction.get(expertRef);
        final expertData = expertSnap.data() ?? {};

        final currentRating =
            double.tryParse(expertData["rating"]?.toString() ?? "0") ?? 0.0;

        final currentReviewCount =
            int.tryParse(expertData["reviewCount"]?.toString() ?? "0") ?? 0;

        final newReviewCount = currentReviewCount + 1;

        final newRating =
            ((currentRating * currentReviewCount) + overallRating) /
                newReviewCount;

        transaction.set(reviewRef, {
          "reviewId": reviewRef.id,
          "requestId": widget.requestId,
          "requestTitle": requestTitle,
          "expertId": expertId,
          "expertName": expertName,
          "userId": user?.uid ?? "",
          "userName": userName,
          "overallRating": overallRating,
          "qualityRating": qualityRating,
          "communicationRating": communicationRating,
          "timelinessRating": timelinessRating,
          "reviewTitle": reviewTitle,
          "review": reviewText,
          "createdAt": FieldValue.serverTimestamp(),
        });

        transaction.set(expertRef, {
          "rating": double.parse(newRating.toStringAsFixed(1)),
          "reviewCount": newReviewCount,
        }, SetOptions(merge: true));

        transaction.set(requestRef, {
          "reviewSubmitted": true,
          "reviewId": reviewRef.id,
          "reviewRating": overallRating,
          "reviewedAt": FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });

      if (!mounted) return;

      _showMessage("Review submitted successfully");
      Navigator.pop(context);
    } catch (e) {
      _showMessage(e.toString());
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _ratingText(int rating) {
    if (rating == 5) return "Excellent";
    if (rating == 4) return "Very Good";
    if (rating == 3) return "Good";
    if (rating == 2) return "Average";
    return "Poor";
  }

  Widget _ratingSection({
    required String title,
    required String subtitle,
    required int rating,
    required Function(int) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff111827),
                ),
              ),
            ),
            Text(
              _ratingText(rating),
              style: TextStyle(
                color: primaryColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xff64748B),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(5, (index) {
            final starValue = index + 1;
            return GestureDetector(
              onTap: () => onChanged(starValue),
              child: Icon(
                Icons.star_rounded,
                size: 40,
                color: starValue <= rating
                    ? primaryColor
                    : const Color(0xffE9D5FF),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _expertCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xffFAF5FF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xffE9D5FF)),
      ),
      child: Row(
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    text: "Reviewing ",
                    style: const TextStyle(
                      color: Color(0xff111827),
                      fontWeight: FontWeight.bold,
                    ),
                    children: [
                      TextSpan(
                        text: expertName,
                        style: TextStyle(color: primaryColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  expertSkill,
                  style: const TextStyle(
                    color: Color(0xff64748B),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _inputField({
    required String label,
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xff111827),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xff94A3B8)),
            filled: true,
            fillColor: Colors.white,
            counterText: maxLength == null ? null : "",
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xffE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xffE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: primaryColor),
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xffF7F4FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

                const SizedBox(height: 18),

                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Submit a Review",
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff111827),
                            ),
                          ),
                          SizedBox(height: 7),
                          Text(
                            "Share your experience and help others",
                            style: TextStyle(
                              color: Color(0xff64748B),
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Image.asset(
                      "assets/images/export.png",
                      height: 120,
                      errorBuilder: (_, __, ___) {
                        return Icon(
                          Icons.reviews_rounded,
                          size: 90,
                          color: primaryColor,
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                _expertCard(),

                _ratingSection(
                  title: "Overall Rating",
                  subtitle: "How would you rate your overall experience?",
                  rating: overallRating,
                  onChanged: (value) {
                    setState(() => overallRating = value);
                  },
                ),

                _ratingSection(
                  title: "Quality of Work",
                  subtitle: "How would you rate the quality of work delivered?",
                  rating: qualityRating,
                  onChanged: (value) {
                    setState(() => qualityRating = value);
                  },
                ),

                _ratingSection(
                  title: "Communication",
                  subtitle: "How was the communication with the expert?",
                  rating: communicationRating,
                  onChanged: (value) {
                    setState(() => communicationRating = value);
                  },
                ),

                _ratingSection(
                  title: "Timeliness",
                  subtitle: "Was the work delivered on time?",
                  rating: timelinessRating,
                  onChanged: (value) {
                    setState(() => timelinessRating = value);
                  },
                ),

                const SizedBox(height: 28),

                _inputField(
                  label: "Review Title (Optional)",
                  controller: titleController,
                  hint: "E.g., Great experience working with $expertName!",
                ),

                const SizedBox(height: 22),

                _inputField(
                  label: "Your Review",
                  controller: reviewController,
                  hint: "Write your review here...",
                  maxLines: 5,
                  maxLength: 500,
                ),

                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "${reviewController.text.length}/500",
                    style: const TextStyle(
                      color: Color(0xff64748B),
                      fontSize: 13,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: isConfirmed,
                      activeColor: primaryColor,
                      onChanged: (value) {
                        setState(() => isConfirmed = value ?? false);
                      },
                    ),
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Text(
                          "I confirm that this review is based on my real experience and is genuine.",
                          style: TextStyle(
                            color: Color(0xff64748B),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: isSubmitting ? null : _submitReview,
                    icon: isSubmitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.send_rounded, color: Colors.white),
                    label: Text(
                      isSubmitting ? "Submitting..." : "Submit Review",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }
}