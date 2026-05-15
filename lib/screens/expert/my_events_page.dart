import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExpertMyEventsPage extends StatelessWidget {
  const ExpertMyEventsPage({super.key});

  String _formatDate(dynamic value) {
    if (value == null) return "";

    if (value is Timestamp) {
      final date = value.toDate();
      return "${date.day}/${date.month}/${date.year}";
    }

    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final expertId = FirebaseAuth.instance.currentUser?.uid;
    final primaryColor = const Color(0xffF5A400);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("My Events"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: expertId == null
          ? const Center(child: Text("Expert not logged in"))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection("events").snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final events = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>? ?? {};

                  final eventExpertId =
                      data["expertId"]?.toString() ??
                      data["createdBy"]?.toString() ??
                      data["createdById"]?.toString() ??
                      data["expertUid"]?.toString() ??
                      data["userId"]?.toString() ??
                      "";

                  return eventExpertId == expertId;
                }).toList();

                if (events.isEmpty) {
                  return const Center(child: Text("No events created yet"));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(18),
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final doc = events[index];
                    final data = doc.data() as Map<String, dynamic>? ?? {};

                    final title =
                        data["title"]?.toString().trim().isNotEmpty == true
                            ? data["title"].toString()
                            : "Untitled Event";

                    final type =
                        data["eventType"]?.toString().trim().isNotEmpty == true
                            ? data["eventType"].toString()
                            : "Contest";

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ExpertEventDetailsPage(
                              eventId: doc.id,
                              eventData: data,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xffE5E7EB)),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: const Color(0xffFFF4CC),
                              child: Icon(Icons.event, color: primaryColor),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    type,
                                    style: const TextStyle(
                                      color: Color(0xff64748B),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class ExpertEventDetailsPage extends StatelessWidget {
  final String eventId;
  final Map<String, dynamic> eventData;

  const ExpertEventDetailsPage({
    super.key,
    required this.eventId,
    required this.eventData,
  });

  String _formatDate(dynamic value) {
    if (value == null) return "";

    if (value is Timestamp) {
      final date = value.toDate();
      return "${date.day}/${date.month}/${date.year}";
    }

    return value.toString();
  }

  String _safeText(dynamic value, String fallback) {
    final text = value?.toString().trim() ?? "";
    return text.isEmpty ? fallback : text;
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: "$label: ",
              style: const TextStyle(
                color: Color(0xff111827),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                color: Color(0xff64748B),
                fontSize: 14,
                fontWeight: FontWeight.normal,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xffF5A400);

    final title = _safeText(eventData["title"], "Untitled Event");
    final description = _safeText(eventData["description"], "No description");
    final type = _safeText(eventData["eventType"], "Contest");
    final prize = _safeText(eventData["prize"], "Not mentioned");
    final joiningLink = _safeText(eventData["joiningLink"], "Not added");
    final date = _formatDate(eventData["date"]);
    final startTime = _safeText(eventData["time"], "");
    final endTime = _safeText(eventData["endTime"], "");

    final now = DateTime.now();

    bool isCompleted = false;

    final eventDateValue = eventData["date"];

    if (eventDateValue is Timestamp && endTime.isNotEmpty) {
      final eventDate = eventDateValue.toDate();

      final timeParts = endTime.split(" ");
      final hm = timeParts[0].split(":");

      int hour = int.parse(hm[0]);
      int minute = int.parse(hm[1]);

      if (timeParts.length > 1) {
        final period = timeParts[1].toUpperCase();

        if (period == "PM" && hour != 12) {
          hour += 12;
        }

        if (period == "AM" && hour == 12) {
          hour = 0;
        }
      }

      final eventEndDateTime = DateTime(
        eventDate.year,
        eventDate.month,
        eventDate.day,
        hour,
        minute,
      );

      isCompleted = now.isAfter(eventEndDateTime);
    }

    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        title: const Text("Event Details"),
        backgroundColor: const Color(0xffF8FAFC),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(18, 12, 18, 18),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xffE5E7EB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xffFFF4CC),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.event,
                        color: primaryColor,
                        size: 26,
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff111827),
                        ),
                      ),
                    ),

                    if (isCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xffDCFCE7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          "Completed",
                          style: TextStyle(
                            color: Color(0xff16A34A),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            "/createEvent",
                            arguments: {
                              "eventId": eventId,
                              "eventData": eventData,
                              "isEdit": true,
                            },
                          );
                        },
                        child: Container(
                          height: 42,
                          width: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xffFFF4CC),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.edit,
                            color: primaryColor,
                            size: 20,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 22),

                _detailRow("Title", title),
                _detailRow("Description", description),
                _detailRow("Type", type),
                _detailRow("Date", date),
                _detailRow("Time", "$startTime - $endTime"),
                _detailRow("Prize", prize),
                _detailRow("Joining Link", joiningLink),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Registered Users",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff111827),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("events")
                  .doc(eventId)
                  .collection("registrations")
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text("Error: ${snapshot.error}"),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final users = snapshot.data!.docs;

                if (users.isEmpty) {
                  return const Center(
                    child: Text("No users registered yet"),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final data =
                        users[index].data() as Map<String, dynamic>? ?? {};

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: const Color(0xffE5E7EB),
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 22,
                            backgroundColor: Color(0xffF1F5F9),
                            child: Icon(
                              Icons.person,
                              color: Color(0xff64748B),
                            ),
                          ),

                          const SizedBox(width: 14),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data["userName"]?.toString() ??
                                      data["name"]?.toString() ??
                                      "User",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Color(0xff111827),
                                  ),
                                ),

                                const SizedBox(height: 4),

                                Text(
                                  data["email"]?.toString() ?? "",
                                  style: const TextStyle(
                                    color: Color(0xff64748B),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}