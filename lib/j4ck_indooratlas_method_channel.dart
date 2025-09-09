import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'j4ck_indooratlas_platform_interface.dart';

class MethodChannelJ4ckIndooratlas extends J4ckIndooratlasPlatform {
  static const MethodChannel _method =
      MethodChannel('j4ck_indooratlas/methods');
  static const EventChannel _locationEvent =
      EventChannel('j4ck_indooratlas/location');
  static const EventChannel _geofenceEvent =
      EventChannel('j4ck_indooratlas/geofence');
  static const EventChannel _orientationEvent =
      EventChannel('j4ck_indooratlas/orientation');
  static const EventChannel _wayfindingEvent =
      EventChannel('j4ck_indooratlas/wayfinding');
  static const EventChannel _mapEvent =
      EventChannel('j4ck_indooratlas/map');

  @override
  Future<void> initializeIndoorAtlas({required String apiKey}) async {
    try {
      await _method.invokeMethod('initializeIndoorAtlas', {'apiKey': apiKey});
    } on PlatformException catch (e) {
      if (kDebugMode) debugPrint('initializeIndoorAtlas failed: ${e.message}');
      rethrow;
    }
  }

    @override
  Stream<Map<String, dynamic>> get mapStream =>
    _mapEvent.receiveBroadcastStream().map(_normalize);

  @override
  Future<void> startLocation() async {
    try {
      await _method.invokeMethod('startLocation');
    } on PlatformException catch (e) {
      if (kDebugMode) debugPrint('startLocation failed: ${e.message}');
      rethrow;
    }
  }

  @override
  Future<void> stopLocation() async {
    await _method.invokeMethod('stopLocation');
  }

  @override
  Future<void> startWayfinding({
    required double latitude,
    required double longitude,
    required int floor,
  }) async {
    await _method.invokeMethod('startWayfinding', {
      'latitude': latitude,
      'longitude': longitude,
      'floor': floor,
    });
  }

  @override
  Future<void> stopWayfinding() async {
    await _method.invokeMethod('stopWayfinding');
  }

  @override
  Future<void> dispose() async {
    await _method.invokeMethod('dispose');
  }

  static Map<String, dynamic> _normalize(dynamic event) {
    if (event == null) return {};
    if (event is Map) {
      return Map<String, dynamic>.from(event.map(
        (key, value) => MapEntry(key.toString(), value),
      ));
    }
    return {"value": event.toString()};
  }

  @override
  Future<Map<String, dynamic>?> getCurrentFloorPlan() async {
    final res = await _method.invokeMethod('getCurrentFloorPlan');
    if (res == null) return null;
    return Map<String, dynamic>.from(res);
  }

  @override
  Stream<Map<String, dynamic>> get locationStream =>
      _locationEvent.receiveBroadcastStream().map(_normalize);

  @override
  Stream<Map<String, dynamic>> get geofenceStream =>
      _geofenceEvent.receiveBroadcastStream().map(_normalize);

  @override
  Stream<Map<String, dynamic>> get orientationStream =>
      _orientationEvent.receiveBroadcastStream().map(_normalize);

  @override
  Stream<Map<String, dynamic>> get wayfindingStream =>
      _wayfindingEvent.receiveBroadcastStream().map(_normalize);
}
