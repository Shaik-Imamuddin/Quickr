import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class EventsPage extends StatelessWidget {
  final Color primaryColor;

  const EventsPage({super.key, required this.primaryColor});

  User? get currentUser => FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    final user = currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("User not logged in")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Events"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("events")
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Unable to load events"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allDocs = snapshot.data?.docs ?? [];

          final docs = allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>? ?? {};
            return !_isEventCompleted(
              data["date"],
              data["endTime"],
            );
          }).toList();

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "No events available",
                style: TextStyle(color: Color(0xff64748B)),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(18),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>? ?? {};

              return _eventCard(
                context: context,
                eventId: doc.id,
                data: data,
                userId: user.uid,
              );
            },
          );
        },
      ),
    );
  }

  Widget _eventCard({
    required BuildContext context,
    required String eventId,
    required Map<String, dynamic> data,
    required String userId,
  }) {
    final title = data["title"]?.toString() ?? "Expert Event";
    final description =
        data["description"]?.toString() ?? "Event details will be updated soon.";
    final eventType = data["eventType"]?.toString() ?? "Event";
    final expertId = data["expertId"]?.toString() ?? "";
    final date = _formatDate(data["date"]);
    final time = data["time"]?.toString() ?? "";
    final endTime = data["endTime"]?.toString() ?? "";
    final prize = data["prize"]?.toString().trim() ?? "";
    final joiningLink = data["joiningLink"]?.toString().trim() ?? "";

    final bool canJoin = _canJoinEvent(data["date"], time);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xffB347FF), Color(0xff9700FF)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                      eventType,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            description,
            style: const TextStyle(color: Colors.white, height: 1.4),
          ),

          const SizedBox(height: 10),

          Text(
            endTime.isEmpty
                ? (time.isEmpty ? date : "$date • $time")
                : "$date • $time - $endTime",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),

          if (prize.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.emoji_events_outlined,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "Prize: $prize",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 8),

          if (expertId.isNotEmpty)
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection("experts")
                  .doc(expertId)
                  .get(),
              builder: (context, snapshot) {
                String expertName = "Expert";

                if (snapshot.hasData && snapshot.data!.exists) {
                  final expertData =
                      snapshot.data!.data() as Map<String, dynamic>? ?? {};
                  expertName = expertData["name"]?.toString() ?? "Expert";
                }

                return Text(
                  "Created by: $expertName",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            )
          else
            const Text(
              "Created by: Expert",
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),

          const SizedBox(height: 16),

          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection("events")
                .doc(eventId)
                .collection("registrations")
                .doc(userId)
                .snapshots(),
            builder: (context, regSnapshot) {
              final registered = regSnapshot.data?.exists ?? false;

              if (!registered) {
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.all(15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _registerEvent(context, eventId),
                    child: const Text(
                      "Register",
                      style: TextStyle(
                        color: Color(0xff9700FF),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.all(15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        if (canJoin) {
                          _joinEvent(context, joiningLink);
                        } else {
                          _showEventStartingMessage(
                            context,
                            data["date"],
                            time,
                          );
                        }
                      },
                      child: const Text(
                        "Join",
                        style: TextStyle(
                          color: Color(0xff9700FF),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white),
                        padding: const EdgeInsets.all(15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        _showCancelConfirmation(context, eventId);
                      },
                      child: const Text(
                        "Cancel",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _registerEvent(BuildContext context, String eventId) async {
    final user = currentUser;
    if (user == null) return;

    final userDoc =
        await FirebaseFirestore.instance.collection("users").doc(user.uid).get();

    final userData = userDoc.data() ?? {};

    await FirebaseFirestore.instance
        .collection("events")
        .doc(eventId)
        .collection("registrations")
        .doc(user.uid)
        .set({
      "userId": user.uid,
      "name": userData["name"] ?? "User",
      "email": user.email ?? userData["email"] ?? "",
      "phone": userData["phone"] ?? "",
      "registeredAt": FieldValue.serverTimestamp(),
      "status": "registered",
    });

    await FirebaseFirestore.instance.collection("events").doc(eventId).set({
      "registrationCount": FieldValue.increment(1),
    }, SetOptions(merge: true));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Registered successfully")),
    );
  }

  void _showCancelConfirmation(BuildContext context, String eventId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 74,
                  width: 74,
                  decoration: const BoxDecoration(
                    color: Color(0xffFEF2F2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xffEF4444),
                    size: 42,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Cancel Registration?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff111827),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Are you sure you want to cancel your event registration?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xff6B7280),
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Color(0xffE5E7EB),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          "No",
                          style: TextStyle(
                            color: Color(0xff374151),
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xffEF4444),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () async {
                          Navigator.pop(context);
                          await _cancelRegistration(context, eventId);
                        },
                        child: const Text(
                          "Yes",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _cancelRegistration(
    BuildContext context,
    String eventId,
  ) async {
    final user = currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection("events")
        .doc(eventId)
        .collection("registrations")
        .doc(user.uid)
        .delete();

    await FirebaseFirestore.instance.collection("events").doc(eventId).set({
      "registrationCount": FieldValue.increment(-1),
    }, SetOptions(merge: true));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Registration cancelled")),
    );
  }

  Future<void> _joinEvent(BuildContext context, String joiningLink) async {
    if (joiningLink.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Joining link not available")),
      );
      return;
    }

    final uri = Uri.tryParse(joiningLink);

    if (uri == null || !uri.hasScheme) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid joining link")),
      );
      return;
    }

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _showEventStartingMessage(
    BuildContext context,
    dynamic dateValue,
    String timeText,
  ) {
    final eventDateTime = _getEventDateTime(dateValue, timeText);

    if (eventDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Event start time not available"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xff111827),
        ),
      );
      return;
    }

    final now = DateTime.now();
    final difference = eventDateTime.difference(now);

    String message;

    if (difference.inDays > 0) {
      message =
          "Event starts after ${difference.inDays} day${difference.inDays > 1 ? 's' : ''}";
    } else if (difference.inHours > 0) {
      message =
          "${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} left to join";
    } else if (difference.inMinutes > 0) {
      message = "${difference.inMinutes} mins left to join";
    } else {
      message = "Event will start soon";
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xff111827),
      ),
    );
  }

  bool _canJoinEvent(dynamic dateValue, String timeText) {
    final eventDateTime = _getEventDateTime(dateValue, timeText);
    if (eventDateTime == null) return false;

    final now = DateTime.now();
    return now.isAfter(eventDateTime) || now.isAtSameMomentAs(eventDateTime);
  }

  bool _isEventCompleted(dynamic dateValue, dynamic endTimeValue) {
    final endTimeText = endTimeValue?.toString().trim() ?? "";

    if (dateValue == null || endTimeText.isEmpty) {
      return false;
    }

    final eventEndDateTime = _getEventDateTime(dateValue, endTimeText);
    if (eventEndDateTime == null) return false;

    final now = DateTime.now();
    return now.isAfter(eventEndDateTime);
  }

  DateTime? _getEventDateTime(dynamic dateValue, String timeText) {
    try {
      DateTime date;

      if (dateValue is Timestamp) {
        date = dateValue.toDate();
      } else if (dateValue is DateTime) {
        date = dateValue;
      } else {
        return null;
      }

      final parsedTime = _parseTimeOfDay(timeText);
      if (parsedTime == null) return null;

      return DateTime(
        date.year,
        date.month,
        date.day,
        parsedTime.hour,
        parsedTime.minute,
      );
    } catch (_) {
      return null;
    }
  }

  TimeOfDay? _parseTimeOfDay(String timeText) {
    try {
      final cleaned = timeText.trim().toUpperCase();

      if (cleaned.isEmpty) return null;

      final regex = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)?$');
      final match = regex.firstMatch(cleaned);

      if (match == null) return null;

      int hour = int.parse(match.group(1)!);
      final minute = int.parse(match.group(2)!);
      final period = match.group(3);

      if (minute < 0 || minute > 59) return null;

      if (period == "PM" && hour != 12) {
        hour += 12;
      }

      if (period == "AM" && hour == 12) {
        hour = 0;
      }

      if (hour < 0 || hour > 23) return null;

      return TimeOfDay(hour: hour, minute: minute);
    } catch (_) {
      return null;
    }
  }

  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return "Coming soon";

    try {
      DateTime date;

      if (dateValue is Timestamp) {
        date = dateValue.toDate();
      } else if (dateValue is DateTime) {
        date = dateValue;
      } else {
        return dateValue.toString();
      }

      return "${date.day}/${date.month}/${date.year}";
    } catch (_) {
      return "Coming soon";
    }
  }
}