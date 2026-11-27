import '../models/settings.dart';

/// Número com vírgula decimal (pt-BR): 3.8 → "3,8".
String dec(double v, int digits) => v.toStringAsFixed(digits).replaceAll('.', ',');

/// Conversões e formatação de unidades. A API sempre devolve °C, km/h e hPa;
/// a conversão acontece só na exibição, então trocar a unidade é instantâneo.
class Units {
  const Units(this.settings);
  final AppSettings settings;

  double temp(double celsius) => settings.tempUnit == TempUnit.fahrenheit
      ? celsius * 9 / 5 + 32
      : celsius;

  /// "24°"
  String deg(double celsius) => '${temp(celsius).round()}°';

  double wind(double kmh) => switch (settings.windUnit) {
        WindUnit.kmh => kmh,
        WindUnit.ms => kmh / 3.6,
        WindUnit.mph => kmh / 1.609344,
      };

  String windValue(double kmh) {
    final v = wind(kmh);
    return settings.windUnit == WindUnit.ms ? dec(v, 1) : '${v.round()}';
  }

  /// "14 km/h"
  String windText(double kmh) => '${windValue(kmh)} ${settings.windUnit.label}';

  double pressure(double hpa) => switch (settings.pressureUnit) {
        PressureUnit.hpa => hpa,
        PressureUnit.mmhg => hpa * 0.750062,
        PressureUnit.inhg => hpa * 0.0295300,
      };

  String pressureValue(double hpa) => settings.pressureUnit == PressureUnit.inhg
      ? dec(pressure(hpa), 2)
      : '${pressure(hpa).round()}';

  static String cardinal(double degrees) {
    const dirs = ['N', 'NE', 'L', 'SE', 'S', 'SO', 'O', 'NO'];
    final i = ((degrees % 360) / 45).round() % 8;
    return dirs[i];
  }

  static String visibility(double meters) {
    if (meters >= 10000) return '${(meters / 1000).round()} km';
    if (meters >= 1000) return '${dec(meters / 1000, 1)} km';
    return '${meters.round()} m';
  }

  static String mm(double v) =>
      v == 0 ? '0 mm' : (v < 10 ? '${dec(v, 1)} mm' : '${v.round()} mm');
}
