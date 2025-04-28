import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // لإضافة القدرة على التقاط الصور
import 'dart:io'; // للتعامل مع الملفات
import 'add_information.dart'; // استيراد الصفحة التالية
import 'package:supabase_flutter/supabase_flutter.dart'; // استيراد مكتبة Supabase
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

final supabase = Supabase.instance.client;

class DriverLicense2Page extends StatefulWidget {
  final Map<String, dynamic>? driverData;
  
  const DriverLicense2Page({Key? key, this.driverData}) : super(key: key);

  @override
  _DriverLicense2PageState createState() => _DriverLicense2PageState();
}

class _DriverLicense2PageState extends State<DriverLicense2Page> {
  final TextEditingController _greyCardNumberController = TextEditingController();
  final TextEditingController _expirationDateController = TextEditingController();
  File? _greyCardFrontImage;
  File? _greyCardBackImage;
  Map<String, dynamic> _driverData = {};

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.driverData != null) {
      _driverData = Map.from(widget.driverData!);
      
      // Pre-fill fields if data exists
      if (_driverData.containsKey('grey_card_number')) {
        _greyCardNumberController.text = _driverData['grey_card_number'];
      }
      if (_driverData.containsKey('grey_card_expiration')) {
        _expirationDateController.text = _driverData['grey_card_expiration'];
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
          if (_driverData.containsKey('grey_card_number')) {
            _greyCardNumberController.text = _driverData['grey_card_number'];
          }
          if (_driverData.containsKey('grey_card_expiration')) {
            _expirationDateController.text = _driverData['grey_card_expiration'];
          }
        });
      } catch (e) {
        print('Error loading saved data: $e');
      }
    }
  }

  Future<void> _saveData() async {
    // Update driver data with current field values
    _driverData['grey_card_number'] = _greyCardNumberController.text.trim();
    _driverData['grey_card_expiration'] = _expirationDateController.text.trim();
    
    final prefs = await SharedPreferences.getInstance();
    
    // We need to handle binary data for SharedPreferences
    // Create a copy of the data without binary fields
    final Map<String, dynamic> dataToSave = Map.from(_driverData);
    
    // Remove binary data as it can't be stored in SharedPreferences
    dataToSave.remove('grey_card_image_front');
    dataToSave.remove('grey_card_image_back');
    dataToSave.remove('license_image_front');
    dataToSave.remove('license_image_back');
    
    await prefs.setString('driver_data', jsonEncode(dataToSave));
  }

  Future<void> _pickGreyCardFrontImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _greyCardFrontImage = File(image.path);
      });
      
      // Convert image to base64 and store in driverData
      final bytes = await _greyCardFrontImage!.readAsBytes();
      final base64Image = base64Encode(bytes);
      _driverData['grey_card_image_front'] = base64Image;
      
      // Save data after picking image
      _saveData();
    }
  }

  Future<void> _pickGreyCardBackImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _greyCardBackImage = File(image.path);
      });
      
      // Convert image to base64 and store in driverData
      final bytes = await _greyCardBackImage!.readAsBytes();
      final base64Image = base64Encode(bytes);
      _driverData['grey_card_image_back'] = base64Image;
      
      // Save data after picking image
      _saveData();
    }
  }

  void _navigateToNextPage(BuildContext context) async {
    if (_greyCardNumberController.text.isEmpty ||
        _expirationDateController.text.isEmpty ||
        _greyCardFrontImage == null ||
        _greyCardBackImage == null) {
      
      // Create a specific error message based on what's missing
      String errorMessage = 'Please complete the following:';
      
      if (_greyCardNumberController.text.isEmpty) {
        errorMessage += '\n• Grey card number is required';
      }
      
      if (_expirationDateController.text.isEmpty) {
        errorMessage += '\n• Expiration date is required';
      }
      
      if (_greyCardFrontImage == null) {
        errorMessage += '\n• Front image of grey card is required';
      }
      
      if (_greyCardBackImage == null) {
        errorMessage += '\n• Back image of grey card is required';
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
    } else {
      try {
        // Validate date format
        if (!_isValidDateFormat(_expirationDateController.text)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter a valid date in MM/DD/YYYY format.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
          return;
        }
        
        // Update driver data
        _driverData['grey_card_number'] = _greyCardNumberController.text.trim();
        _driverData['grey_card_expiration'] = _expirationDateController.text.trim();
        
        // Save data before navigating
        await _saveData();
        
        // Navigate to the next page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddInformationPage(driverData: _driverData),
          ),
        );
      } catch (e) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
  
  // Helper method to validate date format (MM/DD/YYYY)
  bool _isValidDateFormat(String dateStr) {
    // Check basic format with regex
    if (!RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(dateStr)) {
      return false;
    }
    
    // Parse the date to ensure it's valid
    try {
      final parts = dateStr.split('/');
      final month = int.parse(parts[0]);
      final day = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      
      // Basic validation
      if (month < 1 || month > 12) return false;
      if (day < 1 || day > 31) return false;
      if (year < 2000 || year > 2100) return false;
      
      // More precise validation for days in month
      if (month == 2) {
        // February
        final isLeapYear = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
        if (day > (isLeapYear ? 29 : 28)) return false;
      } else if ([4, 6, 9, 11].contains(month)) {
        // April, June, September, November have 30 days
        if (day > 30) return false;
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grey Card', style: TextStyle(color: Colors.white)),
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
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.article_rounded,
                        size: 48,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Grey Card Details',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              _buildTextField(
                controller: _greyCardNumberController,
                label: 'Grey Card Number',
                icon: Icons.credit_card_outlined,
              ),
              const SizedBox(height: 24),
              _buildDateField(context),
              const SizedBox(height: 32),
              Text(
                'Upload Grey Card Photos',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildImageUploadCard(
                      title: 'Front Side',
                      image: _greyCardFrontImage,
                      onTap: _pickGreyCardFrontImage,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildImageUploadCard(
                      title: 'Back Side',
                      image: _greyCardBackImage,
                      onTap: _pickGreyCardBackImage,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => _navigateToNextPage(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A52C9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Done',
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
          prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.7)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildDateField(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _expirationDateController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: 'Expiration Date (MM/DD/YYYY)',
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          prefixIcon: Icon(Icons.calendar_today_rounded, color: Colors.white.withOpacity(0.7)),
          border: InputBorder.none,
          hintText: 'MM/DD/YYYY',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
        ),
        keyboardType: TextInputType.datetime,
        onChanged: (value) {
          // Auto-format as MM/DD/YYYY
          if (value.length == 2 && !value.contains('/')) {
            _expirationDateController.text = '$value/';
            _expirationDateController.selection = TextSelection.fromPosition(
              TextPosition(offset: _expirationDateController.text.length),
            );
          } else if (value.length == 5 && value.contains('/') && !value.endsWith('/')) {
            _expirationDateController.text = '$value/';
            _expirationDateController.selection = TextSelection.fromPosition(
              TextPosition(offset: _expirationDateController.text.length),
            );
          }
        },
      ),
    );
  }

  Widget _buildImageUploadCard({
    required String title,
    required File? image,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: image != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  image,
                  fit: BoxFit.cover,
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo_rounded,
                    size: 40,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to upload',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}