import 'dart:math' as math;

import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../core/units.dart';
import '../../models/weather.dart';
import '../../models/weather_alert.dart';
import '../../widgets/common.dart';
import '../../widgets/weather_illustration.dart';

String hh(DateTime t) => '${t.hour.toString().padLeft(2, '0')}h';
String hhmm(DateTime? t) => t == null
    ? '--:--'
    : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

String capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// "Há 2 min" / "Agora mesmo" / "Há 3 h"
String updatedAgo(DateTime fetchedAtUtc) {
  final m = DateTime.now().toUtc().difference(fetchedAtUtc).inMinutes;
  if (m < 1) return 'Agora mesmo';
  if (m < 60) return 'Há $m min';
  final h = m ~/ 60;
  if (h < 48) return 'Há $h h';
  return 'Há ${h ~/ 24} dias';
}

// ---------------------------------------------------------------------
// Hero: relógio local, data, temperatura e resumo
// ---------------------------------------------------------------------
class HeroSection extends StatelessWidget {
  const HeroSection({
    super.key,
    required this.weather,
    required this.units,
    required this.wide,
    required this.loading,
    required this.onRefresh,
  });

  final Weather weather;
  final Units units;
  final bool wide;
  final bool loading;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final c = ClimaColors.of(context);
    final w = weather;
    final today = w.today;
    final width = MediaQuery.sizeOf(context).width;
    final art = wide ? 160.0 : (width < 400 ? 112.0 : 132.0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Ticker(
            builder: (_) {
              final now = w.localNow();
              return Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(hhmm(now),
                            style: ClimaText.headlineL.copyWith(color: c.textPrimary),
                            semanticsLabel: 'Hora local ${hhmm(now)}'),
                        Text(
                          capitalize(DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(now)),
                          style: ClimaText.body.copyWith(color: c.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  GlassChip(
                    icon: Icons.refresh_rounded,
                    label: loading ? 'Atualizando…' : updatedAgo(w.fetchedAt),
                    tooltip: 'Atualizar previsão',
                    onTap: loading ? null : onRefresh,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        units.deg(w.current.temperature),
                        style: ClimaText.display.copyWith(color: c.textPrimary),
                        semanticsLabel: 'Temperatura ${units.deg(w.current.temperature)}',
                      ),
                    ),
                    Text(w.current.condition, style: ClimaText.title.copyWith(color: c.textPrimary)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              WeatherIllustration(w.current.kind, size: art),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (today != null) ...[
                GlassChip(
                    icon: Icons.thermostat_rounded,
                    iconColor: ClimaTokens.accentSun,
                    label: 'Máx ${units.deg(today.max)}'),
                GlassChip(
                    icon: Icons.thermostat_rounded,
                    iconColor: ClimaTokens.accentRain,
                    label: 'Mín ${units.deg(today.min)}'),
              ],
              GlassChip(label: 'Sensação ${units.deg(w.current.apparentTemperature)}'),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Banner do alerta principal
// ---------------------------------------------------------------------
class AlertBanner extends StatelessWidget {
  const AlertBanner({super.key, required this.alert, required this.weather, required this.onTap});

  final WeatherAlert alert;
  final Weather weather;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = ClimaColors.of(context);
    final color = alertColor(alert);
    final title = alert.official ? '${alert.level.short} · ${alert.title}' : alert.title;
    final when = alertWindow(alert, weather.localNow());
    return GlassCard(
      radius: 20,
      color: color.withValues(alpha: 0.16),
      borderColor: color.withValues(alpha: 0.5),
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      onTap: onTap,
      child: Row(
        children: [
          Icon(alertIcon(alert.topic, official: alert.official), size: 22, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: ClimaText.titleS.copyWith(color: c.textPrimary)),
                const SizedBox(height: 2),
                Text(
                  [?when, alert.official ? 'INMET / Defesa Civil' : 'Previsão Open-Meteo'].join(' · '),
                  style: ClimaText.bodyS.copyWith(color: c.textSecondary),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, size: 20, color: c.textSecondary),
        ],
      ),
    );
  }
}

Color alertColor(WeatherAlert a) => switch (a.level) {
      AlertLevel.red => ClimaTokens.statusDanger,
      AlertLevel.orange => const Color(0xFFFF8A3D),
      AlertLevel.yellow => ClimaTokens.statusWarning,
      AlertLevel.advisory => switch (a.topic) {
          AlertTopic.uv || AlertTopic.heat => ClimaTokens.accentSun,
          AlertTopic.cold || AlertTopic.rain => ClimaTokens.accentRain,
          AlertTopic.storm => ClimaTokens.statusWarning,
          _ => ClimaTokens.brandPrimary,
        },
    };

IconData alertIcon(AlertTopic t, {bool official = false}) {
  if (official) return Icons.warning_amber_rounded;
  return switch (t) {
    AlertTopic.uv || AlertTopic.heat => Icons.wb_sunny_outlined,
    AlertTopic.cold => Icons.thermostat_rounded,
    AlertTopic.rain => Icons.umbrella_outlined,
    AlertTopic.wind => Icons.air_rounded,
    AlertTopic.storm => Icons.thunderstorm_outlined,
    AlertTopic.warning => Icons.warning_amber_rounded,
  };
}

/// "Hoje, 18h–23h" a partir do início/fim do alerta.
String? alertWindow(WeatherAlert a, DateTime now) {
  final s = a.start;
  if (s == null) return null;
  final today = DateTime(now.year, now.month, now.day);
  String day(DateTime d) {
    final diff = DateTime(d.year, d.month, d.day).difference(today).inDays;
    if (diff <= 0) return 'Hoje';
    if (diff == 1) return 'Amanhã';
    return capitalize(DateFormat('EEE', 'pt_BR').format(d).replaceAll('.', ''));
  }

  final e = a.end;
  if (e == null) return '${day(s)}, a partir das ${hh(s)}';
  if (day(s) == day(e)) return '${day(s)}, ${hh(s)}–${hh(e)}';
  return '${day(s)} ${hhmm(s)} → ${day(e)} ${hhmm(e)}';
}

// ---------------------------------------------------------------------
// Próximas 24 horas
// ---------------------------------------------------------------------
class HourlySection extends StatelessWidget {
  const HourlySection({super.key, required this.weather, required this.units});
  final Weather weather;
  final Units units;

  @override
  Widget build(BuildContext context) {
    final c = ClimaColors.of(context);
    final hours = weather.nextHours(24);
    return SectionCard(
      title: 'PRÓXIMAS 24 HORAS',
      icon: Icons.schedule_rounded,
      child: SizedBox(
        height: 136,
        child: hours.isEmpty
            ? Center(child: Text('Previsão horária indisponível.', style: ClimaText.body.copyWith(color: c.textSecondary)))
            : ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: hours.length,
                separatorBuilder: (_, _) => const SizedBox(width: 4),
                itemBuilder: (context, i) {
                  final h = hours[i];
                  final now = i == 0;
                  final prob = h.precipitationProbability;
                  return Semantics(
                    label: '${now ? 'Agora' : hh(h.time)}: ${units.deg(h.temperature)}'
                        '${prob > 0 ? ', $prob% de chuva' : ''}',
                    excludeSemantics: true,
                    child: Container(
                      width: 60,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: now
                          ? BoxDecoration(
                              color: c.textPrimary.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: c.glassStroke),
                            )
                          : null,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(now ? 'Agora' : hh(h.time),
                              style: ClimaText.label.copyWith(color: now ? c.textPrimary : c.textSecondary)),
                          WeatherIllustration(h.kind, size: 32),
                          Text(units.deg(h.temperature), style: ClimaText.titleS.copyWith(color: c.textPrimary)),
                          Text(prob > 0 ? '$prob%' : '—',
                              style: ClimaText.label.copyWith(
                                  color: prob > 0 ? ClimaTokens.accentRain : c.textTertiary)),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Próximos 7 dias
// ---------------------------------------------------------------------
class DailySection extends StatelessWidget {
  const DailySection({super.key, required this.weather, required this.units});
  final Weather weather;
  final Units units;

  @override
  Widget build(BuildContext context) {
    final c = ClimaColors.of(context);
    final days = weather.daily.take(7).toList();
    if (days.isEmpty) return const SizedBox.shrink();
    final lo = days.map((d) => d.min).reduce(math.min);
    final hi = days.map((d) => d.max).reduce(math.max);
    final span = math.max(1.0, hi - lo);

    return SectionCard(
      title: 'PRÓXIMOS 7 DIAS',
      icon: Icons.layers_outlined,
      child: Column(
        children: [
          for (var i = 0; i < days.length; i++) ...[
            if (i > 0) Divider(color: c.divider),
            _DayRow(
              label: i == 0 ? 'Hoje' : capitalize(DateFormat('EEE', 'pt_BR').format(days[i].date).replaceAll('.', '')),
              day: days[i],
              units: units,
              start: (days[i].min - lo) / span,
              end: (days[i].max - lo) / span,
            ),
          ],
        ],
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({required this.label, required this.day, required this.units, required this.start, required this.end});
  final String label;
  final DailyForecast day;
  final Units units;
  final double start;
  final double end;

  @override
  Widget build(BuildContext context) {
    final c = ClimaColors.of(context);
    final p = day.precipitationProbabilityMax;
    return Semantics(
      label: '$label: ${day.condition}, mínima ${units.deg(day.min)}, máxima ${units.deg(day.max)}'
          '${p > 0 ? ', $p% de chuva' : ''}',
      excludeSemantics: true,
      child: SizedBox(
        height: 40,
        child: Row(
          children: [
            SizedBox(width: 48, child: Text(label, style: ClimaText.titleS.copyWith(color: c.textPrimary))),
            const SizedBox(width: 6),
            WeatherIllustration(day.kind, size: 28),
            const SizedBox(width: 6),
            SizedBox(
              width: 36,
              child: Text(p > 0 ? '$p%' : '', style: ClimaText.label.copyWith(color: ClimaTokens.accentRain)),
            ),
            SizedBox(
              width: 34,
              child: Text(units.deg(day.min),
                  textAlign: TextAlign.right, style: ClimaText.body.copyWith(color: c.textTertiary)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: LayoutBuilder(builder: (context, k) {
                final w = k.maxWidth;
                return Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: c.textPrimary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Stack(children: [
                    Positioned(
                      left: w * start,
                      width: math.max(6, w * (end - start)),
                      top: 0,
                      bottom: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          gradient: const LinearGradient(colors: [ClimaTokens.accentRain, ClimaTokens.accentSun]),
                        ),
                      ),
                    ),
                  ]),
                );
              }),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 34,
              child: Text(units.deg(day.max),
                  textAlign: TextAlign.right, style: ClimaText.titleS.copyWith(color: c.textPrimary)),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Grade de detalhes (2 colunas no compacto, 3 no médio/expandido)
// ---------------------------------------------------------------------
class MetricsGrid extends StatelessWidget {
  const MetricsGrid({super.key, required this.weather, required this.units, required this.columns});
  final Weather weather;
  final Units units;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final w = weather;
    final cur = w.current;
    final tiles = <_Metric>[
      _Metric(Icons.water_drop_outlined, 'UMIDADE', '${cur.humidity.round()}%', 'Orvalho ${units.deg(cur.dewPoint)}'),
      _Metric(Icons.air_rounded, 'VENTO', units.windText(cur.windSpeed),
          '${Units.cardinal(cur.windDirection)} · rajadas ${units.windValue(cur.windGusts)}'),
      _uv(w),
      _Metric(Icons.speed_rounded, 'PRESSÃO', units.pressureValue(cur.pressure),
          '${units.settings.pressureUnit.label} · ${_pressureTrend(w)}'),
      _Metric(Icons.visibility_outlined, 'VISIBILIDADE', Units.visibility(cur.visibility), _visibilityLabel(cur.visibility)),
      _rain(w),
    ];

    return LayoutBuilder(builder: (context, k) {
      const gap = 12.0;
      final tileW = (k.maxWidth - gap * (columns - 1)) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [for (final t in tiles) SizedBox(width: tileW, height: 124, child: _MetricTile(t))],
      );
    });
  }

  _Metric _uv(Weather w) {
    final uv = w.current.uvIndex;
    final r = uv.round();
    final label = r <= 2
        ? 'Baixo'
        : r <= 5
            ? 'Moderado'
            : r <= 7
                ? 'Alto'
                : r <= 10
                    ? 'Muito alto'
                    : 'Extremo';
    String sub;
    if (!w.current.isDay) {
      sub = 'Noite · sem radiação';
    } else {
      final now = w.localNow();
      final protect = w.hourly.where((h) =>
          h.time.day == now.day && h.time.month == now.month && !h.time.isBefore(DateTime(now.year, now.month, now.day, now.hour)) &&
          (h.uvIndex ?? 0) >= 3);
      sub = protect.isEmpty ? 'Sem necessidade de protetor' : 'Protetor até ${hh(protect.last.time.add(const Duration(hours: 1)))}';
    }
    return _Metric(Icons.wb_sunny_outlined, 'ÍNDICE UV', '$r · $label', sub,
        color: r >= 6 ? ClimaTokens.statusWarning : null);
  }

  String _pressureTrend(Weather w) {
    final i = w.currentHourIndex();
    if (i < 3) return 'estável';
    final a = w.hourly[i].pressure, b = w.hourly[i - 3].pressure;
    if (a == null || b == null) return 'estável';
    final d = a - b;
    if (d > 1) return 'subindo';
    if (d < -1) return 'caindo';
    return 'estável';
  }

  static String _visibilityLabel(double m) {
    if (m >= 10000) return 'Céu aberto';
    if (m >= 5000) return 'Boa';
    if (m >= 1000) return 'Reduzida';
    return 'Neblina';
  }

  _Metric _rain(Weather w) {
    final today = w.today;
    final next = w.nextHours(24).where((h) => h.precipitation >= 0.1).firstOrNull;
    return _Metric(
      Icons.umbrella_outlined,
      'CHUVA',
      Units.mm(today?.precipitationSum ?? 0),
      next == null ? 'Sem chuva prevista' : '${hh(next.time)}: ${Units.mm(next.precipitation)}',
      color: ClimaTokens.accentRain,
    );
  }
}

class _Metric {
  const _Metric(this.icon, this.title, this.value, this.subtitle, {this.color});
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color? color;
}

class _MetricTile extends StatelessWidget {
  const _MetricTile(this.m);
  final _Metric m;

  @override
  Widget build(BuildContext context) {
    final c = ClimaColors.of(context);
    return Semantics(
      label: '${m.title.toLowerCase()}: ${m.value}, ${m.subtitle}',
      excludeSemantics: true,
      child: GlassCard(
        radius: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(m.icon, size: 16, color: c.textTertiary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(m.title,
                    style: ClimaText.overline.copyWith(color: c.textTertiary), overflow: TextOverflow.ellipsis),
              ),
            ]),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(m.value, style: ClimaText.headline.copyWith(color: m.color ?? c.textPrimary)),
            ),
            Text(m.subtitle,
                style: ClimaText.bodyS.copyWith(color: c.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Nascer e pôr do sol
// ---------------------------------------------------------------------
class SunCard extends StatelessWidget {
  const SunCard({super.key, required this.weather});
  final Weather weather;

  @override
  Widget build(BuildContext context) {
    final c = ClimaColors.of(context);
    final t = weather.today;
    return SectionCard(
      title: 'NASCER E PÔR DO SOL',
      icon: Icons.wb_twilight_rounded,
      child: Ticker(
        period: const Duration(minutes: 1),
        builder: (_) {
          double? progress;
          if (t?.sunrise != null && t?.sunset != null) {
            final now = weather.localNow();
            final total = t!.sunset!.difference(t.sunrise!).inMinutes;
            final done = now.difference(t.sunrise!).inMinutes;
            if (total > 0 && done >= 0 && done <= total) progress = done / total;
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 1 / 0.4,
                child: CustomPaint(painter: _SunArcPainter(progress, c.textPrimary)),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Nascer', style: ClimaText.bodyS.copyWith(color: c.textSecondary)),
                    Text(hhmm(t?.sunrise), style: ClimaText.title.copyWith(color: c.textPrimary)),
                  ]),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('Pôr do sol', style: ClimaText.bodyS.copyWith(color: c.textSecondary)),
                    Text(hhmm(t?.sunset), style: ClimaText.title.copyWith(color: c.textPrimary)),
                  ]),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SunArcPainter extends CustomPainter {
  _SunArcPainter(this.progress, this.ink);
  final double? progress;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height - 8;
    final rx = w / 2 - 12, ry = h - 12;
    final center = Offset(w / 2, h);

    // Arco tracejado
    final arc = Paint()
      ..color = ink.withValues(alpha: 0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    const steps = 60;
    for (var i = 0; i < steps; i += 2) {
      final a1 = math.pi * (1 - i / steps), a2 = math.pi * (1 - (i + 1) / steps);
      canvas.drawLine(
        center + Offset(math.cos(a1) * rx, -math.sin(a1) * ry),
        center + Offset(math.cos(a2) * rx, -math.sin(a2) * ry),
        arc,
      );
    }
    canvas.drawLine(Offset(0, h), Offset(w, h), Paint()..color = ink.withValues(alpha: 0.2));

    final p = progress;
    if (p != null) {
      final a = math.pi * (1 - p);
      final sun = center + Offset(math.cos(a) * rx, -math.sin(a) * ry);
      canvas.drawCircle(sun, 16, Paint()..color = ClimaTokens.accentSun.withValues(alpha: 0.25));
      canvas.drawCircle(sun, 8, Paint()..color = ClimaTokens.accentSun);
    }
  }

  @override
  bool shouldRepaint(_SunArcPainter old) => old.progress != progress || old.ink != ink;
}

// ---------------------------------------------------------------------
// Qualidade do ar
// ---------------------------------------------------------------------
class AirCard extends StatelessWidget {
  const AirCard({super.key, required this.air});
  final AirQuality? air;

  static Color colorFor(int aqi) {
    if (aqi <= 50) return ClimaTokens.statusGood;
    if (aqi <= 100) return const Color(0xFFFFE14D);
    if (aqi <= 150) return ClimaTokens.statusWarning;
    if (aqi <= 200) return ClimaTokens.statusDanger;
    return const Color(0xFFA855F7);
  }

  @override
  Widget build(BuildContext context) {
    final c = ClimaColors.of(context);
    final a = air;
    return SectionCard(
      title: 'QUALIDADE DO AR',
      icon: Icons.eco_outlined,
      child: a == null
          ? Text('Índice indisponível para este local no momento.',
              style: ClimaText.body.copyWith(color: c.textSecondary))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  Text('${a.usAqi}', style: ClimaText.headlineL.copyWith(color: colorFor(a.usAqi))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(a.category, style: ClimaText.title.copyWith(color: c.textPrimary)),
                      Text(
                        [if (a.pm25 != null) 'PM2.5 ${a.pm25!.round()} µg/m³', 'IQA (EPA)'].join(' · '),
                        style: ClimaText.bodyS.copyWith(color: c.textSecondary),
                      ),
                    ]),
                  ),
                ]),
                const SizedBox(height: 12),
                SizedBox(
                  height: 16,
                  child: LayoutBuilder(builder: (context, k) {
                    return Stack(clipBehavior: Clip.none, children: [
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 5,
                        height: 6,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            gradient: const LinearGradient(colors: [
                              Color(0xFF4ADE80),
                              Color(0xFFFFE14D),
                              Color(0xFFFFB020),
                              Color(0xFFFF5A5F),
                              Color(0xFFA855F7),
                            ]),
                          ),
                        ),
                      ),
                      Positioned(
                        left: k.maxWidth * a.scale - 8,
                        top: 0,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: ClimaTokens.bgBase, width: 3),
                          ),
                        ),
                      ),
                    ]);
                  }),
                ),
                const SizedBox(height: 12),
                Text(a.advice, style: ClimaText.bodyS.copyWith(color: c.textSecondary)),
              ],
            ),
    );
  }
}
