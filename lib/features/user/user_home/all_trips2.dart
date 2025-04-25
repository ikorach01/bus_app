import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:bus_app/features/user/user_home/route.dart';

class AllTrips2Page extends StatefulWidget {
  final String departure;
  final String destination;

  const AllTrips2Page({
    super.key,
    required this.departure,
    required this.destination,
  });

  @override
  State<AllTrips2Page> createState() => _AllTrips2PageState();
}

class _AllTrips2PageState extends State<AllTrips2Page> {
  List<Map<String, dynamic>> _trips = [];
  bool _isLoading = true;
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _fetchTrips();
    // Update trips every 10 seconds
    _updateTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _fetchTrips();
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchTrips() async {
    try {
      final response = await Supabase.instance.client
          .from('driver_routes')
          .select('''
            *,
            drivers (
              first_name,
              last_name
            ),
            bus_positions (
              latitude,
              longitude,
              speed,
              timestamp
            )
          ''');

      if (!mounted) return;

      setState(() {
        _trips = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
      // Debug: log fetched trips
      print('Fetched trips (${_trips.length}): $_trips');
    } catch (e) {
      print('Error fetching trips: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatTime(String? time) {
    if (time == null) return 'N/A';
    final dateTime = DateTime.parse(time);
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _getTripStatus(Map<String, dynamic> trip) {
    if (trip['status'] == 'completed') return 'Completed';
    if (trip['status'] == 'cancelled') return 'Cancelled';
    
    final busPosition = trip['bus_positions'];
    if (busPosition == null || busPosition.isEmpty) {
      return 'Not Started';
    }
    
    return 'In Progress';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'in progress':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Trips'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _trips.isEmpty
              ? const Center(
                  child: Text(
                    'No trips found for this route',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView.builder(
                  itemCount: _trips.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final trip = _trips[index];
                    final status = _getTripStatus(trip);
                    final statusColor = _getStatusColor(status);
                    final driver = trip['drivers'];
                    final driverName = driver != null
                        ? '${driver['first_name']} ${driver['last_name']}'
                        : 'Unknown Driver';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RoutePage(trip: trip),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${widget.departure} - ${widget.destination}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: statusColor),
                                    ),
                                    child: Text(
                                      status,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Departure time',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        _formatTime(trip['departure_time']),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Arrival time',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        _formatTime(trip['arrival_time']),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.person_outline, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    driverName,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
