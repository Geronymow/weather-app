import 'package:material_ui/material_ui.dart';

import '../../core/breakpoints.dart';
import '../../core/theme.dart';
import '../../models/settings.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';

/// 07 · Ajustes — unidades, aparência, localização e sobre.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static const version = '0.1.0';

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final c = ClimaColors.of(context);
    final s = app.settings;
    void set(AppSettings n) => app.updateSettings(n);

    return ColoredBox(
      color: c.bgBase,
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: kReadableMaxWidth),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                Text('Ajustes', style: ClimaText.headline.copyWith(color: c.textPrimary, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                const Overline('UNIDADES'),
                _Group(children: [
                  _Row(
                    title: 'Temperatura',
                    trailing: _Seg<TempUnit>(
                      values: TempUnit.values,
                      selected: s.tempUnit,
                      label: (v) => v.label,
                      onChanged: (v) => set(s.copyWith(tempUnit: v)),
                    ),
                  ),
                  _Row(
                    title: 'Vento',
                    trailing: _Seg<WindUnit>(
                      values: WindUnit.values,
                      selected: s.windUnit,
                      label: (v) => v.label,
                      onChanged: (v) => set(s.copyWith(windUnit: v)),
                    ),
                  ),
                  _ChoiceRow<PressureUnit>(
                    title: 'Pressão',
                    values: PressureUnit.values,
                    selected: s.pressureUnit,
                    label: (v) => v.label,
                    onChanged: (v) => set(s.copyWith(pressureUnit: v)),
                  ),
                ]),
                const Overline('APARÊNCIA', padding: EdgeInsets.fromLTRB(0, 16, 0, 4)),
                _Group(children: [
                  _Row(
                    title: 'Tema',
                    trailing: _Seg<ThemeMode>(
                      values: const [ThemeMode.system, ThemeMode.light, ThemeMode.dark],
                      selected: s.themeMode,
                      label: (v) => switch (v) {
                        ThemeMode.system => 'Auto',
                        ThemeMode.light => 'Claro',
                        ThemeMode.dark => 'Escuro',
                      },
                      onChanged: (v) => set(s.copyWith(themeMode: v)),
                    ),
                  ),
                  _SwitchRow(
                    title: 'Fundo conforme o clima',
                    value: s.dynamicBackground,
                    onChanged: (v) => set(s.copyWith(dynamicBackground: v)),
                  ),
                ]),
                const Overline('LOCALIZAÇÃO', padding: EdgeInsets.fromLTRB(0, 16, 0, 4)),
                _Group(children: [
                  _ChoiceRow<LocationPrecision>(
                    title: 'Precisão',
                    values: LocationPrecision.values,
                    selected: s.precision,
                    label: (v) => v.label,
                    onChanged: (v) {
                      set(s.copyWith(precision: v));
                      if (app.selectedPlace == null && app.gpsPlace != null) app.locate(request: false);
                    },
                  ),
                  _SwitchRow(
                    title: 'Atualizar automaticamente',
                    subtitle: 'Enquanto o app estiver aberto',
                    value: s.autoRefresh,
                    onChanged: (v) => set(s.copyWith(autoRefresh: v)),
                  ),
                  if (s.autoRefresh)
                    _ChoiceRow<int>(
                      title: 'Frequência',
                      values: AppSettings.refreshOptions,
                      selected: s.refreshMinutes,
                      label: (v) => v < 60 ? '$v min' : '${v ~/ 60} h',
                      onChanged: (v) => set(s.copyWith(refreshMinutes: v)),
                    ),
                ]),
                const Overline('DADOS E SOBRE', padding: EdgeInsets.fromLTRB(0, 16, 0, 4)),
                _Group(children: [
                  _Row(title: 'Previsão', trailing: _Value('Open-Meteo')),
                  _Row(title: 'Localização', trailing: _Value('Nominatim · OpenStreetMap')),
                  _Row(title: 'Alertas oficiais', trailing: _Value('INMET')),
                  _Row(
                    title: 'Licenças',
                    trailing: Icon(Icons.chevron_right_rounded, color: c.textTertiary),
                    onTap: () => showLicensePage(
                      context: context,
                      applicationName: 'Clima Agora',
                      applicationVersion: version,
                      applicationLegalese: 'Dados meteorológicos: Open-Meteo.com (CC BY 4.0)\n'
                          'Geocodificação: © colaboradores do OpenStreetMap (ODbL)',
                    ),
                  ),
                  _Row(title: 'Versão', trailing: _Value(version)),
                ]),
              ],
            ),
          ),
        ),
      ),
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
      child: Material(
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

class _Row extends StatelessWidget {
  const _Row({required this.title, required this.trailing, this.onTap});
  final String title;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = ClimaColors.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          // Título à esquerda e controle à direita; se não couber (tela
          // estreita ou fonte grande), o controle desce para a linha de baixo.
          child: SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                Text(title, style: ClimaText.body.copyWith(color: c.textPrimary, fontSize: 16)),
                trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Value extends StatelessWidget {
  const _Value(this.text);
  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: ClimaText.body.copyWith(color: ClimaColors.of(context).textSecondary, fontSize: 15));
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({required this.title, required this.value, required this.onChanged, this.subtitle});
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = ClimaColors.of(context);
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      title: Text(title, style: ClimaText.body.copyWith(color: c.textPrimary, fontSize: 16)),
      subtitle: subtitle == null ? null : Text(subtitle!, style: ClimaText.bodyS.copyWith(color: c.textTertiary)),
    );
  }
}

class _Seg<T> extends StatelessWidget {
  const _Seg({required this.values, required this.selected, required this.label, required this.onChanged});
  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<T>(
      showSelectedIcon: true,
      segments: [for (final v in values) ButtonSegment<T>(value: v, label: Text(label(v)))],
      selected: {selected},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}

/// Linha "Pressão  hPa ›" que abre um seletor.
class _ChoiceRow<T> extends StatelessWidget {
  const _ChoiceRow({
    required this.title,
    required this.values,
    required this.selected,
    required this.label,
    required this.onChanged,
  });

  final String title;
  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = ClimaColors.of(context);
    return _Row(
      title: title,
      onTap: () async {
        final v = await showModalBottomSheet<T>(
          context: context,
          showDragHandle: true,
          builder: (ctx) => SafeArea(
            child: RadioGroup<T>(
              groupValue: selected,
              onChanged: (v) => Navigator.pop(ctx, v),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(title, style: ClimaText.title.copyWith(color: c.textPrimary)),
                  ),
                ),
                for (final v in values)
                  RadioListTile<T>(
                    value: v,
                    title: Text(label(v), style: ClimaText.body.copyWith(color: c.textPrimary, fontSize: 16)),
                  ),
                const SizedBox(height: 8),
              ]),
            ),
          ),
        );
        if (v != null) onChanged(v);
      },
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        _Value(label(selected)),
        const SizedBox(width: 4),
        Icon(Icons.chevron_right_rounded, color: c.textTertiary),
      ]),
    );
  }
}
