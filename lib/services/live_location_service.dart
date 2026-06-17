import 'dart:async';

import 'package:geolocator/geolocator.dart';

class LiveLocationSnapshot {
  final bool enabled;
  final bool permissionGranted;
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final DateTime? updatedAt;
  final String? message;

  const LiveLocationSnapshot({
    required this.enabled,
    required this.permissionGranted,
    this.latitude,
    this.longitude,
    this.accuracy,
    this.updatedAt,
    this.message,
  });

  bool get hasCoordinates => latitude != null && longitude != null;
}

class LiveLocationService {
  StreamSubscription<Position>? _subscription;

  Future<LiveLocationSnapshot> startTracking({
    required void Function(LiveLocationSnapshot snapshot) onData,
    void Function(String message)? onError,
  }) async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      return const LiveLocationSnapshot(
        enabled: false,
        permissionGranted: false,
        message:
            'Activa la ubicación del dispositivo para ver el seguimiento en vivo.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return const LiveLocationSnapshot(
        enabled: true,
        permissionGranted: false,
        message:
            'Permite el acceso a la ubicación para mostrar tu posición en tiempo real.',
      );
    }

    await _subscription?.cancel();

    _subscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).listen(
          (position) {
            onData(
              LiveLocationSnapshot(
                enabled: true,
                permissionGranted: true,
                latitude: position.latitude,
                longitude: position.longitude,
                accuracy: position.accuracy,
                updatedAt: position.timestamp.toLocal(),
              ),
            );
          },
          onError: (error) {
            onError?.call('No pudimos actualizar tu ubicación en tiempo real.');
          },
        );

    final current = await Geolocator.getCurrentPosition();
    return LiveLocationSnapshot(
      enabled: true,
      permissionGranted: true,
      latitude: current.latitude,
      longitude: current.longitude,
      accuracy: current.accuracy,
      updatedAt: current.timestamp.toLocal(),
    );
  }

  Future<void> openSettings() => Geolocator.openAppSettings();

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
