import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'add_information.dart'; 

class BasicInfoPage extends StatefulWidget {
  const BasicInfoPage({Key? key}) : super(key: key);

  @override
  _BasicInfoPageState createState() => _BasicInfoPageState();
}

class _BasicInfoPageState extends State<BasicInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _emailController = TextEditingController();
  Map<String, dynamic> _driverData = {};

  @override
  void initState() {
    super.initState();
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
          _driverData = parsedData;
          
          // Pre-fill text fields with saved data
          if (_driverData.containsKey('first_name')) {
            _firstNameController.text = _driverData['first_name'];
          }
          if (_driverData.containsKey('last_name')) {
            _lastNameController.text = _driverData['last_name'];
          }
          if (_driverData.containsKey('date_of_birth')) {
            _dateOfBirthController.text = _driverData['date_of_birth'];
          }
          if (_driverData.containsKey('email_driver')) {
            _emailController.text = _driverData['email_driver'];
          }
        });
      } catch (e) {
        print('Error loading saved data: $e');
      }
    }
  }
  
  Future<void> _saveData() async {
    // Update driver data with current field values
    _driverData['first_name'] = _firstNameController.text.trim();
    _driverData['last_name'] = _lastNameController.text.trim();
    _driverData['date_of_birth'] = _dateOfBirthController.text.trim();
    _driverData['email_driver'] = _emailController.text.trim();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('driver_data', jsonEncode(_driverData));
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)), 
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _dateOfBirthController.text =
            "${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year.toString()}";
      });
      // Save data when date is selected
      _saveData();
    }
  }

  void _validateAndNavigate(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      if (_firstNameController.text.isEmpty ||
          _lastNameController.text.isEmpty ||
          _dateOfBirthController.text.isEmpty ||
          _emailController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill all fields correctly.'),
            backgroundColor: Colors.red,
          ),
        );
      } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
          .hasMatch(_emailController.text)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid email address.'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        // Save data before navigating
        await _saveData();
        
        // Create driver data object
        final driverData = {
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'date_of_birth': _dateOfBirthController.text.trim(),
          'email_driver': _emailController.text.trim(),
        };
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddInformationPage(driverData: driverData),
          ),
        ).then((value) {
          if (value != null) {
            // Handle data returned from AddInformationPage
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Data returned: $value'),
                backgroundColor: Colors.green,
              ),
            );
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Basic Information', style: TextStyle(color: Colors.white)),
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
          child: Form(
            key: _formKey,
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
                          Icons.person_outline_rounded,
                          size: 48,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Personal Information',
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
                Text(
                  'Your Details',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please provide your personal information',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 24),
                _buildTextField(
                  controller: _firstNameController,
                  label: 'First Name',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your first name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _lastNameController,
                  label: 'Last Name',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your last name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: AbsorbPointer(
                    child: _buildTextField(
                      controller: _dateOfBirthController,
                      label: 'Date of Birth',
                      suffixIcon: Icons.calendar_today_rounded,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select your date of birth';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email address';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(value)) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => _validateAndNavigate(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2A52C9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Continue',
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
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
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
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          suffixIcon: suffixIcon != null
              ? Icon(suffixIcon, color: Colors.white.withOpacity(0.7))
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}