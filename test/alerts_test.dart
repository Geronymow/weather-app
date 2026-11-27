import 'package:clima_agora/models/place.dart';
import 'package:clima_agora/models/weather.dart';
import 'package:clima_agora/models/weather_alert.dart';
import 'package:clima_agora/services/alerts_service.dart';
import 'package:clima_agora/services/geocoding_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'fixtures.dart';

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  const sp = Place(name: 'São Paulo', region: 'SP', countryCode: 'BR', latitude: -23.59, longitude: -46.63);
  final morning = DateTime.utc(2026, 9, 22, 12); // 09:00 em São Paulo

  test('UV alto vira aviso com a janela de horário', () {
    final w = Weather.fromJson(forecastJson(uvMax: 7, nowUtc: morning));
    final a = AlertsService.deriveFromForecast(w, place: sp, nowUtc: morning);
    final uv = a.firstWhere((x) => x.id == 'uv');
    expect(uv.title, 'Índice UV alto (7)');
    expect(uv.description, startsWith('Entre 11h e 15h'));
    expect(uv.topic, AlertTopic.uv);
  });

  test('frente fria quando a máxima despenca', () {
    final w = Weather.fromJson(forecastJson(
      dailyMax: [27, 26, 25, 19, 22, 24, 25, 26],
      dailyMin: [16, 16, 15, 13, 14, 15, 16, 16],
      nowUtc: morning,
    ));
    final a = AlertsService.deriveFromForecast(w, place: sp, nowUtc: morning);
    final cold = a.firstWhere((x) => x.id == 'cold-front');
    expect(cold.description, contains('Queda de até 8°'));
    expect(cold.description, contains('mínima de 13°'));
  });

  test('chuva nas próximas 2 horas e tempestade', () {
    final rain = Weather.fromJson(forecastJson(hourlyProb: (i) => 80, nowUtc: morning));
    expect(AlertsService.deriveFromForecast(rain, nowUtc: morning).map((a) => a.id), contains('rain-soon'));

    final storm = Weather.fromJson(forecastJson(hourlyCode: (i) => 95, nowUtc: morning));
    final ids = AlertsService.deriveFromForecast(storm, nowUtc: morning).map((a) => a.id);
    expect(ids, contains('storm'));
    expect(ids, isNot(contains('rain-soon')));
  });

  test('sem avisos em dia tranquilo', () {
    final w = Weather.fromJson(forecastJson(uvMax: 3, dailyMax: [24, 24, 24, 24, 24, 24, 24, 24], nowUtc: morning));
    expect(AlertsService.deriveFromForecast(w, nowUtc: morning), isEmpty);
  });

  test('INMET: filtra pelo município e lê nível/horário', () async {
    final alerts = await AlertsService(client: fakeApiClient())
        .alertsFor(sp, Weather.fromJson(forecastJson(uvMax: 3, nowUtc: morning)));
    final official = alerts.where((a) => a.official).toList();
    expect(official, hasLength(1));
    expect(official.first.title, 'Chuvas intensas');
    expect(official.first.level, AlertLevel.yellow);
    expect(official.first.start, DateTime(2026, 9, 22, 18));

    const rio = Place(name: 'Rio de Janeiro', region: 'RJ', countryCode: 'BR', latitude: -22.9, longitude: -43.2);
    expect(AlertsService.parseInmet({'hoje': []}, rio), isEmpty);
  });

  test('geocodificação reversa nomeia bairro, cidade e UF', () async {
    final p = await GeocodingService(client: fakeApiClient()).reverse(-23.59, -46.63);
    expect(p.title, 'São Paulo, SP');
    expect(p.detail, 'Vila Mariana');
    expect(p.isCurrentLocation, isTrue);
  });

  test('busca converte estado brasileiro em sigla', () async {
    final r = await GeocodingService(client: fakeApiClient()).search('Curitiba');
    expect(r.single.title, 'Curitiba, PR');
  });
}
