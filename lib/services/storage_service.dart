import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/place.dart';
import '../models/settings.dart';
import '../models/weather.dart';

/// Cache de uma previsão salva (para o modo "Sem conexão").
class CachedWeather {
  const CachedWeather(this.weather, this.air);
  final Weather weather;
  final AirQuality? air;
}

/// Persistência local (shared_preferences → SharedPreferences no Android,
/// NSUserDefaults no iOS, localStorage na web).
class StorageService {
  StorageService(this._prefs);
  final SharedPreferences _prefs;

  static Future<StorageService> open() async =>
      StorageService(await SharedPreferences.getInstance());

  static const _kOnboarded = 'onboarded';
  static const _kSettings = 'settings';
  static const _kPlaces = 'places';
  static const _kGps = 'gpsPlace';
  static const _kSelected = 'selectedPlace';
  static const _kCache = 'cache:';

  bool get onboarded => _prefs.getBool(_kOnboarded) ?? false;
  Future<void> setOnboarded() => _prefs.setBool(_kOnboarded, true);

  AppSettings loadSettings() {
    final s = _prefs.getString(_kSettings);
    if (s == null) return const AppSettings();
    try {
      return AppSettings.fromJson(jsonDecode(s) as Map<String, dynamic>);
    } catch (_) {
      return const AppSettings();
    }
  }

  Future<void> saveSettings(AppSettings s) => _prefs.setString(_kSettings, jsonEncode(s.toJson()));

  List<Place> loadPlaces() {
    final s = _prefs.getString(_kPlaces);
    if (s == null) return [];
    try {
      return (jsonDecode(s) as List).map((e) => Place.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> savePlaces(List<Place> places) =>
      _prefs.setString(_kPlaces, jsonEncode(places.map((p) => p.toJson()).toList()));

  Place? _place(String key) {
    final s = _prefs.getString(key);
    if (s == null) return null;
    try {
      return Place.fromJson(jsonDecode(s) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> _setPlace(String key, Place? p) =>
      p == null ? _prefs.remove(key) : _prefs.setString(key, jsonEncode(p.toJson()));

  Place? loadGpsPlace() => _place(_kGps);
  Future<void> saveGpsPlace(Place? p) => _setPlace(_kGps, p);

  Place? loadSelectedPlace() => _place(_kSelected);
  Future<void> saveSelectedPlace(Place? p) => _setPlace(_kSelected, p);

  CachedWeather? loadWeather(String placeId) {
    final s = _prefs.getString('$_kCache$placeId');
    if (s == null) return null;
    try {
      final j = jsonDecode(s) as Map<String, dynamic>;
      final w = Weather.fromJson(
        j['forecast'] as Map<String, dynamic>,
        fetchedAt: DateTime.parse(j['fetchedAt'] as String),
      );
      final a = j['air'] == null ? null : AirQuality.fromJson(j['air'] as Map<String, dynamic>);
      return CachedWeather(w, a);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveWeather(String placeId, Weather w, AirQuality? air) => _prefs.setString(
        '$_kCache$placeId',
        jsonEncode({
          'fetchedAt': w.fetchedAt.toIso8601String(),
          'forecast': w.raw,
          'air': air?.toJson(),
        }),
      );

  Future<void> removeWeather(String placeId) => _prefs.remove('$_kCache$placeId');
}
