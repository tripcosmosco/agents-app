import 'package:flutter/material.dart';

/// Pixel-perfect vector reproduction of the official 4-color Google "G" logo
class GoogleLogo extends StatelessWidget {
  final double size;

  const GoogleLogo({super.key, this.size = 20.0});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double s = w < h ? w : h;
    final double scale = s / 48.0;

    canvas.save();
    canvas.scale(scale, scale);

    // Blue Path (Right horizontal bar and arc)
    final bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    final bluePath = Path()
      ..moveTo(46.98, 24.55)
      ..cubicTo(46.98, 22.92, 46.83, 21.34, 46.56, 19.82)
      ..lineTo(24.0, 19.82)
      ..lineTo(24.0, 28.84)
      ..lineTo(36.94, 28.84)
      ..cubicTo(36.38, 31.83, 34.69, 34.37, 32.14, 36.08)
      ..lineTo(32.14, 42.1)
      ..lineTo(39.91, 42.1)
      ..cubicTo(44.46, 37.91, 46.98, 31.8, 46.98, 24.55)
      ..close();
    canvas.drawPath(bluePath, bluePaint);

    // Green Path (Bottom arc)
    final greenPaint = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.fill;
    final greenPath = Path()
      ..moveTo(24.0, 48.0)
      ..cubicTo(30.48, 48.0, 35.91, 45.85, 39.91, 42.1)
      ..lineTo(32.14, 36.08)
      ..cubicTo(29.98, 37.53, 27.24, 38.38, 24.0, 38.38)
      ..cubicTo(17.75, 38.38, 12.44, 34.13, 10.54, 28.42)
      ..lineTo(2.5, 28.42)
      ..lineTo(2.5, 34.65)
      ..cubicTo(6.46, 42.52, 14.6, 48.0, 24.0, 48.0)
      ..close();
    canvas.drawPath(greenPath, greenPaint);

    // Yellow Path (Left bottom arc)
    final yellowPaint = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.fill;
    final yellowPath = Path()
      ..moveTo(10.54, 28.42)
      ..cubicTo(10.06, 26.99, 9.79, 25.46, 9.79, 23.88)
      ..cubicTo(9.79, 22.3, 10.06, 20.77, 10.54, 19.34)
      ..lineTo(10.54, 13.11)
      ..lineTo(2.5, 13.11)
      ..cubicTo(0.91, 16.28, 0.0, 19.97, 0.0, 23.88)
      ..cubicTo(0.0, 27.79, 0.91, 31.48, 2.5, 34.65)
      ..lineTo(10.54, 28.42)
      ..close();
    canvas.drawPath(yellowPath, yellowPaint);

    // Red Path (Top arc)
    final redPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.fill;
    final redPath = Path()
      ..moveTo(24.0, 9.38)
      ..cubicTo(27.52, 9.38, 30.68, 10.59, 33.17, 12.97)
      ..lineTo(40.08, 6.06)
      ..cubicTo(35.88, 2.3, 30.45, 0.0, 24.0, 0.0)
      ..cubicTo(14.6, 0.0, 6.46, 5.48, 2.5, 13.11)
      ..lineTo(10.54, 19.34)
      ..cubicTo(12.44, 13.63, 17.75, 9.38, 24.0, 9.38)
      ..close();
    canvas.drawPath(redPath, redPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
