import '../core/weather_codes.dart';

double _d(Object? v, [double fallback = 0]) => v is num ? v.toDouble() : fallback;
double? _dn(Object? v) => v is num ? v.toDouble() : null;
int _i(Object? v, [int fallback = 0]) => v is num ? v.toInt() : fallback;

/// Converte "2026-09-22T14:00" (hora local do lugar, sem fuso) em um
/// DateTime "de parede". Todas as comparações do app usam esse mesmo
/// relógio de parede do lugar, então o fuso do aparelho não interfere.
DateTime _wall(String s) {
  final p = DateTime.parse(s);
  return DateTime(p.year, p.month, p.day, p.hour, p.minute);
}

class CurrentWeather {
  const CurrentWeather({
    required this.time,
    required this.temperature,
    required this.apparentTemperature,
    required this.humidity,
    required this.dewPoint,
    required this.weatherCode,
    required this.isDay,
    required this.windSpeed,
    required this.windDirection,
    required this.windGusts,
    required this.pressure,
    required this.visibility,
    required this.uvIndex,
    required this.precipitation,
  });

  final DateTime time;
  final double temperature;
  final double apparentTemperature;
  final double humidity;
  final double dewPoint;
  final int weatherCode;
  final bool isDay;
  final double windSpeed;
  final double windDirection;
  final double windGusts;
  final double pressure;
  final double visibility;
  final double uvIndex;
  final double precipitation;

  String get condition => WeatherCode.describeShort(weatherCode, isDay: isDay);
  WeatherKind get kind => WeatherCode.kind(weatherCode, isDay: isDay);
}

class HourlyForecast {
  const HourlyForecast({
    required this.time,
    required this.temperature,
    required this.weatherCode,
    required this.isDay,
    required this.precipitationProbability,
    required this.precipitation,
    required this.pressure,
    required this.visibility,
    required this.uvIndex,
  });

  final DateTime time;
  final double temperature;
  final int weatherCode;
  final bool isDay;
  final int precipitationProbability;
  final double precipitation;
  final double? pressure;
  final double? visibility;
  final double? uvIndex;

  WeatherKind get kind => WeatherCode.kind(weatherCode, isDay: isDay);
}

class DailyForecast {
  const DailyForecast({
    required this.date,
    required this.weatherCode,
    required this.max,
    required this.min,
    required this.sunrise,
    required this.sunset,
    required this.uvIndexMax,
    required this.precipitationProbabilityMax,
    required this.precipitationSum,
    required this.windSpeedMax,
  });

  final DateTime date;
  final int weatherCode;
  final double max;
  final double min;
  final DateTime? sunrise;
  final DateTime? sunset;
  final double uvIndexMax;
  final int precipitationProbabilityMax;
  final double precipitationSum;
  final double windSpeedMax;

  String get condition => WeatherCode.describeShort(weatherCode);
  WeatherKind get kind => WeatherCode.kind(weatherCode);
}

/// Resposta completa da Open-Meteo Forecast para um lugar.
class Weather {
  Weather({
    required this.utcOffsetSeconds,
    required this.timezone,
    required this.timezoneAbbreviation,
    required this.current,
    required this.hourly,
    required this.daily,
    required this.fetchedAt,
    required this.raw,
  });

  final int utcOffsetSeconds;
  final String timezone;
  final String timezoneAbbreviation;
  final CurrentWeather current;
  final List<HourlyForecast> hourly;
  final List<DailyForecast> daily;

  /// Momento (UTC) em que os dados chegaram — usado no chip "Há 2 min"
  /// e no "Salvo às 13:05" do modo offline.
  final DateTime fetchedAt;

  /// JSON original, guardado no cache offline.
  final Map<String, dynamic> raw;

  Duration get utcOffset => Duration(seconds: utcOffsetSeconds);

  /// Hora local do lugar agora (relógio de parede do lugar).
  DateTime localNow([DateTime? nowUtc]) {
    final t = (nowUtc ?? DateTime.now().toUtc()).add(utcOffset);
    return DateTime(t.year, t.month, t.day, t.hour, t.minute, t.second);
  }

  /// Converte um instante UTC para o relógio de parede do lugar.
  DateTime toLocal(DateTime utc) {
    final t = utc.toUtc().add(utcOffset);
    return DateTime(t.year, t.month, t.day, t.hour, t.minute, t.second);
  }

  DailyForecast? get today => daily.isEmpty ? null : daily.first;

  /// As próximas [count] horas, começando pela hora corrente ("Agora").
  List<HourlyForecast> nextHours([int count = 24, DateTime? nowUtc]) {
    final now = localNow(nowUtc);
    final start = DateTime(now.year, now.month, now.day, now.hour);
    return hourly.where((h) => !h.time.isBefore(start)).take(count).toList();
  }

  /// Índice da hora corrente na lista horária (ou -1).
  int currentHourIndex([DateTime? nowUtc]) {
    final now = localNow(nowUtc);
    final start = DateTime(now.year, now.month, now.day, now.hour);
    return hourly.indexWhere((h) => !h.time.isBefore(start));
  }

  factory Weather.fromJson(Map<String, dynamic> json, {DateTime? fetchedAt}) {
    final c = json['current'] as Map<String, dynamic>;
    final h = json['hourly'] as Map<String, dynamic>;
    final d = json['daily'] as Map<String, dynamic>;

    List<dynamic> col(Map<String, dynamic> m, String k) => (m[k] as List?) ?? const [];
    Object? at(List<dynamic> l, int i) => i < l.length ? l[i] : null;

    final hTime = col(h, 'time');
    final hTemp = col(h, 'temperature_2m');
    final hCode = col(h, 'weather_code');
    final hDay = col(h, 'is_day');
    final hProb = col(h, 'precipitation_probability');
    final hPrec = col(h, 'precipitation');
    final hPres = col(h, 'pressure_msl');
    final hVis = col(h, 'visibility');
    final hUv = col(h, 'uv_index');

    final hourly = <HourlyForecast>[
      for (var i = 0; i < hTime.length; i++)
        HourlyForecast(
          time: _wall(hTime[i] as String),
          temperature: _d(at(hTemp, i)),
          weatherCode: _i(at(hCode, i)),
          isDay: _i(at(hDay, i), 1) == 1,
          precipitationProbability: _i(at(hProb, i)),
          precipitation: _d(at(hPrec, i)),
          pressure: _dn(at(hPres, i)),
          visibility: _dn(at(hVis, i)),
          uvIndex: _dn(at(hUv, i)),
        ),
    ];

    final dTime = col(d, 'time');
    final daily = <DailyForecast>[
      for (var i = 0; i < dTime.length; i++)
        DailyForecast(
          date: _wall('${dTime[i]}T00:00'),
          weatherCode: _i(at(col(d, 'weather_code'), i)),
          max: _d(at(col(d, 'temperature_2m_max'), i)),
          min: _d(at(col(d, 'temperature_2m_min'), i)),
          sunrise: at(col(d, 'sunrise'), i) is String ? _wall(at(col(d, 'sunrise'), i) as String) : null,
          sunset: at(col(d, 'sunset'), i) is String ? _wall(at(col(d, 'sunset'), i) as String) : null,
          uvIndexMax: _d(at(col(d, 'uv_index_max'), i)),
          precipitationProbabilityMax: _i(at(col(d, 'precipitation_probability_max'), i)),
          precipitationSum: _d(at(col(d, 'precipitation_sum'), i)),
          windSpeedMax: _d(at(col(d, 'wind_speed_10m_max'), i)),
        ),
    ];

    final currentTime = _wall(c['time'] as String);
    // Alguns campos (UV, visibilidade) podem faltar no bloco "current";
    // nesse caso usamos o valor da hora correspondente.
    final hi = hourly.lastIndexWhere((x) => !x.time.isAfter(currentTime));
    final hourNow = hi >= 0 ? hourly[hi] : (hourly.isNotEmpty ? hourly.first : null);

    final current = CurrentWeather(
      time: currentTime,
      temperature: _d(c['temperature_2m']),
      apparentTemperature: _d(c['apparent_temperature'], _d(c['temperature_2m'])),
      humidity: _d(c['relative_humidity_2m']),
      dewPoint: _d(c['dew_point_2m']),
      weatherCode: _i(c['weather_code']),
      isDay: _i(c['is_day'], 1) == 1,
      windSpeed: _d(c['wind_speed_10m']),
      windDirection: _d(c['wind_direction_10m']),
      windGusts: _d(c['wind_gusts_10m'], _d(c['wind_speed_10m'])),
      pressure: _d(c['pressure_msl'], hourNow?.pressure ?? 1013),
      visibility: _dn(c['visibility']) ?? hourNow?.visibility ?? 10000,
      uvIndex: _dn(c['uv_index']) ?? hourNow?.uvIndex ?? 0,
      precipitation: _d(c['precipitation']),
    );

    return Weather(
      utcOffsetSeconds: _i(json['utc_offset_seconds']),
      timezone: json['timezone'] as String? ?? 'GMT',
      timezoneAbbreviation: json['timezone_abbreviation'] as String? ?? '',
      current: current,
      hourly: hourly,
      daily: daily,
      fetchedAt: fetchedAt ?? DateTime.now().toUtc(),
      raw: json,
    );
  }
}

/// Qualidade do ar (Open-Meteo Air Quality, índice US AQI / EPA).
class AirQuality {
  const AirQuality({required this.usAqi, this.pm25, this.pm10});

  final int usAqi;
  final double? pm25;
  final double? pm10;

  factory AirQuality.fromJson(Map<String, dynamic> json) {
    final c = json['current'] as Map<String, dynamic>;
    return AirQuality(
      usAqi: _i(c['us_aqi']),
      pm25: _dn(c['pm2_5']),
      pm10: _dn(c['pm10']),
    );
  }

  Map<String, dynamic> toJson() => {
        'current': {'us_aqi': usAqi, 'pm2_5': pm25, 'pm10': pm10},
      };

  /// Categoria em pt-BR (faixas do US AQI).
  String get category {
    if (usAqi <= 50) return 'Boa';
    if (usAqi <= 100) return 'Moderada';
    if (usAqi <= 150) return 'Ruim p/ sensíveis';
    if (usAqi <= 200) return 'Ruim';
    if (usAqi <= 300) return 'Muito ruim';
    return 'Péssima';
  }

  String get advice {
    if (usAqi <= 50) return 'Bom dia para atividades ao ar livre.';
    if (usAqi <= 100) return 'Pessoas muito sensíveis devem reduzir esforço prolongado.';
    if (usAqi <= 150) return 'Grupos sensíveis devem evitar esforço ao ar livre.';
    if (usAqi <= 200) return 'Reduza atividades ao ar livre.';
    return 'Evite atividades ao ar livre.';
  }

  /// Posição do marcador na escala (0–300 → 0–1).
  double get scale => (usAqi / 300).clamp(0.0, 1.0);
}
