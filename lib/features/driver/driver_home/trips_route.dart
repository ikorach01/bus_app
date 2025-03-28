import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'dart:math';

class TripsRoute extends StatefulWidget {
  final String departure;
  final String arrival;

  const TripsRoute({
    Key? key,
    required this.departure,
    required this.arrival,
  }) : super(key: key);

  @override
  State<TripsRoute> createState() => _TripsRouteState();
}

class _TripsRouteState extends State<TripsRoute> {
  final _mapController = MapController();
  LocationData? _currentLocation;
  bool _isTripStarted = false;
  bool _isLoading = true;
  List<LatLng> _routePoints = [];
  final _location = Location();
  bool _isTracking = false;

  // Hardcoded municipality coordinates (you should get these from your database)
  final Map<String, LatLng> _municipalityCoordinates = {
    'Adrar': LatLng(27.8742, -0.2891),
    'Reggane': LatLng(26.7167, -0.1667),
    'Aoulef': LatLng(26.9667, 1.0833),
    'Timimoun': LatLng(29.2639, 0.2306),
    'Zaouiet Kounta': LatLng(27.2333, -0.2500),
    'Tsabit': LatLng(28.3500, -0.2167),
    'Charouine': LatLng(29.0167, -0.2667),
    'Fenoughil': LatLng(27.7333, -0.2333),
  };

  @override
  void initState() {
    super.initState();
    _initializeLocationTracking();
    _setupRoute();
  }

  Future<void> _initializeLocationTracking() async {
    setState(() => _isLoading = true);
    
    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          setState(() => _isLoading = false);
          return;
        }
      }

      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          setState(() => _isLoading = false);
          return;
        }
      }

      // Get initial location
      _currentLocation = await _location.getLocation();
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      // Set up location changes listener
      _location.onLocationChanged.listen((LocationData locationData) {
        if (mounted && _isTracking) {
          setState(() {
            _currentLocation = locationData;
            if (_isTripStarted) {
              _routePoints.add(LatLng(locationData.latitude!, locationData.longitude!));
            }
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _setupRoute() {
    // Get coordinates for departure and arrival
    final departureCoords = _municipalityCoordinates[widget.departure];
    final arrivalCoords = _municipalityCoordinates[widget.arrival];

    if (departureCoords != null && arrivalCoords != null) {
      setState(() {
        _routePoints = [departureCoords, arrivalCoords];
      });

      // Calculate the center point between departure and arrival
      final centerLat = (departureCoords.latitude + arrivalCoords.latitude) / 2;
      final centerLng = (departureCoords.longitude + arrivalCoords.longitude) / 2;
      
      // Calculate appropriate zoom level based on distance
      final distance = _calculateDistance(departureCoords, arrivalCoords);
      final zoom = _calculateZoomLevel(distance);

      // Center the map with calculated zoom
      _mapController.move(LatLng(centerLat, centerLng), zoom);
    }
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    // Haversine formula to calculate distance between two points
    const double earthRadius = 6371000; // Earth's radius in meters
    final double lat1 = point1.latitude * pi / 180;
    final double lat2 = point2.latitude * pi / 180;
    final double deltaLat = (point2.latitude - point1.latitude) * pi / 180;
    final double deltaLon = (point2.longitude - point1.longitude) * pi / 180;

    final double a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1) * cos(lat2) * sin(deltaLon / 2) * sin(deltaLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _calculateZoomLevel(double distance) {
    // Convert distance from meters to kilometers
    final distanceInKm = distance / 1000;
    
    // Basic formula to calculate zoom level based on distance
    // Adjust these values based on your needs
    if (distanceInKm < 10) return 12;
    if (distanceInKm < 50) return 10;
    if (distanceInKm < 100) return 9;
    if (distanceInKm < 500) return 8;
    return 7;
  }

  void _startTrip() {
    setState(() {
      _isTripStarted = true;
      _isTracking = true;
      if (_currentLocation != null) {
        _routePoints = [LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!)];
      }
    });
  }

  void _stopTrip() {
    setState(() {
      _isTripStarted = false;
      _isTracking = false;
    });
    // Here you would typically save the route data to your backend
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF2A52C9),
                  ),
                )
              : FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentLocation != null
                        ? LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!)
                        : LatLng(27.87374386370353, -0.28424559734165983),
                    initialZoom: 12.0,
                    minZoom: 4.0,
                    maxZoom: 18.0,
                    onTap: (_, __) {
                      // Handle tap events if needed
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.bus_app',
                    ),
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
                            child: const Icon(Icons.directions_bus, color: Color(0xFF2A52C9), size: 30),
                          ),
                        ..._routePoints.map(
                          (point) => Marker(
                            point: point,
                            width: 20,
                            height: 20,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF2A52C9).withOpacity(0.7),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

          // Top Bar with Route Info
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF9CB3F9),
                    const Color(0xFF9CB3F9).withOpacity(0.0),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Route',
                    style: TextStyle(
                      color: const Color(0xFF14202E),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.departure} → ${widget.arrival}',
                    style: TextStyle(
                      color: const Color(0xFF14202E),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Controls
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!_isTripStarted)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _startTrip,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2A52C9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Start Trip',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _stopTrip,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Stop Trip',
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
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _location.enableBackgroundMode(enable: false);
    super.dispose();
  }
}