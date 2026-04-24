import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';

class ShopItem {
  final String id;
  final String imagePath;
  final String name;
  final String description;
  final double price;

  const ShopItem({
    required this.id,
    required this.imagePath,
    required this.name,
    required this.description,
    required this.price,
  });
}

const List<ShopItem> _shopItems = [
  ShopItem(id: 'house',    imagePath: 'assets/house1.png',   name: '집',    description: '주민들이 살 수 있는 집',    price: 500),
  ShopItem(id: 'park',     imagePath: 'assets/park.png',     name: '공원',  description: '휴식을 위한 공원',          price: 300),
  ShopItem(id: 'police',   imagePath: 'assets/police.png',   name: '경찰서', description: '마을을 지키는 경찰서',      price: 800),
  ShopItem(id: 'hospital', imagePath: 'assets/hospital.png', name: '병원',  description: '아픈 주민을 치료하는 병원', price: 1000),
];

const Color _darkGreen = Color(0xFF3D5C28);
const Color _bgColor   = Color(0xFFF5E6C8);
const Color _btnBlue   = Color(0xFF4A7FBD);
const Color _btnGreen  = Color(0xFF4A9E4A);
const Color _gold      = Color(0xFF8B6914);

// 크기 상수 따로 관리
const double _coinBadgeW     = 100; // 앱바 코인 뱃지 너비
const double _coinBadgeH     = 48;  // 앱바 코인 뱃지 높이
const double _coinBadgeIcon  = 48;  // 앱바 코인 아이콘 크기
const double _itemImageSize  = 64;  // 아이템 건물 이미지 크기
const double _priceIconSize  = 16;  // 가격 앞 코인 아이콘 크기

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final coinAsset = provider.character == 'cat'
        ? 'assets/catcoin.png'
        : 'assets/dogcoin.png';

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: const Text("🏪 상점"),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: _coinBadgeW,
            height: _coinBadgeH,
            decoration: BoxDecoration(
              color: _gold,
              border: Border.all(color: const Color(0xFF5C4209), width: 2),
            ),
            child: Row(
              children: [
                Image.asset(
                  coinAsset,
                  width: _coinBadgeIcon,
                  height: _coinBadgeIcon,
                  filterQuality: FilterQuality.none,
                ),
                Expanded(
                  child: Text(
                    "${provider.money.toInt()}원",
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
            ),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _shopItems.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = _shopItems[index];
          final owned = provider.owns(item.id);
          final canAfford = provider.canAfford(item.price);

          return Container(
            decoration: BoxDecoration(
              color: owned ? const Color(0xFFD6E8C0) : const Color(0xFFFFF0C8),
              border: Border.all(
                color: owned ? _darkGreen : const Color(0xFF8B6914),
                width: 2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  SizedBox(
                    width: _itemImageSize,
                    height: _itemImageSize,
                    child: Image.asset(
                      item.imagePath,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.none,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _darkGreen,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.description,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B4F1A),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            SizedBox(
                              width: _priceIconSize,
                              height: _priceIconSize,
                              child: Image.asset(
                                coinAsset,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.none,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "${item.price.toInt()}원",
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: _darkGreen,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  owned
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: _btnGreen,
                            border: Border.all(
                                color: const Color(0xFF2A3D1A), width: 2),
                          ),
                          child: const Text(
                            "보유중",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : ElevatedButton(
                          onPressed: canAfford
                              ? () {
                                  provider.buyBuilding(item.id, item.price);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("${item.name} 구매 완료!"),
                                      duration: const Duration(seconds: 1),
                                      backgroundColor: _btnGreen,
                                    ),
                                  );
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _btnBlue,
                            disabledBackgroundColor: const Color(0xFFB0A080),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            elevation: 0,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                              side: BorderSide(
                                  color: Color(0xFF2A3D1A), width: 2),
                            ),
                          ),
                          child: Text(
                            "구매",
                            style: TextStyle(
                              color: canAfford
                                  ? Colors.white
                                  : Colors.grey[400],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}