import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'basic_info.dart';
import 'driver_licence.dart';
import 'vehicle_info.dart';
import '../driver_home/home_page2.dart';

final supabase = Supabase.instance.client;

class AddInformationPage extends StatefulWidget {
  final Map<String, dynamic>? driverData;
  
  const AddInformationPage({Key? key, this.driverData}) : super(key: key);

  @override
  _AddInformationPageState createState() => _AddInformationPageState();
}

class _AddInformationPageState extends State<AddInformationPage> {
  bool isLoading = false;
  Map<String, dynamic> _driverData = {};
  
  @override
  void initState() {
    super.initState();
    if (widget.driverData != null) {
      setState(() {
        _driverData = Map.from(widget.driverData!);
      });
    }
    _loadSavedData();
  }
  
  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString('driver_data');
    
    if (savedData != null && savedData.isNotEmpty) {
      try {
        final Map<String, dynamic> parsedData = jsonDecode(savedData);
        setState(() {
          _driverData.addAll(parsedData);
        });
      } catch (e) {
        debugPrint('Error loading saved data: $e');
      }
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('driver_data', jsonEncode(_driverData));
  }

  Future<void> _submitInformation() async {
    if (!_validateDriverData()) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // 1. Check if a bus with this plate already exists
      try {
        final existingBus = await supabase
            .from('buses')
            .select('id, driver_id')
            .eq('vehicle_registration_plate', _driverData['vehicle_registration_plate'])
            .maybeSingle();

        // If bus exists and belongs to another driver
        if (existingBus != null && existingBus['driver_id'] != null && existingBus['driver_id'] != user.id) {
          Navigator.pop(context); // Close loading dialog
          _showErrorMessage('This vehicle registration plate is already registered by another driver');
          return;
        }
      } catch (e) {
        debugPrint('Error checking existing bus: $e');
        // Continue with registration process as the error might be due to non-existing record
      }

      // 2. Create driver entry with retry mechanism
      final driverData = {
        'id': user.id,
        'user_id': user.id,
        'first_name': _driverData['first_name'],
        'last_name': _driverData['last_name'],
        'date_of_birth': _formatDate(_driverData['date_of_birth']),
        'license_number': _driverData['license_number'],
        'license_image_front': _driverData['license_image_front'],
        'license_image_back': _driverData['license_image_back'],
        'license_expiration': _formatDate(_driverData['license_expiration']),
        'grey_card_number': _driverData['grey_card_number'],
        'grey_card_image_front': _driverData['grey_card_image_front'],
        'grey_card_image_back': _driverData['grey_card_image_back'],
        'grey_card_expiration': _formatDate(_driverData['grey_card_expiration']),
        'vehicle_registration_plate': _driverData['vehicle_registration_plate'],
        'email_driver': _driverData['email_driver'],
        'created_at': DateTime.now().toIso8601String(),
      };

      await _retryOperation(() => supabase
          .from('drivers')
          .upsert(driverData, onConflict: 'id')
          .select()
          .maybeSingle());

      // 3. Create bus with driver_id, with retry mechanism
      final busData = {
        'bus_name': _driverData['bus_name'],
        'vehicle_registration_plate': _driverData['vehicle_registration_plate'],
        'bus_photo': _driverData['bus_photo'],
        'driver_id': user.id,
      };

      final busResponse = await _retryOperation(() => supabase
          .from('buses')
          .upsert(busData, onConflict: 'vehicle_registration_plate')
          .select()
          .maybeSingle());

      if (busResponse == null) {
        throw Exception('Failed to create bus record');
      }

      // 4. Update driver with bus_id, with retry mechanism
      await _retryOperation(() => supabase
          .from('drivers')
          .update({'bus_id': busResponse['id']})
          .eq('id', user.id));

      // 5. Set user role in metadata and SharedPreferences
      await _retryOperation(() => supabase.auth.updateUser(UserAttributes(
            data: {'role': 'driver'},
          )));

      // Save role in SharedPreferences for faster app startup
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_role', 'driver');
      
      // Clear saved form data
      await prefs.remove('driver_data');

      Navigator.pop(context); // Close loading dialog
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage2()),
      );
    } catch (e) {
      debugPrint('Registration error: $e');
      Navigator.pop(context); // Close loading dialog
      _showErrorMessage('Registration failed: ${e.toString()}');
    }
  }

  String _formatDate(dynamic dateInput) {
    if (dateInput == null) return '';
    if (dateInput is DateTime) return dateInput.toIso8601String();
    
    final dateStr = dateInput.toString();
    if (dateStr.contains('/')) {
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        return '${parts[2]}-${parts[0].padLeft(2, '0')}-${parts[1].padLeft(2, '0')}';
      }
    }
    return dateStr;
  }

  bool _validateDriverData() {
    final requiredFields = [
      'first_name', 'last_name', 'date_of_birth',
      'license_number', 'license_image_front', 'license_image_back', 'license_expiration',
      'grey_card_number', 'grey_card_image_front', 'grey_card_image_back', 'grey_card_expiration',
      'vehicle_registration_plate', 'bus_photo', 'email_driver', 'bus_name'
    ];
    
    for (final field in requiredFields) {
      if (_driverData[field] == null || _driverData[field].toString().isEmpty) {
        _showErrorMessage('Missing required field: ${field.replaceAll('_', ' ')}');
        return false;
      }
    }
    return true;
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 8),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }
  
  // Retry operation with exponential backoff
  Future<T?> _retryOperation<T>(Future<T> Function() operation, {int maxRetries = 3}) async {
    int retryCount = 0;
    int waitTime = 1000; // Start with 1 second
    
    while (retryCount < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        retryCount++;
        if (retryCount >= maxRetries) rethrow;
        
        // Exponential backoff with jitter
        final jitter = (waitTime * 0.2 * (DateTime.now().millisecondsSinceEpoch % 10) / 10).toInt();
        final waitTimeWithJitter = waitTime + jitter;
        
        debugPrint('Operation failed (attempt $retryCount): $e. Retrying in ${waitTimeWithJitter}ms...');
        await Future.delayed(Duration(milliseconds: waitTimeWithJitter));
        
        // Double the wait time for next retry
        waitTime *= 2;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register as a Driver', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF9CB3F9),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF9CB3F9), Color(0xFF2A52C9), Color(0xFF14202E)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 32),
              Center(
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: const DecorationImage(
                      image: AssetImage("assets/images/busd.png"),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Complete Your Profile',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please fill in all required information',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 32),
              _buildInfoButton(
                icon: Icons.person_outline_rounded,
                label: 'Basic Information',
                description: 'Name, phone, and contact details',
                onPressed: () {
                  _saveData();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => BasicInfoPage()),
                  ).then((_) => setState(() {}));
                },
              ),
              const SizedBox(height: 16),
              _buildInfoButton(
                icon: Icons.badge_outlined,
                label: 'Driver License',
                description: 'License details and verification',
                onPressed: () {
                  _saveData();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DriverLicensePage(driverData: _driverData),
                    ),
                  ).then((_) => setState(() {}));
                },
              ),
              const SizedBox(height: 16),
              _buildInfoButton(
                icon: Icons.directions_car_outlined,
                label: 'Vehicle Information',
                description: 'Car details and documentation',
                onPressed: () {
                  _saveData();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VehicleInfoPage(driverData: _driverData),
                    ),
                  ).then((_) => setState(() {}));
                },
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submitInformation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A52C9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Complete Registration',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoButton({
    required IconData icon,
    required String label,
    required String description,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF2A52C9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withOpacity(0.6),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}