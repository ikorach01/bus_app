import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'dart:math';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'realtime_provider.dart';
import 'home_page2.dart';

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
  String? _driverId;
  String? _busId;
  String? _startStationId;
  String? _endStationId;

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
    // Delay the _setupRoute call to ensure the map is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupRoute();
    });
    _fetchDriverAndBusInfo();
  }

  Future<void> _fetchDriverAndBusInfo() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        print('No authenticated user found');
        return;
      }

      // Get driver info including vehicle_registration_plate
      final driverResponse = await Supabase.instance.client
          .from('drivers')
          .select('id, bus_id, vehicle_registration_plate')
          .eq('id', user.id)
          .single();

      // Set driver ID
      setState(() {
        _driverId = driverResponse['id'];
      });
      
      // Check if bus_id is null and try to get it from the buses table using vehicle_registration_plate
      String? busId = driverResponse['bus_id'];
      String? vehiclePlate = driverResponse['vehicle_registration_plate'];
      
      if ((busId == null || busId.isEmpty) && vehiclePlate != null && vehiclePlate.isNotEmpty) {
        print('Bus ID is null in drivers table, attempting to find bus using vehicle plate: $vehiclePlate');
        
        // Try to get the bus using vehicle_registration_plate
        final busResponse = await Supabase.instance.client
            .from('buses')
            .select('id')
            .eq('vehicle_registration_plate', vehiclePlate)
            .maybeSingle();
            
        if (busResponse != null) {
          busId = busResponse['id'];
          print('Found bus with ID: $busId for vehicle plate: $vehiclePlate');
          
          // Update the driver record with the bus ID
          await Supabase.instance.client
              .from('drivers')
              .update({'bus_id': busId})
              .eq('id', user.id);
          
          print('Updated driver with bus ID: $busId');
        } else {
          // Bus doesn't exist yet, create it
          print('No bus found for vehicle plate: $vehiclePlate, creating new bus');
          final newBusResponse = await Supabase.instance.client
              .from('buses')
              .insert({
                'vehicle_registration_plate': vehiclePlate,
                'bus_name': 'Bus for $vehiclePlate'
              })
              .select()
              .single();
              
          busId = newBusResponse['id'];
          print('Created new bus with ID: $busId');
          
          // Update the driver record with the new bus ID
          await Supabase.instance.client
              .from('drivers')
              .update({'bus_id': busId})
              .eq('id', user.id);
        }
      }

      setState(() {
        _busId = busId;
      });

      print('Driver ID: $_driverId, Bus ID: $_busId');

      // Get station IDs from the stations table
      await _fetchStationIds();
    } catch (e) {
      print('Error fetching driver info: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching driver info: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _fetchStationIds() async {
    try {
      // Extract the station names without the municipality part
      String departureName = _extractStationNameOnly(widget.departure);
      String arrivalName = _extractStationNameOnly(widget.arrival);
      
      print('Searching for departure station: $departureName');
      print('Searching for arrival station: $arrivalName');
      
      // Get station IDs from the stations table using more precise matching
      // First try exact match
      final departureStation = await Supabase.instance.client
          .from('stations')
          .select('id')
          .eq('name', departureName)
          .maybeSingle();
          
      // If exact match fails, try case-insensitive match
      final departureStationResult = departureStation ?? await Supabase.instance.client
          .from('stations')
          .select('id')
          .ilike('name', departureName)
          .maybeSingle();
      
      // First try exact match
      final arrivalStation = await Supabase.instance.client
          .from('stations')
          .select('id')
          .eq('name', arrivalName)
          .maybeSingle();
          
      // If exact match fails, try case-insensitive match
      final arrivalStationResult = arrivalStation ?? await Supabase.instance.client
          .from('stations')
          .select('id')
          .ilike('name', arrivalName)
          .maybeSingle();
      
      setState(() {
        _startStationId = departureStationResult != null ? departureStationResult['id'] : null;
        _endStationId = arrivalStationResult != null ? arrivalStationResult['id'] : null;
      });

      print('Start Station ID: $_startStationId, End Station ID: $_endStationId');
      
      // If stations not found, create them
      if (_startStationId == null || _endStationId == null) {
        await _createMissingStations(departureName, arrivalName);
      }
    } catch (e) {
      print('Error fetching station IDs: $e');
    }
  }

  // Helper method to extract just the station name without the municipality
  String _extractStationNameOnly(String fullName) {
    // Check if the name contains a parenthesis
    final regex = RegExp(r'(.*?)\s*\(.*\)');
    final match = regex.firstMatch(fullName);
    
    if (match != null && match.groupCount >= 1) {
      return match.group(1)?.trim() ?? fullName;
    }
    
    return fullName;
  }

  Future<void> _createMissingStations(String departureName, String arrivalName) async {
    try {
      // Create stations if they don't exist
      if (_startStationId == null) {
        // Extract municipality from the full name
        final departureCoords = _extractCoordinatesFromText(widget.departure);
        final departureMunicipality = _extractMunicipalityFromText(widget.departure);
        
        if (departureCoords != null) {
          final response = await Supabase.instance.client
              .from('stations')
              .insert({
                'name': departureName,
                'latitude': departureCoords.latitude.toString(),
                'longitude': departureCoords.longitude.toString(),
                'mairie': departureMunicipality,
              })
              .select()
              .single();
          
          setState(() {
            _startStationId = response['id'];
          });
          print('Created start station with ID: $_startStationId');
        }
      }

      if (_endStationId == null) {
        // Extract municipality from the full name
        final arrivalCoords = _extractCoordinatesFromText(widget.arrival);
        final arrivalMunicipality = _extractMunicipalityFromText(widget.arrival);
        
        if (arrivalCoords != null) {
          final response = await Supabase.instance.client
              .from('stations')
              .insert({
                'name': arrivalName,
                'latitude': arrivalCoords.latitude.toString(),
                'longitude': arrivalCoords.longitude.toString(),
                'mairie': arrivalMunicipality,
              })
              .select()
              .single();
          
          setState(() {
            _endStationId = response['id'];
          });
          print('Created end station with ID: $_endStationId');
        }
      }
    } catch (e) {
      print('Error creating stations: $e');
    }
  }

  // Helper method to extract municipality from text
  String? _extractMunicipalityFromText(String text) {
    // Check if it's in format "Station Name (Municipality)"
    final regex = RegExp(r'.*\((.*)\)');
    final match = regex.firstMatch(text);
    
    if (match != null && match.groupCount >= 1) {
      return match.group(1)?.trim();
    }
    
    // If not in parentheses format, return the original text as it might be just the municipality
    return text;
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
    // Make sure the map is ready before trying to move it
    if (!mounted) return;
    
    // Get coordinates for departure and arrival
    final departureCoords = _extractCoordinatesFromText(widget.departure);
    final arrivalCoords = _extractCoordinatesFromText(widget.arrival);

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

      // Center the map with calculated zoom - safely
      try {
        _mapController.move(LatLng(centerLat, centerLng), zoom);
      } catch (e) {
        debugPrint('Error moving map: $e');
        // The map might not be ready yet, which is fine
      }
    } else {
      // If we can't extract coordinates, set default location
      print('Could not extract coordinates from departure: ${widget.departure} or arrival: ${widget.arrival}');
      setState(() {
        // Set a default point to avoid empty route points
        _routePoints = [LatLng(27.8742, -0.2891)]; // Default to Adrar coordinates
      });
    }
  }

  // Helper method to extract coordinates from text that might contain municipality name
  LatLng? _extractCoordinatesFromText(String text) {
    // First check if it's a direct municipality name
    if (_municipalityCoordinates.containsKey(text)) {
      return _municipalityCoordinates[text];
    }
    
    // If not, it might be in format "Station Name (Municipality)"
    final regex = RegExp(r'(.*)\s*\((.*)\)');
    final match = regex.firstMatch(text);
    
    if (match != null && match.groupCount >= 2) {
      final municipality = match.group(2)?.trim();
      if (municipality != null && _municipalityCoordinates.containsKey(municipality)) {
        return _municipalityCoordinates[municipality];
      }
    }
    
    // If all else fails, return null
    return null;
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

  Future<void> _startTrip() async {
    // Check if we have all required information
    if (_driverId == null || _busId == null || _startStationId == null || _endStationId == null) {
      // Debug information to help identify the issue
      print('Missing required information:');
      print('Driver ID: $_driverId');
      print('Bus ID: $_busId');
      print('Start Station ID: $_startStationId');
      print('End Station ID: $_endStationId');
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Missing required information to start trip'),
          backgroundColor: Colors.red,
        ),
      );
      
      // Try to fetch the information again
      await _fetchDriverAndBusInfo();
      
      // Check again after fetching
      if (_driverId == null || _busId == null || _startStationId == null || _endStationId == null) {
        // If still missing, show a more detailed error message
        if (_driverId == null) {
          _showDetailedErrorMessage('Driver ID is missing. Please ensure you are logged in correctly.');
        } else if (_busId == null) {
          _showDetailedErrorMessage('Bus ID is missing. Please contact an administrator to assign a bus to your account.');
        } else if (_startStationId == null || _endStationId == null) {
          _showDetailedErrorMessage('Station information is missing. Please check that "${widget.departure}" and "${widget.arrival}" are valid stations.');
        }
        return;
      }
    }
    
    // If we reach here, all required information is available
    try {
      print('All required information is available:');
      print('Driver ID: $_driverId');
      print('Bus ID: $_busId');
      print('Start Station ID: $_startStationId');
      print('End Station ID: $_endStationId');
      print('Departure: ${widget.departure}');
      print('Arrival: ${widget.arrival}');
      
      // Get the realtime provider
      final realtimeProvider = Provider.of<RealtimeProvider>(context, listen: false);
      
      print('Calling realtimeProvider.startRoute...');
      
      // Use the actual station names instead of IDs for better user experience
      final success = await realtimeProvider.startRoute(
        _driverId!,
        _busId!,
        widget.departure,
        widget.arrival,
      );
      
      print('startRoute result: $success');
      
      if (success) {
        setState(() {
          _isTripStarted = true;
          _isTracking = true;
          if (_currentLocation != null) {
            _routePoints = [LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!)];
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trip started successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to start trip'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error starting trip: $e');
      print('Stack trace: ${StackTrace.current}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error starting trip: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _showDetailedErrorMessage(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cannot Start Trip'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _stopTrip() async {
    try {
      // Get the realtime provider
      final realtimeProvider = Provider.of<RealtimeProvider>(context, listen: false);
      
      print('Ending trip...');
      
      // Call the endRoute method in the realtime provider
      await realtimeProvider.endRoute();
      
      print('Trip ended');
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trip ended successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Navigate back to the home page
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const HomePage2(),
        ),
      );
    } catch (e) {
      print('Error ending trip: $e');
      print('Stack trace: ${StackTrace.current}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error ending trip: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
                    onMapReady: () {
                      // Now it's safe to use the map controller
                      _setupRoute();
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.bus_app',
                    ),
                    PolylineLayer(
                      polylines: [
                        if (_routePoints.isNotEmpty) // Only add polyline if there are points
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