import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

/// O servidor respondeu, mas com erro (4xx/5xx). Diferente de falta de rede.
class ApiException implements Exception {
  ApiException(this.service, this.statusCode);
  final String service;
  final int statusCode;

  @override
  String toString() => '$service respondeu com erro $statusCode';
}

/// Não foi possível falar com o servidor (sem internet, timeout, DNS…).
class NetworkException implements Exception {
  NetworkException(this.cause);
  final Object cause;

  @override
  String toString() => 'Sem conexão: $cause';
}

/// Identificação do app exigida pela política do Nominatim. No navegador o
/// cabeçalho User-Agent é controlado pelo browser, então só o enviamos fora da web.
Map<String, String> get appHeaders => kIsWeb
    ? const {}
    : const {'User-Agent': 'ClimaAgora/0.1 (Flutter; projeto academico)'};

Future<dynamic> getJson(
  http.Client client,
  Uri uri, {
  required String service,
  Duration timeout = const Duration(seconds: 15),
  Map<String, String>? headers,
}) async {
  final http.Response res;
  try {
    res = await client.get(uri, headers: headers).timeout(timeout);
  } catch (e) {
    throw NetworkException(e);
  }
  if (res.statusCode != 200) throw ApiException(service, res.statusCode);
  return jsonDecode(utf8.decode(res.bodyBytes));
}
