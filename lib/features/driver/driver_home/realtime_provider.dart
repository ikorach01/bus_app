import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RealtimeProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  final _location = Location();
  StreamSubscription<LocationData>? _locationSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _busPositionsSubscription;
  
  // Current driver route info
  int? _currentRouteId;
  String? _busId;
  String? _driverId;
  String? _startStation;
  String? _endStation;
  
  // Current location info
  LocationData? _currentLocation;
  double _currentSpeed = 0;
  double _currentHeading = 0;
  
  // List of all active buses for passenger view
  List<Map<String, dynamic>> _activeBuses = [];
  
  // Getters
  LocationData? get currentLocation => _currentLocation;
  double get currentSpeed => _currentSpeed;
  double get currentHeading => _currentHeading;
  int? get currentRouteId => _currentRouteId;
  List<Map<String, dynamic>> get activeBuses => _activeBuses;
  bool get isRouteActive => _currentRouteId != null;
  String? get busId => _busId;
  String? get driverId => _driverId;
  String? get startStation => _startStation;
  String? get endStation => _endStation;
  
  RealtimeProvider() {
    try {
      _initializeLocationTracking();
      _listenToBusPositions();
    } catch (e) {
      debugPrint('Error initializing RealtimeProvider: $e');
      // Continue without location tracking if it fails
    }
  }
  
  // Initialize location tracking
  Future<void> _initializeLocationTracking() async {
    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) return;
      }
      
      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) return;
      }
      
      // Enable background mode for continuous tracking - skip on web platform
      try {
        await _location.enableBackgroundMode(enable: true);
      } catch (e) {
        debugPrint('Could not enable background mode, possibly on web platform: $e');
        // Continue without background mode
      }
      
      // Get initial location
      try {
        _currentLocation = await _location.getLocation();
        notifyListeners();
      } catch (e) {
        debugPrint('Could not get initial location: $e');
        // Continue without initial location
      }
    } catch (e) {
      debugPrint('Error initializing location: $e');
    }
  }
  
  // Start a new route for the driver
  Future<bool> startRoute(String driverId, String busId, String startStation, String endStation) async {
    try {
      print('Starting route with driver ID: $driverId, bus ID: $busId');
      print('Original start station: $startStation');
      print('Original end station: $endStation');
      
      _busId = busId;
      _driverId = driverId;
      _startStation = startStation;
      _endStation = endStation;
      
      // Extract the station names without the municipality part
      String departureStationName = _extractStationNameOnly(startStation);
      String arrivalStationName = _extractStationNameOnly(endStation);
      
      print('Extracted departure station name: $departureStationName');
      print('Extracted arrival station name: $arrivalStationName');
      
      // Get station IDs from the stations table using partial matching
      final departureStation = await _supabase
          .from('stations')
          .select('id, name')
          .ilike('name', '%$departureStationName%')
          .maybeSingle();
      
      final arrivalStation = await _supabase
          .from('stations')
          .select('id, name')
          .ilike('name', '%$arrivalStationName%')
          .maybeSingle();
      
      print('Found departure station: ${departureStation != null ? departureStation : 'null'}');
      print('Found arrival station: ${arrivalStation != null ? arrivalStation : 'null'}');
      
      if (departureStation == null || arrivalStation == null) {
        print('One or both stations not found. Creating missing stations...');
        
        // Try to create the stations if they don't exist
        if (departureStation == null) {
          try {
            final newDepartureStation = await _supabase
                .from('stations')
                .insert({
                  'name': departureStationName,
                  'latitude': '0', // Default values
                  'longitude': '0',
                  'mairie': _extractMunicipalityFromText(startStation),
                })
                .select()
                .single();
            
            print('Created new departure station: $newDepartureStation');
          } catch (e) {
            print('Error creating departure station: $e');
          }
        }
        
        if (arrivalStation == null) {
          try {
            final newArrivalStation = await _supabase
                .from('stations')
                .insert({
                  'name': arrivalStationName,
                  'latitude': '0', // Default values
                  'longitude': '0',
                  'mairie': _extractMunicipalityFromText(endStation),
                })
                .select()
                .single();
            
            print('Created new arrival station: $newArrivalStation');
          } catch (e) {
            print('Error creating arrival station: $e');
          }
        }
        
        // Try to get the stations again
        final updatedDepartureStation = await _supabase
            .from('stations')
            .select('id, name')
            .ilike('name', '%$departureStationName%')
            .maybeSingle();
        
        final updatedArrivalStation = await _supabase
            .from('stations')
            .select('id, name')
            .ilike('name', '%$arrivalStationName%')
            .maybeSingle();
        
        print('Updated departure station: ${updatedDepartureStation != null ? updatedDepartureStation : 'null'}');
        print('Updated arrival station: ${updatedArrivalStation != null ? updatedArrivalStation : 'null'}');
      }
      
      // Insert new route into driver_routes table
      print('Inserting new route into driver_routes table...');
      
      // Try with minimal required fields first
      try {
        print('Trying simplified insert with minimal fields...');
        final response = await _supabase
            .from('driver_routes')
            .insert({
              'driver_id': driverId,
              'start_station': departureStationName,
              'end_station': arrivalStationName,
              'start_time': DateTime.now().toUtc().toIso8601String(),
            })
            .select()
            .single();
        
        print('Route created successfully: $response');
        _currentRouteId = response['id'] as int;
        
        // Start location tracking
        _startLocationTracking();
        
        await _sendLocationUpdate();
        
        notifyListeners();
        return true;
      } catch (e) {
        print('ERROR DETAILS (simplified insert): ${e.toString()}');
        
        // Try to get more details about the error
        if (e is PostgrestException) {
          print('PostgrestException details:');
          print('Code: ${e.code}');
          print('Message: ${e.message}');
          print('Details: ${e.details}');
          print('Hint: ${e.hint}');
        }
        
        print('Error with simplified insert into driver_routes: $e');
        print('Stack trace: ${StackTrace.current}');
        
        // Try with all fields
        print('Trying full insert with all fields...');
        try {
          // Create a new route entry in the driver_routes table
          final routeData = {
            'driver_id': driverId,
            'bus_id': busId,
            'start_station': departureStationName,
            'end_station': arrivalStationName,
            'start_station_id': departureStation != null ? departureStation['id'] : null,
            'end_station_id': arrivalStation != null ? arrivalStation['id'] : null,
            'start_time': DateTime.now().toUtc().toIso8601String(),
          };
          
          // Store station IDs in the database only
          
          final response = await _supabase
              .from('driver_routes')
              .insert(routeData)
              .select('id')
              .single();
          
          print('Route created successfully with full data: $response');
          _currentRouteId = response['id'] as int;
          
          // Start location tracking
          _startLocationTracking();
          
          await _sendLocationUpdate();
          
          notifyListeners();
          return true;
        } catch (e2) {
          print('ERROR DETAILS (full insert): ${e2.toString()}');
          
          // Try to get more details about the error
          if (e2 is PostgrestException) {
            print('PostgrestException details:');
            print('Code: ${e2.code}');
            print('Message: ${e2.message}');
            print('Details: ${e2.details}');
            print('Hint: ${e2.hint}');
          }
          
          print('Error inserting into driver_routes: $e2');
          print('Stack trace: ${StackTrace.current}');
          
          return false;
        }
      }
    } catch (e) {
      print('Error starting route: $e');
      print('Stack trace: ${StackTrace.current}');
      return false;
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

  // Helper method to extract municipality from text
  String? _extractMunicipalityFromText(String text) {
    // Check if it's in format "Station Name (Municipality)"
    final regex = RegExp(r'.*\((.*)\)');
    final match = regex.firstMatch(text);
    
    if (match != null && match.groupCount >= 1) {
      return match.group(1)?.trim();
    }
    
    return null;
  }
  
  // End the current route
  Future<void> endRoute() async {
    if (_currentRouteId == null) return;
    
    try {
      // Stop location tracking
      _stopLocationTracking();
      
      // Update route end time in driver_routes table
      await _supabase
          .from('driver_routes')
          .update({
            'end_time': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', _currentRouteId!);
      
      // Clear route info
      _currentRouteId = null;
      _busId = null;
      _driverId = null;
      _startStation = null;
      _endStation = null;
      // All route data cleared
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error ending route: $e');
    }
  }
  
  // Start tracking location and sending updates
  void _startLocationTracking() {
    _locationSubscription = _location.onLocationChanged.listen((locationData) {
      _currentLocation = locationData;
      _currentSpeed = locationData.speed ?? 0;
      _currentHeading = locationData.heading ?? 0;
      
      // Send location update to server
      _sendLocationUpdate();
      
      notifyListeners();
    });
  }
  
  // Stop tracking location
  void _stopLocationTracking() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
  }
  
  // Send location update to server
  Future<void> _sendLocationUpdate() async {
    if (_currentRouteId == null || _currentLocation == null || _busId == null) return;
    
    try {
      // Insert location update into bus_positions table
      await _supabase
          .from('bus_positions')
          .insert({
            'bus_id': _busId!,
            'route_id': _currentRouteId!,
            'latitude': _currentLocation!.latitude,
            'longitude': _currentLocation!.longitude,
            'speed': _currentSpeed,
            'heading': _currentHeading,
            'timestamp': DateTime.now().toUtc().toIso8601String(),
          });
      
      // Also update the bus location in the buses table
      await _updateBusStatus(null);
    } catch (e) {
      debugPrint('Error sending location update: $e');
    }
  }
  
  // Update bus status in buses table
  Future<void> _updateBusStatus(String? destination) async {
    if (_busId == null || _currentLocation == null) return;
    
    try {
      // Calculate ETA based on distance and speed
      int etaToDestination = 15; // Default 15 minutes
      if (_currentSpeed > 0) {
        etaToDestination = (10 + (30 / _currentSpeed)).round();
      }
      
      final Map<String, dynamic> updateData = {
        'latitude': _currentLocation!.latitude,
        'longitude': _currentLocation!.longitude,
        'speed': (_currentSpeed * 3.6).round(), // Convert m/s to km/h
        'eta_to_destination': etaToDestination,
      };
      
      // Only update destination if provided
      if (destination != null) {
        updateData['destination'] = destination;
      }
      
      await _supabase
          .from('buses')
          .update(updateData)
          .eq('id', _busId!);
    } catch (e) {
      debugPrint('Error updating bus status: $e');
    }
  }
  
  // Listen to all bus positions for passenger view
  void _listenToBusPositions() {
    try {
      // First, get active routes (not ended yet)
      _supabase
          .from('driver_routes')
          .select('id, bus_id, driver_id, start_station, end_station')
          .filter('end_time', 'is', null)
          .then((activeRoutes) {
            // For each active route, get the latest position
            if (activeRoutes.isNotEmpty) {
              final activeBusIds = activeRoutes.map<String>((route) => route['bus_id'] as String).toSet().toList();
              
              // Set up subscription to bus positions for active buses
              _busPositionsSubscription = _supabase
                .from('bus_positions')
                .stream(primaryKey: ['id'])
                .inFilter('bus_id', activeBusIds)
                .order('timestamp', ascending: false)
                .limit(activeBusIds.length * 2) // Get latest 2 positions per bus to calculate heading
                .execute()
                .map((positions) {
                  // Group positions by bus_id and get the latest for each
                  final Map<String, Map<String, dynamic>> latestPositions = {};
                  for (var position in positions) {
                    final busId = position['bus_id'];
                    if (!latestPositions.containsKey(busId) || 
                        DateTime.parse(position['timestamp']).isAfter(
                          DateTime.parse(latestPositions[busId]!['timestamp']))) {
                      latestPositions[busId] = position;
                    }
                  }
                  
                  // Combine with route information
                  return latestPositions.values.map((position) {
                    final route = activeRoutes.firstWhere(
                      (r) => r['bus_id'] == position['bus_id'],
                      orElse: () => {},
                    );
                    
                    if (route.isNotEmpty) {
                      return {
                        ...position,
                        'driver_id': route['driver_id'],
                        'start_station': route['start_station'],
                        'end_station': route['end_station'],
                      };
                    }
                    return position;
                  }).toList();
                })
                .listen((buses) {
                  // Update active buses with latest positions
                  _activeBuses = buses.where((bus) => 
                    bus['latitude'] != null && 
                    bus['longitude'] != null
                  ).toList();
                  notifyListeners();
                }, onError: (error) {
                  debugPrint('Error in bus positions stream: $error');
                });
            }
          })
          .catchError((error) {
            debugPrint('Error fetching active routes: $error');
          });
    } catch (e) {
      debugPrint('Error setting up bus positions stream: $e');
    }
  }
  
  // Get driver info for a specific bus
  Future<Map<String, dynamic>?> getDriverInfoForBus(String busId) async {
    try {
      final response = await _supabase
          .from('drivers')
          .select('first_name, last_name, bus_photo, bus_name')
          .eq('bus_id', busId)
          .maybeSingle();
      
      return response;
    } catch (e) {
      debugPrint('Error getting driver info: $e');
      return null;
    }
  }
  
  // Get bus photo as base64 string
  Future<String?> getBusPhoto(String busId) async {
    try {
      final response = await _supabase
          .from('drivers')
          .select('bus_photo')
          .eq('bus_id', busId)
          .maybeSingle();
      
      if (response != null && response['bus_photo'] != null) {
        try {
          if (response['bus_photo'] is List) {
            final List<int> photoBytes = List<int>.from(response['bus_photo']);
            return base64Encode(photoBytes);
          } else if (response['bus_photo'] is String) {
            return response['bus_photo'];
          } else {
            debugPrint('Unexpected data type for bus_photo: ${response['bus_photo'].runtimeType}');
            return null;
          }
        } catch (e) {
          debugPrint('Error processing bus photo: $e');
          return null;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error getting bus photo: $e');
      return null;
    }
  }
  
  @override
  void dispose() {
    _locationSubscription?.cancel();
    _busPositionsSubscription?.cancel();
    super.dispose();
  }
}