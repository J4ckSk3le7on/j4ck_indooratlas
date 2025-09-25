# j4ck_indooratlas

A comprehensive Flutter plugin for IndoorAtlas indoor positioning and wayfinding, featuring full support for location tracking, turn-by-turn navigation, geofencing, and floor plan integration.

## Features

✅ **Indoor Positioning**: High-accuracy location tracking using WiFi, Bluetooth, and magnetic field fingerprinting  
✅ **Wayfinding**: Turn-by-turn navigation with route calculation and updates  
✅ **Floor Plan Integration**: Automatic floor plan detection and coordinate conversion  
✅ **Geofencing**: Real-time geofence monitoring with enter/exit events  
✅ **Multi-floor Support**: Automatic floor detection and floor-specific positioning  
✅ **Orientation Tracking**: Device heading and 3D orientation  
✅ **Flexible API**: Both callback-based and stream-based APIs  
✅ **Modern Architecture**: Built with latest Flutter and IndoorAtlas SDK versions  

## Supported Platforms

- ✅ Android (API 24+)
- 🚧 iOS (coming soon)

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  j4ck_indooratlas:
    git:
      url: https://github.com/j4ck/j4ck_indooratlas.git
```

## Quick Start

### 1. Setup

Get your API key from the [IndoorAtlas Developer Portal](https://developer.indooratlas.com/).

### 2. Initialize

```dart
import 'package:j4ck_indooratlas/j4ck_indooratlas.dart';

// Initialize the plugin
await IndoorAtlas.initialize('1.0.0', 'YOUR_API_KEY');
await IndoorAtlas.requestPermissions();
```

### 3. Start Positioning

```dart
// Start indoor positioning
await IndoorAtlas.startPositioning();
```

### 4. Listen to Updates

```dart
// Using the listener widget (recommended)
IndoorAtlasListener(
  name: 'MainListener',
  onLocation: (location) {
    print('Location: ${location.latitude}, ${location.longitude}');
    print('Floor: ${location.floor}, Accuracy: ${location.accuracy}m');
  },
  onWayfindingUpdate: (route) {
    print('Route updated: ${route.legs.length} segments');
  },
  child: YourWidget(),
)

// Or using callbacks directly
final listener = IACallbackListener(
  name: 'MyListener',
  onLocation: (location) => handleLocation(location),
  onWayfindingUpdate: (route) => handleRoute(route),
);
IndoorAtlas.subscribe(listener);
```

### 5. Start Wayfinding

```dart
// Navigate to a specific location
await IndoorAtlas.startWayfinding(
  60.1696597,  // destination latitude
  24.932497,   // destination longitude
  floor: 1,    // destination floor
);
```

## Advanced Usage

### Positioning Configuration

```dart
// Lock to indoor-only mode
await IndoorAtlas.lockIndoors(true);

// Lock to specific floor
await IndoorAtlas.lockFloor(2);

// Set positioning mode
await IndoorAtlas.setPositioningMode(0); // High accuracy
await IndoorAtlas.setPositioningMode(1); // Low power
await IndoorAtlas.setPositioningMode(2); // Cart mode

// Configure sensitivities
await IndoorAtlas.setSensitivities(
  5.0, // orientation sensitivity (degrees)
  5.0  // heading sensitivity (degrees)
);

// Set update thresholds
await IndoorAtlas.setOutputThresholds(
  1.0, // minimum distance (meters)
  1.0  // minimum time interval (seconds)
);
```

### Geofence Monitoring

```dart
IndoorAtlasListener(
  name: 'GeofenceListener',
  onGeofences: (geofences) {
    print('Available geofences: ${geofences.length}');
  },
  onGeofenceEvent: (geofenceId, eventType) {
    print('Geofence $geofenceId: $eventType');
  },
  child: YourWidget(),
)

// Get current geofences
final geofences = IndoorAtlas.geofences;
final triggered = IndoorAtlas.triggeredGeofences;
```

### Floor Plan Integration

```dart
IndoorAtlasListener(
  name: 'FloorPlanListener',
  onFloorplan: (enter, floorplan) {
    if (enter) {
      print('Entered floor plan: ${floorplan.name}');
      print('Dimensions: ${floorplan.widthMeters}x${floorplan.heightMeters}m');
      print('Image size: ${floorplan.bitmapWidth}x${floorplan.bitmapHeight}px');
    }
  },
  onLocation: (location) {
    if (location.pixel != null) {
      print('Pixel coordinates: ${location.pixel!.x}, ${location.pixel!.y}');
    }
  },
  child: YourWidget(),
)
```

## API Reference

### Core Classes

#### IndoorAtlas
Main static class for plugin interaction.

**Methods:**
- `initialize(String version, String apiKey)` - Initialize the plugin
- `requestPermissions()` - Request location permissions
- `startPositioning()` / `stopPositioning()` - Control positioning
- `startWayfinding(lat, lon, {floor, mode})` / `stopWayfinding()` - Control wayfinding
- `subscribe(listener)` / `unsubscribe(listener)` - Manage listeners

**Properties:**
- `location` - Current location
- `floorplan` - Current floor plan
- `geofences` - Available geofences
- `triggeredGeofences` - Currently triggered geofences
- `currentDestination` - Current wayfinding destination

#### IALocation
Location information with indoor context.

**Properties:**
- `latitude`, `longitude` - WGS84 coordinates
- `floor` - Floor level
- `accuracy` - Location accuracy in meters
- `heading` - Device heading in degrees
- `pixel` - Floor plan pixel coordinates
- `floorplan` - Associated floor plan
- `timestamp` - Location timestamp

#### IARoute
Wayfinding route information.

**Properties:**
- `legs` - List of route segments (IARouteLeg)
- `error` - Error message if route calculation failed

#### IAFloorplan
Floor plan metadata and coordinate system.

**Properties:**
- `id`, `name` - Floor plan identification
- `floor` - Floor level
- `bitmapWidth`, `bitmapHeight` - Image dimensions
- `widthMeters`, `heightMeters` - Real-world dimensions
- `bearing` - Floor plan rotation
- `metersToPixels`, `pixelsToMeters` - Conversion factors
- `center`, `topLeft`, `topRight`, `bottomLeft`, `bottomRight` - Corner coordinates

#### IAGeofence
Geofence definition and metadata.

**Properties:**
- `id`, `name` - Geofence identification
- `floor` - Floor level
- `coordinates` - Boundary coordinates
- `payload` - Additional metadata

### Listeners

#### IndoorAtlasListener Widget
Declarative listener widget that automatically manages subscriptions.

```dart
IndoorAtlasListener(
  name: 'ListenerName',
  enabled: true, // Optional: enable/disable listener
  onLocation: (IALocation location) => {},
  onFloorplan: (bool enter, IAFloorplan floorplan) => {},
  onWayfindingUpdate: (IARoute route) => {},
  onGeofences: (List<IAGeofence> geofences) => {},
  onGeofenceEvent: (String id, String eventType) => {},
  onHeading: (double heading) => {},
  onOrientation: (double x, y, z, w) => {},
  onStatus: (IAStatus status, String message) => {},
  onDestinationSet: (IACoordinate? destination) => {},
  child: YourWidget(),
)
```

#### IACallbackListener
Programmatic listener for manual subscription management.

```dart
final listener = IACallbackListener(
  name: 'MyListener',
  onLocation: (location) => handleLocation(location),
  // ... other callbacks
);

IndoorAtlas.subscribe(listener);
// ... later
IndoorAtlas.unsubscribe(listener);
```

## Permissions

### Android

The plugin automatically requests these permissions:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.CHANGE_WIFI_STATE" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" /> <!-- Android 12+ -->
```

## Migration from Old Versions

If you're migrating from the old j4ck_indooratlas implementation:

### Old API (deprecated):
```dart
final plugin = J4ckIndooratlas.instance;
await plugin.initializeIndoorAtlas(apiKey: 'key');
plugin.locationStream.listen((data) => {});
```

### New API (recommended):
```dart
await IndoorAtlas.initialize('1.0.0', 'key');
IndoorAtlasListener(
  name: 'Listener',
  onLocation: (location) => {},
  child: widget,
);
```

The old API is still supported for backward compatibility.

## Example App

See the [example](example/) directory for a comprehensive demo app showing all features:

- Real-time location tracking
- Interactive wayfinding
- Geofence monitoring
- Floor plan integration
- Debug information display

## Troubleshooting

### Common Issues

**No location updates:**
- Verify API key is correct
- Ensure location permissions are granted
- Check you're in a mapped indoor space
- Enable WiFi and Bluetooth

**Wayfinding not working:**
- Confirm venue has wayfinding enabled
- Check destination coordinates are within venue bounds
- Verify correct floor level

**Poor accuracy:**
- Ensure good WiFi coverage in the area
- Check for interference from other devices
- Verify venue fingerprinting quality

### Debug Tools

Enable debug logging:
```dart
IndoorAtlas.debugEnabled = true;
```

Get trace ID for support:
```dart
final traceId = await IndoorAtlas.getTraceId();
print('Trace ID: $traceId');
```

## Requirements

- Flutter 3.35.2+
- Dart 3.9+
- Android API level 24+
- IndoorAtlas SDK 3.7.1

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- [IndoorAtlas Documentation](https://docs.indooratlas.com/)
- [IndoorAtlas Support](https://indooratlas.freshdesk.com/)
- [GitHub Issues](https://github.com/j4ck/j4ck_indooratlas/issues)

## Changelog

### 1.0.0
- ✅ Complete rewrite with working wayfinding
- ✅ Updated to IndoorAtlas SDK 3.7.1
- ✅ Updated to Kotlin 2.2.20
- ✅ Updated to Flutter 3.35.2
- ✅ New listener-based API
- ✅ Comprehensive example app
- ✅ Full geofencing support
- ✅ Improved error handling
- ✅ Better documentation