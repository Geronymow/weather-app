import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../core/units.dart';
import '../models/place.dart';
import '../models/settings.dart';
import '../models/weather.dart';
import '../models/weather_alert.dart';
import '../services/alerts_service.dart';
import '../services/geocoding_service.dart';
import '../services/http_json.dart';
import '../services/location_service.dart';
import '../services/storage_service.dart';
import '../services/weather_service.dart';

/// Estado da previsão de um lugar.
class PlaceWeather {
  Weather? weather;
  AirQuality? air;
  List<WeatherAlert> alerts = const [];
  bool loading = false;

  /// Sem rede: [weather] veio do cache salvo.
  bool offline = false;
  String? error;

  bool get hasData => weather != null;
}

/// Estado global do app (padrão ChangeNotifier, sem pacotes extras).
class AppState extends ChangeNotifier {
  AppState({
    required this.storage,
    WeatherService? weatherService,
    GeocodingService? geocoding,
    AlertsService? alertsService,
    LocationService? location,
  })  : weatherService = weatherService ?? WeatherService(),
        geocoding = geocoding ?? GeocodingService(),
        alertsService = alertsService ?? AlertsService(),
        location = location ?? LocationService();

  final StorageService storage;
  final WeatherService weatherService;
  final GeocodingService geocoding;
  final AlertsService alertsService;
  final LocationService location;

  /// Usado para avisos (lembretes) vindos de fora de uma tela específica.
  final messengerKey = GlobalKey<ScaffoldMessengerState>();

  AppSettings settings = const AppSettings();
  bool onboarded = false;
  bool bootstrapped = false;
  List<Place> savedPlaces = [];
  Place? gpsPlace;
  Place? selectedPlace;
  LocationStatus? locationStatus;
  bool locating = false;

  /// O usuário escolheu ver a previsão salva mesmo sem conexão.
  bool viewCachedWhileOffline = false;

  final Map<String, PlaceWeather> _data = {};
  final Set<String> reminders = {};
  final Set<String> _remindersFired = {};
  Timer? _autoRefresh;
  Timer? _reminderTicker;

  Units get units => Units(settings);

  /// Lugar mostrado no Início: o escolhido em Locais ou a posição do GPS.
  Place? get activePlace => selectedPlace ?? gpsPlace;

  PlaceWeather dataFor(Place p) => _data.putIfAbsent(p.id, PlaceWeather.new);
  PlaceWeather? get active => activePlace == null ? null : dataFor(activePlace!);

  // -----------------------------------------------------------------
  // Inicialização (tela Splash)
  // -----------------------------------------------------------------
  Future<void> bootstrap() async {
    settings = storage.loadSettings();
    onboarded = storage.onboarded;
    savedPlaces = storage.loadPlaces();
    gpsPlace = storage.loadGpsPlace();
    selectedPlace = storage.loadSelectedPlace();

    // Mostra de imediato o que estiver salvo; a rede atualiza depois.
    for (final p in [?gpsPlace, ?selectedPlace, ...savedPlaces]) {
      final c = storage.loadWeather(p.id);
      if (c != null) {
        dataFor(p)
          ..weather = c.weather
          ..air = c.air
          ..alerts = AlertsService.deriveFromForecast(c.weather, place: p);
      }
    }
    _restartAutoRefresh();
    _reminderTicker = Timer.periodic(const Duration(seconds: 30), (_) => _checkReminders());

    if (onboarded) {
      final work = selectedPlace == null
          ? locate(request: false).then((r) async {
              if (!r.ok && activePlace != null) await load(activePlace!);
            })
          : load(selectedPlace!);
      // A Splash não espera para sempre: depois de 12 s segue com o cache.
      await work.timeout(const Duration(seconds: 12), onTimeout: () {});
    }
    bootstrapped = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _autoRefresh?.cancel();
    _reminderTicker?.cancel();
    super.dispose();
  }

  // -----------------------------------------------------------------
  // Onboarding e localização
  // -----------------------------------------------------------------
  Future<void> finishOnboarding() async {
    onboarded = true;
    await storage.setOnboarded();
    notifyListeners();
  }

  /// Lê o GPS, nomeia o lugar e carrega a previsão.
  Future<LocationResult> locate({bool request = true}) async {
    locating = true;
    notifyListeners();
    final r = await location.locate(settings.precision, request: request);
    locationStatus = r.status;
    if (r.ok) {
      final p = await geocoding.reverse(r.latitude!, r.longitude!);
      gpsPlace = p;
      selectedPlace = null;
      viewCachedWhileOffline = false;
      await storage.saveGpsPlace(p);
      await storage.saveSelectedPlace(null);
      locating = false;
      notifyListeners();
      await load(p);
    } else {
      locating = false;
      notifyListeners();
    }
    return r;
  }

  // -----------------------------------------------------------------
  // Locais
  // -----------------------------------------------------------------
  Future<void> selectPlace(Place p) async {
    selectedPlace = p.isCurrentLocation ? null : p;
    viewCachedWhileOffline = false;
    await storage.saveSelectedPlace(selectedPlace);
    notifyListeners();
    final d = dataFor(p);
    if (!d.hasData || d.offline || _stale(d.weather!)) await load(p);
  }

  bool isSaved(Place p) => savedPlaces.any((s) => s.id == p.id);

  Future<void> addPlace(Place p) async {
    if (!isSaved(p) && p.id != gpsPlace?.id) {
      savedPlaces = [...savedPlaces, p.copyWith(isCurrentLocation: false)];
      await storage.savePlaces(savedPlaces);
      notifyListeners();
    }
    if (!dataFor(p).hasData) await load(p);
  }

  Future<void> removePlace(Place p) async {
    savedPlaces = savedPlaces.where((s) => s.id != p.id).toList();
    await storage.savePlaces(savedPlaces);
    await storage.removeWeather(p.id);
    _data.remove(p.id);
    if (selectedPlace?.id == p.id) {
      selectedPlace = null;
      await storage.saveSelectedPlace(null);
    }
    notifyListeners();
  }

  /// [newIndex] já vem ajustado (onReorderItem).
  Future<void> reorderPlaces(int oldIndex, int newIndex) async {
    final list = [...savedPlaces];
    list.insert(newIndex, list.removeAt(oldIndex));
    savedPlaces = list;
    await storage.savePlaces(list);
    notifyListeners();
  }

  /// Atualiza os locais salvos cujo dado esteja velho (tela Locais).
  Future<void> refreshSaved() => Future.wait([
        for (final p in [?gpsPlace, ...savedPlaces])
          if (!dataFor(p).hasData || _stale(dataFor(p).weather!)) load(p),
      ]);

  bool _stale(Weather w) =>
      DateTime.now().toUtc().difference(w.fetchedAt) > const Duration(minutes: 10);

  // -----------------------------------------------------------------
  // Previsão
  // -----------------------------------------------------------------
  Future<void> refreshActive() async {
    final p = activePlace;
    if (p == null) return;
    if (p.isCurrentLocation && selectedPlace == null) {
      final r = await locate(request: false);
      if (r.ok) return;
    }
    await load(p);
  }

  Future<void> load(Place p) async {
    final d = dataFor(p);
    if (d.loading) return;
    d
      ..loading = true
      ..error = null;
    notifyListeners();
    try {
      final forecast = weatherService.fetchForecast(p.latitude, p.longitude);
      final air = weatherService
          .fetchAirQuality(p.latitude, p.longitude)
          .then<AirQuality?>((a) => a)
          .catchError((_) => d.air);
      final w = await forecast;
      d
        ..weather = w
        ..air = await air
        ..offline = false
        ..alerts = AlertsService.deriveFromForecast(w, place: p);
      if (identical(p, activePlace) || p.id == activePlace?.id) viewCachedWhileOffline = false;
      await storage.saveWeather(p.id, w, d.air);
      notifyListeners();
      // Alertas oficiais chegam depois, sem atrasar a tela.
      d.alerts = await alertsService.alertsFor(p, w);
      if (p.id == activePlace?.id) _notifyNew(d.alerts);
    } on NetworkException {
      final c = storage.loadWeather(p.id);
      if (c != null) {
        d
          ..weather = c.weather
          ..air = c.air
          ..alerts = AlertsService.deriveFromForecast(c.weather, place: p);
      }
      d.offline = true;
    } catch (e) {
      d.error = e.toString();
    } finally {
      d.loading = false;
      notifyListeners();
    }
  }

  void showCachedWhileOffline() {
    viewCachedWhileOffline = true;
    notifyListeners();
  }

  // -----------------------------------------------------------------
  // Ajustes
  // -----------------------------------------------------------------
  Future<void> updateSettings(AppSettings s) async {
    final timerChanged =
        s.autoRefresh != settings.autoRefresh || s.refreshMinutes != settings.refreshMinutes;
    settings = s;
    notifyListeners();
    await storage.saveSettings(s);
    if (timerChanged) _restartAutoRefresh();
  }

  void _restartAutoRefresh() {
    _autoRefresh?.cancel();
    if (!settings.autoRefresh) return;
    _autoRefresh = Timer.periodic(Duration(minutes: settings.refreshMinutes), (_) {
      if (activePlace != null) load(activePlace!);
    });
  }

  // -----------------------------------------------------------------
  // Avisos dentro do app (preferências de Notificações)
  // -----------------------------------------------------------------
  final Set<String> _notified = {};

  void _notifyNew(List<WeatherAlert> alerts) {
    for (final a in alerts) {
      final wanted = (a.official && settings.notifySevere) ||
          (a.topic == AlertTopic.rain && a.id == 'rain-soon' && settings.notifyRainSoon) ||
          (a.topic == AlertTopic.storm && !a.official && settings.notifySevere);
      if (!wanted || !_notified.add(a.id)) continue;
      messengerKey.currentState?.showSnackBar(SnackBar(content: Text(a.title)));
      break; // um aviso por vez
    }
  }

  // -----------------------------------------------------------------
  // Lembretes de alertas ("Lembrar-me")
  // -----------------------------------------------------------------
  bool isReminded(WeatherAlert a) => reminders.contains(a.id);

  void toggleReminder(WeatherAlert a) {
    if (!reminders.remove(a.id)) reminders.add(a.id);
    notifyListeners();
    _checkReminders();
  }

  void _checkReminders() {
    final d = active;
    final w = d?.weather;
    if (d == null || w == null || reminders.isEmpty) return;
    final now = w.localNow();
    for (final a in d.alerts) {
      if (!reminders.contains(a.id) || _remindersFired.contains(a.id)) continue;
      final start = a.start;
      if (start == null || !start.isAfter(now.add(const Duration(minutes: 30)))) {
        _remindersFired.add(a.id);
        messengerKey.currentState?.showSnackBar(
          SnackBar(content: Text('Lembrete: ${a.title} — ${a.area ?? activePlace?.name ?? ''}')),
        );
      }
    }
  }
}

/// Dá acesso ao [AppState] para qualquer widget abaixo dele.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// Lê sem se inscrever para reconstruções (útil em callbacks).
  static AppState read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
