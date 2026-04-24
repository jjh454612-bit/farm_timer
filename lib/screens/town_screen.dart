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

class _TownScreenState extends State<TownScreen>
    with TickerProviderStateMixin {
  ui.Image? _groundImage;
  ui.Image? _carImage;
  ui.Image? _carFlipImage;
  final Map<String, ui.Image?> _buildingImages = {};
  final Map<int, String> _placedBuildings = {};
  final Set<int> _rotatedTiles = {};
  String? _selectedBuilding;

  int? _previewTile;
  bool _previewRotated = false;

  static const double _groundScale = 2.0;
  static const double _buildingScale = 3.0;
  static const double _tileScale = 3.0;
  static const double _carScale = 1.0;

  static const double _groundW = 256 * _groundScale;
  static const double _groundH = 148 * _groundScale;
  static const double _extraH = 100;

  static List<Offset> get _tileAnchors => [
    Offset(258, 55 + _extraH),
    Offset(110, 128 + _extraH),
    Offset(400, 128 + _extraH),
    Offset(256, 199 + _extraH),
  ];

  double get _bw => 64 * _buildingScale;
  double get _bh => 64 * _buildingScale;
  double get _th => 32 * _tileScale;
  double get _carSize => 32 * _carScale;

  static const Map<String, Map<String, String>> _buildingInfo = {
    'house':    {'emoji': '🏠', 'label': '집'},
    'park':     {'emoji': '🌳', 'label': '공원'},
    'police':   {'emoji': '🚔', 'label': '경찰서'},
    'hospital': {'emoji': '🏥', 'label': '병원'},
  };

  late AnimationController _carController;
  late Animation<Offset> _carAnim;
  late AnimationController _carFlipController;
  late Animation<Offset> _carFlipAnim;

  final TransformationController _transformController =
      TransformationController();

  @override
  void initState() {
    super.initState();
    _loadImages();

    _carController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();
    _carAnim = Tween<Offset>(
      begin: Offset(400, 180 + _extraH),
      end: Offset(130, 50 + _extraH),
    ).animate(CurvedAnimation(
      parent: _carController,
      curve: Curves.linear,
    ));

    _carFlipController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();
    _carFlipAnim = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween(
          begin: Offset(160, 180 + _extraH),
          end: Offset(226, 146 + _extraH),
        ),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: ConstantTween(Offset(226, 146 + _extraH)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: Offset(226, 146 + _extraH),
          end: Offset(400, 60 + _extraH),
        ),
        weight: 40,
      ),
    ]).animate(CurvedAnimation(
      parent: _carFlipController,
      curve: Curves.linear,
    ));
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
      _groundImage = await _loadImg('assets/ground.png');
      _carImage = await _loadImg('assets/car.png');
      _carFlipImage = await _loadImg('assets/car1-1.png');
      _buildingImages['house'] = await _loadImg('assets/house1.png');
      _buildingImages['house-1'] = await _loadImg('assets/house1-1.png');
      _buildingImages['park'] = await _loadImg('assets/park.png');
      _buildingImages['park-1'] = await _loadImg('assets/park1-1.png');
      _buildingImages['police'] = await _loadImg('assets/police.png');
      _buildingImages['police-1'] = await _loadImg('assets/police1-1.png');
      _buildingImages['hospital'] = await _loadImg('assets/hospital.png');
      _buildingImages['hospital-1'] = await _loadImg('assets/hospital1-1.png');
      setState(() {});
    } catch (e) {
      debugPrint("❌ 로드 실패: $e");
    }
  }

  bool _isOnGround(Offset pos) {
    return pos.dx >= 0 &&
        pos.dx <= _groundW &&
        pos.dy >= _extraH &&
        pos.dy <= _groundH + _extraH;
  }

  String _getBuildingKey(int idx) {
    final type = _placedBuildings[idx]!;
    return _rotatedTiles.contains(idx) ? '$type-1' : type;
  }

  String _getPreviewKey() {
    return _previewRotated ? '$_selectedBuilding-1' : _selectedBuilding!;
  }

  void _onTileTap(int idx) {
    if (_selectedBuilding == null) return;
    if (_previewTile == idx) return;
    setState(() {
      _previewTile = idx;
      _previewRotated = false;
    });
  }

  void _confirmPlace() {
    if (_previewTile == null || _selectedBuilding == null) return;
    setState(() {
      _placedBuildings[_previewTile!] = _selectedBuilding!;
      if (_previewRotated) {
        _rotatedTiles.add(_previewTile!);
      } else {
        _rotatedTiles.remove(_previewTile!);
      }
      _previewTile = null;
      _previewRotated = false;
      _selectedBuilding = null;
    });
  }

  void _cancelPlace() {
    setState(() {
      _previewTile = null;
      _previewRotated = false;
    });
  }

  void _rotatePreview() {
    setState(() {
      _previewRotated = !_previewRotated;
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
    _transformController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    final ownedBuildings = context.watch<GameProvider>().ownedBuildings;

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
            child: _groundImage == null
                ? const Center(child: CircularProgressIndicator())
                : InteractiveViewer(
                    transformationController: _transformController,
                    minScale: 0.5,
                    maxScale: 5.0,
                    boundaryMargin: const EdgeInsets.all(200),
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: SizedBox(
                          width: _groundW,
                          height: _groundH + _extraH,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Positioned(
                                top: _extraH,
                                child: CustomPaint(
                                  painter: _TilePainter(image: _groundImage!),
                                  size: const Size(_groundW, _groundH),
                                ),
                              ),
                              AnimatedBuilder(
                                animation: Listenable.merge(
                                    [_carAnim, _carFlipAnim]),
                                builder: (context, _) {
                                  final carPos = _carAnim.value;
                                  final carFlipPos = _carFlipAnim.value;
                                  final sorted = List.generate(4, (i) => i)
                                    ..sort((a, b) => _tileAnchors[a]
                                        .dy
                                        .compareTo(_tileAnchors[b].dy));

                                  bool carDrawn = false;
                                  bool carFlipDrawn = false;
                                  final widgets = <Widget>[];

                                  for (final idx in sorted) {
                                    if (!carDrawn &&
                                        carPos.dy < _tileAnchors[idx].dy) {
                                      carDrawn = true;
                                      if (_carImage != null && _isOnGround(carPos)) {
                                        widgets.add(_buildCar(carPos, _carImage!));
                                      }
                                    }
                                    if (!carFlipDrawn &&
                                        carFlipPos.dy < _tileAnchors[idx].dy) {
                                      carFlipDrawn = true;
                                      if (_carFlipImage != null && _isOnGround(carFlipPos)) {
                                        widgets.add(_buildCar(carFlipPos, _carFlipImage!));
                                      }
                                    }

                                    if (_selectedBuilding != null &&
                                        _previewTile != idx) {
                                      widgets.add(Positioned(
                                        left: _tileAnchors[idx].dx - _bw / 2,
                                        top: _tileAnchors[idx].dy - _th / 2,
                                        child: GestureDetector(
                                          onTap: () => _onTileTap(idx),
                                          child: CustomPaint(
                                            painter: _HighlightPainter(
                                              filled: _placedBuildings.containsKey(idx),
                                            ),
                                            size: Size(_bw, _th),
                                          ),
                                        ),
                                      ));
                                    }

                                    if (_previewTile != idx &&
                                        _placedBuildings.containsKey(idx) &&
                                        _buildingImages[_getBuildingKey(idx)] != null) {
                                      widgets.add(Positioned(
                                        left: _tileAnchors[idx].dx - _bw / 2,
                                        top: _tileAnchors[idx].dy - _bh + _th / 2,
                                        child: CustomPaint(
                                          painter: _TilePainter(
                                            image: _buildingImages[_getBuildingKey(idx)]!,
                                          ),
                                          size: Size(_bw, _bh),
                                        ),
                                      ));
                                    }

                                    if (_previewTile == idx &&
                                        _selectedBuilding != null &&
                                        _buildingImages[_getPreviewKey()] != null) {
                                      widgets.add(Positioned(
                                        left: _tileAnchors[idx].dx - _bw / 2,
                                        top: _tileAnchors[idx].dy - _bh + _th / 2,
                                        child: Opacity(
                                          opacity: 0.5,
                                          child: CustomPaint(
                                            painter: _TilePainter(
                                              image: _buildingImages[_getPreviewKey()]!,
                                            ),
                                            size: Size(_bw, _bh),
                                          ),
                                        ),
                                      ));
                                    }
                                  }

                                  if (!carDrawn && _carImage != null && _isOnGround(carPos)) {
                                    widgets.add(_buildCar(carPos, _carImage!));
                                  }
                                  if (!carFlipDrawn && _carFlipImage != null && _isOnGround(carFlipPos)) {
                                    widgets.add(_buildCar(carFlipPos, _carFlipImage!));
                                  }

                                  if (_previewTile != null) {
                                    widgets.add(Positioned(
                                      left: _tileAnchors[_previewTile!].dx - 48,
                                      top: _tileAnchors[_previewTile!].dy + _th / 2 + 4,
                                      child: Row(
                                        children: [
                                          _actionBtn(
                                            icon: Icons.check,
                                            color: Colors.green,
                                            onTap: _confirmPlace,
                                          ),
                                          const SizedBox(width: 4),
                                          _actionBtn(
                                            icon: Icons.rotate_right,
                                            color: Colors.blue,
                                            onTap: _rotatePreview,
                                          ),
                                          const SizedBox(width: 4),
                                          _actionBtn(
                                            icon: Icons.close,
                                            color: Colors.red,
                                            onTap: _cancelPlace,
                                          ),
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
                  ),
          ),
          Expanded(
            flex: 4,
            child: Container(
              width: double.infinity,
              color: Colors.brown[100],
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "건물 선택",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  if (_selectedBuilding != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        "타일을 탭해서 배치하세요!",
                        style: TextStyle(fontSize: 12, color: Colors.blue[600]),
                      ),
                    ),
                  const SizedBox(height: 12),
                  ownedBuildings.isEmpty
                      ? Text(
                          "상점에서 건물을 구매하세요!",
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        )
                      : Scrollbar(
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                            child: Row(
                              children: ownedBuildings.map((id) {
                                final info = _buildingInfo[id];
                                if (info == null) return const SizedBox();
                                return Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: _buildItemBtn(
                                    id,
                                    info['emoji']!,
                                    info['label']!,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                  if (_selectedBuilding != null) ...[
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => setState(() {
                        _selectedBuilding = null;
                        _previewTile = null;
                        _previewRotated = false;
                      }),
                      child: const Text("선택 취소"),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _buildItemBtn(String id, String emoji, String label) {
    final isSelected = _selectedBuilding == id;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedBuilding = isSelected ? null : id;
        _previewTile = null;
        _previewRotated = false;
      }),
      child: Container(
        width: 70,
        height: 70,
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
            Text(emoji, style: const TextStyle(fontSize: 28)),
            Text(label, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

extension WidgetLet on Widget {
  T let<T>(T Function(Widget) block) => block(this);
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

    canvas.drawPath(
      path,
      Paint()
        ..color =
            (filled ? Colors.green : Colors.yellow).withValues(alpha: 0.4)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = filled ? Colors.green[700]! : Colors.yellow[700]!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_HighlightPainter old) => old.filled != filled;
}