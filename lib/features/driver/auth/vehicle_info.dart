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

      try {
        // First, check if the driver exists
        print('Checking if driver exists with ID: ${user.id}');
        final driverExists = await supabase
            .from('drivers')
            .select('id, vehicle_registration_plate')
            .eq('id', user.id)
            .maybeSingle();
            
        if (driverExists == null) {
          // Driver doesn't exist yet
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please complete your driver registration first.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        
        final vehicleRegistrationPlate = registrationPlateController.text.trim();
        final busName = busNameController.text.trim();
        
        // Prepare bus image if available
        String? busPhotoBase64;
        if (_busImage != null) {
          final bytes = await _busImage!.readAsBytes();
          busPhotoBase64 = base64Encode(bytes);
        }
        
        // Create a transaction-like operation
        // 1. First, update the driver with the vehicle registration plate
        print('Updating driver with vehicle registration plate: $vehicleRegistrationPlate');
        await supabase
            .from('drivers')
            .update({
              'vehicle_registration_plate': vehicleRegistrationPlate,
              'bus_name': busName,
              'bus_photo': busPhotoBase64,
            })
            .eq('id', user.id);
            
        print('Driver updated successfully');
        
        // 2. Then, create or update the bus record
        print('Creating/updating bus record');
        final busData = {
          'vehicle_registration_plate': vehicleRegistrationPlate,
          'bus_name': busName,
          'created_at': DateTime.now().toIso8601String(),
        };
        
        if (busPhotoBase64 != null) {
          busData['bus_photo'] = busPhotoBase64;
        }
        
        // Check if a bus with this registration plate already exists
        final existingBus = await supabase
            .from('buses')
            .select('id')
            .eq('vehicle_registration_plate', vehicleRegistrationPlate)
            .maybeSingle();
            
        String busId;
        if (existingBus != null) {
          // Update existing bus
          print('Updating existing bus with ID: ${existingBus['id']}');
          await supabase
              .from('buses')
              .update(busData)
              .eq('id', existingBus['id']);
          busId = existingBus['id'];
        } else {
          // Insert new bus
          print('Inserting new bus');
          final busResponse = await supabase
              .from('buses')
              .insert(busData)
              .select('id')
              .single();
          busId = busResponse['id'];
        }
        
        print('Bus saved with ID: $busId');
        
        // 3. Finally, update the driver with the bus_id
        print('Updating driver with bus_id: $busId');
        await supabase
            .from('drivers')
            .update({'bus_id': busId})
            .eq('id', user.id);
            
        print('Driver updated with bus ID');

        // Save to SharedPreferences for the registration flow
        final prefs = await SharedPreferences.getInstance();
        final driverData = prefs.getString('driver_data');
        Map<String, dynamic> updatedDriverData = {};

        if (driverData != null) {
          updatedDriverData = json.decode(driverData);
        }

        // Update with vehicle information
        updatedDriverData['vehicle_registration_plate'] = vehicleRegistrationPlate;
        updatedDriverData['bus_name'] = busName;
        
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
        } else if (e.toString().contains('violates foreign key constraint')) {
          errorMessage = 'Invalid reference. Please check your data.';
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