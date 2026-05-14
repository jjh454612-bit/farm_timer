import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;
import '../providers/game_provider.dart';

class TownScreen extends StatefulWidget {
  const TownScreen({super.key});

  @override
  State<TownScreen> createState() => _TownScreenState();
}

class _TownScreenState extends State<TownScreen> with TickerProviderStateMixin {
  ui.Image? _groundImage;
  ui.Image? _carImage;
  ui.Image? _carFlipImage;
  final Map<String, ui.Image?> _buildingImages = {};

  String? _selectedBuilding;
  int? _previewTile;
  bool _previewRotated = false;
  (int, int)? _previewLand;

  static const double _groundScale   = 2.0;
  static const double _buildingScale = 3.0;
  static const double _tileScale     = 3.0;
  static const double _carScale      = 1.0;

  static const double _groundW = 256 * _groundScale;
  static const double _groundH = 148 * _groundScale;
  static const double _extraH  = 500;

  static const double _canvasSize = 5000;
  static const double _originX = _canvasSize / 2 - _groundW / 2;
  static const double _originY = _extraH;

  double get _bw => 64 * _buildingScale;
  double get _bh => 64 * _buildingScale;
  double get _th => 32 * _tileScale;
  double get _carSize => 32 * _carScale;

  static const Set<String> _noRotation = {'towerpark'};

  static const Map<String, Map<String, String>> _buildingInfo = {
    'house':     {'asset': 'assets/house1.png',    'label': '집'},
    'park':      {'asset': 'assets/park.png',      'label': '공원'},
    'police':    {'asset': 'assets/police.png',    'label': '경찰서'},
    'hospital':  {'asset': 'assets/hospital.png',  'label': '병원'},
    'towerpark': {'asset': 'assets/towerpark.png', 'label': '탑 공원'},
    'fire':      {'asset': 'assets/fire.png',      'label': '소방서'},
    'landmark':  {'asset': 'assets/landmark.png',  'label': '랜드마크'},
    'pondpark':  {'asset': 'assets/pondpark.png',  'label': '연못공원'},
    'oldapt':    {'asset': 'assets/oldapt.png',    'label': '구형아파트'},
    'apt':       {'asset': 'assets/apt.png',       'label': '아파트'},
  };

  static int _tileBase(int gx, int gy) => (gx + 50) * 1000 + gy * 4;

  double _groundLeft(int gx) => _originX + gx * _groundW / 2;
  double _groundTop(int gy)  => _originY + gy * (_groundH / 2 - 20);

  void _addGroundAnchors(Map<int, Offset> map, int gx, int gy) {
    final base = _tileBase(gx, gy);
    final gl   = _groundLeft(gx);
    final gt   = _groundTop(gy);
    map[base + 0] = Offset(258 + gl, 55  + gt);
    map[base + 1] = Offset(110 + gl, 128 + gt);
    map[base + 2] = Offset(400 + gl, 128 + gt);
    map[base + 3] = Offset(256 + gl, 199 + gt);
  }

  String _happinessEmoji(int h) {
    if (h < 30) return "😢";
    if (h < 70) return "😐";
    return "😊";
  }


  late AnimationController _carController;
  late AnimationController _carFlipController;

  // ── 차 경로: X자 도로 두 팔 ──
  // car1: gy==gx 대각선 (오른쪽 팔, gx 내림차순)
  // car2: gy==-gx 대각선 (왼쪽 팔, gx 내림차순)
  // ── 모든 대각선 경로 ──
  Offset _interpolate(List<Offset> pts, double t) {
    if (pts.length == 1) return pts[0];
    final n = pts.length - 1;
    final i = (t * n).floor().clamp(0, n - 1);
    final f = t * n - i;
    return Offset(pts[i].dx + (pts[i+1].dx - pts[i].dx) * f,
                  pts[i].dy + (pts[i+1].dy - pts[i].dy) * f);
  }

  // ── 모든 대각선 경로 ──
  // B대각선(gy-gx=k): car.png, 오른쪽→왼쪽 위
  // A대각선(gy+gx=k): car1-1.png, 왼쪽→오른쪽 위
  List<({List<Offset> pts, double phase, bool isFlip})> _allCarRoutes(Set<String> groundGrid) {
    final result = <({List<Offset> pts, double phase, bool isFlip})>[];

    // B대각선 그룹 (gy - gx = k), car.png
    final bGroups = <int, List<(int, int)>>{};
    for (final pos in groundGrid) {
      final p = pos.split(',');
      final gx = int.parse(p[0]); final gy = int.parse(p[1]);
      final k = gy - gx;
      bGroups.putIfAbsent(k, () => []).add((gx, gy));
    }
    final bKeys = bGroups.keys.toList()..sort();

    // A대각선 그룹 (gy + gx = k), car1-1.png
    final aGroups = <int, List<(int, int)>>{};
    for (final pos in groundGrid) {
      final p = pos.split(',');
      final gx = int.parse(p[0]); final gy = int.parse(p[1]);
      final k = gy + gx;
      aGroups.putIfAbsent(k, () => []).add((gx, gy));
    }
    final aKeys = aGroups.keys.toList()..sort();

    // 전체 차 개수 기준 균등 위상 배분
    final total = bKeys.length + aKeys.length;
    int carIdx = 0;

    for (int i = 0; i < bKeys.length; i++, carIdx++) {
      final tiles = bGroups[bKeys[i]]!..sort((a, b) => b.$1.compareTo(a.$1));
      final pts = <Offset>[];
      bool first = true;
      for (final t in tiles) {
        final gx = t.$1; final gy = t.$2;
        if (first) { pts.add(Offset(384.0 + gx*256, 692.0 + gy*128)); first = false; }
        pts.add(Offset(128.0 + gx*256, 564.0 + gy*128));
      }
      result.add((pts: pts, phase: carIdx / total, isFlip: false));
    }

    for (int i = 0; i < aKeys.length; i++, carIdx++) {
      final tiles = aGroups[aKeys[i]]!..sort((a, b) => a.$1.compareTo(b.$1));
      final pts = <Offset>[];
      bool first = true;
      for (final t in tiles) {
        final gx = t.$1; final gy = t.$2;
        if (first) { pts.add(Offset(128.0 + gx*256, 692.0 + gy*128)); first = false; }
        pts.add(Offset(384.0 + gx*256, 564.0 + gy*128));
      }
      result.add((pts: pts, phase: carIdx / total, isFlip: true));
    }

    return result;
  }

  final TransformationController _transformController = TransformationController();

  @override
  void initState() {
    super.initState();
    _loadImages();

    _carController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();

    _carFlipController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    );
    _carFlipController.value = 0.5;
    _carFlipController.repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = MediaQuery.of(context).size;
      _transformController.value = Matrix4.translationValues(
        -((_originX + _groundW / 2) - size.width / 2),
        -((_originY + _groundH / 2) - size.height * 0.3),
        0.0,
      );
    });
  }

  @override
  void dispose() {
    _carController.dispose();
    _carFlipController.dispose();
    _transformController.dispose();
    super.dispose();
  }

  Future<ui.Image> _loadImg(String path) async {
    final data = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    return (await codec.getNextFrame()).image;
  }

  Future<void> _loadImages() async {
    try {
      _groundImage  = await _loadImg('assets/ground.png');
      _carImage     = await _loadImg('assets/car.png');
      _carFlipImage = await _loadImg('assets/car1-1.png');
      _buildingImages['house']      = await _loadImg('assets/house1.png');
      _buildingImages['house-1']    = await _loadImg('assets/house1-1.png');
      _buildingImages['park']       = await _loadImg('assets/park.png');
      _buildingImages['park-1']     = await _loadImg('assets/park1-1.png');
      _buildingImages['police']     = await _loadImg('assets/police.png');
      _buildingImages['police-1']   = await _loadImg('assets/police1-1.png');
      _buildingImages['hospital']   = await _loadImg('assets/hospital.png');
      _buildingImages['hospital-1'] = await _loadImg('assets/hospital1-1.png');
      _buildingImages['towerpark']  = await _loadImg('assets/towerpark.png');
      _buildingImages['fire']       = await _loadImg('assets/fire.png');
      _buildingImages['fire-1']     = await _loadImg('assets/fire1-1.png');
      _buildingImages['landmark']   = await _loadImg('assets/landmark.png');
      _buildingImages['landmark-1'] = await _loadImg('assets/landmark1-1.png');
      _buildingImages['pondpark']   = await _loadImg('assets/pondpark.png');
      _buildingImages['pondpark-1'] = await _loadImg('assets/pondpark1-1.png');
      _buildingImages['oldapt']     = await _loadImg('assets/oldapt.png');
      _buildingImages['oldapt-1']   = await _loadImg('assets/oldapt1-1.png');
      _buildingImages['apt']        = await _loadImg('assets/apt.png');
      _buildingImages['apt-1']      = await _loadImg('assets/apt1-1.png');
      setState(() {});
    } catch (e) {
      debugPrint("❌ 로드 실패: $e");
    }
  }

  String _getBuildingKey(GameProvider provider, int idx) {
    final type = provider.placedBuildings[idx]!;
    if (_noRotation.contains(type)) return type;
    return provider.rotatedTiles.contains(idx) ? '$type-1' : type;
  }

  String _getPreviewKey() =>
      _previewRotated ? '$_selectedBuilding-1' : _selectedBuilding!;

  double _getBuildingH(String key) {
    final img = _buildingImages[key];
    if (img == null) return _bh;
    return img.height * _buildingScale;
  }

  bool get _isLandMode => _selectedBuilding == 'land';

  void _onTileTap(int idx) {
    if (_selectedBuilding == null || _isLandMode) return;
    if (_previewTile == idx) return;
    setState(() { _previewTile = idx; _previewRotated = false; });
  }

  void _confirmPlace() {
    if (_previewTile == null || _selectedBuilding == null || _isLandMode) return;
    context.read<GameProvider>().placeBuilding(
        _previewTile!, _selectedBuilding!, _previewRotated);
    setState(() { _previewTile = null; _previewRotated = false; _selectedBuilding = null; });
  }

  void _cancelPlace() {
    setState(() { _previewTile = null; _previewRotated = false; });
  }

  void _rotatePreview() {
    setState(() => _previewRotated = !_previewRotated);
  }

  void _onLandTap(int nx, int ny) {
    setState(() => _previewLand = (nx, ny));
  }

  void _confirmLand() {
    if (_previewLand == null) return;
    context.read<GameProvider>().useLandVoucher(_previewLand!.$1, _previewLand!.$2);
    setState(() { _previewLand = null; _selectedBuilding = null; });
  }

  void _cancelLand() {
    setState(() => _previewLand = null);
  }

  void _resetSelection() {
    setState(() {
      _selectedBuilding = null;
      _previewTile = null;
      _previewRotated = false;
      _previewLand = null;
    });
  }

  Widget _buildCar(Offset pos, ui.Image image) {
    return Positioned(
      left: pos.dx - _carSize / 2,
      top: pos.dy - _carSize / 2,
      child: CustomPaint(
        painter: _TilePainter(image: image),
        size: Size(_carSize, _carSize),
      ),
    );
  }

  void _resetView() {
    final size = MediaQuery.of(context).size;
    _transformController.value = Matrix4.translationValues(
      -((_originX + _groundW / 2) - size.width / 2),
      -((_originY + _groundH / 2) - size.height * 0.3),
      0.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider        = context.watch<GameProvider>();
    final groundGrid      = provider.groundGrid;
    final ownedBuildings  = provider.ownedBuildings;
    final placedBuildings = provider.placedBuildings;
    final landVouchers    = provider.landVouchers;
    final hasItems        = ownedBuildings.isNotEmpty || landVouchers > 0;
    final population      = provider.population;
    final happiness       = provider.happiness;

    final Map<int, Offset> tileAnchors = {};
    for (final pos in groundGrid) {
      final parts = pos.split(',');
      final gx = int.parse(parts[0]);
      final gy = int.parse(parts[1]);
      _addGroundAnchors(tileAnchors, gx, gy);
    }

    final Set<(int, int)> expansionSlots = {};
    if (_isLandMode) {
      for (final pos in groundGrid) {
        final parts = pos.split(',');
        final gx = int.parse(parts[0]);
        final gy = int.parse(parts[1]);
        for (final d in [(-1, 1), (1, 1)]) {
          final nx = gx + d.$1;
          final ny = gy + d.$2;
          if (!groundGrid.contains('$nx,$ny')) {
            expansionSlots.add((nx, ny));
          }
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("🏘 마을 전경"),
        actions: [
          IconButton(
            icon: const Icon(Icons.center_focus_strong),
            tooltip: '뷰 초기화',
            onPressed: _resetView,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 6,
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF87CEEB), Color(0xFFB8E4F9), Color(0xFF8BC34A)],
                      stops: [0.0, 0.6, 1.0],
                    ),
                  ),
                  child: _groundImage == null
                  ? const Center(child: CircularProgressIndicator())
                  : InteractiveViewer(
                      transformationController: _transformController,
                      constrained: false,
                      boundaryMargin: const EdgeInsets.all(double.infinity),
                      minScale: 0.1,
                      maxScale: 5.0,
                      child: SizedBox(
                        width: _canvasSize,
                        height: _canvasSize,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            for (final pos in (groundGrid.toList()
                              ..sort((a, b) {
                                final ay = int.parse(a.split(',')[1]);
                                final by = int.parse(b.split(',')[1]);
                                return ay.compareTo(by);
                              }))) ...[
                              () {
                                final parts = pos.split(',');
                                final gx = int.parse(parts[0]);
                                final gy = int.parse(parts[1]);
                                return Positioned(
                                  left: _groundLeft(gx),
                                  top: _groundTop(gy),
                                  child: CustomPaint(
                                    painter: _TilePainter(image: _groundImage!),
                                    size: const Size(_groundW, _groundH),
                                  ),
                                );
                              }(),
                            ],
                            AnimatedBuilder(
                              animation: _carController,
                              builder: (context, _) {
                                final routes = _allCarRoutes(groundGrid);
                                final t1 = _carController.value;

                                // 각 경로별 차 위치 계산
                                final carPositions = routes.map((r) {
                                  final t = (t1 + r.phase) % 1.0;
                                  final raw = _interpolate(r.pts, t);
                                  return (pos: Offset(raw.dx + _originX, raw.dy), isFlip: r.isFlip);
                                }).toList();

                                final sorted = tileAnchors.keys.toList()
                                  ..sort((a, b) => tileAnchors[a]!.dy.compareTo(tileAnchors[b]!.dy));

                                final drawnCars = List.filled(carPositions.length, false);
                                final widgets = <Widget>[];

                                for (final slot in expansionSlots) {
                                  final nx = slot.$1;
                                  final ny = slot.$2;
                                  final isPreview = _previewLand == slot;
                                  widgets.add(Positioned(
                                    left: _groundLeft(nx),
                                    top: _groundTop(ny),
                                    child: GestureDetector(
                                      onTap: () => _onLandTap(nx, ny),
                                      child: CustomPaint(
                                        painter: _GroundHighlightPainter(isPreview: isPreview),
                                        size: const Size(_groundW, _groundH),
                                      ),
                                    ),
                                  ));

                                  if (isPreview) {
                                    widgets.add(Positioned(
                                      left: _groundLeft(nx) + _groundW / 2 - 36,
                                      top: _groundTop(ny) + _groundH / 2,
                                      child: Row(
                                        children: [
                                          _actionBtn(icon: Icons.check, color: Colors.green, onTap: _confirmLand),
                                          const SizedBox(width: 8),
                                          _actionBtn(icon: Icons.close, color: Colors.red,   onTap: _cancelLand),
                                        ],
                                      ),
                                    ));
                                  }
                                }

                                for (final idx in sorted) {
                                  final anchor = tileAnchors[idx]!;

                                  for (int ci = 0; ci < carPositions.length; ci++) {
                                    if (!drawnCars[ci] && carPositions[ci].pos.dy < anchor.dy) {
                                      drawnCars[ci] = true;
                                      final img = carPositions[ci].isFlip ? _carFlipImage : _carImage;
                                      if (img != null) widgets.add(_buildCar(carPositions[ci].pos, img));
                                    }
                                  }

                                  if (!_isLandMode && _selectedBuilding != null && _previewTile != idx) {
                                    widgets.add(Positioned(
                                      left: anchor.dx - _bw / 2,
                                      top: anchor.dy - _th / 2,
                                      child: GestureDetector(
                                        onTap: () => _onTileTap(idx),
                                        child: CustomPaint(
                                          painter: _HighlightPainter(
                                              filled: placedBuildings.containsKey(idx)),
                                          size: Size(_bw, _th),
                                        ),
                                      ),
                                    ));
                                  }

                                  if (_previewTile != idx &&
                                      placedBuildings.containsKey(idx) &&
                                      _buildingImages[_getBuildingKey(provider, idx)] != null) {
                                    final key = _getBuildingKey(provider, idx);
                                    final bh  = _getBuildingH(key);
                                    widgets.add(Positioned(
                                      left: anchor.dx - _bw / 2,
                                      top: anchor.dy - bh + _th / 2,
                                      child: CustomPaint(
                                        painter: _TilePainter(image: _buildingImages[key]!),
                                        size: Size(_bw, bh),
                                      ),
                                    ));
                                  }

                                  if (!_isLandMode &&
                                      _previewTile == idx &&
                                      _selectedBuilding != null &&
                                      _buildingImages[_getPreviewKey()] != null) {
                                    final pk  = _getPreviewKey();
                                    final pbh = _getBuildingH(pk);
                                    widgets.add(Positioned(
                                      left: anchor.dx - _bw / 2,
                                      top: anchor.dy - pbh + _th / 2,
                                      child: Opacity(
                                        opacity: 0.5,
                                        child: CustomPaint(
                                          painter: _TilePainter(image: _buildingImages[pk]!),
                                          size: Size(_bw, pbh),
                                        ),
                                      ),
                                    ));
                                  }
                                }

                                for (int ci = 0; ci < carPositions.length; ci++) {
                                  if (!drawnCars[ci]) {
                                    final img = carPositions[ci].isFlip ? _carFlipImage : _carImage;
                                    if (img != null) widgets.add(_buildCar(carPositions[ci].pos, img));
                                  }
                                }

                                if (!_isLandMode && _previewTile != null &&
                                    tileAnchors.containsKey(_previewTile!)) {
                                  final pa = tileAnchors[_previewTile!]!;
                                  widgets.add(Positioned(
                                    left: pa.dx - 48,
                                    top: pa.dy + _th / 2 + 4,
                                    child: Row(
                                      children: [
                                        _actionBtn(icon: Icons.check,        color: Colors.green, onTap: _confirmPlace),
                                        const SizedBox(width: 4),
                                        _actionBtn(icon: Icons.rotate_right, color: Colors.blue,  onTap: _rotatePreview),
                                        const SizedBox(width: 4),
                                        _actionBtn(icon: Icons.close,        color: Colors.red,   onTap: _cancelPlace),
                                      ],
                                    ),
                                  ));
                                }

                                return Stack(children: widgets);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                ),
                Positioned(
                  top: 12, right: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _statCapsule("👥 $population명", const Color(0xFF4A7FBD)),
                      const SizedBox(height: 6),
                      _statCapsule(
                        "${_happinessEmoji(happiness)} $happiness%",
                        happiness < 30
                            ? Colors.red[400]!
                            : happiness < 70
                                ? Colors.grey[600]!
                                : const Color(0xFF4A9E4A),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SafeArea(
            top: false,
            child: Container(
              width: double.infinity,
              color: Colors.brown[100],
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "아이템 선택",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  if (_selectedBuilding != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _isLandMode ? "확장할 땅을 탭하세요!" : "타일을 탭해서 배치하세요!",
                        style: TextStyle(
                          fontSize: 12,
                          color: _isLandMode ? Colors.orange[700] : Colors.blue[600],
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 168,
                    child: !hasItems
                        ? Center(
                            child: Text(
                              "상점에서 아이템을 구매하세요!",
                              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                            ),
                          )
                        : GridView.count(
                            crossAxisCount: 2,
                            scrollDirection: Axis.horizontal,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            children: [
                              if (landVouchers > 0) _buildLandVoucherBtn(landVouchers),
                              ...ownedBuildings.map((id) {
                                final info = _buildingInfo[id];
                                if (info == null) return const SizedBox();
                                final qty = provider.quantity(id);
                                return _buildItemBtn(id, info['asset']!, info['label']!, qty: qty);
                              }),
                            ],
                          ),
                  ),
                  if (_selectedBuilding != null)
                    TextButton(
                      onPressed: _resetSelection,
                      child: const Text("선택 취소"),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCapsule(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: const TextStyle(
              color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildLandVoucherBtn(int count) {
    final isSelected = _isLandMode;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedBuilding = isSelected ? null : 'land';
        _previewTile = null;
        _previewRotated = false;
        _previewLand = null;
      }),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange[100] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.orange[400]! : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(child: Text("🏞", style: TextStyle(fontSize: 28))),
                SizedBox(height: 2),
                Center(child: Text("확장권", style: TextStyle(fontSize: 11))),
              ],
            ),
            if (count > 1)
              Positioned(
                top: 4, right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.orange[600],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text("$count",
                      style: const TextStyle(
                          fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn({required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 4, offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _buildItemBtn(String id, String assetPath, String label, {int qty = 0}) {
    final isSelected = _selectedBuilding == id;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedBuilding = isSelected ? null : id;
        _previewTile = null;
        _previewRotated = false;
        _previewLand = null;
      }),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[100] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue[400]! : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(assetPath, width: 32, height: 32, filterQuality: FilterQuality.none),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(fontSize: 10),
                overflow: TextOverflow.ellipsis,
                maxLines: 1),
          ],
        ),
      ),
    );
  }
}

class _TilePainter extends CustomPainter {
  final ui.Image image;
  _TilePainter({required this.image});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..filterQuality = FilterQuality.none,
    );
  }

  @override
  bool shouldRepaint(_TilePainter old) => old.image != image;
}

class _HighlightPainter extends CustomPainter {
  final bool filled;
  _HighlightPainter({this.filled = false});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(0, size.height / 2)
      ..close();
    canvas.drawPath(path, Paint()
      ..color = (filled ? Colors.green : Colors.yellow).withValues(alpha: 0.4)
      ..style = PaintingStyle.fill);
    canvas.drawPath(path, Paint()
      ..color = filled ? Colors.green[700]! : Colors.yellow[700]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(_HighlightPainter old) => old.filled != filled;
}

class _GroundHighlightPainter extends CustomPainter {
  final bool isPreview;
  const _GroundHighlightPainter({this.isPreview = false});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(256, -1)
      ..lineTo(508, 124)
      ..lineTo(256, 249)
      ..lineTo(5, 124)
      ..close();
    final fillColor   = isPreview ? Colors.green  : Colors.orange;
    final strokeColor = isPreview ? Colors.green[700]! : Colors.orange[700]!;
    canvas.drawPath(path, Paint()
      ..color = fillColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill);
    canvas.drawPath(path, Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4);
  }

  @override
  bool shouldRepaint(_GroundHighlightPainter old) => old.isPreview != isPreview;
}