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
import 'mission_popup.dart';
import 'stats_screen.dart';
import 'settings_screen.dart';

enum AppState { idle, running, paused, fired, firedAnimating, success, successAnimating }

class MainScreen extends StatefulWidget {
  final String character;
  const MainScreen({super.key, required this.character});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _totalSeconds = 1500;
  int _secondsRemaining = 1500;
  double _currentEarning = 0;
  int _elapsedStudySeconds = 0;
  DateTime? _sessionStartTime;
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
  bool _hasClaimedToday = false;

  static const Color _darkGreen = Color(0xFF3D5C28);
  static const Color _btnBlue   = Color(0xFF4A7FBD);
  static const Color _btnOrange = Color(0xFFD4782A);
  static const Color _btnRed    = Color(0xFFBD3A3A);
  static const Color _btnGreen  = Color(0xFF4A9E4A);

  static const double _circleSize    = 200;
  static const double _characterSize = 110;
  static const double _coinBadgeW    = 100;
  static const double _coinBadgeH    = 48;
  static const double _coinIconSize  = 48;
  static const double _topOffset     = 60;

  double get _progress =>
      _appState == AppState.running || _appState == AppState.paused
          ? (_totalSeconds - _secondsRemaining) / _totalSeconds
          : 0.0;

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

    final lastClaimDate = prefs.getString('lastClaimDate') ?? '';
    setState(() {
      _attendanceDays  = days;
      _hasClaimedToday = lastClaimDate == today;
    });
  }

  Future<void> _claimReward(int reward) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await prefs.setString('lastClaimDate', today);
    if (mounted) {
      context.read<GameProvider>().addMoney(reward.toDouble());
      setState(() => _hasClaimedToday = true);
    }
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
        _spriteImage  = f1.image;
        _firedImage   = f2.image;
        _idleImage    = f3.image;
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
      setState(() => _currentFrame =
          (_currentFrame + 1) % (widget.character == 'cat' ? 4 : 7));
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

  void _runTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
          _currentEarning = (_totalSeconds - _secondsRemaining) * 100 / 600;
          _elapsedStudySeconds++;
          if (_elapsedStudySeconds % 60 == 0) {
            context.read<GameProvider>().addStudyMinutes(1);
          }
        } else {
          final remainingSecs = _elapsedStudySeconds % 60;
          if (remainingSecs > 0) {
            context.read<GameProvider>().addStudyMinutes(1);
          }
          if (_sessionStartTime != null) {
            context.read<GameProvider>().addSession(_totalSeconds, _sessionStartTime!);
            _sessionStartTime = null;
          }
          context.read<GameProvider>().addMoney(_currentEarning);
          _currentEarning = 0;
          _elapsedStudySeconds = 0;
          _timer?.cancel();
          _secondsRemaining = _totalSeconds;
          _statusMessage = "💰 알바 성공! 월급을 가져왔어요!";
          _startSuccessAnimation();
          _appState = AppState.successAnimating;
        }
      });
    });
  }

  void _start() {
    setState(() {
      _appState = AppState.running;
      _currentEarning = 0;
      _elapsedStudySeconds = 0;
      _sessionStartTime = DateTime.now();
      _secondsRemaining = _totalSeconds;
      _statusMessage = "🐾 열심히 일하는 중!";
    });
    _startWorkAnimation();
    _runTimer();
  }

  void _pause() {
    final success = context.read<GameProvider>().usePause();
    if (!success) {
      // 횟수 초과 알림
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("⏸ 일시정지 횟수 초과"),
          content: const Text("오늘 일시정지 횟수를 모두 사용했어요!\n내일 다시 5번 충전됩니다."),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("확인"),
            ),
          ],
        ),
      );
      return;
    }
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
    _runTimer();
  }

  void _stop() {
    _timer?.cancel();
    if (_sessionStartTime != null) {
      context.read<GameProvider>().addSession(_elapsedStudySeconds, _sessionStartTime!);
      _sessionStartTime = null;
    }
    setState(() {
      _currentEarning = 0;
      _elapsedStudySeconds = 0;
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
      builder: (_) => AttendancePopup(
        attendanceDays: _attendanceDays,
        hasClaimedToday: _hasClaimedToday,
        onClaim: _claimReward,
      ),
    );
  }

  void _showMissionPopup() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const MissionPopup(),
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
                      setDialogState(
                          () => tempMinutes = index == 0 ? 1 : index * 5);
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
                const Text("분",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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

  String _formatMoney(double money) {
    final m = money.toInt();
    if (m >= 1000) {
      final k = m / 1000;
      return k == k.truncateToDouble()
          ? "${k.toInt()}k"
          : "${k.toStringAsFixed(1)}k";
    }
    return "$m";
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

  bool _isLightColor(Color color) => color.computeLuminance() > 0.5;

  Widget _buildCategorySelector(GameProvider provider) {
    final categories = provider.categories;
    final selectedId = provider.selectedCategoryId;
    final canSelect  = _appState == AppState.idle;
    final displayCategories = canSelect
        ? categories
        : categories.where((c) => c.id == selectedId).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: displayCategories.map((cat) {
          final isSelected = cat.id == selectedId;
          return GestureDetector(
            onTap: canSelect ? () => provider.selectCategory(cat.id) : null,
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? cat.color
                    : cat.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isLightColor(cat.color)
                      ? Colors.grey[400]!
                      : cat.color,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                cat.name,
                style: TextStyle(
                  color: isSelected
                      ? (_isLightColor(cat.color) ? Colors.black87 : Colors.white)
                      : (_isLightColor(cat.color) ? Colors.black87 : cat.color),
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildButtons() {
    final provider = context.read<GameProvider>();
    switch (_appState) {
      case AppState.idle:
        return _singleButton("${context.read<GameProvider>().selectedCategory?.name ?? '공부'} 시작하기", _btnBlue, _start);
      case AppState.running:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _pauseButton(provider.remainingPauses),
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

  Widget _pauseButton(int remaining) {
    return ElevatedButton(
      onPressed: _pause,
      style: ElevatedButton.styleFrom(
        backgroundColor: _btnOrange,
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 10),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: Color(0xFF2A3D1A), width: 2),
        ),
        elevation: 0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("일시정지",
              style: TextStyle(
                  fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
          Text(
            "($remaining/${GameProvider.maxPauseCount})",
            style: const TextStyle(fontSize: 11, color: Colors.white70),
          ),
        ],
      ),
    );
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
      child: Text(label,
          style: const TextStyle(
              fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
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
      child: Text(label,
          style: const TextStyle(
              fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }

  Widget _topIconBtn(String emoji, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: _coinBadgeH,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF8B6914),
          border: Border.all(color: const Color(0xFF5C4209), width: 2),
        ),
        child: Center(
          child: Text(emoji, style: const TextStyle(fontSize: 20)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider   = context.watch<GameProvider>();
    final money      = provider.money;
    final themeColor = provider.themeColor;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        drawer: Drawer(
          width: MediaQuery.of(context).size.width * 0.45,
          child: Container(
            color: themeColor,
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  const Text("메뉴",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _darkGreen)),
                  const Divider(color: Color(0xFF8B6914), thickness: 2),
                  ListTile(
                    leading: const Icon(Icons.store, color: _darkGreen),
                    title: const Text("상점",
                        style: TextStyle(
                            color: _darkGreen, fontWeight: FontWeight.bold)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const ShopScreen()));
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.location_city, color: _darkGreen),
                    title: const Text("마을 전경",
                        style: TextStyle(
                            color: _darkGreen, fontWeight: FontWeight.bold)),
                    onTap: () {
                      ScaffoldMessenger.of(context).clearSnackBars();
                      Navigator.pop(context);
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const TownScreen()));
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.bar_chart, color: _darkGreen),
                    title: const Text("통계",
                        style: TextStyle(
                            color: _darkGreen, fontWeight: FontWeight.bold)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const StatsScreen()));
                    },
                  ),
                  const Spacer(),
                  const Divider(color: Color(0xFF8B6914), thickness: 1),
                  ListTile(
                    leading: const Icon(Icons.settings, color: _darkGreen),
                    title: const Text("설정",
                        style: TextStyle(
                            color: _darkGreen, fontWeight: FontWeight.bold)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const SettingsScreen()));
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        body: Container(
          color: themeColor,
          child: SafeArea(
            child: Column(
              children: [
                // ── 상단 ──
                Expanded(
                  flex: 1,
                  child: Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        color: themeColor,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: _topOffset),
                            SizedBox(
                              width: _circleSize,
                              height: _circleSize,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CustomPaint(
                                    size: Size(_circleSize, _circleSize),
                                    painter: _CircleProgressPainter(
                                        progress: _progress),
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
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 8, left: 16,
                        child: Builder(
                          builder: (context) => IconButton(
                            icon: const Icon(Icons.menu,
                                color: _darkGreen, size: 28),
                            onPressed: () => Scaffold.of(context).openDrawer(),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8, right: 20,
                        child: Row(
                          children: [
                            if (_showGiftButton) ...[
                              _topIconBtn("📋", _showMissionPopup),
                              const SizedBox(width: 8),
                              _topIconBtn("🎁", _showAttendancePopup),
                              const SizedBox(width: 8),
                            ],
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
                                  Image.asset(_coinAsset,
                                      width: _coinIconSize,
                                      height: _coinIconSize,
                                      filterQuality: FilterQuality.none),
                                  Expanded(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        _formatMoney(money),
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold),
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

                // ── 하단 ──
                Expanded(
                  flex: 1,
                  child: Container(
                    width: double.infinity,
                    color: themeColor,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: _appState == AppState.idle
                              ? _showTimerPicker
                              : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              border: _appState == AppState.idle
                                  ? Border.all(color: _darkGreen, width: 2)
                                  : null,
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _formatTime(_secondsRemaining),
                                style: const TextStyle(
                                  fontSize: 90,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'NeoDunggeunmo',
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(_bottomText,
                            style: const TextStyle(
                                fontSize: 14, color: Color(0xFF6B4F1A))),
                        const SizedBox(height: 12),
                        _buildCategorySelector(provider),
                        const SizedBox(height: 16),
                        _buildButtons(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CircleProgressPainter extends CustomPainter {
  final double progress;
  _CircleProgressPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 10.0;
    const segments = 30;

    final bgPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.square
      ..style = PaintingStyle.stroke;

    // 배경 40각형
    final bgPath = Path();
    for (int i = 0; i <= segments; i++) {
      final a = -pi / 2 + (2 * pi * i / segments);
      final p = Offset(center.dx + radius * cos(a), center.dy + radius * sin(a));
      if (i == 0) { bgPath.moveTo(p.dx, p.dy); } else { bgPath.lineTo(p.dx, p.dy); }
    }
    canvas.drawPath(bgPath, bgPaint);

    if (progress > 0) {
      final fgPaint = Paint()
        ..color = const Color(0xFF4A9E4A)
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.square
        ..style = PaintingStyle.stroke;

      final totalSegs = (progress * segments).floor();

      if (totalSegs > 0) {
        final fgPath = Path();
        for (int i = 0; i <= totalSegs; i++) {
          final a = -pi / 2 + (2 * pi * i / segments);
          final p = Offset(center.dx + radius * cos(a), center.dy + radius * sin(a));
          if (i == 0) { fgPath.moveTo(p.dx, p.dy); } else { fgPath.lineTo(p.dx, p.dy); }
        }
        canvas.drawPath(fgPath, fgPaint);
      }

      // 끝점 dot (작은 24각형)
      final angle = -pi / 2 + 2 * pi * (totalSegs / segments);
      final dotX  = center.dx + radius * cos(angle);
      final dotY  = center.dy + radius * sin(angle);
      const dotR  = 7.0;
      final dotPath = Path();
      for (int i = 0; i <= 10; i++) {
        final a = 2 * pi * i / 10;
        final p = Offset(dotX + dotR * cos(a), dotY + dotR * sin(a));
        if (i == 0) { dotPath.moveTo(p.dx, p.dy); } else { dotPath.lineTo(p.dx, p.dy); }
      }
      canvas.drawPath(dotPath, Paint()..color = const Color(0xFF4A9E4A)..style = PaintingStyle.fill);
      canvas.drawPath(dotPath, Paint()
        ..color = Colors.black.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5);
    }
  }

  @override
  bool shouldRepaint(_CircleProgressPainter old) =>
      old.progress != progress;
}