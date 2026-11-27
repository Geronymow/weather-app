import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/breakpoints.dart';
import '../../core/theme.dart';
import '../../models/weather_alert.dart';
import '../../state/app_state.dart';
import '../home/home_sections.dart';

/// 06 · Alertas — alertas oficiais, avisos da previsão e preferências.
class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final c = ClimaColors.of(context);
    final data = app.active;
    final w = data?.weather;
    final alerts = data?.alerts ?? const <WeatherAlert>[];
    final s = app.settings;

    return Scaffold(
      appBar: AppBar(
        title: Text(app.activePlace == null ? 'Alertas' : 'Alertas · ${app.activePlace!.name}'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: kReadableMaxWidth),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              if (alerts.isEmpty)
                _EmptyAlerts(c: c)
              else
                for (final a in alerts) ...[
                  a.official || a == alerts.first
                      ? _FeaturedAlert(alert: a, now: w?.localNow() ?? DateTime.now())
                      : _AdvisoryCard(alert: a),
                  const SizedBox(height: 12),
                ],
              const SizedBox(height: 4),
              Text(
                'Alertas oficiais: INMET (quando disponível para o local). '
                'Avisos: calculados a partir da previsão da Open-Meteo.',
                style: ClimaText.bodyS.copyWith(color: c.textTertiary),
              ),
              const SizedBox(height: 16),
              Text('NOTIFICAÇÕES', style: ClimaText.overline.copyWith(color: c.textTertiary)),
              const SizedBox(height: 8),
              _Group(children: [
                _SwitchRow(
                  title: 'Alertas severos da região',
                  subtitle: 'Defesa Civil e INMET',
                  value: s.notifySevere,
                  onChanged: (v) => app.updateSettings(s.copyWith(notifySevere: v)),
                ),
                _SwitchRow(
                  title: 'Chuva nas próximas 2 horas',
                  subtitle: 'Com base na previsão por hora',
                  value: s.notifyRainSoon,
                  onChanged: (v) => app.updateSettings(s.copyWith(notifyRainSoon: v)),
                ),
                _SwitchRow(
                  title: 'Resumo diário às 07:00',
                  subtitle: 'Previsão do dia na notificação',
                  value: s.notifyDailySummary,
                  onChanged: (v) => app.updateSettings(s.copyWith(notifyDailySummary: v)),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyAlerts extends StatelessWidget {
  const _EmptyAlerts({required this.c});
  final ClimaColors c;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: c.glassStroke),
        ),
        child: Column(children: [
          const Icon(Icons.verified_outlined, size: 40, color: ClimaTokens.statusGood),
          const SizedBox(height: 12),
          Text('Nenhum alerta ativo', style: ClimaText.title.copyWith(color: c.textPrimary)),
          const SizedBox(height: 4),
          Text('Nada fora do normal previsto para as próximas horas.',
              textAlign: TextAlign.center, style: ClimaText.body.copyWith(color: c.textSecondary)),
        ]),
      );
}

/// Cartão de destaque ("AMARELO · PERIGO POTENCIAL / Chuvas intensas").
class _FeaturedAlert extends StatelessWidget {
  const _FeaturedAlert({required this.alert, required this.now});
  final WeatherAlert alert;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final c = ClimaColors.of(context);
    final color = alertColor(alert);
    final window = alertWindow(alert, now);
    final reminded = app.isReminded(alert);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(8, 4, 10, 4),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(12)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(alertIcon(alert.topic, official: alert.official), size: 14, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  '${alert.level.tag} · ${alert.level.severity}'.toUpperCase(),
                  style: ClimaText.overline.copyWith(color: color),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 10),
          Text(alert.title, style: ClimaText.title.copyWith(color: c.textPrimary)),
          const SizedBox(height: 10),
          Text(alert.description, style: ClimaText.body.copyWith(color: c.textSecondary)),
          const SizedBox(height: 10),
          if (window != null) _Meta(icon: Icons.schedule_rounded, text: window),
          if (alert.area != null) _Meta(icon: Icons.location_on_outlined, text: alert.area!),
          _Meta(icon: Icons.notifications_none_rounded, text: 'Fonte: ${alert.source}'),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            FilledButton.tonalIcon(
              onPressed: () {
                app.toggleReminder(alert);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(app.isReminded(alert)
                      ? 'Vamos lembrar você quando o alerta começar (com o app aberto).'
                      : 'Lembrete removido.'),
                ));
              },
              icon: Icon(reminded ? Icons.notifications_active_rounded : Icons.notifications_none_rounded),
              label: Text(reminded ? 'Lembrete ativo' : 'Lembrar-me'),
              style: FilledButton.styleFrom(
                backgroundColor: c.textPrimary.withValues(alpha: 0.12),
                foregroundColor: c.brand,
                shape: const StadiumBorder(),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _share(context),
              icon: const Icon(Icons.share_outlined),
              label: const Text('Compartilhar'),
            ),
          ]),
        ],
      ),
    );
  }

  Future<void> _share(BuildContext context) async {
    final window = alertWindow(alert, now);
    final text = [
      '⚠️ ${alert.title}${alert.official ? ' (${alert.level.short})' : ''}',
      alert.description,
      ?window,
      ?alert.area,
      'Fonte: ${alert.source} — via Clima Agora',
    ].join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Texto do alerta copiado. Cole onde quiser compartilhar.')),
      );
    }
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = ClimaColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Icon(icon, size: 16, color: c.textSecondary),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: ClimaText.bodyS.copyWith(color: c.textSecondary, fontSize: 13))),
      ]),
    );
  }
}

/// Aviso compacto ("Índice UV alto (7)", "Frente fria na quinta").
class _AdvisoryCard extends StatelessWidget {
  const _AdvisoryCard({required this.alert});
  final WeatherAlert alert;

  @override
  Widget build(BuildContext context) {
    final c = ClimaColors.of(context);
    final color = alertColor(alert);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.glassStroke),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.18), shape: BoxShape.circle),
          child: Icon(alertIcon(alert.topic), size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(alert.title, style: ClimaText.titleS.copyWith(color: c.textPrimary)),
            const SizedBox(height: 2),
            Text(alert.description, style: ClimaText.bodyS.copyWith(color: c.textSecondary, fontSize: 13)),
          ]),
        ),
      ]),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = ClimaColors.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: ColoredBox(
        color: c.surface,
        child: Column(children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(color: c.divider),
            children[i],
          ],
        ]),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({required this.title, required this.subtitle, required this.value, required this.onChanged});
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = ClimaColors.of(context);
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      title: Text(title, style: ClimaText.body.copyWith(color: c.textPrimary, fontSize: 15)),
      subtitle: Text(subtitle, style: ClimaText.bodyS.copyWith(color: c.textTertiary)),
    );
  }
}
