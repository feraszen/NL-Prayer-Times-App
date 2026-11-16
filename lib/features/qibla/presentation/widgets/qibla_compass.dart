import 'dart:math' as math;
import 'package:flutter/material.dart';

class QiblaCompass extends StatelessWidget {
  final double qiblaDirection;
  final double heading;
  const QiblaCompass({
    super.key,
    required this.qiblaDirection,
    required this.heading,
  });
  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 1,
    child: CustomPaint(
      painter: _CompassPainter(qiblaDirection, heading),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            const CustomPaint(size: Size(60, 65), painter: _KaabaPainter()),
            const SizedBox(height: 10),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                '${qiblaDirection.toStringAsFixed(0)}°',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _CompassPainter extends CustomPainter {
  final double bearing, heading;
  const _CompassPainter(this.bearing, this.heading);
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero), r = size.shortestSide * .46;
    canvas.drawCircle(
      c,
      r + 8,
      Paint()..color = const Color(0xFF3F8CFF).withValues(alpha: .15),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFF163F6B), Color(0xFF051C37)],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = const Color(0xFFF0F5FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7,
    );
    canvas.drawCircle(
      c,
      r - 12,
      Paint()
        ..color = const Color(0xFF477BAA)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    canvas.drawCircle(
      c,
      r * .65,
      Paint()
        ..color = const Color(0xFF235182).withValues(alpha: .4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    for (var i = 0; i < 120; i++) {
      final a = (i * 3 - heading - 90) * math.pi / 180;
      final major = i % 10 == 0;
      final outer = r - 19, inner = outer - (major ? 13 : 5);
      canvas.drawLine(
        c + Offset(math.cos(a) * outer, math.sin(a) * outer),
        c + Offset(math.cos(a) * inner, math.sin(a) * inner),
        Paint()
          ..color = Colors.white.withValues(alpha: major ? .95 : .5)
          ..strokeWidth = major ? 1.8 : .8,
      );
    }
    for (var i = 0; i < 4; i++) {
      final a = (i * 90 - heading - 90) * math.pi / 180;
      final pos = c + Offset(math.cos(a) * r * .76, math.sin(a) * r * .76);
      final text = TextPainter(
        text: TextSpan(
          text: ['N', 'E', 'S', 'W'][i],
          style: const TextStyle(
            fontFamily: 'IBM Plex Sans Arabic',
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(canvas, pos - Offset(text.width / 2, text.height / 2));
    }
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate((bearing - heading) * math.pi / 180);
    final arrow = Path()
      ..moveTo(0, -r + 1)
      ..lineTo(-13, -r + 39)
      ..lineTo(0, -r + 31)
      ..lineTo(13, -r + 39)
      ..close();
    canvas.drawShadow(arrow, const Color(0xFF061D3C), 4, true);
    canvas.drawPath(arrow, Paint()..color = const Color(0xFFD4AF37));
    canvas.restore();
    canvas.drawPath(
      Path()
        ..moveTo(c.dx - 5, 3)
        ..lineTo(c.dx + 5, 3)
        ..lineTo(c.dx, 11)
        ..close(),
      Paint()..color = const Color(0xFF27AE60),
    );
  }

  @override
  bool shouldRepaint(covariant _CompassPainter old) =>
      old.heading != heading || old.bearing != bearing;
}

class _KaabaPainter extends CustomPainter {
  const _KaabaPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawPath(
      Path()
        ..moveTo(0, h * .15)
        ..lineTo(w * .48, 0)
        ..lineTo(w, h * .16)
        ..lineTo(w, h * .87)
        ..lineTo(w * .48, h)
        ..lineTo(0, h * .85)
        ..close(),
      Paint()..color = const Color(0xFF071321),
    );
    canvas.drawPath(
      Path()
        ..moveTo(w * .48, 0)
        ..lineTo(w, h * .16)
        ..lineTo(w, h * .87)
        ..lineTo(w * .48, h)
        ..close(),
      Paint()..color = const Color(0xFF020D1B),
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, h * .27)
        ..lineTo(w * .48, h * .13)
        ..lineTo(w, h * .28)
        ..lineTo(w, h * .38)
        ..lineTo(w * .48, h * .23)
        ..lineTo(0, h * .37)
        ..close(),
      Paint()..color = const Color(0xFFD4AF37),
    );
    canvas.drawLine(
      Offset(w * .48, h * .24),
      Offset(w * .48, h),
      Paint()
        ..color = Colors.white12
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _KaabaPainter old) => false;
}
