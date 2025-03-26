import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

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
  MapController? _mapController;
  final _supabase = Supabase.instance.client;
  LocationData? _currentLocation;
  bool _isTripStarted = false;
  bool _isLoading = true;
  List<LatLng> _routePoints = [];
  final _location = Location();
  bool _isTracking = false;
  String? _currentRouteId;
  String? _driverId;
  String? _busId;
  String? _startStationId;
  String? _endStationId;
  Timer? _locationUpdateTimer;
  StreamSubscription<LocationData>? _locationSubscription;

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
    _loadDriverInfo();
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    _locationSubscription?.cancel();
    _mapController = null;
    super.dispose();
  }

  Future<void> _loadDriverInfo() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final user = _supabase.auth.currentUser;
      if (user != null) {
        print('Current user ID: ${user.id}');
        
        try {
          // Vérifier si le chauffeur existe
          final driverData = await _supabase
              .from('drivers')
              .select('id, bus_id, first_name, last_name')
              .eq('id', user.id)
              .maybeSingle();
          
          if (driverData != null) {
            print('Driver data found: ${driverData['first_name']} ${driverData['last_name']}');
            
            // Vérifier si un bus est assigné
            if (driverData['bus_id'] != null) {
              setState(() {
                _driverId = driverData['id'];
                _busId = driverData['bus_id'];
              });
              print('Bus ID assigned: ${driverData['bus_id']}');
            } else {
              print('No bus assigned to this driver');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No bus assigned to your account. Please contact admin.')),
              );
            }
          } else {
            print('No driver record found for user ID: ${user.id}');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Driver profile not found. Please complete registration.')),
            );
          }
        } catch (e) {
          print('Error fetching driver data: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading driver data: $e')),
          );
        }
      } else {
        print('No authenticated user found');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to continue')),
        );
      }
    } catch (e) {
      print('Error in _loadDriverInfo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getStationIds() async {
    try {
      print('Getting station IDs for departure: ${widget.departure}, arrival: ${widget.arrival}');
      
      // Vérifier si les coordonnées des municipalités existent
      if (!_municipalityCoordinates.containsKey(widget.departure)) {
        print('Error: Departure municipality ${widget.departure} not found in coordinates list');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Departure location "${widget.departure}" not found')),
        );
        return;
      }
      
      if (!_municipalityCoordinates.containsKey(widget.arrival)) {
        print('Error: Arrival municipality ${widget.arrival} not found in coordinates list');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Arrival location "${widget.arrival}" not found')),
        );
        return;
      }
      
      // Récupérer ou créer la station de départ
      try {
        final startStationData = await _supabase
            .from('stations')
            .select('id')
            .eq('name', widget.departure)
            .maybeSingle();

        if (startStationData != null) {
          _startStationId = startStationData['id'];
          print('Found existing start station ID: $_startStationId');
        } else {
          final startCoordinates = _municipalityCoordinates[widget.departure];
          print('Creating new start station for ${widget.departure} at ${startCoordinates!.latitude}, ${startCoordinates.longitude}');
          
          try {
            final newStartStation = await _supabase
                .from('stations')
                .insert({
                  'name': widget.departure,
                  'latitude': startCoordinates.latitude,
                  'longitude': startCoordinates.longitude,
                })
                .select('id')
                .single();
            
            _startStationId = newStartStation['id'];
            print('Created new start station with ID: $_startStationId');
          } catch (e) {
            print('Error creating start station: $e');
            // Essayer de récupérer à nouveau au cas où la station a été créée entre-temps
            final retryStartStation = await _supabase
                .from('stations')
                .select('id')
                .eq('name', widget.departure)
                .maybeSingle();
                
            if (retryStartStation != null) {
              _startStationId = retryStartStation['id'];
              print('Found start station on retry: $_startStationId');
            } else {
              throw Exception('Failed to create or find start station');
            }
          }
        }
      } catch (e) {
        print('Error processing start station: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error with departure station: $e')),
        );
        return;
      }

      // Récupérer ou créer la station d'arrivée
      try {
        final endStationData = await _supabase
            .from('stations')
            .select('id')
            .eq('name', widget.arrival)
            .maybeSingle();

        if (endStationData != null) {
          _endStationId = endStationData['id'];
          print('Found existing end station ID: $_endStationId');
        } else {
          final endCoordinates = _municipalityCoordinates[widget.arrival];
          print('Creating new end station for ${widget.arrival} at ${endCoordinates!.latitude}, ${endCoordinates.longitude}');
          
          try {
            final newEndStation = await _supabase
                .from('stations')
                .insert({
                  'name': widget.arrival,
                  'latitude': endCoordinates.latitude,
                  'longitude': endCoordinates.longitude,
                })
                .select('id')
                .single();
            
            _endStationId = newEndStation['id'];
            print('Created new end station with ID: $_endStationId');
          } catch (e) {
            print('Error creating end station: $e');
            // Essayer de récupérer à nouveau au cas où la station a été créée entre-temps
            final retryEndStation = await _supabase
                .from('stations')
                .select('id')
                .eq('name', widget.arrival)
                .maybeSingle();
                
            if (retryEndStation != null) {
              _endStationId = retryEndStation['id'];
              print('Found end station on retry: $_endStationId');
            } else {
              throw Exception('Failed to create or find end station');
            }
          }
        }
      } catch (e) {
        print('Error processing end station: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error with arrival station: $e')),
        );
        return;
      }
      
      // Vérifier que toutes les informations sont disponibles
      print('Final station IDs - Start: $_startStationId, End: $_endStationId');
      print('Driver ID: $_driverId, Bus ID: $_busId');
      
      if (_startStationId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not determine departure station ID')),
        );
      }
      
      if (_endStationId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not determine arrival station ID')),
        );
      }
    } catch (e) {
      print('Error in _getStationIds: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting station information: $e')),
      );
    }
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

      _currentLocation = await _location.getLocation();

      _locationSubscription = _location.onLocationChanged.listen((LocationData newLocation) {
        if (!mounted) return;
        
        setState(() {
          _currentLocation = newLocation;

          if (_isTracking && _currentLocation != null) {
            _routePoints.add(LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!));

            if (_mapController != null) {
              try {
                _mapController!.move(
                  LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
                  _mapController!.camera.zoom,
                );
              } catch (e) {
                print('MapController error: $e');
              }
            }
            
            _updateDriverLocation();
          }
        });
      });

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error initializing location tracking: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateDriverLocation() async {
    if (_currentRouteId != null && _currentLocation != null) {
      try {
        await _supabase
            .from('driver_locations')
            .upsert({
              'driver_id': _driverId,
              'route_id': _currentRouteId,
              'latitude': _currentLocation!.latitude,
              'longitude': _currentLocation!.longitude,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            });
      } catch (e) {
        print('Error updating driver location: $e');
      }
    }
  }

  Future<void> _setupRoute() async {
    if (_municipalityCoordinates.containsKey(widget.departure) && _municipalityCoordinates.containsKey(widget.arrival)) {
      final departureCoords = _municipalityCoordinates[widget.departure]!;
      final arrivalCoords = _municipalityCoordinates[widget.arrival]!;

      // Calculer les points de la route
      setState(() {
        _routePoints = [departureCoords, arrivalCoords];
      });
    }
  }

  Future<void> _startTrip() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Recharger les informations du chauffeur et du bus si nécessaires
      if (_driverId == null || _busId == null) {
        await _loadDriverInfo();
      }

      // Obtenir les IDs des stations
      await _getStationIds();

      // Vérifications détaillées pour fournir des messages d'erreur plus spécifiques
      String? missingInfo;
      
      if (_driverId == null) {
        missingInfo = "Driver ID";
        print("Missing Driver ID");
      } else if (_busId == null) {
        missingInfo = "Bus ID";
        print("Missing Bus ID");
      } else if (_startStationId == null) {
        missingInfo = "Departure station";
        print("Missing Start Station ID");
      } else if (_endStationId == null) {
        missingInfo = "Arrival station";
        print("Missing End Station ID");
      }

      if (missingInfo != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Missing required information: $missingInfo')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Toutes les informations sont disponibles, créer l'itinéraire
      print("Creating route with Driver ID: $_driverId, Bus ID: $_busId");
      print("Start Station: $_startStationId, End Station: $_endStationId");
      
      try {
        final routeData = await _supabase
            .from('driver_routes')
            .insert({
              'driver_id': _driverId,
              'bus_id': _busId,
              'start_station': _startStationId,
              'end_station': _endStationId,
              'start_time': DateTime.now().toUtc().toIso8601String(),
            })
            .select('id')
            .single();

        _currentRouteId = routeData['id'].toString();
        print("Route created successfully with ID: $_currentRouteId");

        if (_currentLocation != null) {
          await _updateDriverLocation();
          print("Driver location updated");
        } else {
          print("Current location is null, skipping location update");
        }

        setState(() {
          _isTripStarted = true;
          _isTracking = true;
          _isLoading = false;
          if (_currentLocation != null) {
            _routePoints = [LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!)];
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trip started successfully')),
        );
      } catch (e) {
        print('Error inserting route data: $e');
        
        // Vérifier si c'est une erreur de politique RLS
        if (e.toString().contains('row-level security policy')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permission denied. You may not have rights to create routes.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error creating route: $e')),
          );
        }
        
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error starting trip: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _stopTrip() async {
    try {
      setState(() {
        _isLoading = true;
      });

      if (_currentRouteId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No active trip to stop')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      await _supabase
          .from('driver_routes')
          .update({
            'end_time': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', int.parse(_currentRouteId!));

      setState(() {
        _isTripStarted = false;
        _isTracking = false;
        _isLoading = false;
        _currentRouteId = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trip ended successfully')),
      );
    } catch (e) {
      print('Error stopping trip: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error stopping trip: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF2A52C9),
                  ),
                )
              : FlutterMap(
                  mapController: _mapController = MapController(),
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
}