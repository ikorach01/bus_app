import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // For image picking
import 'dart:io'; // For handling file paths
import 'package:supabase_flutter/supabase_flutter.dart'; // For Supabase integration
import 'add_information.dart'; // Import the AddInformationPage
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

final supabase = Supabase.instance.client;

class VehicleInfoPage extends StatefulWidget {
  final Map<String, dynamic>? driverData;
  
  const VehicleInfoPage({super.key, this.driverData});

  @override
  State<VehicleInfoPage> createState() => _VehicleInfoPageState();
}

class _VehicleInfoPageState extends State<VehicleInfoPage> {
  final TextEditingController registrationPlateController = TextEditingController();
  final TextEditingController busNameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _busImage;
  Map<String, dynamic> _driverData = {};

  @override
  void initState() {
    super.initState();
    if (widget.driverData != null) {
      _driverData = Map.from(widget.driverData!);
      
      // Pre-fill fields if data exists
      if (_driverData.containsKey('vehicle_registration_plate')) {
        registrationPlateController.text = _driverData['vehicle_registration_plate'];
      }
      if (_driverData.containsKey('bus_name')) {
        busNameController.text = _driverData['bus_name'];
      }
    }
    
    // Load any saved data from SharedPreferences
    _loadSavedData();
  }
  
  @override
  void dispose() {
    // Save data when the page is disposed
    _saveData();
    super.dispose();
  }
  
  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString('driver_data');
    
    if (savedData != null && savedData.isNotEmpty) {
      try {
        final Map<String, dynamic> parsedData = jsonDecode(savedData);
        setState(() {
          // Merge saved data with current data
          _driverData.addAll(parsedData);
          
          // Pre-fill text fields with saved data
          if (_driverData.containsKey('vehicle_registration_plate')) {
            registrationPlateController.text = _driverData['vehicle_registration_plate'];
          }
          if (_driverData.containsKey('bus_name')) {
            busNameController.text = _driverData['bus_name'];
          }
        });
      } catch (e) {
        print('Error loading saved data: $e');
      }
    }
  }
  
  Future<void> _saveData() async {
    // Update driver data with current field values
    _driverData['vehicle_registration_plate'] = registrationPlateController.text.trim();
    _driverData['bus_name'] = busNameController.text.trim();
    
    final prefs = await SharedPreferences.getInstance();
    
    // We need to handle binary data for SharedPreferences
    // Create a copy of the data without binary fields
    final Map<String, dynamic> dataToSave = Map.from(_driverData);
    
    // Remove binary data as it can't be stored in SharedPreferences
    dataToSave.remove('bus_photo');
    dataToSave.remove('grey_card_image_front');
    dataToSave.remove('grey_card_image_back');
    dataToSave.remove('license_image_front');
    dataToSave.remove('license_image_back');
    
    await prefs.setString('driver_data', jsonEncode(dataToSave));
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _busImage = File(image.path);
      });
      
      // Read the image as bytes and store in driverData
      final bytes = await _busImage!.readAsBytes();
      // Store as bus_photo to match database field name
      _driverData['bus_photo'] = bytes;
      
      // Save data after picking image
      _saveData();
    }
  }

  bool _validateInputs() {
    // Create a specific error message based on what's missing
    List<String> missingFields = [];
    
    if (registrationPlateController.text.trim().isEmpty) {
      missingFields.add('Registration plate number');
    }
    
    if (busNameController.text.trim().isEmpty) {
      missingFields.add('Bus name');
    }
    
    if (_busImage == null) {
      missingFields.add('Bus image');
    }
    
    if (missingFields.isNotEmpty) {
      String errorMessage = 'Please complete the following:';
      for (var field in missingFields) {
        errorMessage += '\n• $field is required';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
      return false;
    }
    
    return true;
  }

  Future<void> _submitVehicleInfo() async {
    if (!_validateInputs()) return;

    try {
      // Update driver data
      _driverData['vehicle_registration_plate'] = registrationPlateController.text.trim();
      _driverData['bus_name'] = busNameController.text.trim();
      
      // Save data before navigating
      await _saveData();
      
      // Navigate back to AddInformationPage with updated data
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddInformationPage(driverData: _driverData),
        ),
      );
    } catch (e) {
      // Determine the specific error
      String errorMessage = 'An error occurred while saving vehicle information.';
      
      if (e.toString().contains('network')) {
        errorMessage = 'Network error. Please check your internet connection.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$errorMessage\n\nDetails: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Information', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF9CB3F9),
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-0.20, -0.98),
            end: Alignment(0.2, 0.98),
            colors: [Color(0xFF9CB3F9), Color(0xFF2A52C9), Color(0xFF14202E)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 200,
                    height: 160,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: _busImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(
                              _busImage!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo_outlined,
                                color: Colors.white.withOpacity(0.7),
                                size: 48,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Upload Bus Photo',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Vehicle Details',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please provide your vehicle information',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 32),
              _buildTextField(
                controller: registrationPlateController,
                label: 'Registration Plate',
                icon: Icons.credit_card_outlined,
                hint: 'Enter registration plate number',
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: busNameController,
                label: 'Bus Name',
                icon: Icons.directions_bus_outlined,
                hint: 'Enter bus name or model',
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _submitVehicleInfo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A52C9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Save Vehicle Information',
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.7)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}