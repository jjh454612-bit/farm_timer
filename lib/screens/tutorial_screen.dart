import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:ui' as ui;
import '../widgets/sprite_painter.dart';
import '../providers/game_provider.dart';
import 'main_screen.dart';

class TutorialScreen extends StatefulWidget {
  final String character;
  const TutorialScreen({super.key, required this.character});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  ui.Image? _charImage;
  ui.Image? _ttHouseImage;
  int _frame = 0;
  int _dialogIndex = 0;
  bool _showArrow = true;
  bool _showHouse = false;
  Timer? _frameTimer;
  Timer? _arrowTimer;

  static const List<String> _dialogs = [
    "어서와! 나랑 같이 공부해보자!",
    "공부할수록 마을이 점점 커져!",
    "타이머를 설정하고 집중해봐.\n끝나면 돈을 받을 수 있어!",
    "돈으로 건물을 사서\n마을을 꾸밀 수 있어!",
    "자, 시작하기 전에...\n집을 하나 줄게! 🏠",
    "마을 전경에서 집을 설치해봐!\n이제 본격적으로 시작해보자!",
  ];

  @override
  void initState() {
    super.initState();
    _loadImages();
    _startArrowBlink();
  }

  Future<void> _loadImages() async {
    try {
      final isCat = widget.character == 'cat';
      final data1 = await rootBundle.load(
          isCat ? 'assets/idlecat.png' : 'assets/idledog.png');
      final codec1 = await ui.instantiateImageCodec(data1.buffer.asUint8List());
      final f1 = await codec1.getNextFrame();

      final data2 = await rootBundle.load('assets/tthouse.png');
      final codec2 = await ui.instantiateImageCodec(data2.buffer.asUint8List());
      final f2 = await codec2.getNextFrame();

      setState(() {
        _charImage    = f1.image;
        _ttHouseImage = f2.image;
      });

      _frameTimer = Timer.periodic(const Duration(milliseconds: 1000), (_) {
        setState(() => _frame = (_frame + 1) % 2);
      });
    } catch (e) {
      debugPrint("❌ 로드 실패: $e");
    }
  }

  void _startArrowBlink() {
    _arrowTimer = Timer.periodic(const Duration(milliseconds: 600), (_) {
      if (mounted) setState(() => _showArrow = !_showArrow);
    });
  }

  @override
  void dispose() {
    _frameTimer?.cancel();
    _arrowTimer?.cancel();
    super.dispose();
  }

  void _onTap() {
    if (_dialogIndex < _dialogs.length - 1) {
      setState(() {
        _dialogIndex++;
        if (_dialogIndex == 4) _showHouse = true;
      });
    } else {
      _finish();
    }
  }

  void _finish() {
    _frameTimer?.cancel();
    _arrowTimer?.cancel();
    final provider = context.read<GameProvider>();
    provider.giveTutorialHouse();
    provider.startTutorial(); // tutorialStep = 1
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MainScreen(character: widget.character),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = context.watch<GameProvider>().themeColor;
    final isLast = _dialogIndex == _dialogs.length - 1;

    return Scaffold(
      backgroundColor: themeColor,
      body: GestureDetector(
        onTap: _onTap,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: _showHouse && _ttHouseImage != null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CustomPaint(
                              painter: _ImgPainter(image: _ttHouseImage!),
                              size: const Size(128, 128),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              "첫 번째 집 획득!",
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF3D5C28)),
                            ),
                          ],
                        )
                      : const SizedBox(),
                ),
              ),
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0C8),
                  border: Border.all(color: const Color(0xFF3D5C28), width: 3),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5E6C8),
                            border: Border.all(
                                color: const Color(0xFF3D5C28), width: 2),
                          ),
                          child: _charImage == null
                              ? const SizedBox()
                              : CustomPaint(
                                  painter: SpritePainter(
                                    image: _charImage!,
                                    frame: _frame,
                                    totalFrames: 2,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _dialogs[_dialogIndex],
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF3D5C28),
                              height: 1.6,
                              fontFamily: 'NeoDunggeunmo',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        _showArrow
                            ? (isLast ? "▼ 시작하기" : "▼")
                            : (isLast ? "   시작하기" : " "),
                        style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF3D5C28),
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImgPainter extends CustomPainter {
  final ui.Image image;
  _ImgPainter({required this.image});
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..filterQuality = FilterQuality.none,
    );
  }
  @override
  bool shouldRepaint(_ImgPainter old) => old.image != image;
}