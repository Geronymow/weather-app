import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../models/place.dart';
import '../../services/location_service.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import '../alerts/alerts_page.dart';
import 'home_sections.dart';
import 'offline_view.dart';

/// 04 · Início — previsão completa do lugar ativo.
class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.onSearch, this.showSearchAction = true});

  /// Abre a busca (aba Locais).
  final VoidCallback onSearch;
  final bool showSearchAction;

  static final _skyTheme = AppTheme.dark();

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final place = app.activePlace;
    final data = app.active;
    final w = data?.weather;
    final useSky = app.settings.dynamicBackground;
    final sky = w?.skyNow ?? Sky.partly;

    Widget content;
    if (place == null) {
      content = _NoLocation(onSearch: onSearch);
    } else if (data!.offline && !app.viewCachedWhileOffline) {
      content = OfflineView(place: place, data: data);
    } else if (w == null) {
      content = data.error != null
          ? _ErrorView(message: data.error!, onRetry: () => app.load(place))
          : const _LoadingView();
    } else {
      content = _Dashboard(place: place, data: data, onSearch: onSearch, showSearchAction: showSearchAction);
    }

    final background = AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      decoration: BoxDecoration(
        gradient: useSky
            ? (data?.offline == true && !app.viewCachedWhileOffline ? Sky.cloudy.gradient : sky.gradient)
            : null,
        color: useSky ? null : ClimaColors.of(context).bgBase,
      ),
      child: SafeArea(bottom: false, child: content),
    );
    // Sobre os fundos do céu o texto é sempre claro, como no protótipo.
    return useSky ? Theme(data: _skyTheme, child: background) : background;
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({required this.place, required this.data, required this.onSearch, required this.showSearchAction});
  final Place place;
  final PlaceWeather data;
  final VoidCallback onSearch;
  final bool showSearchAction;

  void _openAlerts(BuildContext context) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AlertsPage()));

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final c = ClimaColors.of(context);
    final w = data.weather!;
    final u = app.units;
    final topAlert = data.alerts.firstOrNull;
    final hasOfficial = data.alerts.any((a) => a.official);

    return LayoutBuilder(builder: (context, k) {
      final wide = k.maxWidth >= 600;
      final hPad = wide ? 24.0 : 16.0;
      final maxW = wide ? 960.0 : double.infinity;

      final subtitle = place.isCurrentLocation
          ? [?place.detail, 'localização atual'].join(' · ')
          : [?place.detail, if (place.country != null) place.country!, 'local salvo'].join(' · ');

      final sections = <Widget>[
        HeroSection(
          weather: w,
          units: u,
          wide: wide,
          loading: data.loading,
          onRefresh: app.refreshActive,
        ),
        if (data.offline) _OfflineStrip(savedAt: hhmm(w.toLocal(w.fetchedAt)), onRetry: () => app.load(place)),
        if (topAlert != null) AlertBanner(alert: topAlert, weather: w, onTap: () => _openAlerts(context)),
        HourlySection(weather: w, units: u),
        DailySection(weather: w, units: u),
        MetricsGrid(weather: w, units: u, columns: wide ? 3 : 2),
        if (wide)
          IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Expanded(child: SunCard(weather: w)),
              const SizedBox(width: 12),
              Expanded(child: AirCard(air: data.air)),
            ]),
          )
        else ...[
          SunCard(weather: w),
          AirCard(air: data.air),
        ],
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'Dados: Open-Meteo · Localização: Nominatim\n'
            'Atualizado às ${hhmm(w.toLocal(w.fetchedAt))} (horário local, ${utcLabel(w.utcOffsetSeconds)})',
            textAlign: TextAlign.center,
            style: ClimaText.bodyS.copyWith(color: c.textTertiary),
          ),
        ),
      ];

      return Column(
        children: [
          // Top app bar
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxW),
              child: SizedBox(
                height: 72,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(hPad + 4, 0, hPad - 8, 0),
                  child: Row(children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Icon(Icons.location_on_outlined, size: 18, color: c.textPrimary),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(place.title,
                                  style: ClimaText.titleL.copyWith(color: c.textPrimary),
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ]),
                          Text(subtitle,
                              style: ClimaText.bodyS.copyWith(color: c.textSecondary),
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    if (showSearchAction)
                      IconButton(
                        tooltip: 'Buscar cidade',
                        onPressed: onSearch,
                        icon: const Icon(Icons.search_rounded),
                      ),
                    IconButton(
                      tooltip: data.alerts.isEmpty ? 'Alertas' : 'Alertas (${data.alerts.length})',
                      onPressed: () => _openAlerts(context),
                      icon: Badge(
                        isLabelVisible: data.alerts.isNotEmpty,
                        backgroundColor: hasOfficial ? ClimaTokens.statusDanger : ClimaTokens.statusWarning,
                        smallSize: 8,
                        child: const Icon(Icons.notifications_none_rounded),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: app.refreshActive,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  hPad + (k.maxWidth > maxW ? (k.maxWidth - maxW) / 2 : 0),
                  4,
                  hPad + (k.maxWidth > maxW ? (k.maxWidth - maxW) / 2 : 0),
                  24,
                ),
                itemCount: sections.length,
                separatorBuilder: (_, _) => const SizedBox(height: 16),
                itemBuilder: (_, i) => sections[i],
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _OfflineStrip extends StatelessWidget {
  const _OfflineStrip({required this.savedAt, required this.onRetry});
  final String savedAt;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = ClimaColors.of(context);
    return GlassCard(
      radius: 20,
      padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
      child: Row(children: [
        Icon(Icons.wifi_off_rounded, size: 20, color: c.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Text('Sem conexão · previsão salva às $savedAt',
              style: ClimaText.bodyS.copyWith(color: c.textSecondary)),
        ),
        TextButton(onPressed: onRetry, child: const Text('Tentar')),
      ]),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    final c = ClimaColors.of(context);
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text('Buscando a previsão…', style: ClimaText.body.copyWith(color: c.textSecondary)),
      ]),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = ClimaColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: GlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.cloud_off_rounded, size: 48, color: c.textSecondary),
              const SizedBox(height: 12),
              Text('Não foi possível carregar a previsão',
                  textAlign: TextAlign.center, style: ClimaText.title.copyWith(color: c.textPrimary)),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center, style: ClimaText.bodyS.copyWith(color: c.textSecondary)),
              const SizedBox(height: 20),
              FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('Tentar novamente')),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Sem GPS e sem cidade escolhida.
class _NoLocation extends StatelessWidget {
  const _NoLocation({required this.onSearch});
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final c = ClimaColors.of(context);
    final status = app.locationStatus;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.location_searching_rounded, size: 56, color: c.textSecondary),
            const SizedBox(height: 16),
            Text('Escolha um local', style: ClimaText.titleL.copyWith(color: c.textPrimary)),
            const SizedBox(height: 8),
            Text(
              status == null || status == LocationStatus.granted
                  ? 'Use sua localização ou busque uma cidade para ver a previsão.'
                  : '${LocationResult(status).message} Você pode buscar uma cidade manualmente.',
              textAlign: TextAlign.center,
              style: ClimaText.body.copyWith(color: c.textSecondary),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: app.locating ? null : () => app.locate(),
              icon: app.locating
                  ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.my_location_rounded),
              label: const Text('Usar minha localização'),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: onSearch, child: const Text('Buscar cidade')),
          ]),
        ),
      ),
    );
  }
}
