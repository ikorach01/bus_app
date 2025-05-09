import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TripDetailsPage extends StatefulWidget {
  final int tripId;
  final String busId;
  const TripDetailsPage({super.key, required this.tripId, required this.busId});

  @override
  State<TripDetailsPage> createState() => _TripDetailsPageState();
}

class _TripDetailsPageState extends State<TripDetailsPage> {
  Map<String, dynamic>? _trip;
  Map<String, dynamic>? _latestPosition;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchTrip();
    _fetchLatestBusPosition();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchLatestBusPosition());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchTrip() async {
    final response = await Supabase.instance.client
        .from('custom_trips')
        .select()
        .eq('id', widget.tripId)
        .single();
    setState(() {
      _trip = response;
    });
  }

  Future<void> _fetchLatestBusPosition() async {
    final response = await Supabase.instance.client
        .from('bus_positions')
        .select()
        .eq('bus_id', widget.busId)
        .order('timestamp', ascending: false)
        .limit(1)
        .maybeSingle();
    setState(() {
      _latestPosition = response;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trip Details')),
      body: _trip == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  title: Text('From:  ${_trip!['departure']}'),
                  subtitle: Text('To: ${_trip!['destination']}'),
                ),
                ListTile(
                  title: Text('Status: ${_trip!['status']}'),
                ),
                const Divider(),
                Expanded(
                  child: _latestPosition == null
                      ? const Center(child: Text('No driver location yet.'))
                      : FlutterMap(
                          options: MapOptions(
                            initialCenter: LatLng(
                              _latestPosition!['latitude'] ?? 0,
                              _latestPosition!['longitude'] ?? 0,
                            ),
                            initialZoom: 13.0,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.bus_app',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(
                                    _latestPosition!['latitude'] ?? 0,
                                    _latestPosition!['longitude'] ?? 0,
                                  ),
                                  width: 40,
                                  height: 40,
                                  child: const Icon(Icons.location_on, color: Colors.blue, size: 30),
                                ),
                              ],
                            ),
                          ],
                        ),
                ),
              ],
            ),
    );
  }
}
