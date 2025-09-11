import 'package:flutter/material.dart';
import 'package:j4ck_indooratlas/j4ck_indooratlas.dart';
import 'ui_helpers.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IndoorAtlas Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const IndoorAtlasDemo(),
    );
  }
}

class IndoorAtlasDemo extends StatefulWidget {
  const IndoorAtlasDemo({super.key});

  @override
  State<IndoorAtlasDemo> createState() => _IndoorAtlasDemoState();
}

class _IndoorAtlasDemoState extends State<IndoorAtlasDemo> with UIHelpers {
  // State variables
  bool _isInitialized = false;
  bool _isPositioning = false;
  bool _isWayfinding = false;
  IALocation? _currentLocation;
  IAFloorplan? _currentFloorplan;
  List<IAGeofence> _geofences = [];
  List<IAGeofence> _triggeredGeofences = [];
  IARoute? _currentRoute;
  IACoordinate? _destination;
  double _heading = 0.0;
  String _status = 'Not initialized';
  String _traceId = '';

  // Controllers for wayfinding input
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lonController = TextEditingController();
  final TextEditingController _floorController = TextEditingController(text: '0');

  // Replace with your actual IndoorAtlas API key
  static const String API_KEY = 'YOUR_API_KEY_HERE';

  @override
  void initState() {
    super.initState();
    _initializeIndoorAtlas();
  }

  @override
  void dispose() {
    _latController.dispose();
    _lonController.dispose();
    _floorController.dispose();
    super.dispose();
  }

  Future<void> _initializeIndoorAtlas() async {
    try {
      await IndoorAtlas.initialize('1.0.0', API_KEY);
      await IndoorAtlas.requestPermissions();
      
      // Set up sensitivities for stable positioning
      await IndoorAtlas.setSensitivities(5.0, 5.0);
      
      // Lock to indoors for better performance
      await IndoorAtlas.lockIndoors(true);
      
      // Get trace ID for debugging
      final traceId = await IndoorAtlas.getTraceId();
      
      setState(() {
        _isInitialized = true;
        _status = 'Initialized successfully';
        _traceId = traceId ?? 'Unknown';
      });
    } catch (e) {
      setState(() {
        _status = 'Initialization failed: $e';
      });
    }
  }

  Future<void> _startPositioning() async {
    if (!_isInitialized) return;
    
    try {
      await IndoorAtlas.startPositioning();
      setState(() {
        _isPositioning = true;
        _status = 'Positioning started';
      });
    } catch (e) {
      setState(() {
        _status = 'Failed to start positioning: $e';
      });
    }
  }

  Future<void> _stopPositioning() async {
    try {
      await IndoorAtlas.stopPositioning();
      setState(() {
        _isPositioning = false;
        _status = 'Positioning stopped';
      });
    } catch (e) {
      setState(() {
        _status = 'Failed to stop positioning: $e';
      });
    }
  }

  Future<void> _startWayfinding() async {
    if (!_isInitialized) return;
    
    final lat = double.tryParse(_latController.text);
    final lon = double.tryParse(_lonController.text);
    final floor = int.tryParse(_floorController.text) ?? 0;
    
    if (lat == null || lon == null) {
      setState(() {
        _status = 'Invalid coordinates for wayfinding';
      });
      return;
    }
    
    try {
      await IndoorAtlas.startWayfinding(lat, lon, floor: floor);
      setState(() {
        _isWayfinding = true;
        _destination = IACoordinate(lat, lon);
        _status = 'Wayfinding started to ($lat, $lon)';
      });
    } catch (e) {
      setState(() {
        _status = 'Failed to start wayfinding: $e';
      });
    }
  }

  Future<void> _stopWayfinding() async {
    try {
      await IndoorAtlas.stopWayfinding();
      setState(() {
        _isWayfinding = false;
        _destination = null;
        _currentRoute = null;
        _status = 'Wayfinding stopped';
      });
    } catch (e) {
      setState(() {
        _status = 'Failed to stop wayfinding: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IndoorAtlas Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: IndoorAtlasListener(
        name: 'MainListener',
        onLocation: (location) {
          setState(() {
            _currentLocation = location;
          });
        },
        onFloorplan: (enter, floorplan) {
          setState(() {
            _currentFloorplan = enter ? floorplan : null;
          });
        },
        onGeofences: (geofences) {
          setState(() {
            _geofences = geofences;
          });
        },
        onGeofenceEvent: (geofenceId, eventType) {
          setState(() {
            _triggeredGeofences = IndoorAtlas.getTriggeredGeofences();
          });
        },
        onWayfindingUpdate: (route) {
          setState(() {
            _currentRoute = route;
          });
        },
        onHeading: (heading) {
          setState(() {
            _heading = heading;
          });
        },
        onStatus: (status, message) {
          setState(() {
            _status = 'Status: ${status.name} - $message';
          });
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Section
              buildStatusSection(
                status: _status,
                traceId: _traceId,
                isInitialized: _isInitialized,
                isPositioning: _isPositioning,
                isWayfinding: _isWayfinding,
              ),
              const SizedBox(height: 20),
              
              // Control Buttons
              buildControlSection(
                isInitialized: _isInitialized,
                isPositioning: _isPositioning,
                onStartPositioning: _startPositioning,
                onStopPositioning: _stopPositioning,
              ),
              const SizedBox(height: 20),
              
              // Location Information
              buildLocationSection(
                currentLocation: _currentLocation,
                heading: _heading,
              ),
              const SizedBox(height: 20),
              
              // Floorplan Information
              buildFloorplanSection(
                currentFloorplan: _currentFloorplan,
              ),
              const SizedBox(height: 20),
              
              // Wayfinding Section
              buildWayfindingSection(
                isInitialized: _isInitialized,
                isWayfinding: _isWayfinding,
                destination: _destination,
                latController: _latController,
                lonController: _lonController,
                floorController: _floorController,
                onStartWayfinding: _startWayfinding,
                onStopWayfinding: _stopWayfinding,
              ),
              const SizedBox(height: 20),
              
              // Geofences Section
              buildGeofencesSection(
                geofences: _geofences,
                triggeredGeofences: _triggeredGeofences,
              ),
              const SizedBox(height: 20),
              
              // Route Information
              buildRouteSection(
                currentRoute: _currentRoute,
              ),
            ],
          ),
        ),
      ),
    );
  }