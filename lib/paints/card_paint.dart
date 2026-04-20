import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  CardPaintContainer  (shape clipper – unchanged)
// ─────────────────────────────────────────────
class CardPaintContainer extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(size.width * 0.1434769, size.height * 0.9999155)
      ..lineTo(size.width * 0.8565231, size.height * 0.9999155)
      ..lineTo(size.width, size.height * 0.8565237)
      ..lineTo(size.width, size.height * 0.1434763)
      ..lineTo(size.width * 0.8565231, 0)
      ..lineTo(size.width * 0.1434769, 0)
      ..lineTo(0, size.height * 0.1434763)
      ..lineTo(0, size.height * 0.8565237)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// ─────────────────────────────────────────────
//  CardBorderPainter  – now accepts live opacity
// ─────────────────────────────────────────────
class CardBorderPainter extends CustomPainter {
  /// 0.0 … 1.0  – driven by the glow-pulse animation.
  final double opacity;

  const CardBorderPainter({this.opacity = 0.3});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.1434769, size.height * 0.9999155)
      ..lineTo(size.width * 0.8565231, size.height * 0.9999155)
      ..lineTo(size.width, size.height * 0.8565237)
      ..lineTo(size.width, size.height * 0.1434763)
      ..lineTo(size.width * 0.8565231, 0)
      ..lineTo(size.width * 0.1434769, 0)
      ..lineTo(0, size.height * 0.1434763)
      ..lineTo(0, size.height * 0.8565237)
      ..close();

    // Outer soft glow (behind the crisp line)
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Crisp border line
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(CardBorderPainter old) => old.opacity != opacity;
}