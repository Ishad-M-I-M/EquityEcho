import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class TextFlDotPainter extends FlDotPainter {
  final String text;
  final Color color;
  final Color textColor;
  final double radius;

  TextFlDotPainter({
    required this.text,
    required this.color,
    this.textColor = Colors.white,
    this.radius = 8,
  });

  @override
  void draw(Canvas canvas, FlSpot spot, Offset offsetInCanvas) {
    // Draw background circle
    final paint = Paint()..color = color;
    canvas.drawCircle(offsetInCanvas, radius, paint);

    // Draw text
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: textColor,
          fontSize: radius * 1.2,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        offsetInCanvas.dx - textPainter.width / 2,
        offsetInCanvas.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  Size getSize(FlSpot spot) {
    return Size(radius * 2, radius * 2);
  }

  @override
  Color get mainColor => color;

  @override
  FlDotPainter lerp(FlDotPainter a, FlDotPainter b, double t) {
    if (a is TextFlDotPainter && b is TextFlDotPainter) {
      return TextFlDotPainter(
        text: b.text,
        color: Color.lerp(a.color, b.color, t) ?? b.color,
        textColor: Color.lerp(a.textColor, b.textColor, t) ?? b.textColor,
        radius: a.radius + (b.radius - a.radius) * t,
      );
    }
    return b;
  }

  @override
  List<Object?> get props => [text, color, textColor, radius];
}
