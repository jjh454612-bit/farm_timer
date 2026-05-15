import 'package:flutter/material.dart';

class NoticeScreen extends StatelessWidget {
  const NoticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("📢 공지사항")),
      body: const Center(
        child: Text(
          "추후 업데이트 예정입니다.",
          style: TextStyle(fontSize: 16, color: Color(0xFF6B4F1A)),
        ),
      ),
    );
  }
}