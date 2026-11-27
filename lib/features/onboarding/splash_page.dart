import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../widgets/weather_illustration.dart';

/// 01 · Splash — mostrada enquanto o app carrega ajustes, GPS e previsão.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key, this.message = 'Detectando sua localização…'});
  final String message;

  @override
  Widget build(BuildContext context) {
    const secondary = Color(0xBDFFFFFF);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: Sky.partly.gradient),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(),
              const AppLogo(size: 120),
              const SizedBox(height: 32),
              Text('Clima Agora', style: ClimaText.headline.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.my_location_rounded, size: 18, color: secondary),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(message,
                          overflow: TextOverflow.ellipsis,
                          style: ClimaText.body.copyWith(color: secondary, fontSize: 15)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 160,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: const LinearProgressIndicator(
                    minHeight: 4,
                    color: ClimaTokens.brandPrimary,
                    backgroundColor: Color(0x33FFFFFF),
                  ),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text('Dados: Open-Meteo · Nominatim',
                    style: ClimaText.bodyS.copyWith(color: const Color(0x8AFFFFFF), fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
