// lib/indoor_atlas_bridge.dart
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

// ----------------- Models -----------------
class IACoordinate {
  final double latitude, longitude;
  const IACoordinate(this.latitude, this.longitude);
  const IACoordinate.zero() : latitude = 0, longitude = 0;
}

class IAPoint {
  final double x, y;
  const IAPoint(this.x, this.y);
  const IAPoint.zero() : x = 0, y = 0;
}

class IAFloorplan {
  final String id;
  final String name;
  final String url;
  final int floor;
  final double bearing;
  final int bitmapWidth;
  final int bitmapHeight;
  final double widthMeters;
  final double heightMeters;
  final double metersToPixels;
  final double pixelsToMeters;
  final IACoordinate bottomLeft;
  final IACoordinate bottomRight;
  final IACoordinate center;
  final IACoordinate topLeft;
  final IACoordinate topRight;

  IAFloorplan({
    required this.id,
    required this.name,
    required this.url,
    required this.floor,
    required this.bearing,
    required this.bitmapWidth,
    required this.bitmapHeight,
    required this.widthMeters,
    required this.heightMeters,
    required this.metersToPixels,
    required this.pixelsToMeters,
    required this.bottomLeft,
    required this.bottomRight,
    required this.center,
    required this.topLeft,
    required this.topRight,
  });

  factory IAFloorplan.fromMap(Map map) {
    return IAFloorplan(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      url: map['url'] ?? '',
      floor: (map['floorLevel'] ?? 0) as int,
      bearing: ((map['bearing'] ?? 0) as num).toDouble(),
      bitmapWidth: (map['bitmapWidth'] ?? 0) as int,
      bitmapHeight: (map['bitmapHeight'] ?? 0) as int,
      widthMeters: ((map['widthMeters'] ?? 0) as num).toDouble(),
      heightMeters: ((map['heightMeters'] ?? 0) as num).toDouble(),
      metersToPixels: ((map['metersToPixels'] ?? 0) as num).toDouble(),
      pixelsToMeters: ((map['pixelsToMeters'] ?? 0) as num).toDouble(),
      bottomLeft: IACoordinate(((map['bottomLeft'][1] ?? 0) as num).toDouble(),
          ((map['bottomLeft'][0] ?? 0) as num).toDouble()),
      bottomRight: IACoordinate(((map['bottomRight'][1] ?? 0) as num).toDouble(),
          ((map['bottomRight'][0] ?? 0) as num).toDouble()),
      center: IACoordinate(((map['center'][1] ?? 0) as num).toDouble(),
          ((map['center'][0] ?? 0) as num).toDouble()),
      topLeft: IACoordinate(((map['topLeft'][1] ?? 0) as num).toDouble(),
          ((map['topLeft'][0] ?? 0) as num).toDouble()),
      topRight: IACoordinate(((map['topRight'][1] ?? 0) as num).toDouble(),
          ((map['topRight'][0] ?? 0) as num).toDouble()),
    );
  }
}

class IALocation extends IACoordinate {
  final IAPoint? pixel;
  final IAFloorplan? floorplan;
  final double accuracy;
  final double heading;
  final double altitude;
  final int floor;
  final double floorCertainty;
  final double velocity;
  final DateTime timestamp;

  IALocation({
    required double latitude,
    required double longitude,
    this.pixel,
    this.floorplan,
    this.accuracy = 0,
    this.heading = 0,
    this.altitude = 0,
    this.floor = 0,
    this.floorCertainty = 0,
    this.velocity = 0,
    required this.timestamp,
  }) : super(latitude, longitude);

  factory IALocation.fromMap(Map map) {
    IAPoint? p;
    if (map.containsKey('pix_x') && map.containsKey('pix_y')) {
      final dx = (map['pix_x'] as num).toDouble();
      final dy = (map['pix_y'] as num).toDouble();
      p = IAPoint(dx, dy);
    }

    IAFloorplan? fp;
    if (map.containsKey('region') && (map['region'] as Map).containsKey('floorPlan')) {
      try {
        fp = IAFloorplan.fromMap((map['region'] as Map)['floorPlan'] as Map);
      } catch (_) {}
    } else if (map.containsKey('floorPlan')) {
      try {
        fp = IAFloorplan.fromMap(map['floorPlan'] as Map);
      } catch (_) {}
    }

    return IALocation(
      latitude: ((map['latitude'] ?? 0) as num).toDouble(),
      longitude: ((map['longitude'] ?? 0) as num).toDouble(),
      pixel: p,
      floorplan: fp,
      accuracy: ((map['accuracy'] ?? 0) as num).toDouble(),
      heading: ((map['heading'] ?? 0) as num).toDouble(),
      altitude: ((map['altitude'] ?? 0) as num).toDouble(),
      floor: (map['flr'] ?? 0) as int,
      floorCertainty: ((map['floorCertainty'] ?? 0) as num).toDouble(),
      velocity: ((map['velocity'] ?? 0) as num).toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch((map['timestamp'] ?? DateTime.now().millisecondsSinceEpoch) as int),
    );
  }

  /// helper to create a copy with updated heading
  IALocation copyWithHeading(double h) {
    return IALocation(
      latitude: latitude,
      longitude: longitude,
      pixel: pixel,
      floorplan: floorplan,
      accuracy: accuracy,
      heading: h,
      altitude: altitude,
      floor: floor,
      floorCertainty: floorCertainty,
      velocity: velocity,
      timestamp: timestamp,
    );
  }
}

class IAGeofence {
  final String id;
  final String name;
  final int floor;
  final String? payload;
  final List<IACoordinate> coordinates;

  IAGeofence({
    required this.id,
    required this.name,
    required this.floor,
    this.payload,
    required this.coordinates,
  });

  factory IAGeofence.fromMap(Map map) {
    final geometry = map['geometry'] as Map;
    final coords = (geometry['coordinates'] as List).first as List;

    final coordinates = coords.map((coord) {
      return IACoordinate(
        ((coord[1] as num)).toDouble(), // latitud
        ((coord[0] as num)).toDouble(), // longitud
      );
    }).toList();

    return IAGeofence(
      id: map['id'] ?? '',
      name: ((map['properties'] as Map)['name']) ?? '',
      floor: ((map['properties'] as Map)['floor']) ?? 0,
      payload: (map['properties'] as Map)['payload']?.toString(),
      coordinates: coordinates,
    );
  }
}

// ----------------- IARoute Models -----------------
class IARoutePoint {
  final double latitude;
  final double longitude;
  final int floor;
  IARoutePoint(this.latitude, this.longitude, this.floor);
  factory IARoutePoint.fromMap(Map m) {
    return IARoutePoint(
      ((m['latitude'] ?? 0) as num).toDouble(),
      ((m['longitude'] ?? 0) as num).toDouble(),
      (m['floor'] ?? 0) as int,
    );
  }
}

class IARouteLeg {
  final IARoutePoint begin;
  final IARoutePoint end;
  final double length;
  final double direction;
  final int edgeIndex;

  IARouteLeg({
    required this.begin,
    required this.end,
    required this.length,
    required this.direction,
    required this.edgeIndex,
  });

  factory IARouteLeg.fromMap(Map m) {
    return IARouteLeg(
      begin: IARoutePoint.fromMap(m['begin'] as Map),
      end: IARoutePoint.fromMap(m['end'] as Map),
      length: ((m['length'] ?? 0) as num).toDouble(),
      direction: ((m['direction'] ?? 0) as num).toDouble(),
      edgeIndex: (m['edgeIndex'] ?? -1) as int,
    );
  }
}

class IARoute {
  final List<IARouteLeg> legs;
  final String error;
  IARoute(this.legs, this.error);
  factory IARoute.fromMap(Map m) {
    final legsList = (m['legs'] as List?) ?? [];
    final legs = legsList.map((e) => IARouteLeg.fromMap(e as Map)).toList();
    return IARoute(legs, (m['error'] ?? '') as String);
  }
}

// Minimal status enum
enum IAStatus { outOfService, temporarilyUnavailable, available, limited }