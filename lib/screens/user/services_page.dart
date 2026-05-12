import 'package:flutter/material.dart';

class ServicesPage extends StatelessWidget {
  final Color primaryColor;

  const ServicesPage({super.key, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    final services = [
      ["Problem Solving", Icons.psychology_alt_outlined],
      ["Project Support", Icons.work_outline],
      ["Teaching", Icons.school_outlined],
      ["Mentoring", Icons.diversity_3_outlined],
      ["Debugging Help", Icons.bug_report_outlined],
      ["Resume Review", Icons.description_outlined],
      ["Interview Preparation", Icons.record_voice_over_outlined],
      ["Coding Guidance", Icons.code_outlined],
      ["UI/UX Support", Icons.design_services_outlined],
      ["Firebase Help", Icons.cloud_outlined],
      ["Backend Support", Icons.storage_outlined],
      ["Career Guidance", Icons.trending_up_outlined],
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Services"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: ListView.builder(
        padding: const EdgeInsets.all(18),
        itemCount: services.length,
        itemBuilder: (context, index) {
          final title = services[index][0] as String;
          final icon = services[index][1] as IconData;

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xffE5E7EB)),
              borderRadius: BorderRadius.circular(18),
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xffF3E8FF),
                child: Icon(icon, color: primaryColor, size: 24),
              ),
              title: Text(
                title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              subtitle: const Text(
                "Connect with experts instantly",
                style: TextStyle(color: Color(0xff64748B), fontSize: 12),
              ),
              trailing:
                  const Icon(Icons.chevron_right, color: Color(0xff94A3B8)),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("$title clicked")),
                );
              },
            ),
          );
        },
      ),
    );
  }
}