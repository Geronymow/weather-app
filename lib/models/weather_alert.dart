/// Nível do alerta, nas cores usadas pelo INMET/Defesa Civil.
enum AlertLevel {
  yellow('AMARELO', 'Perigo potencial', 'Alerta amarelo'),
  orange('LARANJA', 'Perigo', 'Alerta laranja'),
  red('VERMELHO', 'Grande perigo', 'Alerta vermelho'),
  advisory('AVISO', 'Informativo', 'Aviso');

  const AlertLevel(this.tag, this.severity, this.short);
  final String tag;
  final String severity;
  final String short;

  bool get isOfficialLevel => this != AlertLevel.advisory;
}

/// Tipo de aviso — define o ícone e a cor do cartão.
enum AlertTopic { warning, uv, cold, heat, rain, wind, storm }

class WeatherAlert {
  const WeatherAlert({
    required this.id,
    required this.title,
    required this.description,
    required this.level,
    required this.topic,
    required this.source,
    this.start,
    this.end,
    this.area,
    this.official = false,
  });

  final String id;
  final String title;
  final String description;
  final AlertLevel level;
  final AlertTopic topic;
  final String source;

  /// Início e fim no relógio de parede do lugar.
  final DateTime? start;
  final DateTime? end;
  final String? area;

  /// Emitido por órgão oficial (INMET). Os demais são calculados a partir
  /// da previsão (UV alto, frente fria, chuva nas próximas horas…).
  final bool official;
}
