// Gera os ícones do app (Android, iOS e web) a partir do logo do protótipo
// Figma (sol + nuvem sobre o fundo "Parcialmente nublado"), usando o mesmo
// painter das ilustrações do app.
//
//   flutter test tool/generate_icons_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:clima_agora/core/theme.dart';
import 'package:clima_agora/core/weather_codes.dart';
import 'package:clima_agora/widgets/weather_illustration.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// [rounded]: cantos transparentes (ícone "comum"); sem isso, sangra até a
/// borda (iOS e ícones "maskable", que recebem a máscara do sistema).
Widget _icon(double size, {required bool rounded}) => Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: Sky.partly.colors,
            ),
            borderRadius: rounded ? BorderRadius.circular(size * 0.22) : null,
          ),
          alignment: Alignment.center,
          child: WeatherIllustration(WeatherKind.partly, size: size * 0.6),
        ),
      ),
    );

Future<void> _render(WidgetTester tester, String path, int px, {bool rounded = false}) async {
  final key = GlobalKey();
  tester.view.physicalSize = Size(px.toDouble(), px.toDouble());
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(RepaintBoundary(key: key, child: _icon(px.toDouble(), rounded: rounded)));
  await tester.runAsync(() async {
    final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File(path)
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

void main() {
  testWidgets('gera ícones', (tester) async {
    addTearDown(tester.view.reset);

    // Web (favicon + PWA)
    await _render(tester, 'web/favicon.png', 64, rounded: true);
    await _render(tester, 'web/icons/Icon-192.png', 192, rounded: true);
    await _render(tester, 'web/icons/Icon-512.png', 512, rounded: true);
    await _render(tester, 'web/icons/Icon-maskable-192.png', 192);
    await _render(tester, 'web/icons/Icon-maskable-512.png', 512);

    // Android (launcher legado)
    const android = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192};
    for (final e in android.entries) {
      await _render(tester, 'android/app/src/main/res/mipmap-${e.key}/ic_launcher.png', e.value, rounded: true);
    }

    // iOS (sem transparência; o sistema aplica a máscara)
    final dir = Directory('ios/Runner/Assets.xcassets/AppIcon.appiconset');
    final re = RegExp(r'Icon-App-([\d.]+)x[\d.]+@(\d)x\.png');
    for (final f in dir.listSync().whereType<File>()) {
      final m = re.firstMatch(f.uri.pathSegments.last);
      if (m == null) continue;
      final px = (double.parse(m.group(1)!) * int.parse(m.group(2)!)).round();
      await _render(tester, f.path, px);
    }
  });
}
