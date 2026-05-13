import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';

class ShopItem {
  final String id;
  final String imagePath;
  final String name;
  final String description;
  final double price; // 땅 확장권은 동적 가격이라 여기선 무시

  const ShopItem({
    required this.id,
    required this.imagePath,
    required this.name,
    required this.description,
    required this.price,
  });
}

const List<ShopItem> _shopItems = [
  ShopItem(id: 'house',     imagePath: 'assets/house1.png',    name: '집',       description: '주민들이 살 수 있는 집',      price: 500),
  ShopItem(id: 'park',      imagePath: 'assets/park.png',      name: '공원',     description: '휴식을 위한 공원',            price: 300),
  ShopItem(id: 'police',    imagePath: 'assets/police.png',    name: '경찰서',   description: '마을을 지키는 경찰서',        price: 800),
  ShopItem(id: 'hospital',  imagePath: 'assets/hospital.png',  name: '병원',     description: '아픈 주민을 치료하는 병원',   price: 1000),
  ShopItem(id: 'towerpark', imagePath: 'assets/towerpark.png', name: '탑 공원',  description: '높은 탑이 있는 공원',         price: 1200),
  ShopItem(id: 'land',      imagePath: '',                     name: '땅 확장권', description: '마을을 한 칸 더 넓혀요. 살수록 가격이 올라요!', price: 0),
];

const Color _darkGreen = Color(0xFF3D5C28);
const Color _bgColor   = Color(0xFFF5E6C8);
const Color _btnBlue   = Color(0xFF4A7FBD);
const Color _btnGreen  = Color(0xFF4A9E4A);
const Color _gold      = Color(0xFF8B6914);

const double _coinBadgeW    = 100;
const double _coinBadgeH    = 48;
const double _coinBadgeIcon = 48;
const double _itemImageSize = 64;
const double _priceIconSize = 16;

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  String _formatMoney(double amount) {
    if (amount >= 1000) {
      final k = amount / 1000;
      return k == k.toInt() ? "${k.toInt()}k" : "${k.toStringAsFixed(1)}k";
    }
    return amount.toInt().toString();
  }

  @override
  Widget build(BuildContext context) {
    final provider  = context.watch<GameProvider>();
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
                Image.asset(coinAsset,
                    width: _coinBadgeIcon,
                    height: _coinBadgeIcon,
                    filterQuality: FilterQuality.none),
                Expanded(
                  child: Text(
                    _formatMoney(provider.money),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
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
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item      = _shopItems[index];
          final isLand    = item.id == 'land';
          final itemPrice = isLand ? provider.nextLandPrice.toDouble() : item.price;
          final owned     = !isLand && provider.owns(item.id);
          final canAfford = provider.canAfford(itemPrice);

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
                  // 이미지
                  SizedBox(
                    width: _itemImageSize,
                    height: _itemImageSize,
                    child: isLand
                        ? const Center(child: Text("🏞", style: TextStyle(fontSize: 36)))
                        : Image.asset(item.imagePath,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.none),
                  ),
                  const SizedBox(width: 16),
                  // 이름 / 설명 / 가격
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _darkGreen),
                            ),
                            if (isLand && provider.landVouchers > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _btnGreen,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  "보유 ${provider.landVouchers}장",
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.description,
                          style: const TextStyle(
                              fontSize: 13, color: Color(0xFF6B4F1A)),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            SizedBox(
                              width: _priceIconSize,
                              height: _priceIconSize,
                              child: Image.asset(coinAsset,
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.none),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "${_formatMoney(itemPrice)}원",
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: _darkGreen),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 구매 버튼
                  owned
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: _btnGreen,
                            border: Border.all(
                                color: const Color(0xFF2A3D1A), width: 2),
                          ),
                          child: const Text("보유중",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        )
                      : ElevatedButton(
                          onPressed: canAfford
                              ? () {
                                  if (isLand) {
                                    provider.buyLandVoucher();
                                  } else {
                                    provider.buyBuilding(item.id, item.price);
                                  }
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