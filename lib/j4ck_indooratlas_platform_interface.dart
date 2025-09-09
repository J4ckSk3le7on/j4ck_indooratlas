import 'dart:async';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'j4ck_indooratlas_method_channel.dart';

abstract class J4ckIndooratlasPlatform extends PlatformInterface {
  J4ckIndooratlasPlatform() : super(token: _token);

  static final Object _token = Object();

  static J4ckIndooratlasPlatform _instance = MethodChannelJ4ckIndooratlas();

  static J4ckIndooratlasPlatform get instance => _instance;

  static set instance(J4ckIndooratlasPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<void> initializeIndoorAtlas({required String apiKey}) {
    throw UnimplementedError('initializeIndoorAtlas() has not been implemented.');
  }

  Future<void> startLocation() {
    throw UnimplementedError('startLocation() has not been implemented.');
  }

  Future<void> stopLocation() {
    throw UnimplementedError('stopLocation() has not been implemented.');
  }

  Future<Map<String, dynamic>?> getCurrentFloorPlan() {
    throw UnimplementedError('getCurrentFloorPlan() has not been implemented.');
  }

  Future<void> startWayfinding({
    required double latitude,
    required double longitude,
    required int floor,
  }) {
    throw UnimplementedError('startWayfinding() has not been implemented.');
  }

  Future<void> stopWayfinding() {
    throw UnimplementedError('stopWayfinding() has not been implemented.');
  }

  Future<void> dispose() {
    throw UnimplementedError('dispose() has not been implemented.');
  }

  Stream<Map<String, dynamic>> get locationStream =>
      Stream.error(UnimplementedError('locationStream is not implemented'));

  Stream<Map<String, dynamic>> get geofenceStream =>
      Stream.error(UnimplementedError('geofenceStream is not implemented'));

  Stream<Map<String, dynamic>> get orientationStream =>
      Stream.error(UnimplementedError('orientationStream is not implemented'));

  Stream<Map<String, dynamic>> get wayfindingStream =>
      Stream.error(UnimplementedError('wayfindingStream is not implemented'));
  
    Stream<Map<String, dynamic>> get mapStream =>
      Stream.error(UnimplementedError('mapStream is not implemented'));

}
