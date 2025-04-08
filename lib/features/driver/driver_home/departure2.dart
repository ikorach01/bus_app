import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Departure2Page extends StatefulWidget {
  const Departure2Page({Key? key}) : super(key: key);

  @override
  State<Departure2Page> createState() => _Departure2PageState();
}

class _Departure2PageState extends State<Departure2Page> {
  final TextEditingController _cityController = TextEditingController();
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _stations = [];
  List<Map<String, dynamic>> _filteredStations = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _fetchStations();
    _cityController.addListener(_filterStations);
  }
  
  @override
  void dispose() {
    _cityController.removeListener(_filterStations);
    _cityController.dispose();
    super.dispose();
  }
  
  void _filterStations() {
    if (_cityController.text.isEmpty) {
      setState(() {
        _filteredStations = _stations;
      });
    } else {
      setState(() {
        _filteredStations = _stations
            .where((station) => station['name']
                .toString()
                .toLowerCase()
                .contains(_cityController.text.toLowerCase()))
            .toList();
      });
    }
  }
  
  Future<void> _fetchStations() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final response = await _supabase
          .from('stations')
          .select('id, name, latitude, longitude')
          .order('name');
      
      setState(() {
        _stations = List<Map<String, dynamic>>.from(response);
        _filteredStations = _stations;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching stations: $e');
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load stations: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _selectStation(Map<String, dynamic> station) {
    // Return the selected station to the home page
    Navigator.pop(context, station);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Departure',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Container(
                  height: 54,
                  decoration: ShapeDecoration(
                    color: const Color(0xFFEFEFF7),
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(
                        width: 1,
                        color: Color(0xFF666666),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: TextField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      hintText: 'City',
                      hintStyle: TextStyle(
                        color: Color(0xFF666666),
                        fontSize: 14,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredStations.isEmpty
                    ? const Center(child: Text('No stations found'))
                    : ListView.builder(
                        itemCount: _filteredStations.length,
                        itemBuilder: (context, index) {
                          final station = _filteredStations[index];
                          return ListTile(
                            title: Text(station['name']),
                            subtitle: Text('Lat: ${station['latitude']}, Long: ${station['longitude']}'),
                            onTap: () => _selectStation(station),
                          );
                        },
                      ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        height: 34,
        padding: const EdgeInsets.only(bottom: 8),
        child: Center(
          child: Container(
            width: 138,
            height: 5,
            decoration: ShapeDecoration(
              color: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
        ),
      ),
    );
  }
}