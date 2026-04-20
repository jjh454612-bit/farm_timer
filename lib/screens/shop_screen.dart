import 'package:flutter/material.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🏪 상점"),
      ),
      body: const Center(
        child: Text("아이템 준비 중..."),
      ),
    );
  }
}