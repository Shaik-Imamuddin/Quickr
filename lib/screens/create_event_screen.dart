import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final Color primaryColor = const Color(0xffF5A400);

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final prizeController = TextEditingController();
  final joiningLinkController = TextEditingController();

  String selectedType = "Hackathon";
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  TimeOfDay? selectedEndTime;

  bool isLoading = false;
  bool isEdit = false;
  bool didLoadEditData = false;

  String? editEventId;

  final List<String> eventTypes = [
    "Hackathon",
    "Contest",
    "Workshop",
    "Seminar",
    "Webinar",
    "Bootcamp",
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (didLoadEditData) return;

    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is Map<String, dynamic>) {
      isEdit = args["isEdit"] == true;
      editEventId = args["eventId"]?.toString();

      final eventData = args["eventData"] as Map<String, dynamic>? ?? {};

      titleController.text = eventData["title"]?.toString() ?? "";
      descriptionController.text = eventData["description"]?.toString() ?? "";
      prizeController.text = eventData["prize"]?.toString() ?? "";
      joiningLinkController.text = eventData["joiningLink"]?.toString() ?? "";

      selectedType = eventData["eventType"]?.toString() ?? "Hackathon";

      final dateValue = eventData["date"];
      if (dateValue is Timestamp) {
        selectedDate = dateValue.toDate();
      } else if (dateValue is DateTime) {
        selectedDate = dateValue;
      }

      selectedTime = _parseTimeOfDay(eventData["time"]?.toString());
      selectedEndTime = _parseTimeOfDay(eventData["endTime"]?.toString());
    }

    didLoadEditData = true;
  }

  TimeOfDay? _parseTimeOfDay(String? time) {
    if (time == null || time.trim().isEmpty) return null;

    try {
      final cleanTime = time.trim();
      final parts = cleanTime.split(" ");
      final hm = parts[0].split(":");

      int hour = int.parse(hm[0]);
      int minute = int.parse(hm[1]);

      if (parts.length > 1) {
        final period = parts[1].toUpperCase();

        if (period == "PM" && hour != 12) {
          hour += 12;
        }

        if (period == "AM" && hour == 12) {
          hour = 0;
        }
      }

      return TimeOfDay(hour: hour, minute: minute);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    prizeController.dispose();
    joiningLinkController.dispose();
    super.dispose();
  }

  Future<void> pickDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2035),
      initialDate: selectedDate ?? DateTime.now(),
    );

    if (date != null) {
      setState(() {
        selectedDate = date;
      });
    }
  }

  Future<void> pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );

    if (time != null) {
      setState(() {
        selectedTime = time;
      });
    }
  }

  Future<void> pickEndTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: selectedEndTime ?? TimeOfDay.now(),
    );

    if (time != null) {
      setState(() {
        selectedEndTime = time;
      });
    }
  }

  Future<void> saveEvent() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    if (titleController.text.trim().isEmpty ||
        descriptionController.text.trim().isEmpty ||
        selectedDate == null ||
        selectedTime == null ||
        selectedEndTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    final eventData = {
      "expertId": user.uid,
      "title": titleController.text.trim(),
      "description": descriptionController.text.trim(),
      "eventType": selectedType,
      "date": Timestamp.fromDate(selectedDate!),
      "time": selectedTime!.format(context),
      "endTime": selectedEndTime!.format(context),
      "prize": prizeController.text.trim(),
      "joiningLink": joiningLinkController.text.trim(),
      "status": "Active",
      "updatedAt": FieldValue.serverTimestamp(),
    };

    if (isEdit && editEventId != null) {
      await FirebaseFirestore.instance
          .collection("events")
          .doc(editEventId)
          .update(eventData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Event updated successfully")),
      );
    } else {
      await FirebaseFirestore.instance.collection("events").add({
        ...eventData,
        "createdAt": FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Event created successfully")),
      );
    }

    setState(() {
      isLoading = false;
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            width * 0.055,
            18,
            width * 0.055,
            30,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit ? "Edit Event" : "Create Event",
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isEdit
                    ? "Update your event details"
                    : "Create hackathon, contest, workshop or seminar",
                style: const TextStyle(color: Color(0xff64748B)),
              ),
              const SizedBox(height: 26),

              _label("Event Type"),
              _dropdown(),

              const SizedBox(height: 16),
              _textField(
                controller: titleController,
                label: "Event Title",
                icon: Icons.title,
              ),

              const SizedBox(height: 16),
              _textField(
                controller: descriptionController,
                label: "Description",
                icon: Icons.description_outlined,
                maxLines: 5,
              ),

              const SizedBox(height: 16),
              _dateTimeSection(),

              const SizedBox(height: 16),
              _textField(
                controller: prizeController,
                label: "Prize / Reward",
                icon: Icons.emoji_events_outlined,
              ),

              const SizedBox(height: 16),
              _textField(
                controller: joiningLinkController,
                label: "Joining Link",
                icon: Icons.link,
              ),

              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: isLoading ? null : saveEvent,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          isEdit ? "Save" : "Create",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
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

  Widget _dateTimeSection() {
    return Column(
      children: [
        GestureDetector(
          onTap: pickDate,
          child: _selectBox(
            icon: Icons.calendar_month,
            text: selectedDate == null
                ? "Select Event Date"
                : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: pickTime,
                child: _selectBox(
                  icon: Icons.access_time,
                  text: selectedTime == null
                      ? "Start Time"
                      : selectedTime!.format(context),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: pickEndTime,
                child: _selectBox(
                  icon: Icons.timer_off_outlined,
                  text: selectedEndTime == null
                      ? "End Time"
                      : selectedEndTime!.format(context),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xff1E293B),
        ),
      ),
    );
  }

  Widget _dropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xffE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedType,
          isExpanded: true,
          items: eventTypes.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(type),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedType = value!;
            });
          },
        ),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryColor),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xffE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xffE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: primaryColor, width: 1.5),
        ),
      ),
    );
  }

  Widget _selectBox({
    required IconData icon,
    required String text,
  }) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xffE5E7EB)),
      ),
      child: Row(
        children: [
          Icon(icon, color: primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xff475569)),
            ),
          ),
        ],
      ),
    );
  }
}