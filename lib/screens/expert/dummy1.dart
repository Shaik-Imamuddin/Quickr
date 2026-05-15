import 'package:flutter/material.dart';

class ExpertDummyPageOne extends StatelessWidget {
  final String title;

  const ExpertDummyPageOne({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text("$title page coming soon")),
    );
  }
}