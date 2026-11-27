import 'dart:convert';

import 'package:clima_agora/app.dart';
import 'package:clima_agora/core/theme.dart';
import 'package:clima_agora/models/settings.dart';
import 'package:clima_agora/services/alerts_service.dart';
import 'package:clima_agora/services/geocoding_service.dart';
import 'package:clima_agora/services/location_service.dart';
import 'package:clima_agora/services/storage_service.dart';
import 'package:clima_agora/services/weather_service.dart';
import 'package:clima_agora/state/app_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fixtures.dart';

class FakeLocation extends LocationService {
  FakeLocation(this.result);
  LocationResult result;

  @override
  Future<LocationResult> locate(LocationPrecision precision, {bool request = true}) async => result;
}

const _granted = LocationResult(LocationStatus.granted, -23.59, -46.63);

Future<AppState> _makeState({
  Map<String, Object> prefs = const {},
  http.Client? client,
  LocationResult location = _granted,
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final c = client ?? fakeApiClient();
  return AppState(
    storage: await StorageService.open(),
    weatherService: WeatherService(client: c),
    geocoding: GeocodingService(client: c),
    alertsService: AlertsService(client: c),
    location: FakeLocation(location),
  );
}

Future<void> _pumpApp(WidgetTester tester, AppState state, {Size size = const Size(412, 915)}) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ClimaAgoraApp(state: state));
  await tester.runAsync(state.bootstrap);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  setUpAll(() async {
    AppTheme.useGoogleFonts = false;
    Intl.defaultLocale = 'pt_BR';
    await initializeDateFormatting('pt_BR');
  });

  testWidgets('primeiro uso: boas-vindas → permitir localização → Início', (tester) async {
    final state = await _makeState();
    await _pumpApp(tester, state);

    expect(find.text('O clima de onde você está'), findsOneWidget);
    await tester.runAsync(() async {
      await tester.tap(find.text('Permitir localização'));
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('São Paulo, SP'), findsOneWidget);
    expect(find.text('Vila Mariana · localização atual'), findsOneWidget);
    expect(find.text('24°'), findsOneWidget);
    expect(find.text('Parcialmente nublado'), findsOneWidget);
    expect(find.text('Máx 27°'), findsOneWidget);
    expect(find.text('PRÓXIMAS 24 HORAS'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    // Alerta oficial do INMET aparece no banner.
    expect(find.text('Alerta amarelo · Chuvas intensas'), findsOneWidget);
  });

  testWidgets('permissão negada leva para Locais (busca manual)', (tester) async {
    final state = await _makeState(location: const LocationResult(LocationStatus.denied));
    await _pumpApp(tester, state);

    await tester.runAsync(() async {
      await tester.tap(find.text('Permitir localização'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Buscar cidade, bairro ou CEP'), findsOneWidget);
    expect(find.text('SUGESTÕES'), findsOneWidget);
  });

  testWidgets('trocar para °F atualiza a temperatura', (tester) async {
    final state = await _makeState(prefs: {'onboarded': true});
    await _pumpApp(tester, state);
    expect(find.text('24°'), findsOneWidget);

    await tester.tap(find.text('Ajustes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('°F'));
    await tester.pumpAndSettle();
    expect(state.settings.tempUnit, TempUnit.fahrenheit);

    await tester.tap(find.text('Início'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('75°'), findsOneWidget);
  });

  testWidgets('sem conexão mostra a última previsão salva', (tester) async {
    final cached = forecastJson();
    final state = await _makeState(
      client: fakeApiClient(offline: true),
      prefs: {
        'onboarded': true,
        'gpsPlace': jsonEncode({'name': 'São Paulo', 'region': 'SP', 'lat': -23.59, 'lon': -46.63, 'gps': true}),
        'cache:-23.59,-46.63': jsonEncode({
          'fetchedAt': DateTime.now().toUtc().subtract(const Duration(hours: 1)).toIso8601String(),
          'forecast': cached,
          'air': null,
        }),
      },
      location: const LocationResult(LocationStatus.error),
    );
    await _pumpApp(tester, state);

    expect(find.text('Sem conexão com a internet'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);
    await tester.tap(find.text('Ver previsão salva'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.textContaining('Sem conexão · previsão salva'), findsOneWidget);
    expect(find.text('24°'), findsOneWidget);
  });

  testWidgets('tablet/web usa NavigationRail; tela larga mostra 2 painéis', (tester) async {
    final state = await _makeState(prefs: {'onboarded': true});
    await _pumpApp(tester, state, size: const Size(700, 1000));
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await _pumpApp(tester, state, size: const Size(1280, 860));
    expect(find.byType(NavigationRail), findsOneWidget);
    // Painel de locais + detalhes lado a lado.
    expect(find.text('Buscar cidade, bairro ou CEP'), findsOneWidget);
    expect(find.text('São Paulo, SP'), findsOneWidget);
  });

  testWidgets('Alertas e resultados da busca abrem sem erros', (tester) async {
    final state = await _makeState(prefs: {'onboarded': true});
    await _pumpApp(tester, state);

    await tester.tap(find.byIcon(Icons.notifications_none_rounded).first);
    await tester.pumpAndSettle();
    expect(find.text('AMARELO · PERIGO POTENCIAL'), findsOneWidget);
    expect(find.text('NOTIFICAÇÕES'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Locais'));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.enterText(find.byType(TextField), 'Curitiba');
      await Future<void>.delayed(const Duration(milliseconds: 600));
    });
    await tester.pump();
    expect(find.text('RESULTADOS'), findsOneWidget);
    expect(find.text('PR · Brasil'), findsOneWidget);
  });
}
