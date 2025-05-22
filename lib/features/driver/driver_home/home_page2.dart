import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'settings2.dart';
import 'departure2.dart';
import 'destination2.dart';
import 'realtime_provider.dart';

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

  // Supabase client
  final _supabase = Supabase.instance.client;

  // Route state
  bool _isRouteActive = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _getUserLocation();

    // Check if there's an active route
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final realtimeProvider = Provider.of<RealtimeProvider>(context, listen: false);
      setState(() {
        _isRouteActive = realtimeProvider.isRouteActive;
      });

      // Listen for changes in route status
      realtimeProvider.addListener(_onRealtimeProviderUpdate);
    });
  }

  void _onRealtimeProviderUpdate() {
    if (!mounted) return;

    final realtimeProvider = Provider.of<RealtimeProvider>(context, listen: false);
    setState(() {
      _isRouteActive = realtimeProvider.isRouteActive;

      // If we have a current location from the provider, update the map
      if (realtimeProvider.currentLocation != null) {
        _currentLocation = realtimeProvider.currentLocation;
        _mapController.move(
          LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
          14.0,
        );
      }
    });
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

        // Store the station name in the controller

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

        // Store the station name in the controller

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
                  : const LatLng(27.87374386370353, -0.28424559734165983), // Default to Adrar, Algeria
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
              ),
              // Draw route line if we have route points
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: Colors.blue,
                      strokeWidth: 4.0,
                    ),
                  ],
                ),
              // Show current location marker
              if (_currentLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 80.0,
                      height: 80.0,
                      point: LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
                      child: _isRouteActive
                          ? Image.asset('assets/images/bus-station.png', width: 60, height: 60)
                          : const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 40.0,
                            ),
                    ),
                  ],
                ),
              // Show destination marker if selected
              if (_destinationLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 40.0,
                      height: 40.0,
                      point: _destinationLocation!,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.green,
                        size: 40.0,
                      ),
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
                          onPressed: _isRouteActive ? _endCurrentRoute : _startNewRoute,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isRouteActive ? Colors.red : const Color(0xFF2A52C9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            _isRouteActive ? 'End Route' : 'Start Route',
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
    // Remove listener
    try {
      final realtimeProvider = Provider.of<RealtimeProvider>(context, listen: false);
      realtimeProvider.removeListener(_onRealtimeProviderUpdate);
    } catch (e) {
      // Provider might not be available during dispose
      print('Error removing listener: $e');
    }
    
    _departureController.dispose();
    _arrivalController.dispose();
    super.dispose();
  }

  // Start a new route
  Future<void> _startNewRoute() async {
    if (_departureController.text.isEmpty || _arrivalController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select departure and destination stations')),
      );
      return;
    }
    
    try {
      // Get current user ID (driver ID)
      final driverId = _supabase.auth.currentUser?.id;
      if (driverId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You need to be logged in to start a route')),
        );
        return;
      }
      
      // Get assigned bus ID for this driver
      final busResponse = await _supabase
          .from('drivers')
          .select('bus_id')
          .eq('user_id', driverId)
          .maybeSingle();
      
      final busId = busResponse?['bus_id'];
      if (busId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No bus assigned to this driver')),
        );
        return;
      }
      
      // Start the route using RealtimeProvider
      final realtimeProvider = Provider.of<RealtimeProvider>(context, listen: false);
      final success = await realtimeProvider.startRoute(
        driverId,
        busId,
        _departureController.text,
        _arrivalController.text,
      );
      
      if (success) {
        setState(() {
          _isRouteActive = true;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Route started successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to start route')),
        );
      }
    } catch (e) {
      print('Error starting route: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting route: $e')),
      );
    }
  }

  // End the current route
  Future<void> _endCurrentRoute() async {
    try {
      final realtimeProvider = Provider.of<RealtimeProvider>(context, listen: false);
      await realtimeProvider.endRoute();
      
      setState(() {
        _isRouteActive = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Route ended successfully')),
      );
    } catch (e) {
      print('Error ending route: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error ending route: $e')),
      );
    }
  }
}