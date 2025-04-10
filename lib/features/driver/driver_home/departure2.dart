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
  List<Map<String, dynamic>> _filteredMunicipalities = [];
  bool _isLoading = true;
  bool _showMunicipalitySuggestions = false;
  
  // List of municipalities in Adrar
  final List<Map<String, dynamic>> _municipalities = [
    {
      'name': 'Adrar',
      'coordinates': {'latitude': '27.8742', 'longitude': '-0.2891'},
    },
    {
      'name': 'Reggane',
      'coordinates': {'latitude': '26.7167', 'longitude': '-0.1667'},
    },
    {
      'name': 'Aoulef',
      'coordinates': {'latitude': '26.9667', 'longitude': '1.0833'},
    },
    {
      'name': 'Timimoun',
      'coordinates': {'latitude': '29.2639', 'longitude': '0.2306'},
    },
    {
      'name': 'Zaouiet Kounta',
      'coordinates': {'latitude': '27.2333', 'longitude': '-0.2500'},
    },
    {
      'name': 'Tsabit',
      'coordinates': {'latitude': '28.3500', 'longitude': '-0.2167'},
    },
    {
      'name': 'Charouine',
      'coordinates': {'latitude': '29.0167', 'longitude': '-0.2667'},
    },
    {
      'name': 'Fenoughil',
      'coordinates': {'latitude': '27.7333', 'longitude': '-0.2333'},
    },
  ];
  
  @override
  void initState() {
    super.initState();
    _fetchStations();
    _cityController.addListener(_filterMunicipalities);
  }
  
  @override
  void dispose() {
    _cityController.removeListener(_filterMunicipalities);
    _cityController.dispose();
    super.dispose();
  }
  
  void _filterMunicipalities() {
    if (_cityController.text.isEmpty) {
      setState(() {
        _filteredMunicipalities = [];
        _showMunicipalitySuggestions = false;
      });
    } else {
      setState(() {
        _filteredMunicipalities = _municipalities
            .where((municipality) => municipality['name']
                .toString()
                .toLowerCase()
                .contains(_cityController.text.toLowerCase()))
            .toList();
        _showMunicipalitySuggestions = true;
      });
    }
  }
  
  Future<void> _fetchStations() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      print('Fetching stations from Supabase...');
      
      final response = await _supabase
          .from('stations')
          .select('id, name, latitude, longitude, mairie')
          .order('name');
      
      print('Stations fetched: ${response.length}');
      if (response.isEmpty) {
        print('No stations found in the database');
      } else {
        print('First station: ${response[0]}');
      }
      
      setState(() {
        _stations = List<Map<String, dynamic>>.from(response);
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
  
  void _selectMunicipality(Map<String, dynamic> municipality) {
    // Create a station-like structure from municipality data
    final stationData = {
      'id': null,
      'name': municipality['name'],
      'latitude': municipality['coordinates']['latitude'],
      'longitude': municipality['coordinates']['longitude'],
    };
    
    // Return the municipality data in station format
    Navigator.pop(context, stationData);
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
                      hintText: 'Search municipality (mairie)',
                      hintStyle: TextStyle(
                        color: Color(0xFF666666),
                        fontSize: 14,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.search, color: Color(0xFF666666)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          
          // Municipality suggestions
          if (_showMunicipalitySuggestions && _filteredMunicipalities.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _filteredMunicipalities.length,
                itemBuilder: (context, index) {
                  final municipality = _filteredMunicipalities[index];
                  return ListTile(
                    leading: const Icon(Icons.location_city, color: Color(0xFF2A52C9)),
                    title: Text(municipality['name']),
                    onTap: () => _selectMunicipality(municipality),
                  );
                },
              ),
            ),
          
          const SizedBox(height: 16),
          
          // Stations section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'All Stations',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF14202E),
                  ),
                ),
                Text(
                  '${_stations.length} stations',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF2A52C9)))
                : _stations.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No stations found in database.',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF666666),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Please add stations to the stations table.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF666666),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 2.0,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: _stations.length,
                          itemBuilder: (context, index) {
                            final station = _stations[index];
                            return GestureDetector(
                              onTap: () => _selectStation(station),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFF9CB3F9)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.directions_bus,
                                      color: Color(0xFF2A52C9),
                                      size: 24,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      station['name'] ?? 'Unknown',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (station['mairie'] != null)
                                      Text(
                                        station['mairie'],
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
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