import 'package:clima_agora/core/theme.dart';
import 'package:clima_agora/core/units.dart';
import 'package:clima_agora/core/weather_codes.dart';
import 'package:clima_agora/models/place.dart';
import 'package:clima_agora/models/settings.dart';
import 'package:clima_agora/models/weather.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show ThemeMode;

import 'fixtures.dart';

void main() {
  group('Weather.fromJson', () {
    test('lê bloco atual, horário e diário', () {
      final w = Weather.fromJson(forecastJson());
      expect(w.current.temperature, 24);
      expect(w.current.condition, 'Parcialmente nublado');
      expect(w.current.kind, WeatherKind.partly);
      expect(w.hourly, hasLength(24 * 8));
      expect(w.daily, hasLength(8));
      expect(w.today!.max, 27);
      expect(w.today!.sunrise!.hour, 5);
      expect(w.today!.sunset!.minute, 1);
      expect(w.utcOffset, const Duration(hours: -3));
    });

    test('nextHours começa na hora corrente do lugar', () {
      final nowUtc = DateTime.utc(2026, 9, 22, 17, 32); // 14:32 em São Paulo
      final w = Weather.fromJson(forecastJson(nowUtc: nowUtc));
      final next = w.nextHours(24, nowUtc);
      expect(next, hasLength(24));
      expect(next.first.time.hour, 14);
      expect(w.localNow(nowUtc).hour, 14);
      expect(w.localNow(nowUtc).minute, 32);
    });

    test('hora local respeita o fuso do lugar (Tóquio, UTC+9)', () {
      final nowUtc = DateTime.utc(2026, 9, 22, 17, 32);
      final w = Weather.fromJson(forecastJson(offsetHours: 9, nowUtc: nowUtc));
      expect(w.localNow(nowUtc).hour, 2);
      expect(w.localNow(nowUtc).day, 23);
    });

    test('campos ausentes no "current" usam o valor da hora', () {
      final j = forecastJson();
      (j['current'] as Map).remove('uv_index');
      (j['current'] as Map).remove('visibility');
      final w = Weather.fromJson(j);
      expect(w.current.visibility, 24140);
      expect(w.current.uvIndex, isNonNegative);
    });
  });

  group('AirQuality', () {
    test('categorias do US AQI', () {
      expect(AirQuality.fromJson(airJson).category, 'Boa');
      expect(const AirQuality(usAqi: 80).category, 'Moderada');
      expect(const AirQuality(usAqi: 160).category, 'Ruim');
      expect(const AirQuality(usAqi: 42).scale, closeTo(0.14, 0.001));
    });
  });

  group('Units', () {
    test('temperatura', () {
      expect(const Units(AppSettings()).deg(24), '24°');
      expect(const Units(AppSettings(tempUnit: TempUnit.fahrenheit)).deg(24), '75°');
    });

    test('vento e pressão', () {
      expect(const Units(AppSettings()).windText(14), '14 km/h');
      expect(const Units(AppSettings(windUnit: WindUnit.ms)).windText(36), '10,0 m/s');
      expect(const Units(AppSettings(windUnit: WindUnit.mph)).windText(16.09344), '10 mph');
      expect(const Units(AppSettings(pressureUnit: PressureUnit.mmhg)).pressureValue(1013.25), '760');
    });

    test('direção cardinal e visibilidade', () {
      expect(Units.cardinal(45), 'NE');
      expect(Units.cardinal(270), 'O');
      expect(Units.cardinal(359), 'N');
      expect(Units.visibility(24140), '24 km');
      expect(Units.visibility(800), '800 m');
    });
  });

  group('WeatherCode', () {
    test('fundo dinâmico conforme o código WMO', () {
      expect(WeatherCode.sky(0), Sky.sunny);
      expect(WeatherCode.sky(2), Sky.partly);
      expect(WeatherCode.sky(3), Sky.cloudy);
      expect(WeatherCode.sky(63), Sky.rain);
      expect(WeatherCode.sky(95), Sky.storm);
      expect(WeatherCode.sky(0, isDay: false), Sky.night);
      expect(WeatherCode.kind(0, isDay: false), WeatherKind.night);
      expect(WeatherCode.describeShort(0), 'Ensolarado');
    });
  });

  group('Persistência', () {
    test('AppSettings ida e volta em JSON', () {
      const s = AppSettings(
        tempUnit: TempUnit.fahrenheit,
        windUnit: WindUnit.mph,
        themeMode: ThemeMode.dark,
        refreshMinutes: 60,
        dynamicBackground: false,
      );
      final r = AppSettings.fromJson(s.toJson());
      expect(r.tempUnit, TempUnit.fahrenheit);
      expect(r.windUnit, WindUnit.mph);
      expect(r.themeMode, ThemeMode.dark);
      expect(r.refreshMinutes, 60);
      expect(r.dynamicBackground, isFalse);
    });

    test('Place: título e id estável', () {
      const p = Place(name: 'São Paulo', region: 'SP', latitude: -23.5912, longitude: -46.6341);
      expect(p.title, 'São Paulo, SP');
      expect(Place.fromJson(p.toJson()), p);
    });
  });
}
