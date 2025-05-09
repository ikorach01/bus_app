import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'trips_route.dart';
import 'settings2.dart';
import 'departure2.dart';
import 'destination2.dart';

class HomePage2 extends StatefulWidget {
  const HomePage2({Key? key}) : super(key: key);

  @override
  State<HomePage2> createState() => _HomePage2State();
}

class _HomePage2State extends State<HomePage2> {
  LocationData? _currentLocation;
  LatLng? _destinationLocation;
  List<LatLng> _routePoints = [];
  late MapController _mapController;
  final TextEditingController _departureController = TextEditingController();
  final TextEditingController _arrivalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    Location location = Location();
    
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Location service is disabled")),
          );
        }
        return;
      }
    }

    PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Location permissions are denied")),
          );
        }
        return;
      }
    }

    LocationData locationData = await location.getLocation();
    if (mounted) {
      setState(() {
        _currentLocation = locationData;
      });
      _mapController.move(
        LatLng(locationData.latitude!, locationData.longitude!),
        14.0,
      );
    }
  }

  Future<void> _openDeparturePage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const Departure2Page()),
    );
    
    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        String locationInfo = result['name'];
        if (result['mairie'] != null && result['mairie'].toString().isNotEmpty) {
          locationInfo += ' (${result['mairie']})';
        }
        _departureController.text = locationInfo;
        
        // If you have coordinates, you can set them here
        if (result['latitude'] != null && result['longitude'] != null) {
          final lat = double.parse(result['latitude'].toString());
          final lng = double.parse(result['longitude'].toString());
          _mapController.move(LatLng(lat, lng), 14.0);
        }
      });
    }
  }

  Future<void> _openDestinationPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const Destination2Page()),
    );
    
    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        String locationInfo = result['name'];
        if (result['mairie'] != null && result['mairie'].toString().isNotEmpty) {
          locationInfo += ' (${result['mairie']})';
        }
        _arrivalController.text = locationInfo;
        
        // If you have coordinates, you can set them here
        if (result['latitude'] != null && result['longitude'] != null) {
          final lat = double.parse(result['latitude'].toString());
          final lng = double.parse(result['longitude'].toString());
          _destinationLocation = LatLng(lat, lng);
          _mapController.move(LatLng(lat, lng), 14.0);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map
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
                      color: const Color(0xFF2A52C9),
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
                      child: const Icon(Icons.my_location, color: Color(0xFF2A52C9), size: 30),
                    ),
                  if (_destinationLocation != null)
                    Marker(
                      point: _destinationLocation!,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.location_on, color: Color(0xFF9CB3F9), size: 30),
                    ),
                ],
              ),
            ],
          ),

          // Location Button
          Positioned(
            top: 50,
            right: 20,
            child: FloatingActionButton(
              onPressed: _getUserLocation,
              backgroundColor: const Color(0xFF2A52C9),
              child: const Icon(Icons.my_location, color: Colors.white),
            ),
          ),

          // Settings Button
          Positioned(
            top: 48,
            right: 80,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Settings2Page()),
                );
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.settings,
                  color: Color(0xFF2A52C9),
                  size: 24,
                ),
              ),
            ),
          ),

          // Bottom Sheet
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Input Form
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF9CB3F9).withOpacity(0.1),
                        const Color(0xFF2A52C9).withOpacity(0.2),
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enter Route Details',
                        style: TextStyle(
                          color: const Color(0xFF14202E),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF9CB3F9)),
                        ),
                        child: TextField(
                          controller: _departureController,
                          decoration: InputDecoration(
                            hintText: 'Current Location',
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16),
                            prefixIcon: Icon(Icons.location_on, color: const Color(0xFF2A52C9)),
                          ),
                          style: TextStyle(fontSize: 16),
                          readOnly: true, // Make it read-only
                          onTap: _openDeparturePage, // Open departure page on tap
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF9CB3F9)),
                        ),
                        child: TextField(
                          controller: _arrivalController,
                          decoration: InputDecoration(
                            hintText: 'Destination',
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16),
                            prefixIcon: Icon(Icons.location_on, color: const Color(0xFF2A52C9)),
                          ),
                          style: TextStyle(fontSize: 16),
                          readOnly: true, // Make it read-only
                          onTap: _openDestinationPage, // Open destination page on tap
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TripsRoute(
                                  departure: _departureController.text,
                                  arrival: _arrivalController.text,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2A52C9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'Confirm Route',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _departureController.dispose();
    _arrivalController.dispose();
    super.dispose();
  }
}