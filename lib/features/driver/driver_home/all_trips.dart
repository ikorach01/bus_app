import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bus_app/features/driver/driver_home/add_trip.dart';
import 'package:bus_app/features/driver/driver_home/trips_route.dart'; // Import TripsRoute

class AllTripsPage extends StatefulWidget {
  const AllTripsPage({super.key});

  @override
  State<AllTripsPage> createState() => _AllTripsPageState();
}

class _AllTripsPageState extends State<AllTripsPage> {
  List<Map<String, dynamic>> _trips = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTrips();
  }

  Future<void> _fetchTrips() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final response = await Supabase.instance.client
          .from('driver_routes')
          .select()
          .eq('driver_id', user.id);

      setState(() {
        _trips = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching trips: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching trips: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteTrip(dynamic tripId) async {
    print('Attempting to delete trip with id: $tripId, type: \'${tripId.runtimeType}\'');
    try {
      // Delete the trip and get deleted rows
      final dynamic response = await Supabase.instance.client
          .from('driver_routes')
          .delete()
          .eq('id', tripId)
          .select();
      print('Delete response: $response');
      final List<Map<String, dynamic>> deletedRows =
          List<Map<String, dynamic>>.from(response);
      if (deletedRows.isNotEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trip deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchTrips(); // Refresh the list
      } else {
        print('No trip deleted.');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not delete trip. It may not exist or you lack permission.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('Error deleting trip: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting trip: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Trips'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddTripPage()),
              ).then((_) => _fetchTrips()); // Refresh list after adding a trip
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _trips.isEmpty
              ? const Center(
                  child: Text(
                    'No trips added yet',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView.builder(
                  itemCount: _trips.length,
                  itemBuilder: (context, index) {
                    final trip = _trips[index];
                    final departureTimeStr = trip['departure_time'];
                    final arrivalTimeStr = trip['arrival_time'];
                    DateTime? departureTime;
                    DateTime? arrivalTime;
                    try {
                      if (departureTimeStr != null) {
                        departureTime = DateTime.parse(departureTimeStr);
                      }
                    } catch (_) {}
                    try {
                      if (arrivalTimeStr != null) {
                        arrivalTime = DateTime.parse(arrivalTimeStr);
                      }
                    } catch (_) {}

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.directions_bus),
                        title: Text(
                          '${trip['departure'] ?? 'Unknown'} → ${trip['destination'] ?? 'Unknown'}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Departure: '
                              '${departureTime != null ? departureTime.toLocal().toString().split('.')[0] : 'N/A'}',
                            ),
                            Text(
                              'Arrival: '
                              '${arrivalTime != null ? arrivalTime.toLocal().toString().split('.')[0] : 'N/A'}',
                            ),
                            Text(
                              'Status: '
                              '${(trip['status'] as String?)?.toUpperCase() ?? 'UNKNOWN'}',
                              style: TextStyle(
                                color: trip['status'] == 'pending'
                                    ? Colors.orange
                                    : trip['status'] == 'active'
                                        ? Colors.blue
                                        : trip['status'] == 'completed'
                                            ? Colors.green
                                            : Colors.red,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete),
                              color: Colors.red,
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Trip'),
                                    content: const Text('Are you sure you want to delete this trip?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          _deleteTrip(trip['id']);
                                        },
                                        child: const Text(
                                          'Delete',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TripsRoute(
                                departure: trip['departure'] ?? 'Unknown',
                                arrival: trip['destination'] ?? 'Unknown',
                                departureLatitude: (trip['departure_latitude'] as num?)?.toDouble(),
                                departureLongitude: (trip['departure_longitude'] as num?)?.toDouble(),
                                arrivalLatitude: (trip['destination_latitude'] as num?)?.toDouble(),
                                arrivalLongitude: (trip['destination_longitude'] as num?)?.toDouble(),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
