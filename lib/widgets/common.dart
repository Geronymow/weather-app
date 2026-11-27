import 'dart:async';
import 'dart:ui';

import 'package:material_ui/material_ui.dart';

import '../core/theme.dart';
import '../core/weather_codes.dart';
import '../models/place.dart';
import '../models/weather.dart';
import '../state/app_state.dart';
import 'weather_illustration.dart';

/// Card de "vidro" (glass/fill + glass/stroke + blur), base do Início.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 24,
    this.color,
    this.borderColor,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = ClimaColors.of(context);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(color: borderColor ?? c.glassStroke),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Material(
          color: color ?? c.glassFill,
          shape: shape,
          child: InkWell(
            onTap: onTap,
            customBorder: shape,
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

/// Card com cabeçalho em overline + ícone ("PRÓXIMAS 24 HORAS").
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = ClimaColors.of(context);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: c.textTertiary),
              const SizedBox(width: 8),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(title, style: ClimaText.overline.copyWith(color: c.textTertiary)),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// Chip de vidro (Máx 27°, Mín 16°, Sensação 25°, "Há 2 min").
class GlassChip extends StatelessWidget {
  const GlassChip({super.key, required this.label, this.icon, this.iconColor, this.onTap, this.tooltip});

  final String label;
  final IconData? icon;
  final Color? iconColor;
  final VoidCallback? onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final c = ClimaColors.of(context);
    final chip = Material(
      color: c.glassFill,
      shape: StadiumBorder(side: BorderSide(color: c.glassStroke)),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: onTap != null ? 40 : 32),
          child: Padding(
            padding: EdgeInsets.fromLTRB(icon != null ? 10 : 12, 6, 12, 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: iconColor ?? c.textPrimary),
                  const SizedBox(width: 6),
                ],
                Text(label, style: ClimaText.label.copyWith(color: c.textPrimary)),
              ],
            ),
          ),
        ),
      ),
    );
    return tooltip == null ? chip : Tooltip(message: tooltip!, child: chip);
  }
}

/// Selo "◎ Atual" dos cartões de cidade.
class CurrentBadge extends StatelessWidget {
  const CurrentBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 2, 8, 2),
      decoration: BoxDecoration(
        color: ClimaTokens.brandPrimary.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.my_location_rounded, size: 12, color: ClimaTokens.brandPrimary),
          const SizedBox(width: 4),
          Text('Atual', style: ClimaText.label.copyWith(color: ClimaTokens.brandPrimary)),
        ],
      ),
    );
  }
}

/// Título de grupo em overline ("SALVOS", "NOTIFICAÇÕES", "UNIDADES").
class Overline extends StatelessWidget {
  const Overline(this.text, {super.key, this.padding = const EdgeInsets.fromLTRB(0, 8, 0, 4)});
  final String text;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Padding(
        padding: padding,
        child: Semantics(
          header: true,
          child: Text(text, style: ClimaText.overline.copyWith(color: ClimaColors.of(context).textTertiary)),
        ),
      );
}

/// Reconstrói o filho a cada [period] — usado nos relógios e no "Há 2 min".
class Ticker extends StatefulWidget {
  const Ticker({super.key, required this.builder, this.period = const Duration(seconds: 15)});
  final WidgetBuilder builder;
  final Duration period;

  @override
  State<Ticker> createState() => _TickerState();
}

class _TickerState extends State<Ticker> {
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(widget.period, (_) => setState(() {}));
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}

/// Cartão de cidade com o fundo do clima dela (Locais e Sem conexão).
class CityCard extends StatelessWidget {
  const CityCard({
    super.key,
    required this.place,
    required this.data,
    this.subtitleOverride,
    this.onTap,
    this.onLongPress,
    this.selected = false,
  });

  final Place place;
  final PlaceWeather data;
  final String? subtitleOverride;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final u = app.units;
    final w = data.weather;
    final sky = w == null ? Sky.partly : w.skyNow;
    const fg = Colors.white;
    const fg2 = Color(0xBDFFFFFF);

    return Semantics(
      button: onTap != null,
      selected: selected,
      child: Container(
        decoration: BoxDecoration(
          gradient: sky.gradient,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? ClimaTokens.brandPrimary : const Color(0x2EFFFFFF),
            width: selected ? 2 : 1,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: onTap,
            onLongPress: onLongPress,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(place.name, style: ClimaText.title.copyWith(color: fg)),
                            if (place.isCurrentLocation) const CurrentBadge(),
                          ],
                        ),
                        const SizedBox(height: 2),
                        if (w == null)
                          Text(
                            data.loading ? 'Carregando…' : (data.offline ? 'Sem conexão' : place.searchSubtitle),
                            style: ClimaText.bodyS.copyWith(color: fg2),
                          )
                        else ...[
                          Ticker(
                            period: const Duration(seconds: 30),
                            builder: (_) => Text(
                              subtitleOverride ?? '${localTimeLabel(w)} · ${w.current.condition}',
                              style: ClimaText.bodyS.copyWith(color: fg2),
                            ),
                          ),
                          if (w.today != null)
                            Text(
                              'Máx ${u.deg(w.today!.max)}  Mín ${u.deg(w.today!.min)}',
                              style: ClimaText.bodyS.copyWith(color: fg2),
                            ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (w != null) ...[
                    WeatherIllustration(w.current.kind, size: 44),
                    const SizedBox(width: 8),
                    Text(u.deg(w.current.temperature),
                        style: ClimaText.headlineL.copyWith(color: fg, fontWeight: FontWeight.w300)),
                  ] else if (data.loading)
                    const SizedBox.square(
                      dimension: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "14:32" ou, se o fuso do lugar for diferente do aparelho, "18:32 (UTC+1)".
String localTimeLabel(Weather w) {
  final now = w.localNow();
  final hhmm = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  final deviceOffset = DateTime.now().timeZoneOffset.inSeconds;
  if (deviceOffset == w.utcOffsetSeconds) return hhmm;
  return '$hhmm (${utcLabel(w.utcOffsetSeconds)})';
}

String utcLabel(int seconds) {
  final sign = seconds < 0 ? '−' : '+';
  final abs = seconds.abs();
  final h = abs ~/ 3600;
  final m = (abs % 3600) ~/ 60;
  return 'UTC$sign$h${m == 0 ? '' : ':${m.toString().padLeft(2, '0')}'}';
}

extension WeatherSky on Weather {
  Sky get skyNow => WeatherCode.sky(current.weatherCode, isDay: current.isDay);
}
