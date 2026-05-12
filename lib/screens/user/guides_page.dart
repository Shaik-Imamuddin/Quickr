import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class GuidesPage extends StatelessWidget {
  final Color primaryColor;

  const GuidesPage({super.key, required this.primaryColor});

  Future<void> _openLink(BuildContext context, String link) async {
    final Uri url = Uri.parse(link);

    if (!await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not open $link")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final guides = [
      [
        "LinkedIn",
        "https://www.linkedin.com/company/quantumnique-solutions-private-limited",
        Icons.business,
      ],
      [
        "Instagram",
        "https://www.instagram.com/quantumnique/",
        Icons.camera_alt,
      ],
      [
        "YouTube",
        "https://www.youtube.com/@quantumniquesolutions",
        Icons.play_circle,
      ],
      [
        "Portfolio",
        "https://www.quantumniquesolutions.com/",
        Icons.language,
      ],
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Guides"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: ListView.builder(
        padding: const EdgeInsets.all(18),
        itemCount: guides.length,
        itemBuilder: (context, index) {
          final title = guides[index][0] as String;
          final link = guides[index][1] as String;
          final icon = guides[index][2] as IconData;

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xffE5E7EB)),
              borderRadius: BorderRadius.circular(18),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xffF3E8FF),
                child: Icon(icon, color: primaryColor),
              ),
              title: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(link),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => _openLink(context, link),
            ),
          );
        },
      ),
    );
  }
}