import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:ui' as ui;

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
      home: const MainScreen(),
    );
  }
}

enum AppState { idle, running, paused, fired, firedAnimating }

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _totalSeconds = 1500;
  int _secondsRemaining = 1500;
  double _currentEarning = 0;
  double _totalMoney = 0;
  Timer? _timer;
  Timer? _frameTimer;

  AppState _appState = AppState.idle;
  int _currentFrame = 0;
  ui.Image? _spriteImage;
  ui.Image? _firedImage;
  ui.Image? _idleImage;

  String _statusMessage = "🐱 고양이도 함께 일할 준비 중...";

  @override
  void initState() {
    super.initState();
    _loadSprites();
  }

  Future<void> _loadSprites() async {
    try {
      final data1 = await rootBundle.load('assets/workcat.png');
      final codec1 = await ui.instantiateImageCodec(data1.buffer.asUint8List());
      final f1 = await codec1.getNextFrame();

      final data2 = await rootBundle.load('assets/firedcat.png');
      final codec2 = await ui.instantiateImageCodec(data2.buffer.asUint8List());
      final f2 = await codec2.getNextFrame();

      final data3 = await rootBundle.load('assets/idlecat.png');
      final codec3 = await ui.instantiateImageCodec(data3.buffer.asUint8List());
      final f3 = await codec3.getNextFrame();

      setState(() {
        _spriteImage = f1.image;
        _firedImage = f2.image;
        _idleImage = f3.image;
      });

      _startIdleAnimation();
    } catch (e) {
      print("❌ 로드 실패: $e");
    }
  }

  @override
  void dispose() {
    _frameTimer?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  void _startIdleAnimation() {
    _frameTimer?.cancel();
    _currentFrame = 0;
    _frameTimer = Timer.periodic(const Duration(milliseconds: 1000), (_) {
      setState(() {
        _currentFrame = (_currentFrame + 1) % 2;
      });
    });
  }

  void _startWorkAnimation() {
    _frameTimer?.cancel();
    _currentFrame = 0;
    _frameTimer = Timer.periodic(const Duration(milliseconds: 400), (_) {
      setState(() {
        _currentFrame = (_currentFrame + 1) % 4;
      });
    });
  }

  void _startFiredAnimation() {
    _frameTimer?.cancel();
    _currentFrame = 0;
    _frameTimer = Timer.periodic(const Duration(milliseconds: 400), (_) {
      setState(() {
        if (_currentFrame < 5) {
          _currentFrame++;
        } else {
          _frameTimer?.cancel();
          _appState = AppState.fired;
        }
      });
    });
  }

  void _start() {
    setState(() {
      _appState = AppState.running;
      _currentEarning = 0;
      _secondsRemaining = _totalSeconds;
      _statusMessage = "🐱 고양이도 열심히 일하는 중!";
    });
    _startWorkAnimation();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
          _currentEarning += 100 / (_totalSeconds / 60 * 6);
        } else {
          _totalMoney += _currentEarning;
          _currentEarning = 0;
          _timer?.cancel();
          _secondsRemaining = _totalSeconds;
          _statusMessage = "💰 알바 성공! 고양이가 월급을 가져왔어요!";
          _startFiredAnimation();
          _appState = AppState.firedAnimating;
        }
      });
    });
  }

  void _pause() {
    _timer?.cancel();
    setState(() {
      _appState = AppState.paused;
      _statusMessage = "⏸ 잠깐 쉬는 중...";
    });
    _startIdleAnimation();
  }

  void _resume() {
    setState(() {
      _appState = AppState.running;
      _statusMessage = "🐱 고양이도 열심히 일하는 중!";
    });
    _startWorkAnimation();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
          _currentEarning += 100 / (_totalSeconds / 60 * 6);
        } else {
          _totalMoney += _currentEarning;
          _currentEarning = 0;
          _timer?.cancel();
          _secondsRemaining = _totalSeconds;
          _statusMessage = "💰 알바 성공! 고양이가 월급을 가져왔어요!";
          _startFiredAnimation();
          _appState = AppState.firedAnimating;
        }
      });
    });
  }

  void _stop() {
    _timer?.cancel();
    setState(() {
      _currentEarning = 0;
      _secondsRemaining = _totalSeconds;
      _statusMessage = "😿 주인이 한눈팔아서 고양이가 실직했어요...";
      _appState = AppState.firedAnimating;
    });
    _startFiredAnimation();
  }

  void _reset() {
    setState(() {
      _appState = AppState.idle;
      _currentFrame = 0;
      _secondsRemaining = _totalSeconds;
      _statusMessage = "🐱 고양이도 일할 준비 중...";
    });
    _startIdleAnimation();
  }

  void _showTimerPicker() {
    // 현재 분 단위로 변환, 5분 단위로 맞춤
    int tempMinutes = ((_totalSeconds ~/ 60) ~/ 5) * 5;
    if (tempMinutes < 10) tempMinutes = 10;
    if (tempMinutes > 120) tempMinutes = 120;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("⏱ 타이머 설정"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "$tempMinutes 분",
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    min: 10,
                    max: 120,
                    divisions: 22,
                    value: tempMinutes.toDouble(),
                    label: "$tempMinutes 분",
                    onChanged: (val) {
                      setDialogState(() {
                        tempMinutes = ((val / 5).round() * 5).clamp(10, 120);
                      });
                    },
                  ),
                  Text(
                    "10분 ~ 120분 (5분 단위)",
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("취소"),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _totalSeconds = tempMinutes * 60;
                      _secondsRemaining = _totalSeconds;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text("확인"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatTime(int seconds) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  ui.Image? get _currentImage {
    switch (_appState) {
      case AppState.fired:
      case AppState.firedAnimating:
        return _firedImage;
      case AppState.running:
        return _spriteImage;
      case AppState.idle:
      case AppState.paused:
        return _idleImage;
    }
  }

  int get _totalFrames {
    switch (_appState) {
      case AppState.fired:
      case AppState.firedAnimating:
        return 6;
      case AppState.running:
        return 4;
      case AppState.idle:
      case AppState.paused:
        return 2;
    }
  }

  String get _bottomText {
    switch (_appState) {
      case AppState.running:
      case AppState.paused:
        return "💵 현재 적립 중: ${_currentEarning.toInt()}원";
      case AppState.fired:
      case AppState.firedAnimating:
        return "💸 모든 돈을 잃었습니다...";
      case AppState.idle:
        return "⏱ 타이머를 눌러 시간을 설정하세요";
    }
  }

  Widget _buildButtons() {
    switch (_appState) {
      case AppState.idle:
        return _singleButton("공부 시작하기", Colors.blue[400]!, _start);
      case AppState.running:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _smallButton("일시정지", Colors.orange[400]!, _pause),
            const SizedBox(width: 16),
            _smallButton("중지", Colors.red[400]!, _stop),
          ],
        );
      case AppState.paused:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _smallButton("재개", Colors.blue[400]!, _resume),
            const SizedBox(width: 16),
            _smallButton("중지", Colors.red[400]!, _stop),
          ],
        );
      case AppState.firedAnimating:
        return const SizedBox();
      case AppState.fired:
        return _singleButton("다시 집중하기", Colors.green[600]!, _reset);
    }
  }

  Widget _singleButton(String label, Color color, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(35)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 22,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _smallButton(String label, Color color, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(35)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 20,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            flex: 1,
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  color: _appState == AppState.running
                      ? Colors.green[100]
                      : Colors.grey[300],
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 120,
                          height: 120,
                          child: _currentImage == null
                              ? const SizedBox()
                              : CustomPaint(
                                  painter: _SpritePainter(
                                    image: _currentImage!,
                                    frame: _currentFrame,
                                    totalFrames: _totalFrames,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _statusMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: _appState == AppState.fired ||
                                    _appState == AppState.firedAnimating
                                ? 14
                                : 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 50,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.monetization_on,
                          color: Colors.amber,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "${_totalMoney.toInt()}원",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              width: double.infinity,
              color: Colors.white,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // idle일 때만 탭 가능, 테두리로 힌트 표시
                  GestureDetector(
                    onTap: _appState == AppState.idle ? _showTimerPicker : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        border: _appState == AppState.idle
                            ? Border.all(color: Colors.blue[200]!, width: 2)
                            : null,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _formatTime(_secondsRemaining),
                        style: const TextStyle(
                          fontSize: 90,
                          fontWeight: FontWeight.w200,
                          fontFamily: 'Courier',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _bottomText,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 60),
                  _buildButtons(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpritePainter extends CustomPainter {
  final ui.Image image;
  final int frame;
  final int totalFrames;

  _SpritePainter({
    required this.image,
    required this.frame,
    required this.totalFrames,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final frameWidth = image.width / totalFrames;
    final src = Rect.fromLTWH(
      frame * frameWidth,
      0,
      frameWidth,
      image.height.toDouble(),
    );
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(
      image,
      src,
      dst,
      Paint()..filterQuality = FilterQuality.none,
    );
  }

  @override
  bool shouldRepaint(_SpritePainter old) => old.frame != frame;
}