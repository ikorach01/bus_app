import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:location/location.dart';
import 'home_page2.dart';
import 'realtime_provider.dart';
import 'dart:async';
import 'dart:math';

class TripsRoute extends StatefulWidget {
  final String departure;
  final String arrival;
  final double? departureLatitude;
  final double? departureLongitude;
  final double? arrivalLatitude;
  final double? arrivalLongitude;

  const TripsRoute({
    Key? key,
    required this.departure,
    required this.arrival,
    this.departureLatitude,
    this.departureLongitude,
    this.arrivalLatitude,
    this.arrivalLongitude,
  }) : super(key: key);

  @override
  State<TripsRoute> createState() => _TripsRouteState();
}

class _TripsRouteState extends State<TripsRoute> {
  final MapController _mapController = MapController();
  bool _isTripStarted = false;
  String? _driverId;
  String? _busId;
  Timer? _locationUpdateTimer;
  LocationData? _currentLocation;
  final Location _location = Location();

  @override
  void initState() {
    super.initState();
    _fetchDriverAndBusInfo();
    _initializeMap();
  }

  Future<void> _fetchDriverAndBusInfo() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final driverResponse = await Supabase.instance.client
          .from('drivers')
          .select('id, bus_id')
          .eq('user_id', user.id)
          .single();

      setState(() {
        _driverId = driverResponse['id'] as String;
        _busId = driverResponse['bus_id'] as String;
      });
    } catch (e) {
      print('Error fetching driver info: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching driver info: $e')),
      );
    }
  }

  Future<void> _initializeMap() async {
    if (widget.departureLatitude != null && widget.departureLongitude != null) {
      _mapController.move(
        LatLng(widget.departureLatitude!, widget.departureLongitude!),
        14.0,
      );
    }

    if (widget.arrivalLatitude != null && widget.arrivalLongitude != null) {
      // Calculate center point between departure and arrival
      final centerLat = (widget.departureLatitude! + widget.arrivalLatitude!) / 2;
      final centerLng = (widget.departureLongitude! + widget.arrivalLongitude!) / 2;
      
      // Calculate zoom level based on distance between points
      final distance = _calculateDistance(
        widget.departureLatitude!,
        widget.departureLongitude!,
        widget.arrivalLatitude!,
        widget.arrivalLongitude!,
      );
      
      final zoom = _calculateZoom(distance);
      
      _mapController.move(
        LatLng(centerLat, centerLng),
        zoom,
      );
    }
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const R = 6371; // Earth's radius in km
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a = sin(dLat/2) * sin(dLat/2) +
            cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
            sin(dLon/2) * sin(dLon/2);
    final c = 2 * atan2(sqrt(a), sqrt(1-a));
    return R * c;
  }

  double _calculateZoom(double distance) {
    // Adjust these values based on your needs
    const minZoom = 12.0;
    const maxZoom = 15.0;
    const minDistance = 0.1; // 100 meters
    const maxDistance = 10.0; // 10 km
    
    if (distance <= minDistance) return maxZoom;
    if (distance >= maxDistance) return minZoom;
    
    // Calculate zoom based on distance
    final range = maxZoom - minZoom;
    final normalizedDistance = (distance - minDistance) / (maxDistance - minDistance);
    return maxZoom - (range * normalizedDistance);
  }

  Future<void> _startTrip() async {
    try {
      // Get the realtime provider
      final realtimeProvider = Provider.of<RealtimeProvider>(context, listen: false);

      // Start the route in realtime provider
      final success = await realtimeProvider.startRoute(
        _driverId!,
        _busId!,
        widget.departure,
        widget.arrival,
      );

      if (!success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to start trip')),
        );
        return;
      }

      setState(() => _isTripStarted = true);

      // Start location updates
      await _startLocationUpdates();
    } catch (e) {
      print('Error starting trip: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting trip: $e')),
      );
    }
  }

  Future<void> _stopTrip() async {
    try {
      // Get the realtime provider
      final realtimeProvider = Provider.of<RealtimeProvider>(context, listen: false);

      // Stop tracking in realtime provider
      await realtimeProvider.stopRoute();

      // Stop location updates
      _stopLocationUpdates();

      setState(() => _isTripStarted = false);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage2()),
      );
    } catch (e) {
      print('Error stopping trip: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error stopping trip: $e')),
      );
    }
  }

  Future<void> _startLocationUpdates() async {
    // Ensure location services are enabled
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled.')),
        );
        return;
      }
    }
    // Request permission
    PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied.')),
        );
        return;
      }
    }
    // Get initial location and update map immediately
    try {
      final initialLocation = await _location.getLocation();
      setState(() {
        _currentLocation = initialLocation;
      });
      if (initialLocation.latitude != null && initialLocation.longitude != null) {
        _mapController.move(
          LatLng(initialLocation.latitude!, initialLocation.longitude!),
          14.0,
        );
      }
    } catch (e) {
      print('Error getting initial location: $e');
    }
    // Start periodic location updates
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        if (!mounted) {
          timer.cancel();
          return;
        }
        final locationData = await _location.getLocation();
        setState(() {
          _currentLocation = locationData;
        });
        // Update the map center
        if (locationData.latitude != null && locationData.longitude != null) {
          _mapController.move(
            LatLng(locationData.latitude!, locationData.longitude!),
            14.0,
          );
        }
      } catch (e) {
        print('Error getting location: $e');
      }
    });
  }

  void _stopLocationUpdates() {
    _locationUpdateTimer?.cancel();
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Route'),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(27.87374386370353, -0.28424559734165983),
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.bus_app',
              ),
              if (widget.departureLatitude != null && widget.departureLongitude != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(widget.departureLatitude!, widget.departureLongitude!),
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.departure_board, color: Colors.green, size: 30),
                    ),
                  ],
                ),
              if (widget.arrivalLatitude != null && widget.arrivalLongitude != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(widget.arrivalLatitude!, widget.arrivalLongitude!),
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.flag, color: Colors.red, size: 30),
                    ),
                  ],
                ),
              if (_currentLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.location_on, color: Colors.blue, size: 30),
                    ),
                  ],
                ),
            ],
          ),
          Positioned(
            bottom: 16.0,
            left: 16.0,
            right: 16.0,
            child: ElevatedButton(
              onPressed: _isTripStarted ? _stopTrip : _startTrip,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isTripStarted ? Colors.red : Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              ),
              child: Text(
                _isTripStarted ? 'Stop Trip' : 'Start Trip',
                style: const TextStyle(fontSize: 18.0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}