import 'package:flutter/material.dart';

class EventScreen extends StatelessWidget {
  const EventScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("🎉 이벤트")),
      body: const Center(
        child: Text(
          "추후 이벤트 예정입니다.",
          style: TextStyle(fontSize: 16, color: Color(0xFF6B4F1A)),
        ),
      ),
    );
  }
}