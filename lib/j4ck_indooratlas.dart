import 'dart:async';
import 'dart:ui';

import 'j4ck_indooratlas_platform_interface.dart';

class J4ckIndooratlas {
  J4ckIndooratlas._private();
  static final J4ckIndooratlas instance = J4ckIndooratlas._private();

  final J4ckIndooratlasPlatform _platform = J4ckIndooratlasPlatform.instance;

  Future<void> initializeIndoorAtlas({required String apiKey}) =>
      _platform.initializeIndoorAtlas(apiKey: apiKey);

  Future<void> startLocation() => _platform.startLocation();
  Future<void> stopLocation() => _platform.stopLocation();

  Future<void> startWayfinding({
    required double latitude,
    required double longitude,
    required int floor,
  }) =>
      _platform.startWayfinding(
          latitude: latitude, longitude: longitude, floor: floor);

  Future<void> stopWayfinding() => _platform.stopWayfinding();

  Future<void> dispose() => _platform.dispose();

  Stream<Map<String, dynamic>> get locationStream =>
      _platform.locationStream;

  Stream<Map<String, dynamic>> get geofenceStream =>
      _platform.geofenceStream;

  Stream<Map<String, dynamic>> get orientationStream =>
      _platform.orientationStream;

  Stream<Map<String, dynamic>> get wayfindingStream =>
      _platform.wayfindingStream;
  
  Stream<Map<String, dynamic>> get mapStream =>
    _platform.mapStream;
  
  Future<Map<String, dynamic>?> getCurrentFloorPlan() =>
    _platform.getCurrentFloorPlan();
  
  Stream<Offset?> get pixelLocationStream =>
    locationStream.map((evt) {
      final x = evt['pixelX'];
      final y = evt['pixelY'];
      if (x is num && y is num) {
        return Offset(x.toDouble(), y.toDouble());
      }
      return null;
    });

  Stream<List<Map<String, double>>> get wayfindingPointsStream =>
      wayfindingStream.map((evt) {
        final legs = evt['legs'];
        if (legs is List) {
          final List<Map<String, double>> points = [];
          for (final leg in legs) {
            if (leg is Map) {
              final begin = leg['begin'];
              final end = leg['end'];
              if (begin is Map && begin['lat'] != null && begin['lon'] != null) {
                points.add({
                  "lat": (begin['lat'] as num).toDouble(),
                  "lon": (begin['lon'] as num).toDouble(),
                });
              }
              if (end is Map && end['lat'] != null && end['lon'] != null) {
                points.add({
                  "lat": (end['lat'] as num).toDouble(),
                  "lon": (end['lon'] as num).toDouble(),
                });
              }
            }
          }
          return points;
        }
        return <Map<String, double>>[];
      }).asBroadcastStream();

}
