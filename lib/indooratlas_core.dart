// lib/indooratlas_core.dart
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'indooratlas.dart';

// ----------------- MethodChannel bridge -----------------
class IndoorAtlas {
  static const MethodChannel _ch = MethodChannel('com.j4ck.j4ck_indooratlas');
  static bool debugEnabled = false;

  // internal state
  static IAFloorplan? _currentFloorplan;
  static IALocation? _currentLocation;
  static String? _traceId;
  static final Set<IAListener> _listeners = Set.identity();
  static final Set<IAGeofence> _currentGeofences = Set.identity();

  // Nuevo: Estado de geocercas activadas para tracking visual
  static final Set<String> _triggeredGeofenceIds = Set.identity();

  // Nuevo: destino actual (para marcar en UI)
  static IACoordinate? _currentDestination;

  /// getter público
  static IACoordinate? get currentDestination => _currentDestination;

  // initialize channel handler
  static void _ensureHandler() {
    _ch.setMethodCallHandler((call) async {
      try {
        switch (call.method) {
          case 'onStatusChanged':
            final int code = (call.arguments as List).first as int;
            for (var l in _listeners) l.onStatus(IAStatus.values[code], '');
            break;
          case 'onLocationChanged':
            final Map map = (call.arguments as List).first as Map;
            final loc = IALocation.fromMap(map);
            _currentLocation = loc;

            // Actualizar estado de geofence
            _updateGeofenceState(loc);

            for (var l in _listeners) l.onLocation(loc);
            break;
          case 'onEnterRegion':
            final Map map = (call.arguments as List).first as Map;
            if (map.containsKey('floorPlan')) {
              _currentFloorplan = IAFloorplan.fromMap(map['floorPlan'] as Map);
              for (var l in _listeners) l.onFloorplan(true, _currentFloorplan!);
            }
            break;
          case 'onExitRegion':
            final Map map = (call.arguments as List).first as Map;
            if (map.containsKey('floorPlan')) {
              final fp = IAFloorplan.fromMap(map['floorPlan'] as Map);
              for (var l in _listeners) l.onFloorplan(false, fp);
              _currentFloorplan = null;
            }
            break;
          case 'onOrientationChanged':
            final args = call.arguments as List;
            // timestamp, x,y,z,w
            for (var l in _listeners) l.onOrientation(args[1], args[2], args[3], args[4]);
            break;
          case 'onHeadingChanged':
            final args = call.arguments as List;
            final heading = (args[1] as num).toDouble();
            for (var l in _listeners) l.onHeading(heading);
            break;
          case 'onGeofencesTriggered':
            final args = call.arguments as List;
            final geofenceMaps = (args[1] as List).cast<Map>();

            // Actualizar las geofences actuales
            _currentGeofences.clear();
            for (final geofenceMap in geofenceMaps) {
              final geofence = IAGeofence.fromMap(geofenceMap);
              _currentGeofences.add(geofence);
            }

            // Notificar a todos los listeners
            for (var l in _listeners) l.onGeofences(_currentGeofences.toList());
            break;
          case 'onGeofenceEvent':
            final args = call.arguments as List;
            final geofenceId = args[0] as String;
            final eventType = args[1] as String; // "ENTER" o "EXIT"

            if (eventType == "ENTER") {
              _triggeredGeofenceIds.add(geofenceId);
            } else if (eventType == "EXIT") {
              _triggeredGeofenceIds.remove(geofenceId);
            }

            for (var l in _listeners) l.onGeofenceEvent(geofenceId, eventType);
            break;
          case 'onWayfindingUpdate':
            // recibe un Map con la estructura de IARoute2Map desde native
            final Map map = (call.arguments as List).first as Map;
            final route = IARoute.fromMap(map);

            // Llamamos al método del listener (implementación concreta lo manejará)
            for (var l in _listeners) {
              try {
                l.onWayfindingUpdate(route);
              } catch (_) {}
            }
            break;
          default:
            if (debugEnabled) debugPrint('Unhandled method ${call.method}');
        }
      } catch (e, st) {
        if (debugEnabled) debugPrint('Error handling method ${call.method}: $e\n$st');
      }
    });
  }

  /// Actualiza el estado de las geocercas basado en la ubicación actual
  static void _updateGeofenceState(IALocation location) {
    if (_currentGeofences.isEmpty) return;

    final newTriggeredIds = <String>{};

    for (final geofence in _currentGeofences) {
      if (_isLocationInGeofence(location, geofence)) {
        newTriggeredIds.add(geofence.id);
      }
    }

    final previousTriggered = Set<String>.from(_triggeredGeofenceIds);
    _triggeredGeofenceIds
      ..clear()
      ..addAll(newTriggeredIds);

    for (final geofenceId in _currentGeofences.map((g) => g.id)) {
      final wasTriggered = previousTriggered.contains(geofenceId);
      final isNowTriggered = newTriggeredIds.contains(geofenceId);

      if (wasTriggered != isNowTriggered) {
        final eventType = isNowTriggered ? "ENTER" : "EXIT";
        for (var l in _listeners) l.onGeofenceEvent(geofenceId, eventType);
      }
    }
  }

  /// Verifica si una ubicación está dentro de una geocerca
  static bool _isLocationInGeofence(IALocation location, IAGeofence geofence) {
    if (geofence.coordinates.isEmpty) return false;

    final pointLat = location.latitude;
    final pointLon = location.longitude;
    return _isPointInPolygon(IACoordinate(pointLat, pointLon), geofence.coordinates);
  }

  /// Algoritmo de punto en polígono usando ray casting
  static bool _isPointInPolygon(IACoordinate point, List<IACoordinate> polygon) {
    if (polygon.length < 3) return false;

    bool inside = false;
    int j = polygon.length - 1;

    for (int i = 0; i < polygon.length; i++) {
      final xi = polygon[i].longitude;  // longitude is x-coordinate (east-west)
      final yi = polygon[i].latitude;   // latitude is y-coordinate (north-south)
      final xj = polygon[j].longitude;  // longitude is x-coordinate (east-west)
      final yj = polygon[j].latitude;   // latitude is y-coordinate (north-south)

      if (((yi > point.latitude) != (yj > point.latitude)) &&
          (point.longitude < (xj - xi) * (point.latitude - yi) / (yj - yi) + xi)) {
        inside = !inside;
      }
      j = i;
    }

    return inside;
  }

  // ----------------- Native commands -----------------
  static Future<void> initialize(String pluginVersion, String apiKey, {String endpoint = ''}) async {
    _ensureHandler();
    await _ch.invokeMethod('initialize', [pluginVersion, apiKey, endpoint]);
  }

  static Future<void> requestPermissions() async {
    await _ch.invokeMethod('requestPermissions');
  }

  static Future<void> startPositioning() async {
    await _ch.invokeMethod('startPositioning');
  }

  static Future<void> stopPositioning() async {
    await _ch.invokeMethod('stopPositioning');
  }

  static Future<void> setOutputThresholds(double meters, double seconds) async {
    await _ch.invokeMethod('setOutputThresholds', [meters, seconds]);
  }

  static Future<void> setPositioningMode(int idx) async {
    await _ch.invokeMethod('setPositioningMode', idx);
  }

  /// Bloquea el posicionamiento solo para interiores (desactiva detección outdoor-indoor)
  static Future<void> lockIndoors(bool locked) async {
    await _ch.invokeMethod('lockIndoors', locked);
  }

  /// Bloquea el posicionamiento a un piso específico
  static Future<void> lockFloor(int floor) async {
    await _ch.invokeMethod('lockFloor', floor);
  }

  /// Desbloquea el piso (permite cambio automático de piso)
  static Future<void> unlockFloor() async {
    await _ch.invokeMethod('unlockFloor');
  }

  /// Configura la sensibilidad de orientación y heading para estabilizar el bearing
  /// headingSensitivity: sensibilidad para cambios de heading (grados)
  /// orientationSensitivity: sensibilidad para cambios de orientación 3D (grados)
  static Future<void> setSensitivities(double orientationSensitivity, double headingSensitivity) async {
    await _ch.invokeMethod('setSensitivities', [orientationSensitivity, headingSensitivity]);
  }

  static Future<String?> getTraceId() async {
    final r = await _ch.invokeMethod('getTraceId');
    _traceId = r as String?;
    return _traceId;
  }

  /// Solicita monitoreo de geofences específicas
  static Future<void> requestGeofences(List<String> geofenceIds) async {
    await _ch.invokeMethod('requestGeofences', geofenceIds);
  }

  /// Detiene el monitoreo de geofences
  static Future<void> removeGeofences() async {
    await _ch.invokeMethod('removeGeofences');
  }

  /// Obtiene las geofences actuales desde el sistema
  static Future<List<IAGeofence>> getCurrentGeofences() async {
    final result = await _ch.invokeMethod('getCurrentGeofences');
    if (result is List) {
      final geofenceMaps = result.cast<Map>();
      return geofenceMaps.map((map) => IAGeofence.fromMap(map)).toList();
    }
    return [];
  }

  /// Obtiene las geofences del venue actual desde la ubicación
  static List<IAGeofence> getVenueGeofences() {
    if (_currentLocation?.floorplan == null) return [];

    return _currentGeofences.toList();
  }

  /// Obtiene las geocercas que están actualmente activadas
  static List<IAGeofence> getTriggeredGeofences() {
    return _currentGeofences.where((g) => _triggeredGeofenceIds.contains(g.id)).toList();
  }

  /// Verifica si una geocerca específica está activada
  static bool isGeofenceTriggered(String geofenceId) {
    return _triggeredGeofenceIds.contains(geofenceId);
  }

  // setLocation: allow manual override (optional)
  static Future<void> setLocation(IACoordinate coord, {int floor = 0, double accuracy = 0}) async {
    await _ch.invokeMethod('setLocation', [coord.latitude, coord.longitude, floor, accuracy]);
  }

  // ----------------- WAYFINDING -----------------

  /// Lanza wayfinding hacia la coordenada dada y guarda destino localmente
  /// mode: optional int — ejemplo: 1 = EXCLUDE_INACCESSIBLE, 2 = EXCLUDE_ACCESSIBLE_ONLY
  static Future<void> startWayfinding(double lat, double lon, {int floor = 0, int? mode}) async {
    _ensureHandler();
    _currentDestination = IACoordinate(lat, lon);
    final args = [lat, lon, floor, if (mode != null) mode];
    await _ch.invokeMethod('startWayfinding', args);

    // Notificar a los listeners que hay un destino nuevo
    for (var l in _listeners) {
      try {
        l.onDestinationSet(_currentDestination);
      } catch (_) {}
    }
  }

  /// Detiene wayfinding y limpia destino local
  static Future<void> stopWayfinding() async {
    _currentDestination = null;
    await _ch.invokeMethod('stopWayfinding');

    for (var l in _listeners) {
      try {
        l.onDestinationSet(_currentDestination);
      } catch (_) {}
    }
  }

  // getters
  static IALocation? get location => _currentLocation;
  static IAFloorplan? get floorplan => _currentFloorplan;
  static String? get traceId => _traceId;
  static List<IAGeofence> get geofences => _currentGeofences.toList();
  static List<IAGeofence> get triggeredGeofences => getTriggeredGeofences();

  // ----------------- Listener management -----------------
  static void subscribe(IAListener listener) {
    _ensureHandler();
    if (_listeners.contains(listener)) return;
    _listeners.add(listener);

    // send current state
    if (_currentFloorplan != null) listener.onFloorplan(true, _currentFloorplan!);
    if (_currentLocation != null) listener.onLocation(_currentLocation!);
    if (_currentGeofences.isNotEmpty) listener.onGeofences(_currentGeofences.toList());

    // Enviar estado actual de geocercas activadas
    if (_triggeredGeofenceIds.isNotEmpty) {
      for (final geofenceId in _triggeredGeofenceIds) {
        listener.onGeofenceEvent(geofenceId, "ENTER");
      }
    }

    // Enviar destino actual (si existe) usando el método del listener
    listener.onDestinationSet(_currentDestination);

    // ensure native positioning is running when first listener subscribes:
    if (_listeners.length == 1) {
      // startPositioning should be called by app logic; here we do not auto-start
    }
  }

  static void unsubscribe(IAListener listener) {
    if (!_listeners.contains(listener)) return;
    _listeners.remove(listener);
    if (_listeners.isEmpty) {
      // stopPositioning();
    }
  }
}