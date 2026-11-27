import 'package:material_ui/material_ui.dart' show ThemeMode;

enum TempUnit {
  celsius('°C'),
  fahrenheit('°F');

  const TempUnit(this.label);
  final String label;
}

enum WindUnit {
  kmh('km/h'),
  ms('m/s'),
  mph('mph');

  const WindUnit(this.label);
  final String label;
}

enum PressureUnit {
  hpa('hPa'),
  mmhg('mmHg'),
  inhg('inHg');

  const PressureUnit(this.label);
  final String label;
}

enum LocationPrecision {
  precise('Precisa (GPS)'),
  approximate('Aproximada');

  const LocationPrecision(this.label);
  final String label;
}

/// Preferências do usuário (tela Ajustes + preferências de notificação).
class AppSettings {
  const AppSettings({
    this.tempUnit = TempUnit.celsius,
    this.windUnit = WindUnit.kmh,
    this.pressureUnit = PressureUnit.hpa,
    this.themeMode = ThemeMode.dark, // o protótipo é escuro (dark-first)
    this.dynamicBackground = true,
    this.precision = LocationPrecision.precise,
    this.autoRefresh = true,
    this.refreshMinutes = 30,
    this.notifySevere = true,
    this.notifyRainSoon = true,
    this.notifyDailySummary = false,
  });

  final TempUnit tempUnit;
  final WindUnit windUnit;
  final PressureUnit pressureUnit;
  final ThemeMode themeMode;
  final bool dynamicBackground;
  final LocationPrecision precision;
  final bool autoRefresh;
  final int refreshMinutes;
  final bool notifySevere;
  final bool notifyRainSoon;
  final bool notifyDailySummary;

  static const refreshOptions = [15, 30, 60, 120];

  AppSettings copyWith({
    TempUnit? tempUnit,
    WindUnit? windUnit,
    PressureUnit? pressureUnit,
    ThemeMode? themeMode,
    bool? dynamicBackground,
    LocationPrecision? precision,
    bool? autoRefresh,
    int? refreshMinutes,
    bool? notifySevere,
    bool? notifyRainSoon,
    bool? notifyDailySummary,
  }) =>
      AppSettings(
        tempUnit: tempUnit ?? this.tempUnit,
        windUnit: windUnit ?? this.windUnit,
        pressureUnit: pressureUnit ?? this.pressureUnit,
        themeMode: themeMode ?? this.themeMode,
        dynamicBackground: dynamicBackground ?? this.dynamicBackground,
        precision: precision ?? this.precision,
        autoRefresh: autoRefresh ?? this.autoRefresh,
        refreshMinutes: refreshMinutes ?? this.refreshMinutes,
        notifySevere: notifySevere ?? this.notifySevere,
        notifyRainSoon: notifyRainSoon ?? this.notifyRainSoon,
        notifyDailySummary: notifyDailySummary ?? this.notifyDailySummary,
      );

  Map<String, dynamic> toJson() => {
        'tempUnit': tempUnit.name,
        'windUnit': windUnit.name,
        'pressureUnit': pressureUnit.name,
        'themeMode': themeMode.name,
        'dynamicBackground': dynamicBackground,
        'precision': precision.name,
        'autoRefresh': autoRefresh,
        'refreshMinutes': refreshMinutes,
        'notifySevere': notifySevere,
        'notifyRainSoon': notifyRainSoon,
        'notifyDailySummary': notifyDailySummary,
      };

  factory AppSettings.fromJson(Map<String, dynamic> j) {
    T pick<T extends Enum>(List<T> values, Object? name, T fallback) =>
        values.where((v) => v.name == name).firstOrNull ?? fallback;
    const d = AppSettings();
    return AppSettings(
      tempUnit: pick(TempUnit.values, j['tempUnit'], d.tempUnit),
      windUnit: pick(WindUnit.values, j['windUnit'], d.windUnit),
      pressureUnit: pick(PressureUnit.values, j['pressureUnit'], d.pressureUnit),
      themeMode: pick(ThemeMode.values, j['themeMode'], d.themeMode),
      dynamicBackground: j['dynamicBackground'] as bool? ?? d.dynamicBackground,
      precision: pick(LocationPrecision.values, j['precision'], d.precision),
      autoRefresh: j['autoRefresh'] as bool? ?? d.autoRefresh,
      refreshMinutes: (j['refreshMinutes'] as num?)?.toInt() ?? d.refreshMinutes,
      notifySevere: j['notifySevere'] as bool? ?? d.notifySevere,
      notifyRainSoon: j['notifyRainSoon'] as bool? ?? d.notifyRainSoon,
      notifyDailySummary: j['notifyDailySummary'] as bool? ?? d.notifyDailySummary,
    );
  }
}
