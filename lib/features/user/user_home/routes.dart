import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class RoutesPage extends StatefulWidget {
  final String tripId;
  final String departure;
  final String destination;

  const RoutesPage({
    super.key,
    required this.tripId,
    required this.departure,
    required this.destination,
  });

  @override
  State<RoutesPage> createState() => _RoutesPageState();
}

class _RoutesPageState extends State<RoutesPage> {
  late MapController _mapController;
  Map<String, dynamic>? _busPosition;
  List<LatLng> _routePoints = [];
  Timer? _updateTimer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _fetchRouteAndPosition();
    
    // Update bus position every 10 seconds
    _updateTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _fetchBusPosition();
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchRouteAndPosition() async {
    try {
      // Fetch route points
      final routeResponse = await Supabase.instance.client
          .from('route_points')
          .select()
          .eq('trip_id', widget.tripId)
          .order('sequence');

      if (!mounted) return;

      setState(() {
        _routePoints = List<Map<String, dynamic>>.from(routeResponse)
            .map((point) => LatLng(point['latitude'], point['longitude']))
            .toList();
      });

      await _fetchBusPosition();
    } catch (e) {
      print('Error fetching route: $e');
    }
  }

  Future<void> _fetchBusPosition() async {
    try {
      final positionResponse = await Supabase.instance.client
          .from('bus_positions')
          .select()
          .eq('trip_id', widget.tripId)
          .single();

      if (!mounted) return;

      setState(() {
        _busPosition = positionResponse;
        _isLoading = false;
      });

      if (_busPosition != null) {
        _mapController.move(
          LatLng(_busPosition!['latitude'], _busPosition!['longitude']),
          14.0,
        );
      }
    } catch (e) {
      print('Error fetching bus position: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Route'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _busPosition != null
                        ? LatLng(_busPosition!['latitude'], _busPosition!['longitude'])
                        : const LatLng(27.87374386370353, -0.28424559734165983),
                    initialZoom: 13.0,
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
                            color: Colors.blue,
                            strokeWidth: 3.0,
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: [
                        // Departure marker
                        Marker(
                          point: _routePoints.first,
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.green,
                            size: 40,
                          ),
                        ),
                        // Destination marker
                        Marker(
                          point: _routePoints.last,
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                        // Bus marker
                        if (_busPosition != null)
                          Marker(
                            point: LatLng(
                              _busPosition!['latitude'],
                              _busPosition!['longitude'],
                            ),
                            width: 40,
                            height: 40,
                            child: Transform.rotate(
                              angle: (_busPosition!['heading'] ?? 0) * (3.14159 / 180),
                              child: Image.asset('assets/images/busd.png'),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: Colors.green),
                              const SizedBox(width: 8),
                              Text(
                                widget.departure,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: Colors.red),
                              const SizedBox(width: 8),
                              Text(
                                widget.destination,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          if (_busPosition != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.speed, color: Colors.blue),
                                const SizedBox(width: 8),
                                Text(
                                  'Speed: ${_busPosition!['speed']} km/h',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
