import 'package:flutter/material.dart';

class GameProvider extends ChangeNotifier {
  double _money = 10000;
  final Set<String> _ownedBuildings = {};
  String _character = 'cat';

  double get money => _money;
  Set<String> get ownedBuildings => _ownedBuildings;
  String get character => _character;

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
}