import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      _driverData['bus_photo'] = bytes;
      
      // Save data after picking image
      _saveData();
    }
  }

  Future<void> _submitVehicleInfo() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        );
      },
    );

    try {
      // Get current user
      final user = supabase.auth.currentUser;
      if (user == null) {
        // Close loading dialog
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must be logged in to submit vehicle information.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      print('Current user ID: ${user.id}');

      // Validate required fields
      if (registrationPlateController.text.trim().isEmpty) {
        // Close loading dialog
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter the vehicle registration plate.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (busNameController.text.trim().isEmpty) {
        // Close loading dialog
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter the bus name.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Prepare data for saving
      final vehicleData = {
        'vehicle_registration_plate': registrationPlateController.text.trim(),
        'bus_name': busNameController.text.trim(),
      };

      // Add bus photo if available
      if (_busImage != null) {
        // Convert image bytes to base64 string for storage
        final bytes = await _busImage!.readAsBytes();
        final base64Image = base64Encode(bytes);
        vehicleData['bus_photo'] = base64Image;
      }

      try {
        // First, create a bus record
        final busData = {
          'vehicle_registration_plate': registrationPlateController.text.trim(),
          'bus_name': busNameController.text.trim(),
          'created_at': DateTime.now().toIso8601String(),
        };

        if (_busImage != null) {
          final bytes = await _busImage!.readAsBytes();
          busData['bus_photo'] = base64Encode(bytes);
        }

        print('Inserting bus data: ${registrationPlateController.text.trim()}');
        
        // Insert into buses table and get the ID
        final busResponse = await supabase
            .from('buses')
            .insert(busData)
            .select('id')
            .single();
            
        print('Bus inserted with ID: ${busResponse['id']}');

        // Then update the driver record with the bus information
        final driverUpdateData = {
          'vehicle_registration_plate': registrationPlateController.text.trim(),
          'bus_name': busNameController.text.trim(),
          'bus_id': busResponse['id'],
        };

        if (_busImage != null) {
          final bytes = await _busImage!.readAsBytes();
          driverUpdateData['bus_photo'] = base64Encode(bytes);
        }

        print('Updating driver record for user: ${user.id}');
        
        // Update the driver record
        await supabase
            .from('drivers')
            .update(driverUpdateData)
            .eq('id', user.id);
            
        print('Driver record updated successfully');

        // Save to SharedPreferences for the registration flow
        final prefs = await SharedPreferences.getInstance();
        final driverData = prefs.getString('driver_data');
        Map<String, dynamic> updatedDriverData = {};

        if (driverData != null) {
          updatedDriverData = json.decode(driverData);
        }

        // Update with vehicle information
        updatedDriverData['vehicle_registration_plate'] = registrationPlateController.text.trim();
        updatedDriverData['bus_name'] = busNameController.text.trim();
        
        if (_busImage != null) {
          final bytes = await _busImage!.readAsBytes();
          updatedDriverData['bus_photo'] = bytes;
        }

        // Save back to SharedPreferences
        await prefs.setString('driver_data', json.encode(updatedDriverData));

        // Close loading dialog
        Navigator.pop(context);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vehicle information saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to the next screen or back
        Navigator.pop(context, true);
      } catch (e) {
        print('Error saving vehicle information: $e');
        
        // Close loading dialog
        Navigator.pop(context);
        
        // Show error message with details
        String errorMessage = 'Failed to save vehicle information.';
        
        if (e.toString().contains('duplicate key')) {
          errorMessage = 'A vehicle with this registration plate already exists.';
        } else if (e.toString().contains('permission denied')) {
          errorMessage = 'You do not have permission to save vehicle information. Please check your authentication.';
        } else if (e.toString().contains('violates row-level security policy')) {
          errorMessage = 'Security policy violation. Please contact support.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$errorMessage\n\nDetails: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 10),
          ),
        );
      }
    } catch (e) {
      print('General error: $e');
      
      // Close loading dialog
      Navigator.pop(context);
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 10),
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