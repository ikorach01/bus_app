import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // For image picking
import 'dart:io'; // For handling file paths
import 'package:supabase_flutter/supabase_flutter.dart'; // For Supabase integration

final supabase = Supabase.instance.client;

class VehicleInfoPage extends StatefulWidget {
  const VehicleInfoPage({super.key});

  @override
  State<VehicleInfoPage> createState() => _VehicleInfoPageState();
}

class _VehicleInfoPageState extends State<VehicleInfoPage> {
  final TextEditingController registrationPlateController = TextEditingController();
  final TextEditingController busNameController = TextEditingController();

  File? _busImage;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _busImage = File(image.path);
      });
    }
  }

  bool _validateInputs() {
    if (registrationPlateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the registration plate.'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    if (busNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the bus name.'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    if (_busImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload a photo of the bus.'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    return true;
  }

  Future<void> _submitVehicleInfo() async {
    if (!_validateInputs()) return;

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in.');
      }

      // Insert data into the `buses` table
      final response = await supabase.from('buses').insert({
        'user_id': user.id,
        'registration_plate': registrationPlateController.text.trim(),
        'bus_name': busNameController.text.trim(),
        'bus_image_path': _busImage?.path,
      });

      if (response.error != null) {
        throw Exception(response.error!.message);
      }

      // Show success message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vehicle information submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to the next page (if needed)
      // Navigator.pushReplacement(...);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
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
                hint: 'Enter bus name or number',
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
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.7)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF2A52C9), width: 2),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      ),
    );
  }
}