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
    required this.id, required this.imagePath, required this.name,
    required this.description, required this.price,
  });
}

const List<ShopItem> _shopItems = [
  ShopItem(id: 'house',       imagePath: 'assets/house1.png',       name: '집',         description: '주민들이 살 수 있는 집',         price: 300),
  ShopItem(id: 'modernhouse', imagePath: 'assets/modernhouse.png',  name: '모던하우스', description: '세련된 현대식 주택',              price: 700),
  ShopItem(id: 'park',        imagePath: 'assets/park.png',         name: '공원',       description: '휴식을 위한 공원',               price: 300),
  ShopItem(id: 'police',      imagePath: 'assets/police.png',       name: '경찰서',     description: '마을을 지키는 경찰서',           price: 800),
  ShopItem(id: 'hospital',    imagePath: 'assets/hospital.png',     name: '병원',       description: '아픈 주민을 치료하는 병원',      price: 1000),
  ShopItem(id: 'towerpark',   imagePath: 'assets/towerpark.png',    name: '탑 공원',    description: '높은 탑이 있는 공원',            price: 1200),
  ShopItem(id: 'fire',        imagePath: 'assets/fire.png',         name: '소방서',     description: '마을을 화재에서 지켜요',         price: 900),
  ShopItem(id: 'landmark',    imagePath: 'assets/landmark.png',     name: '랜드마크',   description: '마을의 상징이 되는 건물',        price: 2000),
  ShopItem(id: 'pondpark',    imagePath: 'assets/pondpark.png',     name: '연못공원',   description: '연못이 있는 아름다운 공원',      price: 600),
  ShopItem(id: 'oldapt',      imagePath: 'assets/oldapt.png',       name: '구형아파트', description: '오래된 아파트',                  price: 700),
  ShopItem(id: 'apt',         imagePath: 'assets/apt.png',          name: '아파트',     description: '현대식 아파트',                  price: 1500),
  ShopItem(id: 'landmark2',   imagePath: 'assets/landmark2.png',    name: '초고층빌딩', description: '마을을 내려다보는 초고층 건물',  price: 5000),
  ShopItem(id: 'land',        imagePath: '',                        name: '땅 확장권',  description: '마을을 한 칸 더 넓혀요. 살수록 가격이 올라요!', price: 0),
];

const Map<String, String> _buildingEffect = {
  'house':       '+2명',
  'modernhouse': '+4명',
  'oldapt':      '+25명',
  'apt':         '+40명',
  'landmark':    '+150명',
  'landmark2':   '+300명, +5% 행복',
  'park':        '+5% 행복',
  'towerpark':   '+10% 행복',
  'pondpark':    '+8% 행복',
  'fire':        '+7% 행복',
  'hospital':    '+9% 행복',
  'police':      '+6% 행복',
};

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

  void _showTopSnackBar(BuildContext context, String message) {
    final height = MediaQuery.of(context).size.height;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        duration: const Duration(seconds: 1),
        backgroundColor: _btnGreen,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(bottom: height - 160, left: 40, right: 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider  = context.watch<GameProvider>();
    final coinAsset = provider.character == 'cat' ? 'assets/catcoin.png' : 'assets/dogcoin.png';

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: const Text("🏪 상점"),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: _coinBadgeW, height: _coinBadgeH,
            decoration: BoxDecoration(
              color: _gold,
              border: Border.all(color: const Color(0xFF5C4209), width: 2),
            ),
            child: Row(
              children: [
                Image.asset(coinAsset, width: _coinBadgeIcon, height: _coinBadgeIcon,
                    filterQuality: FilterQuality.none),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(_formatMoney(provider.money),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 6),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _shopItems.length + 1,
          separatorBuilder: (_, _a) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (index == _shopItems.length) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text("🏗 더 많은 건물이 계속 업데이트될 예정입니다!",
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      textAlign: TextAlign.center),
                ),
              );
            }

            final item        = _shopItems[index];
            final isLand      = item.id == 'land';
            final isUnlimited = GameProvider.unlimitedBuildings.contains(item.id);
            final itemPrice   = isLand ? provider.nextLandPrice.toDouble() : item.price;
            final owned       = !isLand && provider.owns(item.id);
            final qty         = provider.quantity(item.id);
            final canAfford   = provider.canAfford(itemPrice);
            final effect      = _buildingEffect[item.id];

            final bgColor     = (isUnlimited && owned) ? const Color(0xFFD6E8C0) : const Color(0xFFFFF0C8);
            final borderColor = (isUnlimited && owned) ? _darkGreen : const Color(0xFF8B6914);

            return Container(
              decoration: BoxDecoration(
                color: bgColor,
                border: Border.all(color: borderColor, width: 2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    SizedBox(
                      width: _itemImageSize, height: _itemImageSize,
                      child: isLand
                          ? const Center(child: Text("🏞", style: TextStyle(fontSize: 36)))
                          : Image.asset(item.imagePath, fit: BoxFit.contain,
                              filterQuality: FilterQuality.none),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(item.name,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                                        color: _darkGreen),
                                    overflow: TextOverflow.ellipsis),
                              ),
                              const SizedBox(width: 8),
                              if (isUnlimited && owned)
                                _badge("무제한", Colors.teal)
                              else if (!isLand && !isUnlimited && qty > 0)
                                _badge("보유 ${qty}개", _btnGreen)
                              else if (isLand && provider.landVouchers > 0)
                                _badge("보유 ${provider.landVouchers}장", _btnGreen),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(item.description,
                              style: const TextStyle(fontSize: 13, color: Color(0xFF6B4F1A)),
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          if (effect != null)
                            Text(effect, style: TextStyle(
                                fontSize: 12,
                                color: effect.contains('행복') ? Colors.orange[700] : Colors.blue[700],
                                fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              SizedBox(width: _priceIconSize, height: _priceIconSize,
                                  child: Image.asset(coinAsset, fit: BoxFit.contain,
                                      filterQuality: FilterQuality.none)),
                              const SizedBox(width: 4),
                              Text("${_formatMoney(itemPrice)}원",
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                                      color: _darkGreen)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    (isUnlimited && owned)
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: _btnGreen,
                              border: Border.all(color: const Color(0xFF2A3D1A), width: 2),
                            ),
                            child: const Text("보유중",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          )
                        : ElevatedButton(
                            onPressed: canAfford
                                ? () {
                                    if (isLand) { provider.buyLandVoucher(); }
                                    else { provider.buyBuilding(item.id, item.price); }
                                    _showTopSnackBar(context, "${item.name} 구매 완료!");
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _btnBlue,
                              disabledBackgroundColor: const Color(0xFFB0A080),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              elevation: 0,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero,
                                side: BorderSide(color: Color(0xFF2A3D1A), width: 2),
                              ),
                            ),
                            child: Text("구매", style: TextStyle(
                                color: canAfford ? Colors.white : Colors.grey[400],
                                fontWeight: FontWeight.bold)),
                          ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: const TextStyle(
          fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }
}