import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  // بيانات وهمية للحافلات
  final List<Map<String, dynamic>> _mockBuses = [
    {
      'busNumber': '101',
      'destination': 'Nearby Municipalities Station',
      'currentSpeed': '50 km/h',
      'busImage': 'assets/images/OIP (4).jpg', // المسار المحلي للصورة
      'expectedArrivalTime': '10 min',
      'driverName': 'John Doe', // اسم السائق
      'finalDestination': 'Central Station', // المحطة النهائية
      'position': LatLng(27.874, -0.285), // موقع الحافلة على الخريطة
    },
    {
      'busNumber': '202',
      'destination': 'Distant Municipalities Station',
      'currentSpeed': '45 km/h',
      'busImage': 'assets/images/OIP (4).jpg', // المسار المحلي للصورة
      'expectedArrivalTime': '15 min',
      'driverName': 'Jane Smith', // اسم السائق
      'finalDestination': 'North Station', // المحطة النهائية
      'position': LatLng(27.882, -0.281), // موقع الحافلة على الخريطة
    },
  ];

  Map<String, dynamic>? _selectedBus; // الحافلة المختارة

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    Location location = Location();
    
    // التحقق من تمكين خدمة الموقع
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location service is disabled. Please enable it.")),
        );
        return;
      }
    }

    // التحقق من أذونات الموقع
    PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permissions are denied. Please grant them.")),
        );
        return;
      }
    }

    // الحصول على الموقع الحالي
    LocationData locationData = await location.getLocation();
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
      _calculateRoute();
    });
  }

  Future<void> _calculateRoute() async {
    if (_currentLocation == null || _selectedStation == null) return;

    final String apiKey = "0mLFOCbR4d37yR14JI6y1QL3kztkWhKff3tjn95qc8U"; // استبدل بمفتاح API الخاص بك
    final Uri url = Uri.parse(
        "https://router.hereapi.com/v8/routes?apikey=$apiKey&transportMode=bus&origin=${_currentLocation!.latitude},${_currentLocation!.longitude}&destination=${_selectedStation!.latitude},${_selectedStation!.longitude}&return=polyline,travelSummary");

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final route = data['routes'][0];

      // استخراج الوقت المتوقع للسفر
      final int estimatedTimeSeconds = route['sections'][0]['travelSummary']['duration'];
      final Duration duration = Duration(seconds: estimatedTimeSeconds);
      final String estimatedTime =
          "${duration.inMinutes} min${duration.inMinutes > 1 ? 's' : ''}";

      // استخراج نقاط الخطوط للطريق
      final polyline = route['sections'][0]['polyline'];
      final decodedPoints = _decodePolyline(polyline);

      setState(() {
        _routePoints = decodedPoints;
        _estimatedTime = estimatedTime;
      });
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    final List<int> bytes = base64.decode(encoded);
    final List<LatLng> points = [];
    int lat = 0, lon = 0;

    for (int i = 0; i < bytes.length; i += 2) {
      lat += bytes[i];
      lon += bytes[i + 1];
      points.add(LatLng(lat / 1e5, lon / 1e5));
    }
    return points;
  }

  void _showBusDetails(Map<String, dynamic> bus) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Bus ${bus['busNumber']}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // عرض صورة الحافلة
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
                Text('Destination: ${bus['destination']}'), // الوجهة
                Text('Speed: ${bus['currentSpeed']}'), // السرعة الحالية
                Text('Expected Arrival: ${bus['expectedArrivalTime']}'), // الوقت المتوقع
                Text('Driver: ${bus['driverName']}'), // اسم السائق
                Text('Final Destination: ${bus['finalDestination']}'), // المحطة النهائية
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  // عرض الحافلات على الخريطة
                  for (final bus in _mockBuses)
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
                  const Text(
                    "Select a Station",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
