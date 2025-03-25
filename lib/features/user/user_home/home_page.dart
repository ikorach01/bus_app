import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
  List<LatLng> _routePoints = [];
  String _estimatedTime = "N/A";
  late MapController _mapController;
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
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    if (!settingsProvider.delayAlertsEnabled || !mounted) return;

    final delays = await _fetchDelaysFromServer();
    
    if (delays.isNotEmpty && mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.delayAlerts),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: delays.map((delay) => 
              Text('${delay['busNumber']}: ${delay['delay']} minutes delay')
            ).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
          ],
        ),
      );
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
    _mapController.move(
      LatLng(locationData.latitude!, locationData.longitude!),
      14.0,
    );
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
      final String apiKey = "0mLFOCbR4d37yR14JI6y1QL3kztkWhKff3tjn95qc8U";
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
    final List<LatLng> mockRoute = [
      LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
      _selectedStation!,
    ];
    
    setState(() {
      _routePoints = mockRoute;
      _estimatedTime = "15 minutes";
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

      points.add(LatLng(lat / 1e5, lng / 1e5));
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
    final filteredBuses = _mockBuses.where((bus) {
      return bus['destination'] == _selectedStationName || bus['finalDestination'] == _selectedStationName;
    }).toList();

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
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
                      child: const Icon(Icons.my_location, color: Colors.green, size: 30),
                    ),
                  if (_selectedStation != null)
                    Marker(
                      point: _selectedStation!,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.directions_bus, color: Colors.blue, size: 30),
                    ),
                  for (final bus in filteredBuses)
                    Marker(
                      point: bus['position'],
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedBus = bus;
                          });
                          _showBusDetails(bus);
                        },
                        child: const Icon(Icons.directions_bus, color: Colors.red, size: 30),
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
              onPressed: _getUserLocation,
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