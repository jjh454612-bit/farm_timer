import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/character_select_screen.dart';
import 'providers/game_provider.dart';

void main() {
  runApp(const FarmTimerApp());
}

class FarmTimerApp extends StatelessWidget {
  const FarmTimerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GameProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: '공부 농장',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF5B8A3C),
            primary: const Color(0xFF5B8A3C),
            secondary: const Color(0xFFD4A017),
            surface: const Color(0xFFF5E6C8),
          ),

          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF3D5C28),
            foregroundColor: Color(0xFFFFF0A0),
            elevation: 0,
            centerTitle: true,
            shape: Border(
              bottom: BorderSide(color: Color(0xFF2A3D1A), width: 3),
            ),
          ),

          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
                side: const BorderSide(color: Color(0xFF2A3D1A), width: 2),
              ),
              elevation: 0,
            ),
          ),

          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF3D5C28),
            ),
          ),

          cardTheme: const CardThemeData(
            color: Color(0xFFFFF0C8),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
              side: BorderSide(color: Color(0xFF8B6914), width: 2),
            ),
          ),

          scaffoldBackgroundColor: const Color(0xFFF5E6C8),

          dialogTheme: const DialogThemeData(
            backgroundColor: Color(0xFFFFF0C8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
              side: BorderSide(color: Color(0xFF8B6914), width: 2),
            ),
          ),
        ),
        home: const CharacterSelectScreen(),
      ),
    );
  }
}