import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../state/app_state.dart';
import '../../core/weather_codes.dart';
import '../../widgets/weather_illustration.dart';

/// 02 · Boas-vindas — explica o uso da localização e pede a permissão.
/// O pedido abre o diálogo do sistema (03 no protótipo: Android 12+ com
/// "Precisa"/"Aproximada"; no navegador, o aviso de localização do browser).
class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key, required this.onDone});

  /// [manual] = o usuário quer escolher a cidade (vai para Locais).
  final void Function({required bool manual}) onDone;

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  bool _busy = false;

  Future<void> _allow() async {
    setState(() => _busy = true);
    final app = AppScope.read(context);
    await app.finishOnboarding();
    final r = await app.locate();
    if (!mounted) return;
    setState(() => _busy = false);
    if (r.ok) {
      widget.onDone(manual: false);
    } else {
      // Permissão negada: o fluxo segue para a busca manual (Locais).
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${r.message} Escolha uma cidade.')));
      widget.onDone(manual: true);
    }
  }

  Future<void> _manual() async {
    await AppScope.read(context).finishOnboarding();
    widget.onDone(manual: true);
  }

  @override
  Widget build(BuildContext context) {
    const secondary = Color(0xBDFFFFFF);
    const tertiary = Color(0x8AFFFFFF);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: Sky.partly.gradient),
        child: SafeArea(
          child: LayoutBuilder(builder: (context, k) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: k.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(children: [
                            const SizedBox(height: 8),
                            const _Illustration(),
                            const SizedBox(height: 32),
                            Text('O clima de onde você está',
                                textAlign: TextAlign.center,
                                style: ClimaText.headline.copyWith(color: Colors.white, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 12),
                            Text(
                              'Usamos a localização do aparelho para mostrar temperatura, '
                              'hora local e alertas da sua região em tempo real.',
                              textAlign: TextAlign.center,
                              style: ClimaText.body.copyWith(color: secondary, fontSize: 15),
                            ),
                            const SizedBox(height: 28),
                            const _Benefit(icon: Icons.schedule_rounded, text: 'Previsão hora a hora e para 7 dias'),
                            const _Benefit(icon: Icons.water_drop_outlined, text: 'Umidade, vento, UV e qualidade do ar'),
                            const _Benefit(icon: Icons.notifications_none_rounded, text: 'Alertas da Defesa Civil e INMET'),
                          ]),
                          Column(children: [
                            const SizedBox(height: 28),
                            FilledButton.icon(
                              onPressed: _busy ? null : _allow,
                              icon: _busy
                                  ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.location_on_outlined),
                              label: const Text('Permitir localização'),
                              style: FilledButton.styleFrom(
                                backgroundColor: ClimaTokens.brandPrimary,
                                foregroundColor: ClimaTokens.brandOnPrimary,
                                minimumSize: const Size.fromHeight(56),
                                textStyle: ClimaText.titleS.copyWith(fontSize: 16),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _busy ? null : _manual,
                              style: TextButton.styleFrom(foregroundColor: ClimaTokens.brandPrimary),
                              child: const Text('Escolher cidade manualmente'),
                            ),
                            const SizedBox(height: 8),
                            Text('Você pode mudar isso depois em Ajustes.',
                                style: ClimaText.bodyS.copyWith(color: tertiary, fontSize: 13)),
                          ]),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

/// Alvo concêntrico com o pino, uma nuvem e o sol (como no protótipo).
class _Illustration extends StatelessWidget {
  const _Illustration();

  @override
  Widget build(BuildContext context) {
    Widget ring(double d, double a) => Container(
          width: d,
          height: d,
          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: a)),
        );
    return SizedBox(
      width: 180,
      height: 180,
      child: Stack(alignment: Alignment.center, children: [
        ring(172, 0.06),
        ring(126, 0.07),
        ring(80, 0.08),
        Positioned(
          bottom: 38,
          child: Container(
            width: 46,
            height: 12,
            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(23)),
          ),
        ),
        const Positioned(top: 36, child: Icon(Icons.location_on, size: 92, color: ClimaTokens.brandPrimary)),
        const Positioned(top: 30, left: 18, child: WeatherIllustration(WeatherKind.cloud, size: 44)),
        Positioned(
          top: 6,
          right: 4,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFFFD66B).withValues(alpha: 0.3)),
            alignment: Alignment.center,
            child: Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: ClimaTokens.accentSun),
            ),
          ),
        ),
      ]),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), shape: BoxShape.circle),
          child: Icon(icon, size: 18, color: ClimaTokens.brandPrimary),
        ),
        const SizedBox(width: 16),
        Expanded(child: Text(text, style: ClimaText.body.copyWith(color: Colors.white, fontSize: 15))),
      ]),
    );
  }
}
