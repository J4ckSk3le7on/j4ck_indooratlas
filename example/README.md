# IndoorAtlas Flutter Plugin Example

This example demonstrates how to use the IndoorAtlas Flutter plugin with full wayfinding support.

## Features Demonstrated

- **Indoor Positioning**: Real-time location tracking with high accuracy
- **Wayfinding**: Turn-by-turn navigation within indoor spaces
- **Floorplan Integration**: Automatic floor plan detection and coordinate conversion
- **Geofence Monitoring**: Real-time geofence enter/exit events
- **Orientation & Heading**: Device orientation and compass heading
- **Floor Detection**: Automatic floor level detection

## Setup

1. **Get your IndoorAtlas API Key**:
   - Sign up at [IndoorAtlas Developer Portal](https://developer.indooratlas.com/)
   - Create a new application
   - Copy your API key

2. **Update the API Key**:
   - Open `lib/main.dart`
   - Replace `YOUR_API_KEY_HERE` with your actual API key:
   ```dart
   static const String API_KEY = 'your-actual-api-key-here';
   ```

3. **Add Permissions** (Android):
   The plugin automatically requests the following permissions:
   - `ACCESS_FINE_LOCATION`
   - `ACCESS_COARSE_LOCATION` 
   - `CHANGE_WIFI_STATE`
   - `ACCESS_WIFI_STATE`
   - `INTERNET`
   - `BLUETOOTH_SCAN` (Android 12+)

## Usage

### 1. Initialize the Plugin
```dart
await IndoorAtlas.initialize('1.0.0', 'YOUR_API_KEY');
await IndoorAtlas.requestPermissions();
```

### 2. Start Positioning
```dart
await IndoorAtlas.startPositioning();
```

### 3. Listen to Location Updates
```dart
IndoorAtlasListener(
  name: 'LocationListener',
  onLocation: (location) {
    print('Location: ${location.latitude}, ${location.longitude}');
    print('Floor: ${location.floor}');
    print('Accuracy: ${location.accuracy}m');
  },
  child: YourWidget(),
)
```

### 4. Start Wayfinding
```dart
await IndoorAtlas.startWayfinding(
  destinationLatitude, 
  destinationLongitude, 
  floor: destinationFloor
);
```

### 5. Listen to Wayfinding Updates
```dart
IndoorAtlasListener(
  name: 'WayfindingListener',
  onWayfindingUpdate: (route) {
    if (route.error.isEmpty) {
      print('Route has ${route.legs.length} segments');
      for (var leg in route.legs) {
        print('Segment: ${leg.length}m, direction: ${leg.direction}°');
      }
    }
  },
  child: YourWidget(),
)
```

## Key Classes

### IALocation
Contains positioning information:
- `latitude`, `longitude`: WGS84 coordinates
- `floor`: Floor level
- `accuracy`: Location accuracy in meters
- `heading`: Device heading in degrees
- `pixel`: Floor plan pixel coordinates (if available)
- `floorplan`: Associated floor plan information

### IAFloorplan
Contains floor plan information:
- `id`, `name`: Floor plan identification
- `bitmapWidth`, `bitmapHeight`: Image dimensions
- `widthMeters`, `heightMeters`: Real-world dimensions
- `bearing`: Floor plan rotation
- `metersToPixels`, `pixelsToMeters`: Conversion factors

### IARoute
Contains wayfinding route information:
- `legs`: List of route segments
- `error`: Error message if route calculation failed

### IAGeofence
Contains geofence information:
- `id`, `name`: Geofence identification
- `floor`: Floor level
- `coordinates`: Boundary coordinates
- `payload`: Additional metadata

## Advanced Features

### Floor Locking
Lock positioning to a specific floor:
```dart
await IndoorAtlas.lockFloor(1); // Lock to floor 1
await IndoorAtlas.unlockFloor(); // Allow automatic floor detection
```

### Indoor-Only Mode
Disable outdoor positioning:
```dart
await IndoorAtlas.lockIndoors(true);
```

### Sensitivity Configuration
Adjust orientation and heading sensitivity:
```dart
await IndoorAtlas.setSensitivities(
  5.0, // orientation sensitivity (degrees)
  5.0  // heading sensitivity (degrees)
);
```

### Positioning Mode
Set positioning priority:
```dart
await IndoorAtlas.setPositioningMode(0); // High accuracy
await IndoorAtlas.setPositioningMode(1); // Low power
await IndoorAtlas.setPositioningMode(2); // Cart mode
```

## Troubleshooting

### Common Issues

1. **No Location Updates**:
   - Ensure you have a valid API key
   - Check that location permissions are granted
   - Verify you're in a mapped indoor space

2. **Wayfinding Not Working**:
   - Make sure you're in a venue with wayfinding enabled
   - Check that the destination coordinates are within the venue
   - Verify the floor level is correct

3. **Poor Accuracy**:
   - Ensure WiFi is enabled and scanning
   - Check that Bluetooth is enabled (Android 12+)
   - Verify the venue has good WiFi coverage

### Debug Information

The example app displays:
- Trace ID for debugging with IndoorAtlas support
- Real-time location accuracy
- Current floor plan information
- Active geofences
- Route calculation status

## Support

For technical support:
- [IndoorAtlas Documentation](https://docs.indooratlas.com/)
- [IndoorAtlas Support Portal](https://indooratlas.freshdesk.com/)
- [GitHub Issues](https://github.com/j4ck/j4ck_indooratlas/issues)