import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../core/units.dart';
import '../core/weather_codes.dart';
import '../models/place.dart';
import '../models/weather.dart';
import '../models/weather_alert.dart';
import 'http_json.dart';

/// Alertas: oficiais (INMET, só para o Brasil) + avisos calculados a partir
/// da previsão (UV alto, frente fria, chuva/tempestade próxima, calor, vento).
class AlertsService {
  AlertsService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  Future<List<WeatherAlert>> alertsFor(Place place, Weather weather) async {
    final official = await _inmet(place);
    final derived = deriveFromForecast(weather, place: place);
    return [...official, ...derived];
  }

  // -------------------------------------------------------------------
  // INMET (Alert-AS). Em navegadores a API pode bloquear CORS; nesse caso
  // ou sem rede, seguimos só com os avisos calculados.
  // -------------------------------------------------------------------
  Future<List<WeatherAlert>> _inmet(Place place) async {
    if ((place.countryCode ?? '').toUpperCase() != 'BR') return const [];
    try {
      final json = await getJson(
        _client,
        Uri.https('apiprevmet3.inmet.gov.br', '/avisos/ativos'),
        service: 'INMET',
        timeout: const Duration(seconds: 8),
      );
      return parseInmet(json, place);
    } catch (_) {
      return const [];
    }
  }

  static String _norm(String s) {
    const from = 'áàâãäéèêëíìîïóòôõöúùûüçÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ';
    const to = 'aaaaaeeeeiiiiooooouuuucAAAAAEEEEIIIIOOOOOUUUUC';
    final b = StringBuffer();
    for (final ch in s.split('')) {
      final i = from.indexOf(ch);
      b.write(i >= 0 ? to[i] : ch);
    }
    return b.toString().toLowerCase();
  }

  /// Interpreta a resposta do INMET de forma tolerante (campos opcionais).
  static List<WeatherAlert> parseInmet(Object? json, Place place) {
    final items = <Map<String, dynamic>>[];
    void collect(Object? v) {
      if (v is List) {
        items.addAll(v.whereType<Map>().map((m) => m.cast<String, dynamic>()));
      } else if (v is Map) {
        for (final k in ['hoje', 'futuro']) {
          collect(v[k]);
        }
      }
    }

    collect(json);
    final city = _norm(place.name);
    final uf = (place.region ?? '').toUpperCase();
    final out = <WeatherAlert>[];

    for (final it in items) {
      final municipios = _norm('${it['municipios'] ?? ''}');
      // Formato típico: "São Paulo - SP (3550308), Osasco - SP (...)"
      final hit = municipios.contains('$city - ${uf.toLowerCase()}') ||
          (uf.isEmpty && municipios.contains(city));
      if (!hit) continue;

      final sev = _norm('${it['severidade'] ?? ''}');
      final level = sev.contains('grande')
          ? AlertLevel.red
          : (sev == 'perigo' ? AlertLevel.orange : AlertLevel.yellow);
      final title = '${it['descricao'] ?? 'Alerta meteorológico'}';
      final riscos = it['riscos'];
      final desc = riscos is List ? riscos.join(' ') : '${riscos ?? ''}';

      out.add(WeatherAlert(
        id: 'inmet-${it['id'] ?? title}',
        title: _capitalize(title),
        description: desc.trim().isEmpty ? 'Acompanhe as orientações da Defesa Civil.' : desc.trim(),
        level: level,
        topic: _topicFromText(_norm(title)),
        source: 'INMET · Defesa Civil',
        start: _dt(it['data_inicio'], it['hora_inicio']) ?? _parse(it['inicio']),
        end: _dt(it['data_fim'], it['hora_fim']) ?? _parse(it['fim']),
        area: place.title,
        official: true,
      ));
    }
    out.sort((a, b) => b.level.index.compareTo(a.level.index));
    return out;
  }

  static AlertTopic _topicFromText(String t) {
    if (t.contains('tempestade')) return AlertTopic.storm;
    if (t.contains('chuva')) return AlertTopic.rain;
    if (t.contains('vento')) return AlertTopic.wind;
    if (t.contains('calor') || t.contains('umidade')) return AlertTopic.heat;
    if (t.contains('frio') || t.contains('geada')) return AlertTopic.cold;
    return AlertTopic.warning;
  }

  static DateTime? _dt(Object? date, Object? time) {
    if (date is! String || date.isEmpty) return null;
    final t = time is String && time.isNotEmpty ? time : '00:00';
    return DateTime.tryParse('${date}T${t.length == 5 ? '$t:00' : t}');
  }

  static DateTime? _parse(Object? v) => v is String ? DateTime.tryParse(v) : null;

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();

  // -------------------------------------------------------------------
  // Avisos calculados a partir da previsão
  // -------------------------------------------------------------------
  static List<WeatherAlert> deriveFromForecast(Weather w, {Place? place, DateTime? nowUtc}) {
    const src = 'Previsão Open-Meteo';
    final out = <WeatherAlert>[];
    final now = w.localNow(nowUtc);
    final next = w.nextHours(24, nowUtc);
    final today = w.today;
    final hourFmt = DateFormat('H', 'pt_BR');
    String h(DateTime t) => '${hourFmt.format(t)}h';

    // Tempestade nas próximas 24 h.
    final storm = next.where((x) => WeatherCode.isStorm(x.weatherCode)).toList();
    if (storm.isNotEmpty) {
      out.add(WeatherAlert(
        id: 'storm',
        title: 'Possibilidade de tempestade',
        description: 'Raios, rajadas de vento e chuva forte entre ${h(storm.first.time)} e '
            '${h(storm.last.time.add(const Duration(hours: 1)))}. Evite áreas abertas.',
        level: AlertLevel.advisory,
        topic: AlertTopic.storm,
        source: src,
        start: storm.first.time,
        end: storm.last.time.add(const Duration(hours: 1)),
        area: place?.title,
      ));
    }

    // Chuva nas próximas 2 horas.
    final soon = next.take(3).where((x) => x.precipitationProbability >= 50 || x.precipitation >= 0.5);
    if (soon.isNotEmpty && storm.isEmpty) {
      final f = soon.first;
      out.add(WeatherAlert(
        id: 'rain-soon',
        title: 'Chuva nas próximas 2 horas',
        description: 'A partir das ${h(f.time)}, com ${f.precipitationProbability}% de chance'
            '${f.precipitation > 0 ? ' e ${dec(f.precipitation, 1)} mm' : ''}. Leve o guarda-chuva.',
        level: AlertLevel.advisory,
        topic: AlertTopic.rain,
        source: src,
        start: f.time,
        area: place?.title,
      ));
    }

    if (today != null) {
      // UV alto hoje.
      if (today.uvIndexMax >= 6) {
        final uv = today.uvIndexMax.round();
        final label = uv >= 11 ? 'extremo' : (uv >= 8 ? 'muito alto' : 'alto');
        final todayHours = w.hourly.where((x) =>
            x.time.day == today.date.day && x.time.month == today.date.month && (x.uvIndex ?? 0) >= 6);
        final window = todayHours.isEmpty
            ? 'Perto do meio-dia'
            : 'Entre ${h(todayHours.first.time)} e ${h(todayHours.last.time.add(const Duration(hours: 1)))}';
        out.add(WeatherAlert(
          id: 'uv',
          title: 'Índice UV $label ($uv)',
          description: '$window. Use protetor solar e evite exposição prolongada.',
          level: AlertLevel.advisory,
          topic: AlertTopic.uv,
          source: src,
          area: place?.title,
        ));
      }

      // Chuva volumosa hoje.
      if (today.precipitationSum >= 30) {
        out.add(WeatherAlert(
          id: 'heavy-rain',
          title: 'Chuva forte hoje',
          description: 'Acumulado previsto de ${today.precipitationSum.round()} mm. '
              'Risco de alagamentos em áreas baixas.',
          level: AlertLevel.advisory,
          topic: AlertTopic.rain,
          source: src,
          area: place?.title,
        ));
      }

      // Calor intenso e ventos fortes nos próximos 3 dias.
      for (final d in w.daily.take(3)) {
        final day = _dayName(d.date, now);
        if (d.max >= 34) {
          out.add(WeatherAlert(
            id: 'heat-${d.date.day}',
            title: 'Calor intenso $day',
            description: 'Máxima de ${d.max.round()}°. Beba água e evite sol entre 10h e 16h.',
            level: AlertLevel.advisory,
            topic: AlertTopic.heat,
            source: src,
            area: place?.title,
          ));
          break;
        }
      }
      for (final d in w.daily.take(3)) {
        if (d.windSpeedMax >= 50) {
          out.add(WeatherAlert(
            id: 'wind-${d.date.day}',
            title: 'Ventos fortes ${_dayName(d.date, now)}',
            description: 'Rajadas de até ${d.windSpeedMax.round()} km/h. Cuidado com objetos soltos.',
            level: AlertLevel.advisory,
            topic: AlertTopic.wind,
            source: src,
            area: place?.title,
          ));
          break;
        }
      }

      // Frente fria: queda forte da máxima em relação a hoje (até 5 dias).
      DailyForecast? cold;
      var drop = 0.0;
      for (final d in w.daily.skip(1).take(5)) {
        final dd = today.max - d.max;
        if (dd >= 6 && dd > drop) {
          drop = dd;
          cold = d;
        }
      }
      if (cold != null) {
        final wd = DateFormat('EEEE', 'pt_BR').format(cold.date);
        out.add(WeatherAlert(
          id: 'cold-front',
          title: 'Frente fria ${_dayName(cold.date, now)}',
          description: 'Queda de até ${drop.round()}° — mínima de ${cold.min.round()}° '
              'na madrugada de $wd.',
          level: AlertLevel.advisory,
          topic: AlertTopic.cold,
          source: src,
          area: place?.title,
        ));
      }
    }
    return out;
  }

  /// "hoje", "amanhã" ou "na quinta".
  static String _dayName(DateTime d, DateTime now) {
    final a = DateTime(now.year, now.month, now.day);
    final diff = DateTime(d.year, d.month, d.day).difference(a).inDays;
    if (diff <= 0) return 'hoje';
    if (diff == 1) return 'amanhã';
    final wd = DateFormat('EEEE', 'pt_BR').format(d).split('-').first;
    final prep = (d.weekday == DateTime.saturday || d.weekday == DateTime.sunday) ? 'no' : 'na';
    return '$prep $wd';
  }
}
