import 'package:flutter/material.dart';

class GridBackgroundPainter extends CustomPainter {
  final Color lineColor;
  final double gridSpacing;

  const GridBackgroundPainter({
    required this.lineColor,
    this.gridSpacing = 40.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 0.5;

    for (double x = 0; x < size.width; x += gridSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += gridSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant GridBackgroundPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor || oldDelegate.gridSpacing != gridSpacing;
  }
}
