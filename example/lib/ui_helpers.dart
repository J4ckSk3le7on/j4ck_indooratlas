import 'package:flutter/material.dart';
import 'package:j4ck_indooratlas/j4ck_indooratlas.dart';

mixin UIHelpers<T extends StatefulWidget> on State<T> {
  
  Widget buildStatusSection({
    required String status,
    required String traceId,
    required bool isInitialized,
    required bool isPositioning,
    required bool isWayfinding,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'System Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Status: $status'),
            Text('Trace ID: $traceId'),
            Text('Initialized: ${isInitialized ? "Yes" : "No"}'),
            Text('Positioning: ${isPositioning ? "Active" : "Inactive"}'),
            Text('Wayfinding: ${isWayfinding ? "Active" : "Inactive"}'),
          ],
        ),
      ),
    );
  }

  Widget buildControlSection({
    required bool isInitialized,
    required bool isPositioning,
    required VoidCallback? onStartPositioning,
    required VoidCallback? onStopPositioning,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Controls',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: isInitialized && !isPositioning ? onStartPositioning : null,
                    child: const Text('Start Positioning'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isPositioning ? onStopPositioning : null,
                    child: const Text('Stop Positioning'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildLocationSection({
    required IALocation? currentLocation,
    required double heading,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Location Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (currentLocation != null) ...[
              Text('Latitude: ${currentLocation.latitude.toStringAsFixed(6)}'),
              Text('Longitude: ${currentLocation.longitude.toStringAsFixed(6)}'),
              Text('Floor: ${currentLocation.floor}'),
              Text('Accuracy: ${currentLocation.accuracy.toStringAsFixed(2)}m'),
              Text('Heading: ${heading.toStringAsFixed(1)}°'),
              if (currentLocation.pixel != null)
                Text('Pixel: (${currentLocation.pixel!.x.toStringAsFixed(1)}, ${currentLocation.pixel!.y.toStringAsFixed(1)})'),
              Text('Timestamp: ${currentLocation.timestamp.toLocal()}'),
            ] else
              const Text('No location data available'),
          ],
        ),
      ),
    );
  }

  Widget buildFloorplanSection({required IAFloorplan? currentFloorplan}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Floorplan Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (currentFloorplan != null) ...[
              Text('ID: ${currentFloorplan.id}'),
              Text('Name: ${currentFloorplan.name}'),
              Text('Floor Level: ${currentFloorplan.floor}'),
              Text('Dimensions: ${currentFloorplan.bitmapWidth}x${currentFloorplan.bitmapHeight}'),
              Text('Size: ${currentFloorplan.widthMeters.toStringAsFixed(1)}m x ${currentFloorplan.heightMeters.toStringAsFixed(1)}m'),
              Text('Bearing: ${currentFloorplan.bearing.toStringAsFixed(1)}°'),
              if (currentFloorplan.url.isNotEmpty)
                Text('URL: ${currentFloorplan.url}'),
            ] else
              const Text('No floorplan available'),
          ],
        ),
      ),
    );
  }

  Widget buildWayfindingSection({
    required bool isInitialized,
    required bool isWayfinding,
    required IACoordinate? destination,
    required TextEditingController latController,
    required TextEditingController lonController,
    required TextEditingController floorController,
    required VoidCallback? onStartWayfinding,
    required VoidCallback? onStopWayfinding,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Wayfinding',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: latController,
                    decoration: const InputDecoration(
                      labelText: 'Latitude',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: lonController,
                    decoration: const InputDecoration(
                      labelText: 'Longitude',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: floorController,
                    decoration: const InputDecoration(
                      labelText: 'Floor',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: isInitialized && !isWayfinding ? onStartWayfinding : null,
                    child: const Text('Start Wayfinding'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isWayfinding ? onStopWayfinding : null,
                    child: const Text('Stop Wayfinding'),
                  ),
                ),
              ],
            ),
            if (destination != null) ...[
              const SizedBox(height: 8),
              Text('Destination: ${destination.latitude.toStringAsFixed(6)}, ${destination.longitude.toStringAsFixed(6)}'),
            ],
          ],
        ),
      ),
    );
  }

  Widget buildGeofencesSection({
    required List<IAGeofence> geofences,
    required List<IAGeofence> triggeredGeofences,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Geofences (${geofences.length} total, ${triggeredGeofences.length} triggered)',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (geofences.isEmpty)
              const Text('No geofences available')
            else
              Column(
                children: geofences.map((geofence) {
                  final isTriggered = triggeredGeofences.any((g) => g.id == geofence.id);
                  return ListTile(
                    leading: Icon(
                      isTriggered ? Icons.location_on : Icons.location_off,
                      color: isTriggered ? Colors.green : Colors.grey,
                    ),
                    title: Text(geofence.name.isEmpty ? geofence.id : geofence.name),
                    subtitle: Text('Floor: ${geofence.floor}${geofence.payload != null ? ' | ${geofence.payload}' : ''}'),
                    trailing: isTriggered ? const Chip(
                      label: Text('ACTIVE'),
                      backgroundColor: Colors.green,
                    ) : null,
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget buildRouteSection({required IARoute? currentRoute}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Route Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (currentRoute != null) ...[
              if (currentRoute.error.isNotEmpty)
                Text('Error: ${currentRoute.error}', style: const TextStyle(color: Colors.red))
              else ...[
                Text('Route Legs: ${currentRoute.legs.length}'),
                if (currentRoute.legs.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...(currentRoute.legs.asMap().entries.map((entry) {
                    final index = entry.key;
                    final leg = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text(
                        'Leg ${index + 1}: ${leg.length.toStringAsFixed(1)}m, '
                        'Direction: ${leg.direction.toStringAsFixed(1)}°',
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  })),
                  const SizedBox(height: 8),
                  Text('Total Distance: ${currentRoute.legs.fold(0.0, (sum, leg) => sum + leg.length).toStringAsFixed(1)}m'),
                ],
              ],
            ] else
              const Text('No route information available'),
          ],
        ),
      ),
    );
  }
}