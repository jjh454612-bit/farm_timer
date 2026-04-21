import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:ui' as ui;
import '../widgets/sprite_painter.dart';
import '../widgets/attendance_popup.dart';
import 'shop_screen.dart';
import 'town_screen.dart';
enum AppState { idle, running, paused, fired, firedAnimating, success, successAnimating }

class MainScreen extends StatefulWidget {
  final String character;
  const MainScreen({super.key, required this.character});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _totalSeconds = 1500; // 테스트용 1분
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
  ui.Image? _successImage;

  String _statusMessage = "🐾 함께 일할 준비 중...";
  int _attendanceDays = 0;

  @override
  void initState() {
    super.initState();
    _loadSprites();
    _checkAttendance();
  }

  Future<void> _checkAttendance() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastDate = prefs.getString('lastAttendanceDate') ?? '';
    int days = prefs.getInt('attendanceDays') ?? 0;

    if (lastDate != today) {
      final yesterday = DateTime.now()
          .subtract(const Duration(days: 1))
          .toIso8601String()
          .substring(0, 10);

      if (lastDate == yesterday) {
        days = days + 1;
        if (days > 7) days = 1;
      } else {
        days = 1;
      }

      await prefs.setString('lastAttendanceDate', today);
      await prefs.setInt('attendanceDays', days);
    }

    setState(() => _attendanceDays = days);
  }

  Future<void> _loadSprites() async {
    try {
      final isCat = widget.character == 'cat';

      final data1 = await rootBundle.load(isCat ? 'assets/workcat.png' : 'assets/workdog.png');
      final codec1 = await ui.instantiateImageCodec(data1.buffer.asUint8List());
      final f1 = await codec1.getNextFrame();

      final data2 = await rootBundle.load(isCat ? 'assets/firedcat.png' : 'assets/fireddog.png');
      final codec2 = await ui.instantiateImageCodec(data2.buffer.asUint8List());
      final f2 = await codec2.getNextFrame();

      final data3 = await rootBundle.load(isCat ? 'assets/idlecat.png' : 'assets/idledog.png');
      final codec3 = await ui.instantiateImageCodec(data3.buffer.asUint8List());
      final f3 = await codec3.getNextFrame();

      final data4 = await rootBundle.load(isCat ? 'assets/successcat.png' : 'assets/successdog.png');
      final codec4 = await ui.instantiateImageCodec(data4.buffer.asUint8List());
      final f4 = await codec4.getNextFrame();

      setState(() {
        _spriteImage = f1.image;
        _firedImage = f2.image;
        _idleImage = f3.image;
        _successImage = f4.image;
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
      setState(() => _currentFrame = (_currentFrame + 1) % 2);
    });
  }

  void _startWorkAnimation() {
    _frameTimer?.cancel();
    _currentFrame = 0;
    _frameTimer = Timer.periodic(const Duration(milliseconds: 400), (_) {
      setState(() => _currentFrame = (_currentFrame + 1) % (widget.character == 'cat' ? 4 : 7));
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

  void _startSuccessAnimation() {
    _frameTimer?.cancel();
    _currentFrame = 0;
    final totalFrames = widget.character == 'cat' ? 10 : 11;
    _frameTimer = Timer.periodic(const Duration(milliseconds: 1000), (_) {
      setState(() {
        if (_currentFrame < totalFrames - 1) {
          _currentFrame++;
        } else {
          _frameTimer?.cancel();
          _appState = AppState.success;
        }
      });
    });
  }

  void _start() {
    setState(() {
      _appState = AppState.running;
      _currentEarning = 0;
      _secondsRemaining = _totalSeconds;
      _statusMessage = "🐾 열심히 일하는 중!";
    });
    _startWorkAnimation();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
          _currentEarning += 100 / 600;
        } else {
          _totalMoney += _currentEarning;
          _currentEarning = 0;
          _timer?.cancel();
          _secondsRemaining = _totalSeconds;
          _statusMessage = "💰 알바 성공! 월급을 가져왔어요!";
          _startSuccessAnimation();
          _appState = AppState.successAnimating;
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
      _statusMessage = "🐾 열심히 일하는 중!";
    });
    _startWorkAnimation();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
          _currentEarning += 100 / 600;
        } else {
          _totalMoney += _currentEarning;
          _currentEarning = 0;
          _timer?.cancel();
          _secondsRemaining = _totalSeconds;
          _statusMessage = "💰 알바 성공! 월급을 가져왔어요!";
          _startSuccessAnimation();
          _appState = AppState.successAnimating;
        }
      });
    });
  }

  void _stop() {
    _timer?.cancel();
    setState(() {
      _currentEarning = 0;
      _secondsRemaining = _totalSeconds;
      _statusMessage = "😿 한눈팔아서 실직했어요...";
      _appState = AppState.firedAnimating;
    });
    _startFiredAnimation();
  }

  void _reset() {
    setState(() {
      _appState = AppState.idle;
      _currentFrame = 0;
      _secondsRemaining = _totalSeconds;
      _statusMessage = "🐾 함께 일할 준비 중...";
    });
    _startIdleAnimation();
  }

  void _showAttendancePopup() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AttendancePopup(attendanceDays: _attendanceDays),
    );
  }

  void _showTimerPicker() {
  int tempMinutes = (_totalSeconds ~/ 60 ~/ 5) * 5;
  if (tempMinutes < 5) tempMinutes = 5;

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text("⏱ 타이머 설정"),
        content: SizedBox(
          height: 200,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 80,
                child: ListWheelScrollView.useDelegate(
                  itemExtent: 50,
                  perspective: 0.005,
                  diameterRatio: 1.5,
                  physics: const FixedExtentScrollPhysics(),
                  controller: FixedExtentScrollController(
                    initialItem: (tempMinutes ~/ 5) - 1,
                  ),
                  onSelectedItemChanged: (index) {
                    setDialogState(() => tempMinutes = index == 0 ? 1 : index * 5);
                  },
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: 25,
                    builder: (context, index) {
                      final minutes = index == 0 ? 1 : index * 5;
                      return Center(
                        child: Text(
                          "$minutes",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: tempMinutes == minutes
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: tempMinutes == minutes
                                ? Colors.black
                                : Colors.grey[400],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const Text(
                "분",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
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
      ),
    ),
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
      case AppState.success:
      case AppState.successAnimating:
        return _successImage;
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
      case AppState.success:
      case AppState.successAnimating:
        return widget.character == 'cat' ? 10 : 11;
      case AppState.running:
        return widget.character == 'cat' ? 4 : 7;
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
      case AppState.success:
      case AppState.successAnimating:
        return "🎉 수고했어요!";
      case AppState.idle:
        return "⏱ 타이머를 눌러 시간을 설정하세요";
    }
  }

  bool get _showGiftButton =>
      _appState != AppState.running && _appState != AppState.paused;

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
      case AppState.successAnimating:
        return const SizedBox();
      case AppState.fired:
      case AppState.success:
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
        style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
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
        style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        width: MediaQuery.of(context).size.width * 0.4,
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Text(
                "메뉴",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              ListTile(
  leading: const Icon(Icons.store),
  title: const Text("상점"),
  onTap: () {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ShopScreen()),
    );
  },
),
ListTile(
  leading: const Icon(Icons.location_city),
  title: const Text("마을 전경"),
  onTap: () {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TownScreen()),
    );
  },
),
            ],
          ),
        ),
      ),
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
                                  painter: SpritePainter(
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
                  left: 16,
                  child: Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu, color: Colors.black54, size: 28),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                ),
                Positioned(
                  top: 50,
                  right: 20,
                  child: Row(
                    children: [
                      if (_showGiftButton) ...[
                        GestureDetector(
                          onTap: _showAttendancePopup,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: const Text("🎁", style: TextStyle(fontSize: 20)),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.monetization_on, color: Colors.amber, size: 22),
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
                    ],
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