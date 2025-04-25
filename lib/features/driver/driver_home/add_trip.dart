import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bus_app/features/driver/driver_home/departure2.dart';
import 'package:bus_app/features/driver/driver_home/destination2.dart';
import 'package:bus_app/features/driver/driver_home/all_trips.dart';

class AddTripPage extends StatefulWidget {
  const AddTripPage({super.key});

  @override
  State<AddTripPage> createState() => _AddTripPageState();
}

class _AddTripPageState extends State<AddTripPage> {
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic>? _departure;
  Map<String, dynamic>? _destination;
  DateTime? _departureDate;
  TimeOfDay? _departureTime;
  DateTime? _arrivalDate;
  TimeOfDay? _arrivalTime;

  Future<void> _selectDepartureDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _departureDate = picked;
      });
    }
  }

  Future<void> _selectDepartureTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _departureTime = picked;
      });
    }
  }

  Future<void> _selectArrivalDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _departureDate ?? DateTime.now(),
      firstDate: _departureDate ?? DateTime.now(),
      lastDate: (_departureDate ?? DateTime.now()).add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _arrivalDate = picked;
      });
    }
  }

  Future<void> _selectArrivalTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _arrivalTime = picked;
      });
    }
  }

  Future<void> _addTrip() async {
    if (!_formKey.currentState!.validate()) return;
    if (_departure == null ||
        _destination == null ||
        _departureDate == null ||
        _departureTime == null ||
        _arrivalDate == null ||
        _arrivalTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final departureDateTime = DateTime(
      _departureDate!.year,
      _departureDate!.month,
      _departureDate!.day,
      _departureTime!.hour,
      _departureTime!.minute,
    );

    final arrivalDateTime = DateTime(
      _arrivalDate!.year,
      _arrivalDate!.month,
      _arrivalDate!.day,
      _arrivalTime!.hour,
      _arrivalTime!.minute,
    );

    if (arrivalDateTime.isBefore(departureDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Arrival time must be after departure time'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Get the driver's bus ID
      final busResponse = await Supabase.instance.client
          .from('buses')
          .select('id')
          .eq('driver_id', user.id)
          .single();

      final busId = busResponse['id'];

      await Supabase.instance.client.from('driver_routes').insert({
        'driver_id': user.id,
        'bus_id': busId,
        'departure': _departure!['name'],
        'departure_latitude': double.parse(_departure!['latitude'].toString()),
        'departure_longitude': double.parse(_departure!['longitude'].toString()),
        'destination': _destination!['name'],
        'destination_latitude': double.parse(_destination!['latitude'].toString()),
        'destination_longitude': double.parse(_destination!['longitude'].toString()),
        'departure_time': departureDateTime.toIso8601String(),
        'arrival_time': arrivalDateTime.toIso8601String(),
        'status': 'pending',
        'start_station': null, // Since we're using custom locations
        'end_station': null, // Since we're using custom locations
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trip added successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back to AllTripsPage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const AllTripsPage(),
        ),
      );

    } catch (e) {
      print('Error adding trip: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding trip: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Trip'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ListTile(
              title: Text(_departure != null ? _departure!['name'] : 'Select Departure'),
              leading: const Icon(Icons.location_on),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final result = await Navigator.push<Map<String, dynamic>>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Departure2Page(),
                  ),
                );
                if (result != null) {
                  setState(() {
                    _departure = result;
                  });
                }
              },
            ),
            const Divider(),
            ListTile(
              title: Text(_destination != null ? _destination!['name'] : 'Select Destination'),
              leading: const Icon(Icons.location_on),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final result = await Navigator.push<Map<String, dynamic>>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Destination2Page(),
                  ),
                );
                if (result != null) {
                  setState(() {
                    _destination = result;
                  });
                }
              },
            ),
            const Divider(),
            ListTile(
              title: Text(
                _departureDate == null
                    ? 'Select Departure Date'
                    : 'Departure Date: ${_departureDate!.day}/${_departureDate!.month}/${_departureDate!.year}',
              ),
              leading: const Icon(Icons.calendar_today),
              onTap: _selectDepartureDate,
            ),
            ListTile(
              title: Text(
                _departureTime == null
                    ? 'Select Departure Time'
                    : 'Departure Time: ${_departureTime!.format(context)}',
              ),
              leading: const Icon(Icons.access_time),
              onTap: _selectDepartureTime,
            ),
            const Divider(),
            ListTile(
              title: Text(
                _arrivalDate == null
                    ? 'Select Arrival Date'
                    : 'Arrival Date: ${_arrivalDate!.day}/${_arrivalDate!.month}/${_arrivalDate!.year}',
              ),
              leading: const Icon(Icons.calendar_today),
              onTap: _selectArrivalDate,
            ),
            ListTile(
              title: Text(
                _arrivalTime == null
                    ? 'Select Arrival Time'
                    : 'Arrival Time: ${_arrivalTime!.format(context)}',
              ),
              leading: const Icon(Icons.access_time),
              onTap: _selectArrivalTime,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _addTrip,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A52C9),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Add Trip'),
            ),
          ],
        ),
      ),
    );
  }
}
