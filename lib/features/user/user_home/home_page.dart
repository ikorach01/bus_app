import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bus_app/features/user/settings_page.dart';
import 'dart:async';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  LocationData? _currentLocation;
  LatLng? _selectedStation;
  List<LatLng> _routePoints = [];
  String _estimatedTime = "N/A";
  MapController? _mapController;
  final _supabase = Supabase.instance.client;
  String? _selectedStationName;
  List<Map<String, dynamic>> _activeBuses = [];
  bool _isLoading = true;
  Timer? _locationUpdateTimer;
  RealtimeChannel? _routesChannel;
  List<Map<String, dynamic>> _stations = [
    {
      'name': 'Nearby Municipalities Station',
      'lat': 27.87374386370353,
      'lon': -0.28424559734165983,
    },
    {
      'name': 'Distant Municipalities Station',
      'lat': 27.88156764617432,
      'lon': -0.28019696476583544,
    },
  ];

  final List<Map<String, dynamic>> _mockBuses = [
    {
      'busNumber': '101',
      'destination': 'Nearby Municipalities Station',
      'currentSpeed': '50 km/h',
      'busImage': 'assets/images/OIP (4).jpg',
      'expectedArrivalTime': '10 min',
      'driverName': 'John Doe',
      'finalDestination': 'Central Station',
      'position': LatLng(27.874, -0.285),
    },
    {
      'busNumber': '202',
      'destination': 'Distant Municipalities Station',
      'currentSpeed': '45 km/h',
      'busImage': 'assets/images/OIP (4).jpg',
      'expectedArrivalTime': '15 min',
      'driverName': 'Jane Smith',
      'finalDestination': 'North Station',
      'position': LatLng(27.882, -0.281),
    },
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _fetchActiveBuses();
    _setupRealtimeSubscription();
    // Mettre à jour la position actuelle toutes les 30 secondes
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _getCurrentLocation();
    });
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    _routesChannel?.unsubscribe();
    _mapController = null;
    super.dispose();
  }

  void _setupRealtimeSubscription() {
    // S'abonner aux changements de la table driver_routes
    _routesChannel = _supabase
        .channel('public:driver_routes')
        .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'driver_routes',
            callback: (payload) {
              // Actualiser les bus actifs lorsqu'un nouveau trajet est ajouté
              _fetchActiveBuses();
            })
        .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'driver_routes',
            callback: (payload) {
              // Actualiser les bus actifs lorsqu'un trajet est mis à jour
              _fetchActiveBuses();
            })
        .subscribe();
  }

  Future<void> _fetchActiveBuses() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Fetch active routes (routes with start_time but no end_time)
      final activeRoutes = await _supabase
          .from('driver_routes')
          .select('''
            id, 
            driver_id, 
            bus_id, 
            start_time, 
            end_time,
            start_station(id, name, latitude, longitude),
            end_station(id, name, latitude, longitude),
            drivers:driver_id(first_name, last_name, bus_name, bus_photo)
          ''')
          .filter('end_time', 'is', null);

      List<Map<String, dynamic>> buses = [];

      for (final route in activeRoutes) {
        final driver = route['drivers'];
        final startStation = route['start_station'];
        final endStation = route['end_station'];

        // Récupérer la position actuelle du chauffeur depuis la table driver_locations
        final driverLocationData = await _supabase
            .from('driver_locations')
            .select('latitude, longitude, updated_at')
            .eq('route_id', route['id'])
            .order('updated_at', ascending: false)
            .limit(1)
            .maybeSingle();

        double currentLat;
        double currentLng;

        if (driverLocationData != null) {
          // Utiliser la position réelle du chauffeur
          currentLat = driverLocationData['latitude'];
          currentLng = driverLocationData['longitude'];
        } else {
          // Fallback: calculer une position estimée entre le départ et l'arrivée
          final startLat = startStation['latitude'] as double;
          final startLng = startStation['longitude'] as double;
          final endLat = endStation['latitude'] as double;
          final endLng = endStation['longitude'] as double;

          // Calculer une position à 30% du trajet entre le départ et l'arrivée
          currentLat = startLat + (endLat - startLat) * 0.3;
          currentLng = startLng + (endLng - startLng) * 0.3;
        }

        // Calculate estimated arrival time (for demo purposes)
        final startTime = DateTime.parse(route['start_time']);
        final now = DateTime.now();
        final elapsedMinutes = now.difference(startTime).inMinutes;
        final totalEstimatedMinutes = 30; // Assuming 30 min total trip time
        final remainingMinutes = totalEstimatedMinutes - elapsedMinutes;

        buses.add({
          'id': route['id'],
          'busNumber': driver['bus_name'] ?? 'Bus ${route['id']}',
          'destination': endStation['name'],
          'currentSpeed': '50 km/h', // Mock speed
          'busImage': driver['bus_photo'] != null
              ? 'data:image/jpeg;base64,${base64Encode(driver['bus_photo'])}'
              : 'assets/images/OIP (4).jpg',
          'expectedArrivalTime': '$remainingMinutes min',
          'driverName': '${driver['first_name']} ${driver['last_name']}',
          'finalDestination': endStation['name'],
          'position': LatLng(currentLat, currentLng),
          'startStation': startStation['name'],
          'endStation': endStation['name'],
          'startTime': startTime.toString(),
          'routeId': route['id'],
          'lastUpdated': driverLocationData != null
              ? DateTime.parse(driverLocationData['updated_at']).toLocal().toString()
              : 'Position estimée',
        });
      }

      setState(() {
        _activeBuses = buses;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching active buses: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showBusDetails(Map<String, dynamic> bus) {
    showDialog(
      context: context,
      builder: (context) {
        final isArabic = Localizations.localeOf(context).languageCode == 'ar';

        final busText = isArabic ? 'حافلة' : 'Bus';
        final destinationText = isArabic ? 'الوجهة' : 'Destination';
        final speedText = isArabic ? 'السرعة' : 'Speed';
        final expectedArrivalText = isArabic ? 'وقت الوصول المتوقع' : 'Expected Arrival';
        final driverText = isArabic ? 'السائق' : 'Driver';
        final routeText = isArabic ? 'المسار' : 'Route';
        final startTimeText = isArabic ? 'وقت البدء' : 'Start Time';
        final lastUpdatedText = isArabic ? 'آخر تحديث' : 'Last Updated';
        final closeText = isArabic ? 'إغلاق' : 'Close';

        return AlertDialog(
          title: Text('$busText ${bus['busNumber']}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: bus['busImage'].startsWith('data:image')
                      ? Image.memory(
                          base64Decode(bus['busImage'].split(',')[1]),
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Image.asset(
                          bus['busImage'],
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                ),
                const SizedBox(height: 10),
                Text('$routeText: ${bus['startStation']} → ${bus['endStation']}', 
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('$destinationText: ${bus['destination']}'),
                Text('$speedText: ${bus['currentSpeed']}'),
                Text('$expectedArrivalText: ${bus['expectedArrivalTime']}'),
                Text('$driverText: ${bus['driverName']}'),
                Text('$startTimeText: ${DateTime.parse(bus['startTime']).toLocal().toString().substring(0, 16)}'),
                Text('$lastUpdatedText: ${bus['lastUpdated']}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(closeText),
            ),
          ],
        );
      },
    );
  }

  Future<void> _getCurrentLocation() async {
    Location location = Location();

    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location service is disabled')),
        );
        return;
      }
    }

    PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied')),
        );
        return;
      }
    }

    LocationData locationData = await location.getLocation();
    if (!mounted) return;
    
    setState(() {
      _currentLocation = locationData;
    });
    
    // Utiliser le MapController de manière sécurisée
    if (_mapController != null) {
      try {
        _mapController!.move(
          LatLng(locationData.latitude!, locationData.longitude!),
          14.0,
        );
      } catch (e) {
        print('MapController not ready yet: $e');
        // Ne pas afficher d'erreur à l'utilisateur, simplement ignorer l'erreur
      }
    }
  }

  void _selectStation(Map<String, dynamic> station) {
    setState(() {
      _selectedStationName = station['name'];
    });
  }

  @override
  Widget build(BuildContext context) {
    final buses = _activeBuses.isNotEmpty ? _activeBuses : _mockBuses;

    final filteredBuses = buses.where((bus) {
      if (_selectedStationName == null) return true;
      return bus['destination'] == _selectedStationName || bus['finalDestination'] == _selectedStationName;
    }).toList();

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController = MapController(),
            options: MapOptions(
              initialCenter: _currentLocation != null
                  ? LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!)
                  : LatLng(27.87374386370353, -0.28424559734165983),
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.bus_app',
              ),
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 5.0,
                      color: Colors.red,
                    ),
                  ],
                ),
              if (_currentLocation != null)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
                      color: Colors.blue.withOpacity(0.3),
                      borderColor: Colors.blue,
                      borderStrokeWidth: 2.0,
                      radius: 10.0,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  if (_currentLocation != null)
                    Marker(
                      point: LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.my_location, color: Colors.blue),
                    ),
                  ..._stations.map(
                    (station) => Marker(
                      point: LatLng(station['lat'], station['lon']),
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () => _selectStation(station),
                        child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                      ),
                    ),
                  ),
                  ...filteredBuses.map(
                    (bus) => Marker(
                      point: bus['position'],
                      width: 50,
                      height: 50,
                      child: GestureDetector(
                        onTap: () => _showBusDetails(bus),
                        child: const Icon(Icons.directions_bus, color: Colors.green, size: 40),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: _getCurrentLocation,
              backgroundColor: Colors.blue,
              child: const Icon(Icons.my_location, color: Colors.white),
            ),
          ),
          Positioned(
            top: 20,
            left: 20,
            child: FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
              backgroundColor: Colors.blue,
              child: const Icon(Icons.settings, color: Colors.white),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    Localizations.localeOf(context).languageCode == 'ar'
                        ? 'اختر المحطة'
                        : 'Select Station',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      _selectStation(_stations[0]);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFCAD7FF),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: Text(_stations[0]['name']),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      _selectStation(_stations[1]);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFCAD7FF),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: Text(_stations[1]['name']),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}