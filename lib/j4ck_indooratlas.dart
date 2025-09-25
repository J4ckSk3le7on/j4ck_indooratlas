// lib/j4ck_indooratlas.dart
library j4ck_indooratlas;

// Export all IndoorAtlas functionality
export 'indooratlas.dart';
export 'indooratlas_core.dart';
export 'indooratlas_listeners.dart';

// Backward compatibility with original API
import 'dart:async';
import 'dart:ui';
import 'indooratlas.dart';
import 'indooratlas_core.dart';

class J4ckIndooratlas {
  J4ckIndooratlas._private();
  static final J4ckIndooratlas instance = J4ckIndooratlas._private();

  Future<void> initializeIndoorAtlas({required String apiKey}) =>
      IndoorAtlas.initialize('1.0.0', apiKey);

  Future<void> startLocation() => IndoorAtlas.startPositioning();
  Future<void> stopLocation() => IndoorAtlas.stopPositioning();

  Future<void> startWayfinding({
    required double latitude,
    required double longitude,
    required int floor,
  }) =>
      IndoorAtlas.startWayfinding(latitude, longitude, floor: floor);

  Future<void> stopWayfinding() => IndoorAtlas.stopWayfinding();

  Future<void> dispose() => IndoorAtlas.stopPositioning();

  Stream<Map<String, dynamic>> get locationStream =>
      _createLocationStream();

  Stream<Map<String, dynamic>> get geofenceStream =>
      _createGeofenceStream();

  Stream<Map<String, dynamic>> get orientationStream =>
      _createOrientationStream();

  Stream<Map<String, dynamic>> get wayfindingStream =>
      _createWayfindingStream();
  
  Stream<Map<String, dynamic>> get mapStream =>
    _createMapStream();
  
  Future<Map<String, dynamic>?> getCurrentFloorPlan() async {
    final floorplan = IndoorAtlas.floorplan;
    if (floorplan == null) return null;
    
    return {
      'id': floorplan.id,
      'name': floorplan.name,
      'url': floorplan.url,
      'floorLevel': floorplan.floor,
      'bearing': floorplan.bearing,
      'bitmapWidth': floorplan.bitmapWidth,
      'bitmapHeight': floorplan.bitmapHeight,
      'widthMeters': floorplan.widthMeters,
      'heightMeters': floorplan.heightMeters,
      'metersToPixels': floorplan.metersToPixels,
      'pixelsToMeters': floorplan.pixelsToMeters,
    };
  }
  
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

  // Private stream creation methods
  Stream<Map<String, dynamic>> _createLocationStream() {
    final controller = StreamController<Map<String, dynamic>>.broadcast();
    
    final listener = IACallbackListener(
      name: 'LocationStream',
      onLocation: (location) {
        controller.add({
          'latitude': location.latitude,
          'longitude': location.longitude,
          'floorLevel': location.floor,
          'accuracy': location.accuracy,
          'bearing': location.heading,
          'time': location.timestamp.millisecondsSinceEpoch,
          'pixelX': location.pixel?.x,
          'pixelY': location.pixel?.y,
        });
      },
    );
    
    IndoorAtlas.subscribe(listener);
    
    controller.onCancel = () {
      IndoorAtlas.unsubscribe(listener);
    };
    
    return controller.stream;
  }

  Stream<Map<String, dynamic>> _createGeofenceStream() {
    final controller = StreamController<Map<String, dynamic>>.broadcast();
    
    final listener = IACallbackListener(
      name: 'GeofenceStream',
      onGeofences: (geofences) {
        controller.add({
          'event': 'geofences_updated',
          'geofences': geofences.map((g) => {
            'id': g.id,
            'name': g.name,
            'floor': g.floor,
            'payload': g.payload,
          }).toList(),
        });
      },
      onGeofenceEvent: (id, eventType) {
        controller.add({
          'event': eventType.toLowerCase(),
          'geofenceId': id,
        });
      },
    );
    
    IndoorAtlas.subscribe(listener);
    
    controller.onCancel = () {
      IndoorAtlas.unsubscribe(listener);
    };
    
    return controller.stream;
  }

  Stream<Map<String, dynamic>> _createOrientationStream() {
    final controller = StreamController<Map<String, dynamic>>.broadcast();
    
    final listener = IACallbackListener(
      name: 'OrientationStream',
      onHeading: (heading) {
        controller.add({
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'heading': heading,
        });
      },
      onOrientation: (x, y, z, w) {
        controller.add({
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'quaternion': [x, y, z, w],
        });
      },
    );
    
    IndoorAtlas.subscribe(listener);
    
    controller.onCancel = () {
      IndoorAtlas.unsubscribe(listener);
    };
    
    return controller.stream;
  }

  Stream<Map<String, dynamic>> _createWayfindingStream() {
    final controller = StreamController<Map<String, dynamic>>.broadcast();
    
    final listener = IACallbackListener(
      name: 'WayfindingStream',
      onWayfindingUpdate: (route) {
        final legs = route.legs.map((leg) => {
          'begin': {
            'lat': leg.begin.latitude,
            'lon': leg.begin.longitude,
            'floor': leg.begin.floor,
          },
          'end': {
            'lat': leg.end.latitude,
            'lon': leg.end.longitude,
            'floor': leg.end.floor,
          },
          'length': leg.length,
          'direction': leg.direction,
          'edgeIndex': leg.edgeIndex,
        }).toList();
        
        controller.add({
          'legs': legs,
          'error': route.error,
        });
      },
    );
    
    IndoorAtlas.subscribe(listener);
    
    controller.onCancel = () {
      IndoorAtlas.unsubscribe(listener);
    };
    
    return controller.stream;
  }

  Stream<Map<String, dynamic>> _createMapStream() {
    final controller = StreamController<Map<String, dynamic>>.broadcast();
    
    final listener = IACallbackListener(
      name: 'MapStream',
      onFloorplan: (enter, floorplan) {
        if (enter) {
          controller.add({
            'id': floorplan.id,
            'name': floorplan.name,
            'url': floorplan.url,
            'floorLevel': floorplan.floor,
            'bearing': floorplan.bearing,
            'bitmapWidth': floorplan.bitmapWidth,
            'bitmapHeight': floorplan.bitmapHeight,
            'widthMeters': floorplan.widthMeters,
            'heightMeters': floorplan.heightMeters,
            'metersToPixels': floorplan.metersToPixels,
            'pixelsToMeters': floorplan.pixelsToMeters,
          });
        }
      },
    );
    
    IndoorAtlas.subscribe(listener);
    
    controller.onCancel = () {
      IndoorAtlas.unsubscribe(listener);
    };
    
    return controller.stream;
  }
}