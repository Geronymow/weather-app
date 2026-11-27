import 'package:http/http.dart' as http;

import '../models/weather.dart';
import 'http_json.dart';

/// Open-Meteo Forecast + Air Quality (sem chave de API).
class WeatherService {
  WeatherService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  static const _current = 'temperature_2m,apparent_temperature,relative_humidity_2m,'
      'dew_point_2m,weather_code,is_day,wind_speed_10m,wind_direction_10m,'
      'wind_gusts_10m,pressure_msl,visibility,uv_index,precipitation';
  static const _hourly = 'temperature_2m,weather_code,is_day,precipitation_probability,'
      'precipitation,pressure_msl,visibility,uv_index';
  static const _daily = 'weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset,'
      'uv_index_max,precipitation_probability_max,precipitation_sum,wind_speed_10m_max';

  static Uri forecastUri(double lat, double lon) => Uri.https(
        'api.open-meteo.com',
        '/v1/forecast',
        {
          'latitude': lat.toStringAsFixed(4),
          'longitude': lon.toStringAsFixed(4),
          'current': _current,
          'hourly': _hourly,
          'daily': _daily,
          'forecast_days': '8',
          'timezone': 'auto',
        },
      );

  Future<Weather> fetchForecast(double lat, double lon) async {
    final json = await getJson(_client, forecastUri(lat, lon), service: 'Open-Meteo');
    return Weather.fromJson(json as Map<String, dynamic>);
  }

  Future<AirQuality> fetchAirQuality(double lat, double lon) async {
    final uri = Uri.https('air-quality-api.open-meteo.com', '/v1/air-quality', {
      'latitude': lat.toStringAsFixed(4),
      'longitude': lon.toStringAsFixed(4),
      'current': 'us_aqi,pm2_5,pm10',
      'timezone': 'auto',
    });
    final json = await getJson(_client, uri, service: 'Open-Meteo Air Quality');
    return AirQuality.fromJson(json as Map<String, dynamic>);
  }
}
