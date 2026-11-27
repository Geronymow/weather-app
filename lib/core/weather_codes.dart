import 'theme.dart';

/// Tipo de ilustração (mesmos nomes do protótipo: wx/sun, wx/partly…).
enum WeatherKind { sun, partly, cloud, rain, storm, night, nightCloud, snow, fog }

/// Interpretação do weather_code (WMO) retornado pela Open-Meteo.
class WeatherCode {
  static String describe(int code) {
    switch (code) {
      case 0:
        return 'Céu limpo';
      case 1:
        return 'Predominantemente limpo';
      case 2:
        return 'Parcialmente nublado';
      case 3:
        return 'Nublado';
      case 45:
      case 48:
        return 'Neblina';
      case 51:
      case 53:
      case 55:
        return 'Garoa';
      case 56:
      case 57:
        return 'Garoa congelante';
      case 61:
        return 'Chuva fraca';
      case 63:
        return 'Chuva';
      case 65:
        return 'Chuva forte';
      case 66:
      case 67:
        return 'Chuva congelante';
      case 71:
      case 73:
      case 75:
      case 77:
        return 'Neve';
      case 80:
      case 81:
        return 'Pancadas de chuva';
      case 82:
        return 'Pancadas fortes';
      case 85:
      case 86:
        return 'Pancadas de neve';
      case 95:
        return 'Tempestade';
      case 96:
      case 99:
        return 'Tempestade com granizo';
      default:
        return 'Indefinido';
    }
  }

  /// Texto curto para o dia ensolarado (o protótipo usa "Ensolarado").
  static String describeShort(int code, {bool isDay = true}) {
    if (code == 0) return isDay ? 'Ensolarado' : 'Céu limpo';
    return describe(code);
  }

  static WeatherKind kind(int code, {bool isDay = true}) {
    if (code == 0 || code == 1) return isDay ? WeatherKind.sun : WeatherKind.night;
    if (code == 2) return isDay ? WeatherKind.partly : WeatherKind.nightCloud;
    if (code == 3) return WeatherKind.cloud;
    if (code == 45 || code == 48) return WeatherKind.fog;
    if (isRain(code)) return WeatherKind.rain;
    if ((code >= 71 && code <= 77) || code == 85 || code == 86) return WeatherKind.snow;
    if (isStorm(code)) return WeatherKind.storm;
    return WeatherKind.cloud;
  }

  static Sky sky(int code, {bool isDay = true}) {
    if (isStorm(code)) return Sky.storm;
    if (isRain(code)) return Sky.rain;
    if (!isDay) return Sky.night;
    if (code == 0 || code == 1) return Sky.sunny;
    if (code == 2) return Sky.partly;
    return Sky.cloudy;
  }

  static bool isRain(int code) =>
      (code >= 51 && code <= 67) || (code >= 80 && code <= 82);

  static bool isStorm(int code) => code >= 95 && code <= 99;
}
