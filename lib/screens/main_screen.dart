import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import '../widgets/sprite_painter.dart';
import '../widgets/attendance_popup.dart';
import '../providers/game_provider.dart';
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
  // ──────────────────────────────────────────
  // 타이머 관련
  // ──────────────────────────────────────────
  int _totalSeconds = 1500;       // 총 타이머 시간 (초)
  int _secondsRemaining = 1500;   // 남은 시간 (초)
  double _currentEarning = 0;     // 현재 회차 적립 중인 돈
  Timer? _timer;                  // 타이머
  Timer? _frameTimer;             // 스프라이트 애니메이션 타이머

  // ──────────────────────────────────────────
  // 앱 상태 & 애니메이션
  // ──────────────────────────────────────────
  AppState _appState = AppState.idle;
  int _currentFrame = 0;          // 현재 스프라이트 프레임
  ui.Image? _spriteImage;         // 일하는 스프라이트
  ui.Image? _firedImage;          // 해고 스프라이트
  ui.Image? _idleImage;           // 대기 스프라이트
  ui.Image? _successImage;        // 성공 스프라이트

  String _statusMessage = "🐾 함께 일할 준비 중...";
  int _attendanceDays = 0;        // 출석 일수

  // ──────────────────────────────────────────
  // 색상 팔레트
  // ──────────────────────────────────────────
  static const Color _bgIdle    = Color(0xFFD6C9A0); // 대기 배경 (모래빛)
  static const Color _bgRunning = Color(0xFFA8C87A); // 실행 배경 (풀색)
  static const Color _bgBottom  = Color(0xFFF5E6C8); // 하단 배경 (양피지)
  static const Color _darkGreen = Color(0xFF3D5C28); // 진한 초록
  static const Color _btnBlue   = Color(0xFF4A7FBD); // 버튼 파랑
  static const Color _btnOrange = Color(0xFFD4782A); // 버튼 주황
  static const Color _btnRed    = Color(0xFFBD3A3A); // 버튼 빨강
  static const Color _btnGreen  = Color(0xFF4A9E4A); // 버튼 초록

  // ──────────────────────────────────────────
  // 크기 상수
  // ──────────────────────────────────────────
  static const double _circleSize    = 200; // 원형 진행바 지름
  static const double _characterSize = 110; // 캐릭터 크기
  static const double _coinBadgeW    = 100; // 코인 뱃지 너비
  static const double _coinBadgeH    = 48;  // 코인 뱃지 높이
  static const double _coinIconSize  = 48;  // 코인 아이콘 크기
  static const double _topOffset     = 60;  // 상단 여백 (출석/코인 버튼과 겹침 방지)

  // 진행도 계산 (0.0 ~ 1.0)
  double get _progress =>
      _appState == AppState.running || _appState == AppState.paused
          ? (_totalSeconds - _secondsRemaining) / _totalSeconds
          : 0.0;

  // 캐릭터에 맞는 코인 이미지
  String get _coinAsset =>
      widget.character == 'cat' ? 'assets/catcoin.png' : 'assets/dogcoin.png';

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
      debugPrint("❌ 로드 실패: $e");
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
          _currentEarning = (_totalSeconds - _secondsRemaining) * 100 / 600;
        } else {
          context.read<GameProvider>().addMoney(_currentEarning);
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
          _currentEarning = (_totalSeconds - _secondsRemaining) * 100 / 600;
        } else {
          context.read<GameProvider>().addMoney(_currentEarning);
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
        return _singleButton("공부 시작하기", _btnBlue, _start);
      case AppState.running:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _smallButton("일시정지", _btnOrange, _pause),
            const SizedBox(width: 16),
            _smallButton("중지", _btnRed, _stop),
          ],
        );
      case AppState.paused:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _smallButton("재개", _btnBlue, _resume),
            const SizedBox(width: 16),
            _smallButton("중지", _btnRed, _stop),
          ],
        );
      case AppState.firedAnimating:
      case AppState.successAnimating:
        return const SizedBox();
      case AppState.fired:
      case AppState.success:
        return _singleButton("다시 집중하기", _btnGreen, _reset);
    }
  }

  Widget _singleButton(String label, Color color, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: Color(0xFF2A3D1A), width: 2),
        ),
        elevation: 0,
      ),
      child: Text(
        label,
        style: const TextStyle(
            fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _smallButton(String label, Color color, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: Color(0xFF2A3D1A), width: 2),
        ),
        elevation: 0,
      ),
      child: Text(
        label,
        style: const TextStyle(
            fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final money = context.watch<GameProvider>().money;

    return Scaffold(
      drawer: Drawer(
        width: MediaQuery.of(context).size.width * 0.4,
        child: Container(
          color: const Color(0xFFF5E6C8),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Text(
                  "메뉴",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _darkGreen),
                ),
                const Divider(color: Color(0xFF8B6914), thickness: 2),
                ListTile(
                  leading: const Icon(Icons.store, color: _darkGreen),
                  title: const Text("상점",
                      style: TextStyle(
                          color: _darkGreen, fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ShopScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.location_city, color: _darkGreen),
                  title: const Text("마을 전경",
                      style: TextStyle(
                          color: _darkGreen, fontWeight: FontWeight.bold)),
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
      ),
      body: SafeArea( // ← 상태바 침범 방지
        child: Column(
          children: [
            // ──────────────────────────────────────────
            // 상단 영역 (캐릭터 + 원형 진행바)
            // ──────────────────────────────────────────
            Expanded(
              flex: 1,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    color: _appState == AppState.running ? _bgRunning : _bgIdle,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: _topOffset), // 상단 버튼과 겹침 방지 여백
                        // 원형 진행바 + 캐릭터
                        SizedBox(
                          width: _circleSize,
                          height: _circleSize,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CustomPaint(
                                size: Size(_circleSize, _circleSize),
                                painter: _CircleProgressPainter(
                                  progress: _progress,
                                ),
                              ),
                              SizedBox(
                                width: _characterSize,
                                height: _characterSize,
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
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _statusMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: _appState == AppState.fired ||
                                    _appState == AppState.firedAnimating
                                ? 14
                                : 20,
                            fontWeight: FontWeight.bold,
                            color: _darkGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 메뉴 버튼
                  Positioned(
                    top: 8,
                    left: 16,
                    child: Builder(
                      builder: (context) => IconButton(
                        icon: const Icon(Icons.menu, color: _darkGreen, size: 28),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                    ),
                  ),
                  // 출석 + 코인 버튼
                  Positioned(
                    top: 8,
                    right: 20,
                    child: Row(
                      children: [
                        if (_showGiftButton) ...[
                          GestureDetector(
                            onTap: _showAttendancePopup,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B6914),
                                border: Border.all(
                                    color: const Color(0xFF5C4209), width: 2),
                              ),
                              child: const Text("🎁",
                                  style: TextStyle(fontSize: 20)),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        // 코인 뱃지
                        Container(
                          width: _coinBadgeW,
                          height: _coinBadgeH,
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B6914),
                            border: Border.all(
                                color: const Color(0xFF5C4209), width: 2),
                          ),
                          child: Row(
                            children: [
                              Image.asset(
                                _coinAsset,
                                width: _coinIconSize,
                                height: _coinIconSize,
                                filterQuality: FilterQuality.none,
                              ),
                              Expanded(
                                child: Text(
                                  "${money.toInt()}원",
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // ──────────────────────────────────────────
            // 하단 영역 (타이머 + 버튼)
            // ──────────────────────────────────────────
            Expanded(
              flex: 1,
              child: Container(
                width: double.infinity,
                color: _bgBottom,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 타이머 표시 (idle 상태에서 탭하면 설정)
                    GestureDetector(
                      onTap: _appState == AppState.idle ? _showTimerPicker : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          border: _appState == AppState.idle
                              ? Border.all(color: _darkGreen, width: 2)
                              : null,
                        ),
                        child: Text(
                          _formatTime(_secondsRemaining),
                          style: const TextStyle(
                            fontSize: 90,
                            fontWeight: FontWeight.w200,
                            fontFamily: 'Courier',
                            color: _darkGreen,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // 현재 상태 텍스트
                    Text(
                      _bottomText,
                      style: const TextStyle(
                          fontSize: 14, color: Color(0xFF6B4F1A)),
                    ),
                    const SizedBox(height: 60),
                    // 시작/정지/재개 버튼
                    _buildButtons(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────
// 원형 진행바 페인터
// ──────────────────────────────────────────
class _CircleProgressPainter extends CustomPainter {
  final double progress; // 0.0 ~ 1.0

  _CircleProgressPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 10.0;

    // 배경 원 (빈 부분)
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    if (progress > 0) {
      // 진행 원 (초록색, 시계방향)
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,           // 12시 방향 시작
        2 * pi * progress, // 시계방향으로 채움
        false,
        Paint()
          ..color = const Color(0xFF4A9E4A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.butt,
      );

      // 진행 끝부분 동그란 점
      final angle = -pi / 2 + 2 * pi * progress;
      final dotX = center.dx + radius * cos(angle);
      final dotY = center.dy + radius * sin(angle);
      canvas.drawCircle(
        Offset(dotX, dotY),
        7,
        Paint()..color = const Color(0xFF4A9E4A),
      );
      canvas.drawCircle(
        Offset(dotX, dotY),
        7,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(_CircleProgressPainter old) =>
      old.progress != progress;
}