// lib/indooratlas_listeners.dart
import 'package:flutter/widgets.dart';
import 'indooratlas.dart';
import 'indooratlas_core.dart';

// ----------------- Listener classes for convenience -----------------
abstract class IAListener {
  final UniqueKey key = UniqueKey();
  final String name;
  IAListener(this.name);
  void onStatus(IAStatus status, String message) {}
  void onLocation(IALocation location) {}
  void onFloorplan(bool enter, IAFloorplan floorplan) {}
  void onOrientation(double x, double y, double z, double w) {}
  void onHeading(double heading) {}
  void onGeofences(List<IAGeofence> geofences) {}
  void onGeofenceEvent(String geofenceId, String eventType) {}
  // opcional: onWayfindingUpdate (implementable por listeners)
  void onWayfindingUpdate(IARoute route) {}
  // opcional: cuando se establece o se limpia el destino
  void onDestinationSet(IACoordinate? destination) {}
}

typedef IAOnStatusCb = void Function(IAStatus status, String message);
typedef ValueLocationSetter = void Function(IALocation loc);
typedef IAOnFloorplanCb = void Function(bool enter, IAFloorplan floorplan);
typedef IAOnOrientationCb = void Function(double x, double y, double z, double w);
typedef ValueHeadingSetter = void Function(double heading);
typedef IAOnGeofencesCb = void Function(List<IAGeofence> geofences);

class IACallbackListener extends IAListener {
  final IAOnStatusCb? onStatusCb;
  final ValueLocationSetter? onLocationCb;
  final IAOnFloorplanCb? onFloorplanCb;
  final IAOnOrientationCb? onOrientationCb;
  final ValueHeadingSetter? onHeadingCb;
  final IAOnGeofencesCb? onGeofencesCb;
  final void Function(String geofenceId, String eventType)? onGeofenceEventCb;

  // Renombrados: campos que guardan callbacks para evitar colisión con métodos
  final void Function(IARoute route)? onWayfindingUpdateCb;
  final void Function(IACoordinate? destination)? onDestinationSetCb;

  IACallbackListener({
    required String name,
    this.onStatusCb,
    this.onLocationCb,
    this.onFloorplanCb,
    this.onOrientationCb,
    this.onHeadingCb,
    this.onGeofencesCb,
    this.onGeofenceEventCb,
    void Function(IARoute route)? onWayfindingUpdate,
    void Function(IACoordinate? destination)? onDestinationSet,
  })  : onWayfindingUpdateCb = onWayfindingUpdate,
        onDestinationSetCb = onDestinationSet,
        super(name);

  @override
  void onStatus(IAStatus status, String message) => onStatusCb?.call(status, message);
  @override
  void onLocation(IALocation location) => onLocationCb?.call(location);
  @override
  void onFloorplan(bool enter, IAFloorplan floorplan) => onFloorplanCb?.call(enter, floorplan);
  @override
  void onOrientation(double x, double y, double z, double w) => onOrientationCb?.call(x, y, z, w);
  @override
  void onHeading(double heading) => onHeadingCb?.call(heading);
  @override
  void onGeofences(List<IAGeofence> geofences) => onGeofencesCb?.call(geofences);
  @override
  void onGeofenceEvent(String geofenceId, String eventType) => onGeofenceEventCb?.call(geofenceId, eventType);

  // implementaciones que delegan a los campos renombrados
  @override
  void onWayfindingUpdate(IARoute route) => onWayfindingUpdateCb?.call(route);
  @override
  void onDestinationSet(IACoordinate? destination) => onDestinationSetCb?.call(destination);
}

// Widget that auto-subscribes
class IndoorAtlasListener extends StatefulWidget {
  final Widget child;
  final IACallbackListener listener;
  final bool enabled;

  IndoorAtlasListener({
    Key? key,
    required String name,
    this.enabled = true,
    this.child = const SizedBox.shrink(),
    IAOnStatusCb? onStatus,
    ValueLocationSetter? onLocation,
    IAOnFloorplanCb? onFloorplan,
    IAOnOrientationCb? onOrientation,
    ValueHeadingSetter? onHeading,
    IAOnGeofencesCb? onGeofences,
    void Function(String geofenceId, String eventType)? onGeofenceEvent,
    void Function(IARoute route)? onWayfindingUpdate,
    void Function(IACoordinate? destination)? onDestinationSet,
  })  : listener = IACallbackListener(
          name: name,
          onStatusCb: onStatus,
          onLocationCb: onLocation,
          onFloorplanCb: onFloorplan,
          onOrientationCb: onOrientation,
          onHeadingCb: onHeading,
          onGeofencesCb: onGeofences,
          onGeofenceEventCb: onGeofenceEvent,
          onWayfindingUpdate: onWayfindingUpdate,
          onDestinationSet: onDestinationSet,
        ),
        super(key: key);

  @override
  State<IndoorAtlasListener> createState() => _IndoorAtlasListenerState();
}

class _IndoorAtlasListenerState extends State<IndoorAtlasListener> {
  IAListener? _old;

  void _enable(IAListener? old) {
    if (widget.enabled) {
      if (old != null) {
        IndoorAtlas.unsubscribe(old);
      }
      IndoorAtlas.subscribe(widget.listener);
    } else if (old != null) {
      IndoorAtlas.unsubscribe(old);
    }
  }

  @override
  void initState() {
    super.initState();
    _enable(null);
  }

  @override
  void didUpdateWidget(covariant IndoorAtlasListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    _enable(oldWidget.listener);
  }

  @override
  void dispose() {
    IndoorAtlas.unsubscribe(widget.listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}