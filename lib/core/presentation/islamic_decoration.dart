import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

class IslamicBackdrop extends StatelessWidget {
  final Widget child;
  final bool mosque;
  const IslamicBackdrop({super.key, required this.child, this.mosque = false});
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: Theme.of(context).brightness == Brightness.dark
            ? const [Color(0xFF091B34), Color(0xFF102D50), Color(0xFF143B65)]
            : const [
                Color(0xFF061D3C),
                AppColors.royalBlue,
                AppColors.deepSkyBlue,
              ],
      ),
    ),
    child: CustomPaint(
      painter: _IslamicPainter(mosque: mosque),
      child: child,
    ),
  );
}

class _IslamicPainter extends CustomPainter {
  final bool mosque;
  _IslamicPainter({required this.mosque});
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.045)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;
    for (double y = -32; y < size.height + 40; y += 48) {
      for (double x = -32; x < size.width + 40; x += 48) {
        final star = Path();
        for (var i = 0; i < 16; i++) {
          final radius = i.isEven ? 25.0 : 16.0;
          final angle = i * math.pi / 8;
          final point = Offset(
            x + math.cos(angle) * radius,
            y + math.sin(angle) * radius,
          );
          if (i == 0) {
            star.moveTo(point.dx, point.dy);
          } else {
            star.lineTo(point.dx, point.dy);
          }
        }
        canvas.drawPath(star..close(), line);
      }
    }
    if (mosque) {
      final arch = Path()
        ..moveTo(0, size.height * .62)
        ..lineTo(0, size.height * .32)
        ..cubicTo(
          0,
          size.height * .22,
          size.width * .13,
          size.height * .2,
          size.width * .16,
          size.height * .19,
        )
        ..cubicTo(
          size.width * .13,
          size.height * .10,
          size.width * .38,
          size.height * .11,
          size.width * .5,
          0,
        )
        ..cubicTo(
          size.width * .62,
          size.height * .11,
          size.width * .87,
          size.height * .10,
          size.width * .84,
          size.height * .19,
        )
        ..cubicTo(
          size.width * .87,
          size.height * .2,
          size.width,
          size.height * .22,
          size.width,
          size.height * .32,
        )
        ..lineTo(size.width, size.height * .62);
      canvas.drawPath(
        arch,
        Paint()
          ..color = AppColors.prayerHighlight.withValues(alpha: .35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3,
      );
      final skyline = Paint()
        ..color = const Color(0xFF031D40).withValues(alpha: .55);
      final baseline = size.height * .80;
      for (var i = 0; i < 9; i++) {
        final x = size.width * i / 8;
        final h = i.isEven ? 50.0 : 78.0;
        canvas.drawRect(
          Rect.fromLTWH(x - 23, baseline - h, 46, h + 65),
          skyline,
        );
        final dome = Path()
          ..moveTo(x - 23, baseline - h)
          ..quadraticBezierTo(x - 25, baseline - h - 20, x, baseline - h - 37)
          ..quadraticBezierTo(x + 25, baseline - h - 20, x + 23, baseline - h)
          ..close();
        canvas.drawPath(dome, skyline);
        canvas.drawLine(
          Offset(x, baseline - h - 37),
          Offset(x, baseline - h - 49),
          Paint()
            ..color = skyline.color
            ..strokeWidth = 2,
        );
      }
      for (final fraction in [.12, .82]) {
        final x = size.width * fraction;
        canvas.drawRect(Rect.fromLTWH(x, baseline - 160, 7, 220), skyline);
        canvas.drawPath(
          Path()
            ..moveTo(x - 3, baseline - 160)
            ..lineTo(x + 3.5, baseline - 181)
            ..lineTo(x + 10, baseline - 160)
            ..close(),
          skyline,
        );
      }
      final stars = Paint()..color = Colors.white.withValues(alpha: .6);
      for (var i = 0; i < 24; i++) {
        canvas.drawCircle(
          Offset(
            (i * 67.0 + 31) % size.width,
            35 + (i * 37.0) % (size.height * .42),
          ),
          i % 3 == 0 ? 1.3 : .6,
          stars,
        );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _IslamicPainter oldDelegate) =>
      mosque != oldDelegate.mosque;
}

class SurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: Theme.of(context).dividerColor.withValues(alpha: .6),
      ),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF13294B).withValues(alpha: .045),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Material(
      type: MaterialType.transparency,
      textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
      ),
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: child,
    ),
  );
}
