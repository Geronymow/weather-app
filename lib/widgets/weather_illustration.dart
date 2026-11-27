import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../core/weather_codes.dart';

/// Ilustrações do tempo do protótipo (wx/sun, wx/partly, wx/cloud, wx/rain,
/// wx/storm, wx/night, wx/night-cloud), desenhadas com a mesma geometria
/// dos SVGs do Figma (viewBox 100×100). Vetorial: fica nítido em qualquer tamanho.
class WeatherIllustration extends StatelessWidget {
  const WeatherIllustration(this.kind, {super.key, this.size = 32, this.semanticLabel});

  final WeatherKind kind;
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      image: semanticLabel != null,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _WxPainter(kind)),
      ),
    );
  }
}

class _WxPainter extends CustomPainter {
  _WxPainter(this.kind);
  final WeatherKind kind;

  static const _cloudLight = Color(0xFFF4F7FF);
  static const _sunRay = Color(0xFFFFC23D);
  static const _rain = Color(0xFF5CC8FF);
  static const _moon = Color(0xFFE7EAFF);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    switch (kind) {
      case WeatherKind.sun:
        _sun(canvas, 50, 50, 24);
        final ray = Paint()
          ..color = _sunRay
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round;
        for (var i = 0; i < 8; i++) {
          final a = math.pi / 4 * i;
          canvas.drawLine(
            Offset(50 + math.cos(a) * 36, 50 + math.sin(a) * 36),
            Offset(50 + math.cos(a) * 45, 50 + math.sin(a) * 45),
            ray,
          );
        }
      case WeatherKind.partly:
        _sun(canvas, 62, 36, 20);
        _cloud(canvas, -6, 6, 1, _cloudLight);
      case WeatherKind.cloud:
        _cloud(canvas, -2, -6, 1.04, const Color(0xFFDDE6F8));
        _cloud(canvas, 10, 4, 0.8, _cloudLight);
      case WeatherKind.rain:
        _cloud(canvas, -2, -14, 1, const Color(0xFFD5DFF3));
        final drop = Paint()
          ..color = _rain
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round;
        for (final p in const [Offset(34, 70), Offset(50, 74), Offset(66, 70)]) {
          canvas.drawLine(p, p + const Offset(-5, 14), drop);
        }
      case WeatherKind.storm:
        _cloud(canvas, -2, -16, 1, const Color(0xFFA9B6D3));
        final bolt = Path()
          ..moveTo(54, 60)
          ..lineTo(42, 80)
          ..lineTo(52, 80)
          ..lineTo(47, 96)
          ..lineTo(63, 74)
          ..lineTo(53, 74)
          ..lineTo(59, 60)
          ..close();
        canvas.drawPath(bolt, Paint()..color = _sunRay);
      case WeatherKind.night:
        final moon = Path()
          ..moveTo(60, 18)
          ..arcToPoint(const Offset(84, 64), radius: const Radius.circular(30), largeArc: true, clockwise: false)
          ..arcToPoint(const Offset(60, 18), radius: const Radius.circular(24), largeArc: true)
          ..close();
        final p = Paint()..color = _moon;
        canvas.drawPath(moon, p);
        canvas.drawCircle(const Offset(26, 26), 2.5, p);
        canvas.drawCircle(const Offset(82, 24), 2, p);
        canvas.drawCircle(const Offset(20, 60), 1.8, p);
      case WeatherKind.nightCloud:
        final moon = Path()
          ..moveTo(62, 12)
          ..arcToPoint(const Offset(82, 48), radius: const Radius.circular(24), largeArc: true, clockwise: false)
          ..arcToPoint(const Offset(62, 12), radius: const Radius.circular(19), largeArc: true)
          ..close();
        canvas.drawPath(moon, Paint()..color = _moon);
        _cloud(canvas, -8, 8, 0.95, const Color(0xFFC8D2EE));
      case WeatherKind.snow:
        _cloud(canvas, -2, -14, 1, const Color(0xFFDDE6F8));
        final flake = Paint()..color = Colors.white;
        for (final p in const [Offset(32, 76), Offset(50, 82), Offset(68, 76), Offset(41, 92), Offset(59, 92)]) {
          canvas.drawCircle(p, 3.6, flake);
        }
      case WeatherKind.fog:
        _cloud(canvas, -2, -16, 1, const Color(0xFFC8D2EE));
        final line = Paint()
          ..color = const Color(0xFFDDE6F8)
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(const Offset(18, 72), const Offset(82, 72), line);
        canvas.drawLine(const Offset(26, 84), const Offset(74, 84), line);
    }
    canvas.restore();
  }

  void _sun(Canvas c, double cx, double cy, double r) {
    c.drawCircle(Offset(cx, cy), r * 1.45, Paint()..color = const Color(0x4DFFD66B));
    // radialGradient cx=40% cy=35% r=70% (objectBoundingBox do círculo)
    final center = Offset(cx - r + 0.8 * r, cy - r + 0.7 * r);
    c.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..shader = RadialGradient(
          colors: const [Color(0xFFFFE68A), Color(0xFFFFA41B)],
        ).createShader(Rect.fromCircle(center: center, radius: 1.4 * r)),
    );
  }

  void _cloud(Canvas c, double dx, double dy, double s, Color fill) {
    c.save();
    c.translate(dx, dy);
    c.scale(s);
    final p = Paint()..color = fill;
    c.drawCircle(const Offset(34, 58), 14, p);
    c.drawCircle(const Offset(53, 47), 20, p);
    c.drawCircle(const Offset(71, 58), 13, p);
    c.drawRRect(RRect.fromLTRBR(20, 56, 84, 74, const Radius.circular(9)), p);
    c.restore();
  }

  @override
  bool shouldRepaint(_WxPainter old) => old.kind != kind;
}

/// Logo do app (cartão de vidro com sol + nuvem), como na Splash.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 120});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0x1FFFFFFF),
        borderRadius: BorderRadius.circular(size * 0.3),
        border: Border.all(color: const Color(0x2EFFFFFF)),
        boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 32, offset: Offset(0, 12))],
      ),
      alignment: Alignment.center,
      child: WeatherIllustration(WeatherKind.partly, size: size * 0.62),
    );
  }
}
