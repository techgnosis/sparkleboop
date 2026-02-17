import 'dart:math';
import 'package:flutter/material.dart';
import '../game/jewel.dart';

class JewelPainter extends CustomPainter {
  final JewelType type;
  final bool selected;

  JewelPainter({required this.type, this.selected = false});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.38;

    final paint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    switch (type) {
      case JewelType.diamond:
        // White/light blue diamond shape
        paint.shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Colors.lightBlue.shade200],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
        strokePaint.color = Colors.lightBlue.shade400;
        _drawDiamond(canvas, center, radius, paint, strokePaint);

      case JewelType.ruby:
        // Red circle with facets
        paint.shader = RadialGradient(
          center: const Alignment(-0.3, -0.3),
          colors: [Colors.red.shade300, Colors.red.shade900],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
        strokePaint.color = Colors.red.shade900;
        _drawCircleGem(canvas, center, radius, paint, strokePaint);

      case JewelType.emerald:
        // Green rectangle/octagon
        paint.shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.green.shade300, Colors.green.shade800],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
        strokePaint.color = Colors.green.shade900;
        _drawOctagon(canvas, center, radius, paint, strokePaint);

      case JewelType.sapphire:
        // Blue triangle
        paint.shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blue.shade300, Colors.blue.shade800],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
        strokePaint.color = Colors.blue.shade900;
        _drawTriangle(canvas, center, radius, paint, strokePaint);

      case JewelType.topaz:
        // Orange/yellow square
        paint.shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.yellow.shade300, Colors.orange.shade700],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
        strokePaint.color = Colors.orange.shade900;
        _drawSquare(canvas, center, radius, paint, strokePaint);

      case JewelType.amethyst:
        // Purple hexagon
        paint.shader = RadialGradient(
          center: const Alignment(-0.2, -0.2),
          colors: [Colors.purple.shade300, Colors.purple.shade900],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
        strokePaint.color = Colors.purple.shade900;
        _drawHexagon(canvas, center, radius, paint, strokePaint);

      case JewelType.pearl:
        // White/pink circle with sheen
        paint.shader = RadialGradient(
          center: const Alignment(-0.3, -0.3),
          radius: 0.8,
          colors: [Colors.white, Colors.pink.shade100, Colors.pink.shade300],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
        strokePaint.color = Colors.pink.shade400;
        _drawStar(canvas, center, radius, paint, strokePaint);
    }

    // Draw highlight/sparkle
    _drawHighlight(canvas, center, radius);

    // Selection indicator
    if (selected) {
      final selPaint = Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.white
        ..strokeWidth = 3.0;
      canvas.drawCircle(center, radius + 3, selPaint);
    }
  }

  void _drawDiamond(Canvas canvas, Offset c, double r, Paint fill, Paint stroke) {
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..lineTo(c.dx + r, c.dy)
      ..lineTo(c.dx, c.dy + r)
      ..lineTo(c.dx - r, c.dy)
      ..close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
    // Facet line
    final facet = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white.withValues(alpha: 0.4)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(c.dx - r, c.dy), Offset(c.dx + r, c.dy), facet);
  }

  void _drawCircleGem(Canvas canvas, Offset c, double r, Paint fill, Paint stroke) {
    canvas.drawCircle(c, r, fill);
    canvas.drawCircle(c, r, stroke);
  }

  void _drawOctagon(Canvas canvas, Offset c, double r, Paint fill, Paint stroke) {
    final path = Path();
    final cut = r * 0.4;
    path.moveTo(c.dx - r + cut, c.dy - r);
    path.lineTo(c.dx + r - cut, c.dy - r);
    path.lineTo(c.dx + r, c.dy - r + cut);
    path.lineTo(c.dx + r, c.dy + r - cut);
    path.lineTo(c.dx + r - cut, c.dy + r);
    path.lineTo(c.dx - r + cut, c.dy + r);
    path.lineTo(c.dx - r, c.dy + r - cut);
    path.lineTo(c.dx - r, c.dy - r + cut);
    path.close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  void _drawTriangle(Canvas canvas, Offset c, double r, Paint fill, Paint stroke) {
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..lineTo(c.dx + r, c.dy + r * 0.7)
      ..lineTo(c.dx - r, c.dy + r * 0.7)
      ..close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  void _drawSquare(Canvas canvas, Offset c, double r, Paint fill, Paint stroke) {
    final rr = r * 0.85;
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: c, width: rr * 2, height: rr * 2),
      const Radius.circular(4),
    );
    canvas.drawRRect(rect, fill);
    canvas.drawRRect(rect, stroke);
  }

  void _drawHexagon(Canvas canvas, Offset c, double r, Paint fill, Paint stroke) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (pi / 3) * i - pi / 6;
      final x = c.dx + r * cos(angle);
      final y = c.dy + r * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  void _drawStar(Canvas canvas, Offset c, double r, Paint fill, Paint stroke) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final outerAngle = (2 * pi / 5) * i - pi / 2;
      final innerAngle = outerAngle + pi / 5;
      final outerX = c.dx + r * cos(outerAngle);
      final outerY = c.dy + r * sin(outerAngle);
      final innerR = r * 0.45;
      final innerX = c.dx + innerR * cos(innerAngle);
      final innerY = c.dy + innerR * sin(innerAngle);
      if (i == 0) {
        path.moveTo(outerX, outerY);
      } else {
        path.lineTo(outerX, outerY);
      }
      path.lineTo(innerX, innerY);
    }
    path.close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  void _drawHighlight(Canvas canvas, Offset c, double r) {
    final highlight = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white.withValues(alpha: 0.3);
    canvas.drawCircle(
      Offset(c.dx - r * 0.2, c.dy - r * 0.2),
      r * 0.25,
      highlight,
    );
  }

  @override
  bool shouldRepaint(covariant JewelPainter oldDelegate) {
    return oldDelegate.type != type || oldDelegate.selected != selected;
  }
}
