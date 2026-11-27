import 'package:geolocator/geolocator.dart';

import '../models/settings.dart';

enum LocationStatus { granted, denied, deniedForever, serviceDisabled, error }

class LocationResult {
  const LocationResult(this.status, [this.latitude, this.longitude]);
  final LocationStatus status;
  final double? latitude;
  final double? longitude;

  bool get ok => status == LocationStatus.granted && latitude != null;

  String get message => switch (status) {
        LocationStatus.granted => '',
        LocationStatus.denied => 'Permissão de localização negada.',
        LocationStatus.deniedForever =>
          'A localização está bloqueada. Libere nas configurações do aparelho ou do navegador.',
        LocationStatus.serviceDisabled => 'Ative a localização do aparelho.',
        LocationStatus.error => 'Não foi possível obter sua localização.',
      };
}

/// GPS via geolocator (Fused Location Provider no Android, Geolocation API na web).
class LocationService {
  /// Pede permissão (se preciso) e lê a posição atual.
  Future<LocationResult> locate(LocationPrecision precision, {bool request = true}) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LocationResult(LocationStatus.serviceDisabled);
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied && request) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied) return const LocationResult(LocationStatus.denied);
      if (perm == LocationPermission.deniedForever) {
        return const LocationResult(LocationStatus.deniedForever);
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: precision == LocationPrecision.precise
              ? LocationAccuracy.high
              : LocationAccuracy.low,
          timeLimit: const Duration(seconds: 20),
        ),
      );
      return LocationResult(LocationStatus.granted, pos.latitude, pos.longitude);
    } catch (_) {
      // Timeout do GPS: tenta a última posição conhecida (não existe na web).
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) {
          return LocationResult(LocationStatus.granted, last.latitude, last.longitude);
        }
      } catch (_) {}
      return const LocationResult(LocationStatus.error);
    }
  }

  Future<void> openSettings() async {
    try {
      await Geolocator.openAppSettings();
    } catch (_) {}
  }
}
