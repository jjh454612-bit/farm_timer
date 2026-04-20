import 'package:flutter/material.dart';
import 'screens/character_select_screen.dart';

void main() {
  runApp(const FarmTimerApp());
}

class FarmTimerApp extends StatelessWidget {
  const FarmTimerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '공부 농장',
      home: const CharacterSelectScreen(),
    );
  }
}