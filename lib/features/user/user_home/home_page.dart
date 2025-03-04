import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'departure.dart';
import 'Destination.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  LocationData? _currentLocation;
  LatLng? _departureLocation;
  LatLng? _destinationLocation;
  String _departureName = "Select Departure";
  String _destinationName = "Select Destination";
  List<LatLng> _routePoints = [];
  String _estimatedTime = "N/A";
  late MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    Location location = Location();
    LocationData locationData = await location.getLocation();
    setState(() {
      _currentLocation = locationData;
    });
    _mapController.move(
      LatLng(locationData.latitude!, locationData.longitude!),
      14.0,
    );
  }

  void _updateDeparture(Map<String, dynamic> departure) {
    setState(() {
      _departureName = departure['name'];
      _departureLocation = LatLng(departure['lat'], departure['lon']);
      _calculateRoute();
    });
  }

  void _updateDestination(Map<String, dynamic> destination) {
    setState(() {
      _destinationName = destination['name'];
      _destinationLocation = LatLng(destination['lat'], destination['lon']);
      _calculateRoute();
    });
  }

  void _swapLocations() {
    setState(() {
      String tempName = _departureName;
      _departureName = _destinationName;
      _destinationName = tempName;

      LatLng? tempLocation = _departureLocation;
      _departureLocation = _destinationLocation;
      _destinationLocation = tempLocation;
    });
    _calculateRoute();
  }

  Future<void> _calculateRoute() async {
    if (_departureLocation == null || _destinationLocation == null) return;

    final String apiKey = "0mLFOCbR4d37yR14JI6y1QL3kztkWhKff3tjn95qc8U"; // استبدل بمفتاح HERE API الخاص بك
    final Uri url = Uri.parse(
        "https://router.hereapi.com/v8/routes?apikey=$apiKey&transportMode=bus&origin=${_departureLocation!.latitude},${_departureLocation!.longitude}&destination=${_destinationLocation!.latitude},${_destinationLocation!.longitude}&return=polyline,travelSummary");

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final route = data['routes'][0];

      // استخراج الوقت المقدر للوصول
      final int estimatedTimeSeconds = route['sections'][0]['travelSummary']['duration'];
      final Duration duration = Duration(seconds: estimatedTimeSeconds);
      final String estimatedTime =
          "${duration.inMinutes} min${duration.inMinutes > 1 ? 's' : ''}";

      // استخراج النقاط لرسم المسار
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
                  : LatLng(37.427961, -122.085749),
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
                      color: Colors.red, // لون المسار
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
                  if (_departureLocation != null)
                    Marker(
                      point: _departureLocation!,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.directions_bus, color: Colors.blue, size: 30),
                    ),
                  if (_destinationLocation != null)
                    Marker(
                      point: _destinationLocation!,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.location_on, color: Colors.red, size: 30),
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
                color: Colors.white, // البطاقة البيضاء
                borderRadius: BorderRadius.circular(16), // زوايا دائرية
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    spreadRadius: 2, // تأثير الظل
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // عرض الوقت المقدر للوصول
                  Text(
                    "Estimated Time: $_estimatedTime",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  // حقلا Departure و Destination مع زر التبديل بينهما
                  Row(
                    children: [
                      // حقل Departure
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const DeparturePage()),
                            );
                            if (result != null) _updateDeparture(result);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                            child: Text(_departureName),
                          ),
                        ),
                      ),

                      // زر التبديل (↕️)
                      IconButton(
                        onPressed: _swapLocations,
                        icon: const Icon(Icons.swap_vert, size: 30),
                        color: Colors.blue,
                      ),

                      // حقل Destination
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const DestinationPage()), // تأكد من وجود الصفحة
                            );
                            if (result != null) _updateDestination(result);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                            child: Text(_destinationName), // عرض الوجهة المختارة
                          ),
                        ),
                      ),
                    ],
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
