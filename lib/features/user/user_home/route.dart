import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RoutePage extends StatefulWidget {
  final Map<String, dynamic> trip;
  const RoutePage({Key? key, required this.trip}) : super(key: key);

  @override
  State<RoutePage> createState() => _RoutePageState();
}

class _RoutePageState extends State<RoutePage> {
  final MapController _mapController = MapController();
  Map<String, dynamic>? _busPosition;
  late final StreamSubscription<List<Map<String, dynamic>>> _subscription;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Start streaming bus positions for this trip
    _subscription = Supabase.instance.client
        .from('bus_positions')
        .stream(primaryKey: ['id'])
        .eq('route_id', widget.trip['id'])
        .order('timestamp', ascending: true)
        .execute()
        .listen((positions) {
      if (!mounted) return;
      if (positions.isNotEmpty) {
        final latest = positions.last;
        setState(() {
          _busPosition = latest;
          _isLoading = false;
        });
        final lat = latest['latitude'] as double;
        final lng = latest['longitude'] as double;
        _mapController.move(LatLng(lat, lng), 15.0);
      }
    }, onError: (error) {
      debugPrint('Error streaming positions: $error');
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Tracking'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _busPosition != null
                    ? LatLng(_busPosition!['latitude'], _busPosition!['longitude'])
                    : const LatLng(0, 0),
                initialZoom: 15.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.bus_app',
                ),
                if (widget.trip['departure_latitude'] != null && widget.trip['departure_longitude'] != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(widget.trip['departure_latitude'], widget.trip['departure_longitude']),
                        width: 30,
                        height: 30,
                        child: const Icon(Icons.circle, color: Colors.green, size: 30),
                      ),
                    ],
                  ),
                if (widget.trip['destination_latitude'] != null && widget.trip['destination_longitude'] != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(widget.trip['destination_latitude'], widget.trip['destination_longitude']),
                        width: 30,
                        height: 30,
                        child: const Icon(Icons.circle, color: Colors.red, size: 30),
                      ),
                    ],
                  ),
                if (_busPosition != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(_busPosition!['latitude'], _busPosition!['longitude']),
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.directions_bus, color: Colors.blue, size: 40),
                      ),
                    ],
                  ),
              ],
            ),
    );
  }
}
