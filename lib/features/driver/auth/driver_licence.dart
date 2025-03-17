import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // For image picking
import 'dart:io'; // For handling file paths
import 'driver_licence2.dart'; // Import the DriverLicense2Page

class DriverLicensePage extends StatefulWidget {
  const DriverLicensePage({Key? key}) : super(key: key);

  @override
  _DriverLicensePageState createState() => _DriverLicensePageState();
}

class _DriverLicensePageState extends State<DriverLicensePage> {
  final TextEditingController licenseNumberController = TextEditingController();
  final TextEditingController expirationDateController = TextEditingController();

  File? _frontImage;
  File? _backImage;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(bool isFront) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        if (isFront) {
          _frontImage = File(image.path);
        } else {
          _backImage = File(image.path);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver License'),
        backgroundColor: const Color(0xFF14212F),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(1.00, -0.00),
            end: Alignment(-0.00, 1.00),
            colors: [Color(0xFF9CB3FA), Color(0xFF2A52CA), Color(0xFF14212F)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Driver License Number Field
              const Text(
                'Driver License Number',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: licenseNumberController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Enter license number',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF2A52CA)),
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                ),
              ),
              const SizedBox(height: 20),

              // Front of Driver's License
              const Text(
                'Front of Driver’s License',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => _pickImage(true),
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                    image: _frontImage != null
                        ? DecorationImage(
                            image: FileImage(_frontImage!),
                            fit: BoxFit.cover,
                          )
                        : const DecorationImage(
                            image: AssetImage('assets/images/photograph1.png'),
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Back of Driver's License
              const Text(
                'Back of Driver’s License',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => _pickImage(false),
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                    image: _backImage != null
                        ? DecorationImage(
                            image: FileImage(_backImage!),
                            fit: BoxFit.cover,
                          )
                        : const DecorationImage(
                            image: AssetImage('assets/images/photograph1.png'),
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Date of Expiration Field
              const Text(
                'Date of Expiration',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: expirationDateController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'MM/DD/YYYY',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF2A52CA)),
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                ),
              ),
              const SizedBox(height: 30),

              // Next Button
              ElevatedButton(
                onPressed: () {
                  // Navigate to DriverLicense2Page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DriverLicense2Page(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: const Color(0xFF2A52CA),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Next',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}