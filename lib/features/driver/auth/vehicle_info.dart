import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'add_information.dart';
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
      if (_driverData['vehicle_registration_plate'] != null) {
        registrationPlateController.text = _driverData['vehicle_registration_plate'];
      }
      if (_driverData['bus_name'] != null) {
        busNameController.text = _driverData['bus_name'];
      }
    }
    _loadSavedData();
  }
  
  @override
  void dispose() {
    _saveData();
    super.dispose();
  }
  
  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString('driver_data');
    
    if (savedData != null) {
      try {
        setState(() {
          _driverData.addAll(jsonDecode(savedData));
          if (_driverData['vehicle_registration_plate'] != null) {
            registrationPlateController.text = _driverData['vehicle_registration_plate'];
          }
          if (_driverData['bus_name'] != null) {
            busNameController.text = _driverData['bus_name'];
          }
        });
      } catch (e) {
        debugPrint('Error loading saved data: $e');
      }
    }
  }
  
  Future<void> _saveData() async {
    _driverData['vehicle_registration_plate'] = registrationPlateController.text.trim();
    _driverData['bus_name'] = busNameController.text.trim();
    
    final prefs = await SharedPreferences.getInstance();
    final dataToSave = Map.from(_driverData);
    
    // Remove binary data that can't be stored in SharedPreferences
    dataToSave.removeWhere((key, value) => value is Uint8List || value is List<int>);
    
    await prefs.setString('driver_data', jsonEncode(dataToSave));
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _busImage = File(image.path));
      final bytes = await _busImage!.readAsBytes();
      _driverData['bus_photo'] = bytes;
      await _saveData();
    }
  }

  Uint8List? _getImageBytes() {
    final dynamic data = _driverData['bus_photo'];
    
    if (data == null) return null;
    if (data is Uint8List) return data;
    if (data is List<int>) return Uint8List.fromList(data);
    if (data is List<dynamic>) return Uint8List.fromList(data.cast<int>());
    
    return null;
  }

  bool _validateInputs() {
    if (registrationPlateController.text.trim().isEmpty) {
      _showErrorMessage('Registration plate number is required');
      return false;
    }
    if (busNameController.text.trim().isEmpty) {
      _showErrorMessage('Bus name is required');
      return false;
    }
    if (_busImage == null && _getImageBytes() == null) {
      _showErrorMessage('Bus image is required');
      return false;
    }
    return true;
  }

  Future<void> _submitVehicleInfo() async {
    if (!_validateInputs()) return;

    try {
      _driverData['vehicle_registration_plate'] = registrationPlateController.text.trim();
      _driverData['bus_name'] = busNameController.text.trim();
      
      if (_busImage != null) {
        final bytes = await _busImage!.readAsBytes();
        _driverData['bus_photo'] = bytes;
      }
      
      await _saveData();
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddInformationPage(driverData: _driverData),
        ),
      );
    } catch (e) {
      _showErrorMessage('Error saving vehicle information: ${e.toString()}');
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'OK',
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageBytes = _getImageBytes();
    
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
                    child: _busImage != null || imageBytes != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: _busImage != null
                                ? Image.file(_busImage!, fit: BoxFit.cover)
                                : Image.memory(
                                    imageBytes!,
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