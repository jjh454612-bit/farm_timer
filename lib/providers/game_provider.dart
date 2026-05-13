import 'package:flutter/material.dart';

class GameProvider extends ChangeNotifier {
  double _money = 10000;
  final Set<String> _ownedBuildings = {};
  String _character = 'cat';
  final Map<int, String> _placedBuildings = {};
  final Set<int> _rotatedTiles = {};

  // 2D 그리드: "gx,gy" 형태로 설치된 땅 위치 저장 (메인 = "0,0")
  final Set<String> _groundGrid = {'0,0'};

  // 땅 확장권
  int _landVouchers = 0;
  int _totalLandPurchased = 0; // 가격 계산용 누적 구매 횟수

  double get money => _money;
  Set<String> get ownedBuildings => _ownedBuildings;
  String get character => _character;
  Map<int, String> get placedBuildings => _placedBuildings;
  Set<int> get rotatedTiles => _rotatedTiles;
  Set<String> get groundGrid => Set.unmodifiable(_groundGrid);
  int get landVouchers => _landVouchers;

  // 다음 땅 확장권 가격: 구매할수록 비싸짐 (2000 → 4000 → 6000...)
  int get nextLandPrice => 2000 * (_totalLandPurchased + 1);

  void setCharacter(String character) {
    _character = character;
    notifyListeners();
  }

  void addMoney(double amount) {
    _money += amount;
    notifyListeners();
  }

  void spendMoney(double amount) {
    _money -= amount;
    notifyListeners();
  }

  bool canAfford(double price) => _money >= price;

  void buyBuilding(String id, double price) {
    if (!canAfford(price)) return;
    _money -= price;
    _ownedBuildings.add(id);
    notifyListeners();
  }

  bool owns(String id) => _ownedBuildings.contains(id);

  void placeBuilding(int tileIndex, String buildingId, bool isRotated) {
    _placedBuildings[tileIndex] = buildingId;
    if (isRotated) {
      _rotatedTiles.add(tileIndex);
    } else {
      _rotatedTiles.remove(tileIndex);
    }
    notifyListeners();
  }

  // 상점에서 땅 확장권 구매 (가격 점진적 인상)
  void buyLandVoucher() {
    final price = nextLandPrice.toDouble();
    if (!canAfford(price)) return;
    _money -= price;
    _landVouchers++;
    _totalLandPurchased++;
    notifyListeners();
  }

  // 마을에서 확장권 사용: 그리드 위치 (gx, gy)에 땅 추가
  void useLandVoucher(int gx, int gy) {
    if (_landVouchers <= 0) return;
    _landVouchers--;
    _groundGrid.add('$gx,$gy');
    notifyListeners();
  }
}