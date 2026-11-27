/// Um local (cidade/bairro) com coordenadas.
class Place {
  const Place({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.region,
    this.country,
    this.countryCode,
    this.detail,
    this.isCurrentLocation = false,
  });

  final String name;
  final double latitude;
  final double longitude;

  /// Estado/província (ex.: "SP" ou "Lisboa").
  final String? region;
  final String? country;
  final String? countryCode;

  /// Bairro ou complemento (ex.: "Vila Mariana").
  final String? detail;

  /// Veio do GPS do aparelho.
  final bool isCurrentLocation;

  /// Chave estável para salvar/remover (coordenadas arredondadas ~1 km).
  String get id => '${latitude.toStringAsFixed(2)},${longitude.toStringAsFixed(2)}';

  /// "São Paulo, SP"
  String get title => region != null && region!.isNotEmpty && region != name
      ? '$name, $region'
      : name;

  /// Linha de apoio usada na busca: "São Paulo · Brasil"
  String get searchSubtitle =>
      [if (region != null && region != name) region, country].whereType<String>().join(' · ');

  Place copyWith({String? detail, bool? isCurrentLocation, String? name, String? region}) => Place(
        name: name ?? this.name,
        latitude: latitude,
        longitude: longitude,
        region: region ?? this.region,
        country: country,
        countryCode: countryCode,
        detail: detail ?? this.detail,
        isCurrentLocation: isCurrentLocation ?? this.isCurrentLocation,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'lat': latitude,
        'lon': longitude,
        'region': region,
        'country': country,
        'cc': countryCode,
        'detail': detail,
        'gps': isCurrentLocation,
      };

  factory Place.fromJson(Map<String, dynamic> j) => Place(
        name: j['name'] as String,
        latitude: (j['lat'] as num).toDouble(),
        longitude: (j['lon'] as num).toDouble(),
        region: j['region'] as String?,
        country: j['country'] as String?,
        countryCode: j['cc'] as String?,
        detail: j['detail'] as String?,
        isCurrentLocation: j['gps'] as bool? ?? false,
      );

  @override
  bool operator ==(Object other) => other is Place && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Siglas dos estados brasileiros, para mostrar "São Paulo, SP".
const brazilianStates = {
  'Acre': 'AC', 'Alagoas': 'AL', 'Amapá': 'AP', 'Amazonas': 'AM', 'Bahia': 'BA',
  'Ceará': 'CE', 'Distrito Federal': 'DF', 'Espírito Santo': 'ES', 'Goiás': 'GO',
  'Maranhão': 'MA', 'Mato Grosso': 'MT', 'Mato Grosso do Sul': 'MS',
  'Minas Gerais': 'MG', 'Pará': 'PA', 'Paraíba': 'PB', 'Paraná': 'PR',
  'Pernambuco': 'PE', 'Piauí': 'PI', 'Rio de Janeiro': 'RJ',
  'Rio Grande do Norte': 'RN', 'Rio Grande do Sul': 'RS', 'Rondônia': 'RO',
  'Roraima': 'RR', 'Santa Catarina': 'SC', 'São Paulo': 'SP', 'Sergipe': 'SE',
  'Tocantins': 'TO',
};

/// Cidades sugeridas na tela Locais (coordenadas fixas, sem chamada de rede).
const suggestedPlaces = [
  Place(name: 'Belo Horizonte', region: 'MG', country: 'Brasil', countryCode: 'BR', latitude: -19.92, longitude: -43.94),
  Place(name: 'Porto Alegre', region: 'RS', country: 'Brasil', countryCode: 'BR', latitude: -30.03, longitude: -51.23),
  Place(name: 'Salvador', region: 'BA', country: 'Brasil', countryCode: 'BR', latitude: -12.97, longitude: -38.50),
  Place(name: 'Recife', region: 'PE', country: 'Brasil', countryCode: 'BR', latitude: -8.05, longitude: -34.88),
  Place(name: 'Manaus', region: 'AM', country: 'Brasil', countryCode: 'BR', latitude: -3.12, longitude: -60.02),
  Place(name: 'Rio de Janeiro', region: 'RJ', country: 'Brasil', countryCode: 'BR', latitude: -22.91, longitude: -43.17),
  Place(name: 'Curitiba', region: 'PR', country: 'Brasil', countryCode: 'BR', latitude: -25.43, longitude: -49.27),
  Place(name: 'Lisboa', country: 'Portugal', countryCode: 'PT', latitude: 38.72, longitude: -9.14),
];
