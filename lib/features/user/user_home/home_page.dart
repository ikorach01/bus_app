import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'dart:async';
import 'package:bus_app/features/user/settings_page.dart';
import 'package:bus_app/features/user/user_home/all_trips2.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  LocationData? _currentLocation;
  late MapController _mapController;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    Location location = Location();
    try {
      LocationData locationData = await location.getLocation();
      if (!mounted) return;
      setState(() {
        _currentLocation = locationData;
        _mapReady = true;
      });
      
      if (locationData.latitude != null && locationData.longitude != null) {
        _mapController.move(
          LatLng(locationData.latitude!, locationData.longitude!),
          14.0,
        );
      }
    } catch (e) {
      print("Error getting location: $e");
      setState(() {
        _mapReady = true;
      });
    }
  }

  void _openTripsPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AllTrips2Page(
          departure: '',
          destination: '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bus Tracking'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_mapReady)
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
                MarkerLayer(
                  markers: [
                    if (_currentLocation != null)
                      Marker(
                        point: LatLng(
                          _currentLocation!.latitude!,
                          _currentLocation!.longitude!,
                        ),
                        width: 30,
                        height: 30,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.blue,
                          size: 30,
                        ),
                      ),
                  ],
                ),
              ],
            )
          else
            const Center(child: CircularProgressIndicator()),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Find Available Trips',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _openTripsPage,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'View All Trips',
                      style: TextStyle(fontSize: 16),
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