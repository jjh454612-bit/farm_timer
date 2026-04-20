import 'package:flutter/material.dart';

class TownScreen extends StatelessWidget {
  const TownScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🏘 마을 전경"),
      ),
      body: Column(
        children: [
          // 상단 60% - 마을 배경
          Expanded(
            flex: 6,
            child: Container(
              color: Colors.lightBlue[100],
              child: const Center(
                child: Text("마을 배경"),
              ),
            ),
          ),
          // 하단 40% - 보유 아이템
          Expanded(
            flex: 4,
            child: Container(
              color: Colors.brown[100],
              child: const Center(
                child: Text("보유 아이템"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}