import 'package:flutter/material.dart';

class RankingScreen extends StatelessWidget {
  const RankingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("🏆 랭킹")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("🏆", style: TextStyle(fontSize: 64)),
              const SizedBox(height: 24),
              const Text(
                "여기에서는 다른 사람들의 공부 시간을 볼 수 있어요!\n다른 사람들은 얼마나 공부했는지 확인해봐요.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Color(0xFF3D5C28)),
              ),
              const SizedBox(height: 24),
              Text(
                "추후 업데이트 예정입니다.",
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}