import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

String _iso(DateTime t) =>
    '${t.year.toString().padLeft(4, '0')}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}'
    'T${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

String _date(DateTime t) => _iso(t).substring(0, 10);

/// Gera uma resposta da Open-Meteo Forecast coerente com o relógio real,
/// no fuso [offsetHours] (padrão: São Paulo, UTC−3).
Map<String, dynamic> forecastJson({
  int offsetHours = -3,
  double temp = 24,
  int code = 2,
  List<double>? dailyMax,
  List<double>? dailyMin,
  double uvMax = 7,
  int Function(int hourIndex)? hourlyCode,
  int Function(int hourIndex)? hourlyProb,
  DateTime? nowUtc,
}) {
  final now = (nowUtc ?? DateTime.now().toUtc()).add(Duration(hours: offsetHours));
  final day0 = DateTime(now.year, now.month, now.day);
  final hours = [for (var i = 0; i < 24 * 8; i++) day0.add(Duration(hours: i))];
  final days = [for (var i = 0; i < 8; i++) day0.add(Duration(days: i))];
  final maxs = dailyMax ?? [27, 23, 21, 22, 26, 29, 28, 27];
  final mins = dailyMin ?? [16, 17, 15, 14, 15, 17, 18, 16];

  return {
    'latitude': -23.59,
    'longitude': -46.63,
    'utc_offset_seconds': offsetHours * 3600,
    'timezone': 'America/Sao_Paulo',
    'timezone_abbreviation': 'GMT-3',
    'current': {
      'time': _iso(DateTime(now.year, now.month, now.day, now.hour, (now.minute ~/ 15) * 15)),
      'temperature_2m': temp,
      'apparent_temperature': temp + 1,
      'relative_humidity_2m': 62,
      'dew_point_2m': 16.2,
      'weather_code': code,
      'is_day': 1,
      'wind_speed_10m': 14,
      'wind_direction_10m': 45,
      'wind_gusts_10m': 28,
      'pressure_msl': 1015.3,
      'visibility': 24140,
      'uv_index': 5.2,
      'precipitation': 0,
    },
    'hourly': {
      'time': hours.map(_iso).toList(),
      'temperature_2m': [for (var i = 0; i < hours.length; i++) 18 + (i % 24) / 3],
      'weather_code': [for (var i = 0; i < hours.length; i++) hourlyCode?.call(i) ?? code],
      'is_day': [for (final h in hours) (h.hour >= 6 && h.hour < 18) ? 1 : 0],
      'precipitation_probability': [for (var i = 0; i < hours.length; i++) hourlyProb?.call(i) ?? 0],
      'precipitation': [for (var i = 0; i < hours.length; i++) (hourlyProb?.call(i) ?? 0) > 50 ? 2.0 : 0.0],
      'pressure_msl': [for (var i = 0; i < hours.length; i++) 1015.0],
      'visibility': [for (var i = 0; i < hours.length; i++) 24140.0],
      'uv_index': [for (final h in hours) (h.hour >= 11 && h.hour < 15) ? uvMax : 1.0],
    },
    'daily': {
      'time': days.map(_date).toList(),
      'weather_code': [for (var i = 0; i < 8; i++) code],
      'temperature_2m_max': maxs,
      'temperature_2m_min': mins,
      'sunrise': [for (final d in days) _iso(d.add(const Duration(hours: 5, minutes: 52)))],
      'sunset': [for (final d in days) _iso(d.add(const Duration(hours: 18, minutes: 1)))],
      'uv_index_max': [for (var i = 0; i < 8; i++) uvMax],
      'precipitation_probability_max': [20, 90, 70, 20, 0, 0, 10, 0],
      'precipitation_sum': [0.0, 12.0, 6.0, 0.0, 0.0, 0.0, 0.0, 0.0],
      'wind_speed_10m_max': [20.0, 30.0, 20.0, 15.0, 15.0, 15.0, 15.0, 15.0],
    },
  };
}

const airJson = {
  'current': {'us_aqi': 42, 'pm2_5': 9.1, 'pm10': 15.0},
};

/// Cliente HTTP falso que responde às APIs usadas pelo app.
http.Client fakeApiClient({bool offline = false, Map<String, dynamic>? forecast}) => MockClient((req) async {
      if (offline) throw http.ClientException('offline');
      final host = req.url.host;
      Object body;
      if (host == 'api.open-meteo.com') {
        body = forecast ?? forecastJson();
      } else if (host == 'air-quality-api.open-meteo.com') {
        body = airJson;
      } else if (host == 'geocoding-api.open-meteo.com') {
        body = {
          'results': [
            {'name': 'Curitiba', 'latitude': -25.43, 'longitude': -49.27, 'admin1': 'Paraná', 'country': 'Brasil', 'country_code': 'BR'},
          ],
        };
      } else if (host == 'nominatim.openstreetmap.org') {
        body = {
          'lat': '-23.59',
          'lon': '-46.63',
          'address': {
            'suburb': 'Vila Mariana',
            'city': 'São Paulo',
            'state': 'São Paulo',
            'ISO3166-2-lvl4': 'BR-SP',
            'country': 'Brasil',
            'country_code': 'br',
          },
        };
      } else if (host == 'apiprevmet3.inmet.gov.br') {
        body = {
          'hoje': [
            {
              'id': 1,
              'descricao': 'Chuvas Intensas',
              'severidade': 'Perigo Potencial',
              'riscos': ['Baixo risco de alagamentos.'],
              'municipios': 'Osasco - SP (3534401), São Paulo - SP (3550308)',
              'data_inicio': '2026-09-22',
              'hora_inicio': '18:00',
              'data_fim': '2026-09-23',
              'hora_fim': '06:00',
            },
          ],
          'futuro': [],
        };
      } else {
        return http.Response('not found', 404);
      }
      return http.Response.bytes(utf8.encode(jsonEncode(body)), 200,
          headers: {'content-type': 'application/json; charset=utf-8'});
    });
