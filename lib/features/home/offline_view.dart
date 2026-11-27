import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../models/place.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import 'home_sections.dart';

/// 08 · Sem conexão — mostra a última previsão salva e tenta de novo.
class OfflineView extends StatelessWidget {
  const OfflineView({super.key, required this.place, required this.data});
  final Place place;
  final PlaceWeather data;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final c = ClimaColors.of(context);
    final w = data.weather;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  color: c.glassFill,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.glassStroke),
                ),
                child: Icon(Icons.wifi_off_rounded, size: 48, color: c.textPrimary),
              ),
              const SizedBox(height: 24),
              Text('Sem conexão com a internet',
                  textAlign: TextAlign.center, style: ClimaText.titleL.copyWith(color: c.textPrimary)),
              const SizedBox(height: 8),
              Text(
                w != null
                    ? 'Mostrando a última previsão salva. Atualizamos assim que a conexão voltar.'
                    : 'Ainda não há previsão salva para este local. Verifique sua conexão.',
                textAlign: TextAlign.center,
                style: ClimaText.body.copyWith(color: c.textSecondary),
              ),
              if (w != null) ...[
                const SizedBox(height: 24),
                Opacity(
                  opacity: 0.85,
                  child: CityCard(
                    place: place,
                    data: data,
                    subtitleOverride: 'Salvo às ${hhmm(w.toLocal(w.fetchedAt))} · ${w.current.condition}',
                    onTap: app.showCachedWhileOffline,
                  ),
                ),
                const SizedBox(height: 4),
                TextButton(onPressed: app.showCachedWhileOffline, child: const Text('Ver previsão salva')),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: data.loading ? null : () => app.load(place),
                icon: data.loading
                    ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.refresh_rounded),
                label: const Text('Tentar novamente'),
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
