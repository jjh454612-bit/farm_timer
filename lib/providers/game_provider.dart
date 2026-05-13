import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ──────────────────────────────────────────
// 카테고리 모델
// ──────────────────────────────────────────
class StudyCategory {
  final String id;
  final String name;
  final Color color;

  const StudyCategory({
    required this.id,
    required this.name,
    required this.color,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'color': color.toARGB32(),
  };

  factory StudyCategory.fromJson(Map<String, dynamic> json) => StudyCategory(
    id: json['id'] as String,
    name: json['name'] as String,
    color: Color(json['color'] as int),
  );
}

const List<StudyCategory> _defaultCategories = [
  StudyCategory(id: 'study',   name: '공부', color: Color(0xFF4A7FBD)),
  StudyCategory(id: 'reading', name: '독서', color: Color(0xFF4A9E4A)),
];

// ──────────────────────────────────────────
// 세션 모델
// ──────────────────────────────────────────
class StudySession {
  final DateTime startTime;
  final int seconds;
  final String categoryId;

  const StudySession({
    required this.startTime,
    required this.seconds,
    required this.categoryId,
  });

  Map<String, dynamic> toJson() => {
    'startTime': startTime.toIso8601String(),
    'seconds':   seconds,
    'categoryId': categoryId,
  };

  factory StudySession.fromJson(Map<String, dynamic> json) => StudySession(
    startTime:  DateTime.parse(json['startTime'] as String),
    seconds:    json['seconds'] as int,
    categoryId: json['categoryId'] as String,
  );
}

class GameProvider extends ChangeNotifier {
  double _money = 0;
  String _character = 'cat';
  Map<int, String> _placedBuildings = {};
  Set<int> _rotatedTiles = {};
  Set<String> _groundGrid = {'0,0'};
  int _landVouchers = 0;
  int _totalLandPurchased = 0;
  Map<String, int> _ownedBuildings = {};

  // ── 일일 미션 ──
  int _todayStudyMinutes = 0;
  List<int> _dailyMissions = [];
  Set<int> _claimedMissions = {};
  String _lastMissionDate = '';
  static const List<int> _missionPool = [20, 40, 60, 80, 100, 120];

  // ── 카테고리 ──
  List<StudyCategory> _categories = List.from(_defaultCategories);
  String _selectedCategoryId = 'study';

  // ── 테마 색상 ──
  Color _themeColor = const Color(0xFFF5E6C8);

  // ── 세션 기록 ──
  List<StudySession> _sessions = [];

  // ── 일시정지 제한 ──
  static const int maxPauseCount = 5;
  int _pauseCount = 0;
  String _lastPauseDate = '';

  static const List<Color> palette = [
    Color(0xFFF5E6C8),
    Color(0xFFF5F5F5),
    Color(0xFFE0E0E0),
    Color(0xFFFFCDD2),
    Color(0xFFF8BBD9),
    Color(0xFFFFCCBC),
    Color(0xFFFFE0B2),
    Color(0xFFFFF9C4),
    Color(0xFFC8E6C9),
    Color(0xFFB2DFDB),
    Color(0xFFB3E5FC),
    Color(0xFFBBDEFB),
    Color(0xFFB2EBF2),
    Color(0xFFD1C4E9),
    Color(0xFFE1BEE7),
    Color(0xFFD7CCC8),
  ];

  bool _loaded = false;
  bool get loaded => _loaded;

  static const Set<String> unlimitedBuildings = {
    'park', 'towerpark', 'pondpark', 'fire', 'hospital', 'police',
  };

  static const Map<String, int> _populationMap = {
    'house':    10,
    'oldapt':   25,
    'apt':      40,
    'landmark': 150,
  };

  static const Map<String, int> _happinessMap = {
    'park':      5,
    'towerpark': 10,
    'pondpark':  8,
    'fire':      7,
    'hospital':  9,
    'police':    6,
  };

  // ──────────────────────────────────────────
  // Getters
  // ──────────────────────────────────────────
  double get money => _money;
  String get character => _character;
  Map<int, String> get placedBuildings => _placedBuildings;
  Set<int> get rotatedTiles => _rotatedTiles;
  Set<String> get groundGrid => Set.unmodifiable(_groundGrid);
  int get landVouchers => _landVouchers;
  int get nextLandPrice => 2000 * (_totalLandPurchased + 1);
  bool owns(String id) => _ownedBuildings.containsKey(id);
  int quantity(String id) => _ownedBuildings[id] ?? 0;
  Set<String> get ownedBuildings => _ownedBuildings.keys.toSet();
  int get todayStudyMinutes => _todayStudyMinutes;
  List<int> get dailyMissions => List.unmodifiable(_dailyMissions);
  Set<int> get claimedMissions => Set.unmodifiable(_claimedMissions);
  List<StudyCategory> get categories => List.unmodifiable(_categories);
  String get selectedCategoryId => _selectedCategoryId;
  Color get themeColor => _themeColor;
  List<StudySession> get sessions => List.unmodifiable(_sessions);
  int get pauseCount => _pauseCount;
  int get remainingPauses => maxPauseCount - _pauseCount;
  bool get canPause => _pauseCount < maxPauseCount;

  StudyCategory? get selectedCategory =>
      _categories.where((c) => c.id == _selectedCategoryId).firstOrNull;

  int get population => _placedBuildings.values
      .map((id) => _populationMap[id] ?? 0)
      .fold(0, (a, b) => a + b);

  int get happiness => min(100, _placedBuildings.values
      .map((id) => _happinessMap[id] ?? 0)
      .fold(0, (a, b) => a + b));

  bool isMissionComplete(int index) =>
      index < _dailyMissions.length &&
      _todayStudyMinutes >= _dailyMissions[index];

  int missionReward(int minutes) => (minutes ~/ 20) * 100;

  List<StudySession> sessionsForDate(DateTime date) {
    return _sessions.where((s) =>
        s.startTime.year == date.year &&
        s.startTime.month == date.month &&
        s.startTime.day == date.day).toList();
  }

  List<StudySession> get weekSessions {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 6));
    final start = DateTime(weekAgo.year, weekAgo.month, weekAgo.day);
    return _sessions.where((s) => s.startTime.isAfter(start)).toList();
  }

  List<StudySession> get todaySessions => sessionsForDate(DateTime.now());

  // ──────────────────────────────────────────
  // 저장/불러오기
  // ──────────────────────────────────────────
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    _money              = prefs.getDouble('money') ?? 10000;
    _character          = prefs.getString('character') ?? 'cat';
    _landVouchers       = prefs.getInt('landVouchers') ?? 0;
    _totalLandPurchased = prefs.getInt('totalLandPurchased') ?? 0;

    final gridJson = prefs.getString('groundGrid');
    if (gridJson != null) {
      _groundGrid = List<String>.from(jsonDecode(gridJson)).toSet();
    }

    final ownedJson = prefs.getString('ownedBuildings');
    if (ownedJson != null) {
      final map = Map<String, dynamic>.from(jsonDecode(ownedJson));
      _ownedBuildings = map.map((k, v) => MapEntry(k, v as int));
    }

    final placedJson = prefs.getString('placedBuildings');
    if (placedJson != null) {
      final map = Map<String, dynamic>.from(jsonDecode(placedJson));
      _placedBuildings = map.map((k, v) => MapEntry(int.parse(k), v as String));
    }

    final rotatedJson = prefs.getString('rotatedTiles');
    if (rotatedJson != null) {
      final list = List<dynamic>.from(jsonDecode(rotatedJson));
      _rotatedTiles = list.map((e) => e as int).toSet();
    }

    _lastMissionDate   = prefs.getString('lastMissionDate') ?? '';
    _todayStudyMinutes = prefs.getInt('todayStudyMinutes') ?? 0;

    final missionsJson = prefs.getString('dailyMissions');
    if (missionsJson != null) {
      _dailyMissions = List<int>.from(jsonDecode(missionsJson));
    }

    final claimedJson = prefs.getString('claimedMissions');
    if (claimedJson != null) {
      _claimedMissions = List<int>.from(jsonDecode(claimedJson)).toSet();
    }

    final categoriesJson = prefs.getString('categories');
    if (categoriesJson != null) {
      final list = List<dynamic>.from(jsonDecode(categoriesJson));
      _categories = list
          .map((e) => StudyCategory.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    _selectedCategoryId = prefs.getString('selectedCategoryId') ?? 'study';
    if (_categories.every((c) => c.id != _selectedCategoryId)) {
      _selectedCategoryId = _categories.first.id;
    }

    final themeColorVal = prefs.getInt('themeColor');
    if (themeColorVal != null) {
      _themeColor = Color(themeColorVal);
    }

    final sessionsJson = prefs.getString('sessions');
    if (sessionsJson != null) {
      final list = List<dynamic>.from(jsonDecode(sessionsJson));
      _sessions = list
          .map((e) => StudySession.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    // 일시정지 횟수 불러오기
    _lastPauseDate = prefs.getString('lastPauseDate') ?? '';
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (_lastPauseDate != today) {
      _pauseCount    = 0;
      _lastPauseDate = today;
      await prefs.setInt('pauseCount', 0);
      await prefs.setString('lastPauseDate', today);
    } else {
      _pauseCount = prefs.getInt('pauseCount') ?? 0;
    }

    _checkMissionReset(prefs);

    _loaded = true;
    notifyListeners();
  }

  void _checkMissionReset(SharedPreferences prefs) {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (_lastMissionDate != today) {
      _todayStudyMinutes = 0;
      _claimedMissions   = {};
      _dailyMissions     = _generateMissions();
      _lastMissionDate   = today;
      _saveMissions(prefs);
    }
  }

  List<int> _generateMissions() {
    final pool = List<int>.from(_missionPool)..shuffle(Random());
    return pool.take(3).toList()..sort();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('money', _money);
    await prefs.setString('character', _character);
    await prefs.setInt('landVouchers', _landVouchers);
    await prefs.setInt('totalLandPurchased', _totalLandPurchased);
    await prefs.setString('groundGrid', jsonEncode(_groundGrid.toList()));
    await prefs.setString('ownedBuildings', jsonEncode(_ownedBuildings));
    await prefs.setString('placedBuildings',
        jsonEncode(_placedBuildings.map((k, v) => MapEntry(k.toString(), v))));
    await prefs.setString('rotatedTiles', jsonEncode(_rotatedTiles.toList()));
    await prefs.setInt('themeColor', _themeColor.toARGB32());
    await _saveMissions(null);
    await _saveCategories(null);
    await _saveSessions(null);
  }

  Future<void> _saveMissions(SharedPreferences? existingPrefs) async {
    final prefs = existingPrefs ?? await SharedPreferences.getInstance();
    await prefs.setInt('todayStudyMinutes', _todayStudyMinutes);
    await prefs.setString('dailyMissions', jsonEncode(_dailyMissions));
    await prefs.setString('claimedMissions', jsonEncode(_claimedMissions.toList()));
    await prefs.setString('lastMissionDate', _lastMissionDate);
  }

  Future<void> _saveCategories(SharedPreferences? existingPrefs) async {
    final prefs = existingPrefs ?? await SharedPreferences.getInstance();
    await prefs.setString(
        'categories', jsonEncode(_categories.map((c) => c.toJson()).toList()));
    await prefs.setString('selectedCategoryId', _selectedCategoryId);
  }

  Future<void> _saveSessions(SharedPreferences? existingPrefs) async {
    final prefs = existingPrefs ?? await SharedPreferences.getInstance();
    await prefs.setString(
        'sessions', jsonEncode(_sessions.map((s) => s.toJson()).toList()));
  }

  Future<void> _savePauseCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('pauseCount', _pauseCount);
    await prefs.setString('lastPauseDate', _lastPauseDate);
  }

  // ──────────────────────────────────────────
  // Methods
  // ──────────────────────────────────────────
  void setCharacter(String character) {
    _character = character;
    _save();
    notifyListeners();
  }

  void addMoney(double amount) {
    _money += amount;
    _save();
    notifyListeners();
  }

  void spendMoney(double amount) {
    _money -= amount;
    _save();
    notifyListeners();
  }

  bool canAfford(double price) => _money >= price;

  void buyBuilding(String id, double price) {
    if (!canAfford(price)) return;
    _money -= price;
    if (unlimitedBuildings.contains(id)) {
      _ownedBuildings[id] = 1;
    } else {
      _ownedBuildings[id] = (_ownedBuildings[id] ?? 0) + 1;
    }
    _save();
    notifyListeners();
  }

  void placeBuilding(int tileIndex, String buildingId, bool isRotated) {
    _placedBuildings[tileIndex] = buildingId;
    if (isRotated) {
      _rotatedTiles.add(tileIndex);
    } else {
      _rotatedTiles.remove(tileIndex);
    }
    if (!unlimitedBuildings.contains(buildingId)) {
      final current = _ownedBuildings[buildingId] ?? 0;
      if (current <= 1) {
        _ownedBuildings.remove(buildingId);
      } else {
        _ownedBuildings[buildingId] = current - 1;
      }
    }
    _save();
    notifyListeners();
  }

  void buyLandVoucher() {
    final price = nextLandPrice.toDouble();
    if (!canAfford(price)) return;
    _money -= price;
    _landVouchers++;
    _totalLandPurchased++;
    _save();
    notifyListeners();
  }

  void useLandVoucher(int gx, int gy) {
    if (_landVouchers <= 0) return;
    _landVouchers--;
    _groundGrid.add('$gx,$gy');
    _save();
    notifyListeners();
  }

  void addStudyMinutes(int minutes) {
    _todayStudyMinutes += minutes;
    _saveMissions(null);
    notifyListeners();
  }

  void addSession(int seconds, DateTime startTime) {
    if (seconds < 60) return;
    _sessions.add(StudySession(
      startTime:  startTime,
      seconds:    seconds,
      categoryId: _selectedCategoryId,
    ));
    final cutoff = DateTime.now().subtract(const Duration(days: 90));
    _sessions.removeWhere((s) => s.startTime.isBefore(cutoff));
    _saveSessions(null);
    notifyListeners();
  }

  void claimMission(int index) {
    if (!isMissionComplete(index)) return;
    if (_claimedMissions.contains(index)) return;
    _claimedMissions.add(index);
    _money += missionReward(_dailyMissions[index]);
    _save();
    notifyListeners();
  }

  // 일시정지 사용 (true: 성공, false: 횟수 초과)
  bool usePause() {
    if (_pauseCount >= maxPauseCount) return false;
    _pauseCount++;
    _savePauseCount();
    notifyListeners();
    return true;
  }

  void selectCategory(String id) {
    if (_categories.every((c) => c.id != id)) return;
    _selectedCategoryId = id;
    _saveCategories(null);
    notifyListeners();
  }

  void addCategory(String name, Color color) {
    final id = 'cat_${DateTime.now().millisecondsSinceEpoch}';
    _categories.add(StudyCategory(id: id, name: name, color: color));
    _saveCategories(null);
    notifyListeners();
  }

  void removeCategory(String id) {
    if (_categories.length <= 1) return;
    _categories.removeWhere((c) => c.id == id);
    if (_selectedCategoryId == id) {
      _selectedCategoryId = _categories.first.id;
    }
    _saveCategories(null);
    notifyListeners();
  }

  void setThemeColor(Color color) {
    _themeColor = color;
    _save();
    notifyListeners();
  }
}