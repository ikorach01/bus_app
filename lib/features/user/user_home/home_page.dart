import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:bus_app/providers/settings_provider.dart';
import 'package:bus_app/features/user/settings_page.dart';
import 'package:bus_app/features/driver/driver_home/realtime_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  LocationData? _currentLocation;
  LatLng? _selectedStation;
  String _estimatedTime = "N/A";
  late MapController _mapController;
  List<LatLng> _routePoints = [];
  bool _mapReady = false;
  List<Map<String, dynamic>> _stations = [];
  bool _showOnlyMoving = false;

  // Bus data
  List<Map<String, dynamic>> _activeBuses = [];
  Map<String, dynamic>? _selectedBus;
  String? _selectedStationName;

  // Helper method to validate coordinates
  LatLng _validateCoordinates(double? lat, double? lng) {
    // Default coordinates for Adrar, Algeria if invalid
    const double defaultLat = 27.87374386370353;
    const double defaultLng = -0.28424559734165983;
    
    // Check if values are null
    if (lat == null || lng == null) {
      return const LatLng(defaultLat, defaultLng);
    }
    
    // Validate latitude (must be between -90 and 90)
    double validLat = lat;
    if (lat < -90 || lat > 90) {
      print('Invalid latitude value: $lat, using default');
      validLat = defaultLat;
    }
    
    // Validate longitude (must be between -180 and 180)
    double validLng = lng;
    if (lng < -180 || lng > 180) {
      print('Invalid longitude value: $lng, using default');
      validLng = defaultLng;
    }
    
    return LatLng(validLat, validLng);
  }

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _getUserLocation();
    _fetchStations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForDelays();
      _fetchActiveBuses();
    });
  }

  Future<void> _fetchActiveBuses() async {
    final realtimeProvider = Provider.of<RealtimeProvider>(context, listen: false);
    
    // Get initial active buses
    setState(() {
      _activeBuses = realtimeProvider.activeBuses;
    });
  }

  Future<void> _checkForDelays() async {
    try {
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
      if (!settingsProvider.delayAlertsEnabled || !mounted) return;

      final delays = await _fetchDelaysFromServer();
      
      if (delays.isNotEmpty && mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delay Alerts'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: delays.map((delay) => 
                Text('${delay['busNumber']}: ${delay['delay']} minutes delay')
              ).toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print("Error checking for delays: $e");
    }
  }

  Future<List<Map<String, dynamic>>> _fetchDelaysFromServer() async {
    // محاكاة لجلب البيانات من السيرفر
    await Future.delayed(const Duration(seconds: 1));
    return [
      {'busNumber': '101', 'delay': 5},
      {'busNumber': '202', 'delay': 10},
    ];
  }

  Future<void> _getUserLocation() async {
    Location location = Location();
    
    try {
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location service is disabled')),
          );
          // Set default location if service is not available
          setState(() {
            _mapReady = true;
          });
          return;
        }
      }

      // Special handling for web platform
      try {
        PermissionStatus permissionGranted = await location.hasPermission();
        if (permissionGranted == PermissionStatus.denied) {
          permissionGranted = await location.requestPermission();
          if (permissionGranted != PermissionStatus.granted) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission denied')),
            );
            // Set default location if permission is denied
            setState(() {
              _mapReady = true;
            });
            return;
          }
        }
      } catch (e) {
        print("Error with location permissions: $e");
        // Continue with default location on web platforms where permissions might not work
        setState(() {
          _mapReady = true;
        });
      }

      try {
        LocationData locationData = await location.getLocation();
        if (!mounted) return;
        setState(() {
          _currentLocation = locationData;
        });
      } catch (e) {
        print("Error getting location: $e");
        // Set map as ready even if location failed
        setState(() {
          _mapReady = true;
        });
      }
    } catch (e) {
      print("General location error: $e");
      // Set map as ready even if there was an error
      setState(() {
        _mapReady = true;
      });
    }
  }

  Future<void> _fetchStations() async {
    try {
      final data = await Supabase.instance.client
          .from('stations')
          .select('name, latitude, longitude');
      if (data is List) {
        final stations = data.map((e) => {
          'name': e['name'],
          'lat': double.tryParse(e['latitude']) ?? 0.0,
          'lon': double.tryParse(e['longitude']) ?? 0.0,
        }).toList();
        setState(() => _stations = stations);
      } else {
        print('Unexpected stations data: $data');
      }
    } catch (e) {
      print('Exception fetching stations: $e');
    }
  }

  void _updateSelectedStation(Map<String, dynamic> station) {
    final latlng = LatLng(station['lat'], station['lon']);
    setState(() {
      _selectedStation = latlng;
      _selectedStationName = station['name'];
    });
    // only move map if it's already ready
    if (_mapReady) {
      _mapController.move(latlng, 14.0);
    }
  }

  Future<void> _calculateRoute() async {
    if (_currentLocation == null || _selectedStation == null) return;

    try {
      // Get API key from settings provider for better security
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
      final String apiKey = settingsProvider.hereApiKey;

      final Uri url = Uri.parse(
          "https://router.hereapi.com/v8/routes?apikey=$apiKey&transportMode=bus&origin=${_currentLocation!.latitude},${_currentLocation!.longitude}&destination=${_selectedStation!.latitude},${_selectedStation!.longitude}&return=polyline,summary");

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data.containsKey('routes') && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          
          if (route.containsKey('sections') && route['sections'].isNotEmpty) {
            final section = route['sections'][0];
            
            if (section.containsKey('summary')) {
              final int estimatedTimeSeconds = section['summary']['duration'] ?? 0;
              final Duration duration = Duration(seconds: estimatedTimeSeconds);
              final String estimatedTime =
                  "${duration.inMinutes} minutes";
              
              if (section.containsKey('polyline')) {
                final polyline = section['polyline'];
                final decodedPoints = _decodePolyline(polyline);

                if (!mounted) return;
                setState(() {
                  _routePoints = decodedPoints;
                  _estimatedTime = estimatedTime;
                });
              }
            }
          }
        }
      } else {
        // Fallback to mock route if API fails
        _createMockRoute();
      }
    } catch (e) {
      print("Error calculating route: $e");
      // Fallback to mock route if API fails
      _createMockRoute();
    }
  }

  void _createMockRoute() {
    if (_currentLocation == null || _selectedStation == null) return;
    
    // Create a simple straight line between current location and selected station
    List<LatLng> mockRoute = [
      _validateCoordinates(_currentLocation!.latitude, _currentLocation!.longitude),
      _validateCoordinates(_selectedStation!.latitude, _selectedStation!.longitude),
    ];
    
    setState(() {
      _routePoints = mockRoute;
      _estimatedTime = "10 minutes (estimated)";
    });
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      double latitude = lat / 1E5;
      double longitude = lng / 1E5;
      points.add(LatLng(latitude, longitude));
    }
    return points;
  }

  Future<void> _showBusDetails(Map<String, dynamic> bus) async {
    setState(() {
      _selectedBus = bus;
    });

    final realtimeProvider = Provider.of<RealtimeProvider>(context, listen: false);
    final driverInfo = await realtimeProvider.getDriverInfoForBus(bus['bus_id']);
    
    // Get bus photo
    String? busPhotoBase64;
    try {
      busPhotoBase64 = await realtimeProvider.getBusPhoto(bus['bus_id']);
    } catch (e) {
      print('Error getting bus photo: $e');
    }
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) {
        // Get the current locale
        final isArabic = Localizations.localeOf(context).languageCode == 'ar';
        
        // Translate strings based on locale
        final busText = isArabic ? 'حافلة' : 'Bus';
        final destinationText = isArabic ? 'الوجهة' : 'Destination';
        final speedText = isArabic ? 'السرعة' : 'Speed';
        final expectedArrivalText = isArabic ? 'وقت الوصول المتوقع' : 'Expected Arrival';
        final driverText = isArabic ? 'السائق' : 'Driver';
        final finalDestinationText = isArabic ? 'الوجهة النهائية' : 'Final Destination';
        final closeText = isArabic ? 'إغلاق' : 'Close';
        
        // Format driver name
        final String driverName = driverInfo != null 
            ? '${driverInfo['first_name']} ${driverInfo['last_name']}'
            : 'Unknown';
        
        // Format bus name
        final String busName = driverInfo != null && driverInfo['bus_name'] != null
            ? driverInfo['bus_name']
            : bus['id'].toString();
        
        // Format speed
        final String speed = '${bus['speed']} km/h';
        
        // Format ETA
        final String eta = '${bus['eta_to_destination']} min';
        
        return AlertDialog(
          title: Text('$busText $busName'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: busPhotoBase64 != null
                      ? Image.memory(
                          base64Decode(busPhotoBase64),
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            print('Error loading image: $error');
                            return Container(
                              height: 150,
                              width: double.infinity,
                              color: Colors.grey[300],
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.directions_bus, size: 50, color: Colors.grey[600]),
                                    const SizedBox(height: 8),
                                    Text(isArabic ? 'لا يمكن تحميل الصورة' : 'Image not available',
                                        style: TextStyle(color: Colors.grey[600])),
                                  ],
                                ),
                              ),
                            );
                          },
                        )
                      : Image.asset(
                          'assets/images/busd.png',
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            print('Error loading image: $error');
                            return Container(
                              height: 150,
                              width: double.infinity,
                              color: Colors.grey[300],
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.directions_bus, size: 50, color: Colors.grey[600]),
                                    const SizedBox(height: 8),
                                    Text(isArabic ? 'لا يمكن تحميل الصورة' : 'Image not available',
                                        style: TextStyle(color: Colors.grey[600])),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 10),
                Text('$destinationText: ${bus['destination']}'),
                Text('$speedText: $speed'),
                Text('$expectedArrivalText: $eta'),
                Text('$driverText: $driverName'),
                Text('$finalDestinationText: ${bus['destination']}'),
                Text(
                  'Speed: ${(_selectedBus!['speed'] ?? 0) * 3.6} km/h',
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Updated: ${_formatTimestamp(_selectedBus!['timestamp'] ?? DateTime.now().toIso8601String())}',
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(closeText),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get real-time bus data
    final realtimeProvider = Provider.of<RealtimeProvider>(context);
    final realBuses = realtimeProvider.activeBuses;
    
    // Get real-time bus data from provider
    
    // Get active buses from the realtime provider
    _activeBuses = realtimeProvider.activeBuses;
    
    // Convert bus data to include LatLng position for map markers
    final buses = _activeBuses.isNotEmpty
        ? _activeBuses.map((bus) {
            return {
              ...bus,
              'position': LatLng(
                bus['latitude'] ?? 0.0,
                bus['longitude'] ?? 0.0,
              ),
            };
          }).toList()
        : []; // Fallback to empty list if no real buses
    
    // Show moving buses if refreshed, else filter by station
    final filteredBuses = _showOnlyMoving
        ? buses.where((bus) => (bus['speed'] ?? 0) > 0).toList()
        : buses.where((bus) {
            return _selectedStationName == null ||
                   bus['destination'] == _selectedStationName;
          }).toList();

    return Scaffold(
      body: Stack(
        children: [
          if (realBuses.isEmpty)
            Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  Localizations.localeOf(context).languageCode == 'ar'
                      ? 'لا توجد حافلات نشطة حالياً'
                      : 'No active buses at the moment',
                  style: const TextStyle(fontSize: 18, color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation != null 
                ? _validateCoordinates(_currentLocation!.latitude, _currentLocation!.longitude)
                : const LatLng(27.87374386370353, -0.28424559734165983),
              initialZoom: 14.0,
              onMapReady: () {
                setState(() {
                  _mapReady = true;
                });
                // center on pre-selected station once map loads
                if (_selectedStation != null) {
                  _mapController.move(_selectedStation!, 14.0);
                } else if (_currentLocation != null) {
                  _mapController.move(_validateCoordinates(_currentLocation!.latitude, _currentLocation!.longitude), 14.0);
                }
              },
            ),
            children: [

              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.bus_app',
              ),
              MarkerLayer(
                markers: [
                  if (_currentLocation != null)
                    Marker(
                      point: _validateCoordinates(_currentLocation!.latitude, _currentLocation!.longitude),
                      width: 40,
                      height: 40,
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: Image.asset(
                          'assets/images/user_location.png',
                          width: 20,
                          height: 20,
                        ),
                      ),
                    ),
                  ..._stations.where((station) => _selectedStationName == null || station['name'] == _selectedStationName).map(
                    (station) => Marker(
                      point: _validateCoordinates(station['lat'], station['lon']),
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () => _updateSelectedStation(station),
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: Image.asset(
                            'assets/images/station_icon.png',
                            width: 20,
                            height: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Show bus markers from real-time data only
                  ...filteredBuses.map(
                    (bus) => Marker(
                      point: bus['position'],
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () => _showBusDetails(bus),
                        child: Image.asset('assets/images/bus_marker.png'),
                      ),
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
              heroTag: 'homePageFAB',
              onPressed: _getUserLocation,
              backgroundColor: Colors.blue,
              child: const Icon(Icons.my_location, color: Colors.white),
            ),
          ),
          Positioned(
            top: 80,
            right: 20,
            child: FloatingActionButton(
              heroTag: 'refreshFAB',
              onPressed: _refreshBuses,
              backgroundColor: Colors.green,
              child: const Icon(Icons.refresh, color: Colors.white),
            ),
          ),
          Positioned(
            top: 20,
            left: 20,
            child: FloatingActionButton(
              heroTag: 'settingsPageFAB',
              onPressed: () {
                try {
                  // Try to get the SettingsProvider from the current context
                  final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
                  
                  // Navigate to SettingsPage with the provider
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChangeNotifierProvider.value(
                        value: settingsProvider,
                        child: const SettingsPage(),
                      ),
                    ),
                  );
                } catch (e) {
                  // If provider is not available, create a new one
                  print("Error accessing SettingsProvider: $e");
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChangeNotifierProvider(
                        create: (context) => SettingsProvider(),
                        child: const SettingsPage(),
                      ),
                    ),
                  );
                }
              },
              backgroundColor: Colors.blue,
              child: const Icon(Icons.settings, color: Colors.white),
            ),
          ),
          Positioned.fill(
            child: DraggableScrollableSheet(
              initialChildSize: 0.25, // show ~2 stations initially
              minChildSize: 0.15,     // height when collapsed
              maxChildSize: 0.6,      // full expand height
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 5,
                        margin: const EdgeInsets.only(top: 8, bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          children: [
                            Text(
                              Localizations.localeOf(context).languageCode == 'ar'
                                  ? 'اختر المحطة'
                                  : 'Select Station',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                            ..._stations.map((station) => Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                  child: ElevatedButton(
                                    onPressed: () => _updateSelectedStation(station),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFCAD7FF),
                                      minimumSize: const Size(double.infinity, 50),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(station['name']),
                                  ),
                                )),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _refreshBuses() {
    setState(() {
      _selectedStationName = null;
      _showOnlyMoving = true;
    });
    _fetchActiveBuses();
  }
  
  // Format timestamp for display
  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp).toLocal();
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes} min ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours} hours ago';
      } else {
        return '${dateTime.day}/${dateTime.month} ${dateTime.hour}:${dateTime.minute}';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

}