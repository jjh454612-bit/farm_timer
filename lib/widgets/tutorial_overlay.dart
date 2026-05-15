import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../widgets/sprite_painter.dart';

/// darkOverlay: false면 어두운 배경 없이 대화창만 표시
class TutorialOverlay extends StatefulWidget {
  final Rect? highlightRect;
  final String message;
  final String nextLabel;
  final VoidCallback onNext;
  final bool darkOverlay;
  final bool showDialog;
  final ui.Image? charImage;
  final int charFrame;

  const TutorialOverlay({
    super.key,
    this.highlightRect,
    required this.message,
    required this.onNext,
    this.nextLabel = '▼',
    this.darkOverlay = true,
    this.showDialog = true,
    this.charImage,
    this.charFrame = 0,
  });

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  bool _arrowVisible = true;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _ctrl.addListener(() {
      if (mounted) setState(() => _arrowVisible = _ctrl.value > 0.5);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 어두운 배경 (구멍 포함)
        if (widget.darkOverlay)
          IgnorePointer(
            child: CustomPaint(
              size: MediaQuery.of(context).size,
              painter: _OverlayPainter(highlightRect: widget.highlightRect),
            ),
          ),

        // 하이라이트 영역 제외한 곳에서 탭 → onNext
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) {
            if (widget.highlightRect == null ||
                !widget.highlightRect!.contains(details.globalPosition)) {
              widget.onNext();
            }
            // highlight 영역 탭은 아래 위젯으로 pass-through
          },
          child: const SizedBox.expand(),
        ),

        // 하이라이트 노란 테두리 (깜빡임)
        if (widget.highlightRect != null)
          Positioned(
            left: widget.highlightRect!.left - 4,
            top: widget.highlightRect!.top - 4,
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _ctrl,
                builder: (context, child) => Container(
                  width: widget.highlightRect!.width + 8,
                  height: widget.highlightRect!.height + 8,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.yellow.withValues(
                          alpha: _arrowVisible ? 1.0 : 0.2),
                      width: 3,
                    ),
                  ),
                ),
              ),
            ),
          ),

        // 하단 레트로 대화창
        if (widget.showDialog)
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: IgnorePointer(
              child: Container(
                margin: EdgeInsets.fromLTRB(12, 12, 12,
                    12 + MediaQuery.of(context).padding.bottom),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0C8),
                  border: Border.all(color: const Color(0xFF3D5C28), width: 3),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5E6C8),
                            border: Border.all(
                                color: const Color(0xFF3D5C28), width: 2),
                          ),
                          child: widget.charImage == null
                              ? const SizedBox()
                              : CustomPaint(
                                  painter: SpritePainter(
                                    image: widget.charImage!,
                                    frame: widget.charFrame,
                                    totalFrames: 2,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.message,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF3D5C28),
                              height: 1.6,
                              fontFamily: 'NeoDunggeunmo',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        _arrowVisible ? widget.nextLabel : '  ',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF3D5C28),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _OverlayPainter extends CustomPainter {
  final Rect? highlightRect;
  _OverlayPainter({this.highlightRect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.65);
    if (highlightRect == null) {
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
      return;
    }
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(highlightRect!.inflate(4));
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_OverlayPainter old) =>
      old.highlightRect != highlightRect;
}