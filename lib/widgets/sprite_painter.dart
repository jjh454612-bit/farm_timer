import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class SpritePainter extends CustomPainter {
  final ui.Image image;
  final int frame;
  final int totalFrames;

  SpritePainter({
    required this.image,
    required this.frame,
    required this.totalFrames,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final frameWidth = image.width / totalFrames;
    final src = Rect.fromLTWH(
      frame * frameWidth, 0, frameWidth, image.height.toDouble(),
    );
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(image, src, dst, Paint()..filterQuality = FilterQuality.none);
  }

  @override
  bool shouldRepaint(SpritePainter old) => old.frame != frame;
}