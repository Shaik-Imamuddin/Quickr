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

  final List<String> eventTypes = [
    "Hackathon",
    "Contest",
    "Workshop",
    "Seminar",
    "Webinar",
    "Bootcamp",
  ];

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
      initialDate: DateTime.now(),
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
      initialTime: TimeOfDay.now(),
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
      initialTime: TimeOfDay.now(),
    );

    if (time != null) {
      setState(() {
        selectedEndTime = time;
      });
    }
  }

  Future<void> createEvent() async {
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

    await FirebaseFirestore.instance.collection("events").add({
      "expertId": user.uid,
      "title": titleController.text.trim(),
      "description": descriptionController.text.trim(),
      "eventType": selectedType,
      "date": Timestamp.fromDate(selectedDate!),
      "time": selectedTime!.format(context),
      "endTime": selectedEndTime!.format(context),
      "prize": prizeController.text.trim(),
      "joiningLink": joiningLinkController.text.trim(),
      "createdAt": FieldValue.serverTimestamp(),
      "status": "Active",
    });

    setState(() {
      isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Event created successfully")),
    );

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
              const Text(
                "Create Event",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Create hackathon, contest, workshop or seminar",
                style: TextStyle(color: Color(0xff64748B)),
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
                  onPressed: isLoading ? null : createEvent,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Create",
                          style: TextStyle(
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