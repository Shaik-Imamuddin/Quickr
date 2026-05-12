import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EventsPage extends StatelessWidget {
  final Color primaryColor;

  const EventsPage({super.key, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Events"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection("events").snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _dummyEvents();
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return _dummyEvents();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(18),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>? ?? {};

              final title = data["title"]?.toString() ?? "Expert Event";
              final description = data["description"]?.toString() ??
                  "Event details will be updated soon.";
              final date = data["date"]?.toString() ?? "Coming soon";

              return _eventCard(title, description, date);
            },
          );
        },
      ),
    );
  }

  Widget _dummyEvents() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        _eventCard(
          "Live Coding Session",
          "Experts can add live coding events from their panel later.",
          "Coming soon",
        ),
        _eventCard(
          "Project Support Workshop",
          "A practical event for students building real-world projects.",
          "Coming soon",
        ),
        _eventCard(
          "Mentoring Meetup",
          "Connect with experts for career and interview guidance.",
          "Coming soon",
        ),
      ],
    );
  }

  Widget _eventCard(String title, String description, String date) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xffB347FF), Color(0xff9700FF)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white,
            child: Icon(Icons.event, color: Color(0xffA020F0), size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: const TextStyle(color: Colors.white, height: 1.3),
                ),
                const SizedBox(height: 8),
                Text(
                  date,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}