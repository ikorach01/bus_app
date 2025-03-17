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
      body: Container(
        width: 412,
        height: 917,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(1.00, -0.01),
            end: Alignment(-0.00, 1.00),
            colors: [Color(0xFF9CB3FA), Color(0xFF2A52CA), Color(0xFF2C54CB), Color(0xFF14212F)],
          ),
        ),
        child: Stack(
          children: [
            // Registration Plate Field
            Positioned(
              left: 16,
              top: 96,
              child: Container(
                width: 379,
                height: 147,
                decoration: ShapeDecoration(
                  color: Color(0xFFEAEEFB),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(width: 1, color: Color(0xFF666666)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Registration Plate',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 24,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 10),
                      TextField(
                        controller: registrationPlateController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Enter registration plate',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bus Name Field
            Positioned(
              left: 16,
              top: 280,
              child: Container(
                width: 379,
                height: 147,
                decoration: ShapeDecoration(
                  color: Color(0xFFEAEEFB),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(width: 1, color: Color(0xFF666666)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bus Name',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 24,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 10),
                      TextField(
                        controller: busNameController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Enter bus name',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Photo of the Bus
            Positioned(
              left: 111,
              top: 498,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Photo of the bus',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 10),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 241,
                      height: 218,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        image: _busImage != null
                            ? DecorationImage(
                                image: FileImage(_busImage!),
                                fit: BoxFit.cover,
                              )
                            : DecorationImage(
                                image: AssetImage(
                                    'assets/images/vehicle.png'),
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Done Button
            Positioned(
              left: 79,
              top: 837,
              child: GestureDetector(
                onTap: _submitVehicleInfo,
                child: Container(
                  width: 254,
                  height: 46,
                  clipBehavior: Clip.antiAlias,
                  decoration: ShapeDecoration(
                    color: Color(0xFF547CF5),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        width: 1,
                        color: Colors.white.withOpacity(0.5),
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Done',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}