import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:bus_app/providers/settings_provider.dart';
import 'package:bus_app/features/user/settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  LocationData? _currentLocation;
  LatLng? _selectedStation;
  String _estimatedTime = "N/A";
  late MapController _mapController;
  List<LatLng> _routePoints = [];
  bool _mapReady = false;
  final List<Map<String, dynamic>> _stations = [
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

  Map<String, dynamic>? _selectedBus;
  String? _selectedStationName;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _getUserLocation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForDelays();
    });
  }

  Future<void> _checkForDelays() async {
    try {
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
      if (!settingsProvider.delayAlertsEnabled || !mounted) return;

      final delays = await _fetchDelaysFromServer();
      
      if (delays.isNotEmpty && mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delay Alerts'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: delays.map((delay) => 
                Text('${delay['busNumber']}: ${delay['delay']} minutes delay')
              ).toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print("Error checking for delays: $e");
    }
  }

  Future<List<Map<String, dynamic>>> _fetchDelaysFromServer() async {
    // محاكاة لجلب البيانات من السيرفر
    await Future.delayed(const Duration(seconds: 1));
    return [
      {'busNumber': '101', 'delay': 5},
      {'busNumber': '202', 'delay': 10},
    ];
  }

  Future<void> _getUserLocation() async {
    Location location = Location();
    
    try {
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location service is disabled')),
          );
          // Set default location if service is not available
          setState(() {
            _mapReady = true;
          });
          return;
        }
      }

      // Special handling for web platform
      try {
        PermissionStatus permissionGranted = await location.hasPermission();
        if (permissionGranted == PermissionStatus.denied) {
          permissionGranted = await location.requestPermission();
          if (permissionGranted != PermissionStatus.granted) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission denied')),
            );
            // Set default location if permission is denied
            setState(() {
              _mapReady = true;
            });
            return;
          }
        }
      } catch (e) {
        print("Error with location permissions: $e");
        // Continue with default location on web platforms where permissions might not work
        setState(() {
          _mapReady = true;
        });
      }

      try {
        LocationData locationData = await location.getLocation();
        if (!mounted) return;
        setState(() {
          _currentLocation = locationData;
          _mapReady = true;
        });
        
        // Only move the map if we have valid coordinates
        if (locationData.latitude != null && locationData.longitude != null) {
          try {
            _mapController.move(
              LatLng(locationData.latitude!, locationData.longitude!),
              14.0,
            );
          } catch (e) {
            print("Error moving map: $e");
          }
        }
      } catch (e) {
        print("Error getting location: $e");
        // Set map as ready even if location failed
        setState(() {
          _mapReady = true;
        });
      }
    } catch (e) {
      print("General location error: $e");
      // Set map as ready even if there was an error
      setState(() {
        _mapReady = true;
      });
    }
  }

  void _updateSelectedStation(Map<String, dynamic> station) {
    setState(() {
      _selectedStation = LatLng(station['lat'], station['lon']);
      _selectedStationName = station['name'];
      _calculateRoute();
    });
  }

  Future<void> _calculateRoute() async {
    if (_currentLocation == null || _selectedStation == null) return;

    try {
      // Get API key from settings provider for better security
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
      final String apiKey = settingsProvider.hereApiKey;

      final Uri url = Uri.parse(
          "https://router.hereapi.com/v8/routes?apikey=$apiKey&transportMode=bus&origin=${_currentLocation!.latitude},${_currentLocation!.longitude}&destination=${_selectedStation!.latitude},${_selectedStation!.longitude}&return=polyline,summary");

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data.containsKey('routes') && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          
          if (route.containsKey('sections') && route['sections'].isNotEmpty) {
            final section = route['sections'][0];
            
            if (section.containsKey('summary')) {
              final int estimatedTimeSeconds = section['summary']['duration'] ?? 0;
              final Duration duration = Duration(seconds: estimatedTimeSeconds);
              final String estimatedTime =
                  "${duration.inMinutes} minutes";
              
              if (section.containsKey('polyline')) {
                final polyline = section['polyline'];
                final decodedPoints = _decodePolyline(polyline);

                if (!mounted) return;
                setState(() {
                  _routePoints = decodedPoints;
                  _estimatedTime = estimatedTime;
                });
              }
            }
          }
        }
      } else {
        // Fallback to mock route if API fails
        _createMockRoute();
      }
    } catch (e) {
      print("Error calculating route: $e");
      // Fallback to mock route if API fails
      _createMockRoute();
    }
  }

  void _createMockRoute() {
    if (_currentLocation == null || _selectedStation == null) return;
    
    // Create a simple straight line between current location and selected station
    List<LatLng> mockRoute = [
      LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
      _selectedStation!,
    ];
    
    setState(() {
      _routePoints = mockRoute;
      _estimatedTime = "10 minutes (estimated)";
    });
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      double latitude = lat / 1E5;
      double longitude = lng / 1E5;
      points.add(LatLng(latitude, longitude));
    }
    return points;
  }

  void _showBusDetails(Map<String, dynamic> bus) {
    showDialog(
      context: context,
      builder: (context) {
        // Get the current locale
        final isArabic = Localizations.localeOf(context).languageCode == 'ar';
        
        // Translate strings based on locale
        final busText = isArabic ? 'حافلة' : 'Bus';
        final destinationText = isArabic ? 'الوجهة' : 'Destination';
        final speedText = isArabic ? 'السرعة' : 'Speed';
        final expectedArrivalText = isArabic ? 'وقت الوصول المتوقع' : 'Expected Arrival';
        final driverText = isArabic ? 'السائق' : 'Driver';
        final finalDestinationText = isArabic ? 'الوجهة النهائية' : 'Final Destination';
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
                  child: Image.asset(
                    bus['busImage'],
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 10),
                Text('$destinationText: ${bus['destination']}'),
                Text('$speedText: ${bus['currentSpeed']}'),
                Text('$expectedArrivalText: ${bus['expectedArrivalTime']}'),
                Text('$driverText: ${bus['driverName']}'),
                Text('$finalDestinationText: ${bus['finalDestination']}'),
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

  @override
  Widget build(BuildContext context) {
    // Filter buses based on selected station
    final filteredBuses = _mockBuses.where((bus) {
      return bus['destination'] == _selectedStationName || bus['finalDestination'] == _selectedStationName;
    }).toList();

    return Scaffold(
      body: Stack(
        children: [
          // Only show map if it's ready
          if (_mapReady || _currentLocation != null)
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentLocation != null 
                  ? LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!)
                  : const LatLng(27.87374386370353, -0.28424559734165983), // Default center if location not available
                initialZoom: 14.0,
                onMapReady: () {
                  setState(() {
                    _mapReady = true;
                  });
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.bus_app',
                ),
                MarkerLayer(
                  markers: [
                    if (_currentLocation != null)
                      Marker(
                        point: LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
                        width: 80,
                        height: 80,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.blue,
                          size: 40,
                        ),
                      ),
                    ..._stations.map(
                      (station) => Marker(
                        point: LatLng(station['lat'], station['lon']),
                        width: 80,
                        height: 80,
                        child: GestureDetector(
                          onTap: () => _updateSelectedStation(station),
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                    // Use filteredBuses instead of _mockBuses to show only relevant buses
                    ...filteredBuses.map(
                      (bus) => Marker(
                        point: bus['position'],
                        width: 80,
                        height: 80,
                        child: GestureDetector(
                          onTap: () => _showBusDetails(bus),
                          child: const Icon(
                            Icons.directions_bus,
                            color: Colors.green,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_routePoints.isNotEmpty && _routePoints.length >= 2)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routePoints,
                        color: Colors.blue,
                        strokeWidth: 4,
                      ),
                    ],
                  ),
              ],
            )
          else
            // Show loading indicator if map is not ready
            const Center(
              child: CircularProgressIndicator(),
            ),
          Positioned(
            top: 20,
            right: 20,
            child: FloatingActionButton(
              heroTag: 'homePageFAB',
              onPressed: _getUserLocation,
              backgroundColor: Colors.blue,
              child: const Icon(Icons.my_location, color: Colors.white),
            ),
          ),
          Positioned(
            top: 20,
            left: 20,
            child: FloatingActionButton(
              heroTag: 'settingsPageFAB',
              onPressed: () {
                try {
                  // Try to get the SettingsProvider from the current context
                  final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
                  
                  // Navigate to SettingsPage with the provider
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChangeNotifierProvider.value(
                        value: settingsProvider,
                        child: const SettingsPage(),
                      ),
                    ),
                  );
                } catch (e) {
                  // If provider is not available, create a new one
                  print("Error accessing SettingsProvider: $e");
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChangeNotifierProvider(
                        create: (context) => SettingsProvider(),
                        child: const SettingsPage(),
                      ),
                    ),
                  );
                }
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
                      _updateSelectedStation(_stations[0]);
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
                      _updateSelectedStation(_stations[1]);
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