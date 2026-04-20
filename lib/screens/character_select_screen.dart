import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:ui' as ui;
import '../widgets/sprite_painter.dart';
import 'main_screen.dart';

class CharacterSelectScreen extends StatefulWidget {
  const CharacterSelectScreen({super.key});

  @override
  State<CharacterSelectScreen> createState() => _CharacterSelectScreenState();
}

class _CharacterSelectScreenState extends State<CharacterSelectScreen> {
  ui.Image? _catImage;
  ui.Image? _dogImage;
  int _catFrame = 0;
  int _dogFrame = 0;
  Timer? _frameTimer;
  String? _selected;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    try {
      final data1 = await rootBundle.load('assets/idlecat.png');
      final codec1 = await ui.instantiateImageCodec(data1.buffer.asUint8List());
      final f1 = await codec1.getNextFrame();

      final data2 = await rootBundle.load('assets/idledog.png');
      final codec2 = await ui.instantiateImageCodec(data2.buffer.asUint8List());
      final f2 = await codec2.getNextFrame();

      setState(() {
        _catImage = f1.image;
        _dogImage = f2.image;
      });

      _frameTimer = Timer.periodic(const Duration(milliseconds: 1000), (_) {
        setState(() {
          _catFrame = (_catFrame + 1) % 2;
          _dogFrame = (_dogFrame + 1) % 2;
        });
      });
    } catch (e) {
      print("❌ 로드 실패: $e");
    }
  }

  @override
  void dispose() {
    _frameTimer?.cancel();
    super.dispose();
  }

  void _onSelect(String character) {
    setState(() => _selected = character);
  }

  void _onConfirm() {
    if (_selected == null) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("정말 선택하시겠어요?"),
        content: const Text("한 번 선택하면 바꿀 수 없어요!"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("아니요"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _frameTimer?.cancel();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => MainScreen(character: _selected!),
                ),
              );
            },
            child: const Text("예"),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(String character, ui.Image? image, int frame, String label) {
    final isSelected = _selected == character;
    return GestureDetector(
      onTap: () => _onSelect(character),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 140,
        height: 200,
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[50] : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.blue[400]! : Colors.grey[300]!,
            width: isSelected ? 3 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 90,
              height: 90,
              child: image == null
                  ? const CircularProgressIndicator()
                  : CustomPaint(
                      painter: SpritePainter(
                        image: image,
                        frame: frame,
                        totalFrames: 2,
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.blue[600] : Colors.grey[700],
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 8),
              Icon(Icons.check_circle, color: Colors.blue[400], size: 20),
            ]
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "함께할 친구를 선택하세요!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "공부할 때 옆에서 응원해줄 거예요 🐾",
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 60),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCard('cat', _catImage, _catFrame, '고양이'),
                const SizedBox(width: 24),
                _buildCard('dog', _dogImage, _dogFrame, '강아지'),
              ],
            ),
            const SizedBox(height: 60),
            ElevatedButton(
              onPressed: _selected != null ? _onConfirm : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[400],
                disabledBackgroundColor: Colors.grey[300],
                padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(35),
                ),
              ),
              child: const Text(
                "시작하기",
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}