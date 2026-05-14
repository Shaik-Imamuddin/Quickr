import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewPage extends StatelessWidget {
  final String requestId;

  const ReviewPage({
    super.key,
    required this.requestId,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xffA020F0);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Review",
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            const SizedBox(height: 30),
            const Icon(
              Icons.rate_review_outlined,
              size: 90,
              color: primaryColor,
            ),
            const SizedBox(height: 25),
            const Text(
              "Review Page",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Dummy review page for now.\nLater we will implement full reviews.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xff64748B),
                height: 1.5,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection("requests")
                      .doc(requestId)
                      .update({
                    "reviewSubmitted": true,
                    "reviewedAt": FieldValue.serverTimestamp(),
                  });

                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                child: const Text(
                  "Submit Dummy Review",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}