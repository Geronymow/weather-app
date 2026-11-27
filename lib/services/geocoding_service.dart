import 'package:http/http.dart' as http;

import '../models/place.dart';
import 'http_json.dart';

/// Busca de cidades (Open-Meteo Geocoding), bairros (Nominatim), CEP (ViaCEP)
/// e geocodificação reversa para dar nome à posição do GPS (Nominatim).
class GeocodingService {
  GeocodingService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  static final _cep = RegExp(r'^\d{5}-?\d{3}$');

  Future<List<Place>> search(String query) async {
    final q = query.trim();
    if (q.length < 2) return const [];
    if (_cep.hasMatch(q)) return _searchCep(q.replaceAll('-', ''));

    final cities = await _searchOpenMeteo(q);
    if (cities.isNotEmpty) return cities;
    // Nada encontrado como cidade: tenta como bairro/endereço.
    return _searchNominatim(q);
  }

  Future<List<Place>> _searchOpenMeteo(String q) async {
    final uri = Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
      'name': q,
      'count': '10',
      'language': 'pt',
      'format': 'json',
    });
    final json = await getJson(_client, uri, service: 'Open-Meteo Geocoding') as Map<String, dynamic>;
    final results = (json['results'] as List?) ?? const [];
    return [
      for (final r in results.cast<Map<String, dynamic>>())
        Place(
          name: r['name'] as String,
          latitude: (r['latitude'] as num).toDouble(),
          longitude: (r['longitude'] as num).toDouble(),
          region: _region(r['admin1'] as String?, r['country_code'] as String?),
          country: r['country'] as String?,
          countryCode: (r['country_code'] as String?)?.toUpperCase(),
        ),
    ];
  }

  Future<List<Place>> _searchNominatim(String q) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': q,
      'format': 'jsonv2',
      'addressdetails': '1',
      'limit': '8',
      'accept-language': 'pt-BR',
    });
    final list = await getJson(_client, uri, service: 'Nominatim', headers: appHeaders) as List;
    return [
      for (final r in list.cast<Map<String, dynamic>>()) ?_fromNominatim(r),
    ];
  }

  Future<List<Place>> _searchCep(String cep) async {
    final uri = Uri.https('viacep.com.br', '/ws/$cep/json/');
    final j = await getJson(_client, uri, service: 'ViaCEP') as Map<String, dynamic>;
    if (j['erro'] != null) return const [];
    final city = j['localidade'] as String? ?? '';
    final uf = j['uf'] as String? ?? '';
    final bairro = j['bairro'] as String? ?? '';
    // ViaCEP não traz coordenadas: localizamos o bairro (ou a cidade).
    final hits = bairro.isNotEmpty ? await _searchNominatim('$bairro, $city, $uf, Brasil') : <Place>[];
    final base = hits.isNotEmpty ? hits.first : (await _searchOpenMeteo(city)).firstOrNull;
    if (base == null) return const [];
    return [
      Place(
        name: city,
        region: uf,
        country: 'Brasil',
        countryCode: 'BR',
        detail: bairro.isEmpty ? null : bairro,
        latitude: base.latitude,
        longitude: base.longitude,
      ),
    ];
  }

  /// Nome do lugar para uma coordenada do GPS. Nunca falha: sem rede,
  /// devolve um nome genérico para não travar o carregamento do clima.
  Future<Place> reverse(double lat, double lon) async {
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'lat': lat.toString(),
        'lon': lon.toString(),
        'format': 'jsonv2',
        'zoom': '16',
        'addressdetails': '1',
        'accept-language': 'pt-BR',
      });
      final j = await getJson(_client, uri,
          service: 'Nominatim', headers: appHeaders, timeout: const Duration(seconds: 8));
      final p = _fromNominatim(j as Map<String, dynamic>, lat: lat, lon: lon);
      if (p != null) return p.copyWith(isCurrentLocation: true);
    } catch (_) {
      // segue para o nome genérico
    }
    return Place(name: 'Localização atual', latitude: lat, longitude: lon, isCurrentLocation: true);
  }

  Place? _fromNominatim(Map<String, dynamic> r, {double? lat, double? lon}) {
    final a = (r['address'] as Map?)?.cast<String, dynamic>() ?? const {};
    final city = a['city'] ?? a['town'] ?? a['village'] ?? a['municipality'] ?? a['county'] ?? r['name'];
    if (city is! String || city.isEmpty) return null;
    final hood = a['suburb'] ?? a['neighbourhood'] ?? a['quarter'] ?? a['city_district'];
    final cc = (a['country_code'] as String?)?.toUpperCase();
    final iso = a['ISO3166-2-lvl4'] as String?; // ex.: "BR-SP"
    final region = (cc == 'BR' && iso != null && iso.contains('-'))
        ? iso.split('-').last
        : _region(a['state'] as String?, cc);
    return Place(
      name: city,
      latitude: lat ?? double.parse('${r['lat']}'),
      longitude: lon ?? double.parse('${r['lon']}'),
      region: region,
      country: a['country'] as String?,
      countryCode: cc,
      detail: hood is String && hood != city ? hood : null,
    );
  }

  static String? _region(String? admin1, String? countryCode) {
    if (admin1 == null) return null;
    if ((countryCode ?? '').toUpperCase() == 'BR') return brazilianStates[admin1] ?? admin1;
    return admin1;
  }
}
