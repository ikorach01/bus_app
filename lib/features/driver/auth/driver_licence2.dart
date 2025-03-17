import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // For image picking
import 'dart:io'; // For handling file paths
import 'package:supabase_flutter/supabase_flutter.dart'; // For Supabase integration
import 'add_information.dart'; // Import the AddInformationPage

final supabase = Supabase.instance.client;

class DriverLicense2Page extends StatefulWidget {
  const DriverLicense2Page({Key? key}) : super(key: key);
  @override
  State<DriverLicense2Page> createState() => _DriverLicense2PageState();
}

class _DriverLicense2PageState extends State<DriverLicense2Page> {
  final TextEditingController greyCardNumberController = TextEditingController();
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

  bool _validateInputs() {
    if (greyCardNumberController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the grey card number.'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    if (_frontImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload the front of the grey card.'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    if (_backImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload the back of the grey card.'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    if (expirationDateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the expiration date.'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    return true;
  }

  Future<void> _submitGreyCardInfo() async {
    if (!_validateInputs()) return;

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in.');
      }

      final response = await supabase.from('grey_cards').insert({
        'user_id': user.id,
        'grey_card_number': greyCardNumberController.text.trim(),
        'front_image_path': _frontImage?.path,
        'back_image_path': _backImage?.path,
        'expiration_date': expirationDateController.text.trim(),
      });

      if (response.error != null) {
        throw Exception(response.error!.message);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Grey card information submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const AddInformationPage(),
        ),
      );
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
        title: const Text('Driver License'),
        backgroundColor: const Color(0xFF14212F),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
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
              const Text(
                'Grey Card Number',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: greyCardNumberController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Enter grey card number',
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

              const Text(
                'Front of Grey Card',
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

              const Text(
                'Back of Grey Card',
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

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitGreyCardInfo,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: const Color(0xFF2A52CA),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}