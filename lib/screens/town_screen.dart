import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

class TownScreen extends StatefulWidget {
  const TownScreen({super.key});

  @override
  State<TownScreen> createState() => _TownScreenState();
}

class RoadData {
  double x;
  double y;
  bool isRotated;
  String type;

  RoadData({required this.x, required this.y, this.isRotated = false, this.type = 'asphalt'});
}

class GrassData {
  final double x;
  final double y;
  final int type;

  GrassData({required this.x, required this.y, required this.type});
}

class _TownScreenState extends State<TownScreen> {
  ui.Image? _groundImage;
  ui.Image? _asphaltImage;
  ui.Image? _dirtImage;
  ui.Image? _grass1Image;
  ui.Image? _grass2Image;
  ui.Image? _grass3Image;
  ui.Image? _grass4Image;

  int _grassFrame = 0;
  Timer? _grassTimer;

  List<RoadData> _roads = [];
  List<GrassData> _grasses = [];

  String? _selectedItem;
  double? _dragX;
  double? _dragY;
  bool _dragIsRotated = false;
  bool _showGrid = false;

  static const double groundSize = 256;
  static const double roadW = 9;
  static const double roadH = 64;

  @override
  void initState() {
    super.initState();
    _loadImages();
    _generateGrass();
  }

  void _generateGrass() {
    final random = Random();
    _grasses = List.generate(30, (i) => GrassData(
      x: random.nextDouble() * (groundSize - 16),
      y: random.nextDouble() * (groundSize - 16),
      type: random.nextInt(4),
    ));
  }

  Future<ui.Image> _loadImage(String path) async {
    final data = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  Future<void> _loadImages() async {
    try {
      _groundImage = await _loadImage('assets/ground.png');
      _asphaltImage = await _loadImage('assets/asphaltroad.png');
      _dirtImage = await _loadImage('assets/dirtroad.png');
      _grass1Image = await _loadImage('assets/grass1.png');
      _grass2Image = await _loadImage('assets/grass2.png');
      _grass3Image = await _loadImage('assets/grass3.png');
      _grass4Image = await _loadImage('assets/grass4.png');

      setState(() {});

      _grassTimer = Timer.periodic(const Duration(milliseconds: 300), (_) {
        setState(() => _grassFrame = (_grassFrame + 1) % 4);
      });
    } catch (e) {
      print("❌ 로드 실패: $e");
    }
  }

  @override
  void dispose() {
    _grassTimer?.cancel();
    super.dispose();
  }

  double get _currentW => _dragIsRotated ? roadH : roadW;
  double get _currentH => _dragIsRotated ? roadW : roadH;

  bool get _isValidPlacement {
    if (_dragX == null || _dragY == null) return false;
    return _dragX! >= 0 &&
        _dragY! >= 0 &&
        _dragX! + _currentW <= groundSize &&
        _dragY! + _currentH <= groundSize;
  }

  void _updateDrag(Offset localPos) {
    setState(() {
      _showGrid = true;
      _dragX = (localPos.dx - _currentW / 2).floorToDouble().clamp(0.0, groundSize - _currentW);
      _dragY = (localPos.dy - _currentH / 2).floorToDouble().clamp(0.0, groundSize - _currentH);
    });
  }

  void _cancelPlacement() {
    setState(() {
      _dragX = null;
      _dragY = null;
      _showGrid = false;
      _dragIsRotated = false;
      _selectedItem = null;
    });
  }

  void _confirmPlacement() {
    if (!_isValidPlacement || _selectedItem == null) return;
    setState(() {
      _roads.add(RoadData(
        x: _dragX!,
        y: _dragY!,
        type: _selectedItem!,
        isRotated: _dragIsRotated,
      ));
      _dragX = null;
      _dragY = null;
      _showGrid = false;
      _dragIsRotated = false;
      _selectedItem = null;
    });
  }

  void _rotateDrag() {
    setState(() => _dragIsRotated = !_dragIsRotated);
  }

  ui.Image? _getGrassImage(int type) {
    switch (type) {
      case 0: return _grass1Image;
      case 1: return _grass2Image;
      case 2: return _grass3Image;
      case 3: return _grass4Image;
      default: return _grass1Image;
    }
  }

  ui.Image? _getRoadImage(String type) {
    return type == 'asphalt' ? _asphaltImage : _dirtImage;
  }

  @override
  Widget build(BuildContext context) {
    final isPlacing = _dragX != null && _dragY != null && _selectedItem != null;

    return Scaffold(
      appBar: AppBar(title: const Text("🏘 마을 전경")),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                flex: 6,
                child: _groundImage == null
                    ? const Center(child: CircularProgressIndicator())
                    : InteractiveViewer(
                        boundaryMargin: const EdgeInsets.all(200),
                        minScale: 0.5,
                        maxScale: 3.0,
                        panEnabled: !isPlacing,
                        scaleEnabled: true,
                        child: Center(
                          child: Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.001)
                              ..rotateX(-1.0),
                            child: GestureDetector(
                              onPanStart: _selectedItem != null
                                  ? (d) => _updateDrag(d.localPosition)
                                  : null,
                              onPanUpdate: _selectedItem != null
                                  ? (d) => _updateDrag(d.localPosition)
                                  : null,
                              child: SizedBox(
                                width: groundSize,
                                height: groundSize,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    // 바닥
                                    CustomPaint(
                                      painter: _TilePainter(image: _groundImage!),
                                      size: const Size(groundSize, groundSize),
                                    ),
                                    // 풀들
                                    for (final grass in _grasses)
                                      if (_getGrassImage(grass.type) != null)
                                        Positioned(
                                          left: grass.x,
                                          top: grass.y,
                                          child: CustomPaint(
                                            painter: _SpritePainter(
                                              image: _getGrassImage(grass.type)!,
                                              frame: _grassFrame,
                                              totalFrames: 4,
                                            ),
                                            size: const Size(16, 16),
                                          ),
                                        ),
                                    // 그리드
                                    if (_showGrid)
                                      CustomPaint(
                                        painter: _GridPainter(groundSize: groundSize),
                                        size: const Size(groundSize, groundSize),
                                      ),
                                    // 배치된 도로들
                                    for (final road in _roads)
                                      Positioned(
                                        left: road.x,
                                        top: road.y,
                                        child: _getRoadImage(road.type) != null
                                            ? CustomPaint(
                                                painter: _TilePainter(
                                                  image: _getRoadImage(road.type)!,
                                                ),
                                                size: road.isRotated
                                                    ? const Size(roadH, roadW)
                                                    : const Size(roadW, roadH),
                                              )
                                            : const SizedBox(),
                                      ),
                                    // 드래그 미리보기
                                    if (isPlacing)
                                      Positioned(
                                        left: _dragX!,
                                        top: _dragY!,
                                        child: Opacity(
                                          opacity: 0.6,
                                          child: _getRoadImage(_selectedItem!) != null
                                              ? CustomPaint(
                                                  painter: _TilePainter(
                                                    image: _getRoadImage(_selectedItem!)!,
                                                  ),
                                                  size: Size(_currentW, _currentH),
                                                )
                                              : const SizedBox(),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
              // 하단 아이템
              Expanded(
                flex: 4,
                child: Container(
                  color: Colors.brown[100],
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      const Text(
                        "아이템",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildItemButton(
                            label: "아스팔트",
                            emoji: "🛣️",
                            isSelected: _selectedItem == 'asphalt',
                            onTap: () => setState(() {
                              _selectedItem = _selectedItem == 'asphalt' ? null : 'asphalt';
                              _showGrid = false;
                              _dragX = null;
                              _dragY = null;
                            }),
                          ),
                          const SizedBox(width: 12),
                          _buildItemButton(
                            label: "흙길",
                            emoji: "🟫",
                            isSelected: _selectedItem == 'dirt',
                            onTap: () => setState(() {
                              _selectedItem = _selectedItem == 'dirt' ? null : 'dirt';
                              _showGrid = false;
                              _dragX = null;
                              _dragY = null;
                            }),
                          ),
                        ],
                      ),
                      if (_selectedItem != null)
                        const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: Text(
                            "땅 위에 드래그해서 위치를 잡아주세요!",
                            style: TextStyle(fontSize: 13, color: Colors.blue),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // 배치 버튼들 - Transform 밖에 고정
          if (isPlacing)
            Positioned(
              bottom: MediaQuery.of(context).size.height * 0.42,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 회전 버튼
                  GestureDetector(
                    onTap: _rotateDrag,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.rotate_right, size: 28),
                    ),
                  ),
                  const SizedBox(width: 20),
                  // 체크 버튼
                  GestureDetector(
                    onTap: _isValidPlacement ? _confirmPlacement : null,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: _isValidPlacement ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.check, size: 28, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 20),
                  // X 버튼
                  GestureDetector(
                    onTap: _cancelPlacement,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.close, size: 28, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildItemButton({
    required String label,
    required String emoji,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
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

class _GridPainter extends CustomPainter {
  final double groundSize;

  _GridPainter({required this.groundSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    for (int i = 0; i <= groundSize; i++) {
      canvas.drawLine(Offset(i.toDouble(), 0), Offset(i.toDouble(), groundSize), paint);
      canvas.drawLine(Offset(0, i.toDouble()), Offset(groundSize, i.toDouble()), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}

class _TilePainter extends CustomPainter {
  final ui.Image image;
  _TilePainter({required this.image});

  @override
  void paint(Canvas canvas, Size size) {
    final src = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(image, src, dst, Paint()..filterQuality = FilterQuality.none);
  }

  @override
  bool shouldRepaint(_TilePainter old) => old.image != image;
}

class _SpritePainter extends CustomPainter {
  final ui.Image image;
  final int frame;
  final int totalFrames;

  _SpritePainter({
    required this.image,
    required this.frame,
    required this.totalFrames,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final frameWidth = image.width / totalFrames;
    final src = Rect.fromLTWH(frame * frameWidth, 0, frameWidth, image.height.toDouble());
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(image, src, dst, Paint()..filterQuality = FilterQuality.none);
  }

  @override
  bool shouldRepaint(_SpritePainter old) => old.frame != frame;
}