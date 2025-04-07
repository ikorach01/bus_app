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
  
  RealtimeProvider() {
    _initializeLocationTracking();
    _listenToBusPositions();
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
      
      // Enable background mode for continuous tracking
      await _location.enableBackgroundMode(enable: true);
      
      // Get initial location
      _currentLocation = await _location.getLocation();
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing location: $e');
    }
  }
  
  // Start a new route for the driver
  Future<bool> startRoute(String driverId, String busId, String startStation, String endStation) async {
    try {
      _busId = busId;
      
      // Get station IDs from the stations table
      final departureStation = await _supabase
          .from('stations')
          .select('id')
          .eq('name', startStation)
          .maybeSingle();
      
      final arrivalStation = await _supabase
          .from('stations')
          .select('id')
          .eq('name', endStation)
          .maybeSingle();
      
      // Insert new route into driver_routes table
      final response = await _supabase
          .from('driver_routes')
          .insert({
            'driver_id': driverId,
            'bus_id': busId,
            'start_station': startStation,
            'end_station': endStation,
            'start_station_id': departureStation != null ? departureStation['id'] : null,
            'end_station_id': arrivalStation != null ? arrivalStation['id'] : null,
            'start_time': DateTime.now().toUtc().toIso8601String(),
          })
          .select()
          .single();
      
      _currentRouteId = response['id'] as int;
      
      // Start location tracking
      _startLocationTracking();
      
      // Update bus status in buses table
      await _updateBusStatus(endStation);
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error starting route: $e');
      return false;
    }
  }
  
  // End the current route
  Future<bool> endRoute() async {
    if (_currentRouteId == null) return false;
    
    try {
      // Update the end_time in driver_routes
      await _supabase
          .from('driver_routes')
          .update({
            'end_time': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', _currentRouteId!);
      
      // Stop location tracking
      _stopLocationTracking();
      
      // Reset route info
      _currentRouteId = null;
      _busId = null;
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error ending route: $e');
      return false;
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
      await _supabase
          .from('bus_positions')
          .insert({
            'bus_id': int.parse(_busId!),
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
        // More sophisticated ETA calculation could be implemented here
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
          .eq('id', int.parse(_busId!));
    } catch (e) {
      debugPrint('Error updating bus status: $e');
    }
  }
  
  // Listen to all bus positions for passenger view
  void _listenToBusPositions() {
    _busPositionsSubscription = _supabase
        .from('buses')
        .stream(primaryKey: ['id'])
        .execute()
        .map((event) => event.map((e) => e).toList())
        .listen((buses) {
          _activeBuses = buses.where((bus) => 
            bus['latitude'] != null && 
            bus['longitude'] != null
          ).toList();
          notifyListeners();
        });
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
        // The bus_photo is stored as bytea in the database
        final List<int> photoBytes = List<int>.from(response['bus_photo']);
        return base64Encode(photoBytes);
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