import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'basic_info.dart';
import 'driver_licence.dart';
import 'vehicle_info.dart';
import '../driver_home/home_page2.dart';

final supabase = Supabase.instance.client;

class AddInformationPage extends StatefulWidget {
  final Map<String, dynamic>? driverData;
  
  const AddInformationPage({Key? key, this.driverData}) : super(key: key);

  @override
  _AddInformationPageState createState() => _AddInformationPageState();
}

class _AddInformationPageState extends State<AddInformationPage> {
  bool isLoading = false;
  Map<String, dynamic> _driverData = {};
  
  @override
  void initState() {
    super.initState();
    if (widget.driverData != null) {
      setState(() {
        _driverData = Map.from(widget.driverData!);
      });
    }
    
    // Load any saved data from SharedPreferences
    _loadSavedData();
  }
  
  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString('driver_data');
    
    if (savedData != null && savedData.isNotEmpty) {
      try {
        final Map<String, dynamic> parsedData = jsonDecode(savedData);
        setState(() {
          _driverData.addAll(parsedData);
        });
      } catch (e) {
        print('Error loading saved data: $e');
      }
    }
  }
  
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('driver_data', jsonEncode(_driverData));
  }

  Future<void> _submitInformation() async {
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
      // Get the current user
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Ensure user is registered in user_profiles first
      try {
        final profile = await supabase
            .from('user_profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();

        if (profile == null) {
          await supabase.from('user_profiles').insert({
            'id': user.id,
            'email': user.email ?? '',
            'phone': _driverData['phone'] ?? '',
            'user_type': 'driver'
          });
        }
      } catch (e) {
        Navigator.pop(context); // Close loading dialog
        _showErrorMessage('Error creating user profile: ${e.toString()}');
        return;
      }

      // Check if we have all required fields
      bool isComplete = _validateDriverData();
      
      // Format dates for database
      String formattedDob = '';
      String formattedLicenseExp = '';
      String formattedGreyCardExp = '';
      
      try {
        if (_driverData.containsKey('date_of_birth') && _driverData['date_of_birth'] != null) {
          final dobParts = _driverData['date_of_birth'].toString().split('/');
          if (dobParts.length == 3) {
            formattedDob = '${dobParts[2]}-${dobParts[0]}-${dobParts[1]}'; // YYYY-MM-DD
          } else {
            formattedDob = _driverData['date_of_birth'].toString();
          }
        }
        
        if (_driverData.containsKey('license_expiration') && _driverData['license_expiration'] != null) {
          final licExpParts = _driverData['license_expiration'].toString().split('/');
          if (licExpParts.length == 3) {
            formattedLicenseExp = '${licExpParts[2]}-${licExpParts[0]}-${licExpParts[1]}'; // YYYY-MM-DD
          } else {
            formattedLicenseExp = _driverData['license_expiration'].toString();
          }
        }
        
        if (_driverData.containsKey('grey_card_expiration') && _driverData['grey_card_expiration'] != null) {
          final greyCardExpParts = _driverData['grey_card_expiration'].toString().split('/');
          if (greyCardExpParts.length == 3) {
            formattedGreyCardExp = '${greyCardExpParts[2]}-${greyCardExpParts[0]}-${greyCardExpParts[1]}'; // YYYY-MM-DD
          } else {
            formattedGreyCardExp = _driverData['grey_card_expiration'].toString();
          }
        }
      } catch (e) {
        print('Error formatting dates: $e');
        // Continue with original values if formatting fails
        formattedDob = _driverData['date_of_birth']?.toString() ?? '';
        formattedLicenseExp = _driverData['license_expiration']?.toString() ?? '';
        formattedGreyCardExp = _driverData['grey_card_expiration']?.toString() ?? '';
      }

      // Prepare data for insertion, including only the fields that exist
      final driverData = {
        'id': user.id,  // Set the driver ID to the user's authentication ID
        'user_id': user.id,
        'created_at': DateTime.now().toIso8601String(),
      };
      
      // Add fields that exist in _driverData to the driverData map
      if (_driverData.containsKey('first_name') && _driverData['first_name'] != null) {
        driverData['first_name'] = _driverData['first_name'].toString();
      }
      
      if (_driverData.containsKey('last_name') && _driverData['last_name'] != null) {
        driverData['last_name'] = _driverData['last_name'].toString();
      }
      
      if (formattedDob.isNotEmpty) {
        driverData['date_of_birth'] = formattedDob;
      }
      
      if (_driverData.containsKey('license_number') && _driverData['license_number'] != null) {
        driverData['license_number'] = _driverData['license_number'].toString();
      }
      
      if (_driverData.containsKey('license_image_front') && _driverData['license_image_front'] != null) {
        // Handle image data properly - it might be a List<int> or Uint8List
        if (_driverData['license_image_front'] is List) {
          // Convert to base64 string if it's a list of bytes
          driverData['license_image_front'] = base64Encode(List<int>.from(_driverData['license_image_front']));
        } else {
          driverData['license_image_front'] = _driverData['license_image_front'].toString();
        }
      }
      
      if (_driverData.containsKey('license_image_back') && _driverData['license_image_back'] != null) {
        // Handle image data properly - it might be a List<int> or Uint8List
        if (_driverData['license_image_back'] is List) {
          // Convert to base64 string if it's a list of bytes
          driverData['license_image_back'] = base64Encode(List<int>.from(_driverData['license_image_back']));
        } else {
          driverData['license_image_back'] = _driverData['license_image_back'].toString();
        }
      }
      
      if (formattedLicenseExp.isNotEmpty) {
        driverData['license_expiration'] = formattedLicenseExp;
      }
      
      if (_driverData.containsKey('grey_card_number') && _driverData['grey_card_number'] != null) {
        driverData['grey_card_number'] = _driverData['grey_card_number'].toString();
      }
      
      if (_driverData.containsKey('grey_card_image_front') && _driverData['grey_card_image_front'] != null) {
        // Handle image data properly - it might be a List<int> or Uint8List
        if (_driverData['grey_card_image_front'] is List) {
          // Convert to base64 string if it's a list of bytes
          driverData['grey_card_image_front'] = base64Encode(List<int>.from(_driverData['grey_card_image_front']));
        } else {
          driverData['grey_card_image_front'] = _driverData['grey_card_image_front'].toString();
        }
      }
      
      if (_driverData.containsKey('grey_card_image_back') && _driverData['grey_card_image_back'] != null) {
        // Handle image data properly - it might be a List<int> or Uint8List
        if (_driverData['grey_card_image_back'] is List) {
          // Convert to base64 string if it's a list of bytes
          driverData['grey_card_image_back'] = base64Encode(List<int>.from(_driverData['grey_card_image_back']));
        } else {
          driverData['grey_card_image_back'] = _driverData['grey_card_image_back'].toString();
        }
      }
      
      if (formattedGreyCardExp.isNotEmpty) {
        driverData['grey_card_expiration'] = formattedGreyCardExp;
      }
      
      if (_driverData.containsKey('vehicle_registration_plate') && _driverData['vehicle_registration_plate'] != null) {
        driverData['vehicle_registration_plate'] = _driverData['vehicle_registration_plate'].toString();
      }
      
      if (_driverData.containsKey('bus_name') && _driverData['bus_name'] != null) {
        driverData['bus_name'] = _driverData['bus_name'].toString();
      }
      
      if (_driverData.containsKey('bus_image') && _driverData['bus_image'] != null) {
        // Handle image data properly - it might be a List<int> or Uint8List
        if (_driverData['bus_image'] is List) {
          // Convert to base64 string for database
          driverData['bus_photo'] = base64Encode(List<int>.from(_driverData['bus_image']));
        } else {
          driverData['bus_photo'] = _driverData['bus_image'].toString();
        }
      } else if (_driverData.containsKey('bus_photo') && _driverData['bus_photo'] != null) {
        // Handle image data properly - it might be a List<int> or Uint8List
        if (_driverData['bus_photo'] is List) {
          // Convert to base64 string for database
          driverData['bus_photo'] = base64Encode(List<int>.from(_driverData['bus_photo']));
        } else {
          driverData['bus_photo'] = _driverData['bus_photo'].toString();
        }
      }
      
      if (_driverData.containsKey('email_driver') && _driverData['email_driver'] != null) {
        driverData['email_driver'] = _driverData['email_driver'].toString();
      }

      // Insert data into drivers table using the authenticated user's context
      try {
        // Step 1: Check if driver already exists in the database
        final existingDriverResponse = await supabase
            .from('drivers')
            .select('id')
            .eq('id', user.id)
            .maybeSingle();
        
        final driverExists = existingDriverResponse != null;
        
        // Step 2: Insert or update driver record with vehicle information
        if (driverExists) {
          // Update existing driver with vehicle information
          await supabase
              .from('drivers')
              .update({
                'first_name': driverData['first_name'],
                'last_name': driverData['last_name'],
                'date_of_birth': driverData['date_of_birth'],
                'license_number': driverData['license_number'],
                'license_image_front': driverData['license_image_front'],
                'license_image_back': driverData['license_image_back'],
                'license_expiration': driverData['license_expiration'],
                'grey_card_number': driverData['grey_card_number'],
                'grey_card_image_front': driverData['grey_card_image_front'],
                'grey_card_image_back': driverData['grey_card_image_back'],
                'grey_card_expiration': driverData['grey_card_expiration'],
                'vehicle_registration_plate': driverData['vehicle_registration_plate'],
                'bus_name': driverData['bus_name'],
                'bus_photo': driverData['bus_photo'],
                'email_driver': driverData['email_driver'],
              })
              .eq('id', user.id);
          
          print('Updated existing driver record');
        } else {
          // Insert new driver record
          await supabase.from('drivers').insert(driverData);
          print('Inserted new driver record');
        }
        
        // Step 3: Handle the bus record creation/update
        try {
          // Get the vehicle registration plate from the driver data
          final String registrationPlate = driverData['vehicle_registration_plate'].toString();
          
          // First, try to find if a bus with this registration plate exists
          final busResponse = await supabase
              .from('buses')
              .select()
              .eq('vehicle_registration_plate', registrationPlate);
          
          String? busId;
          
          if (busResponse.isNotEmpty) {
            // Bus exists, update it
            busId = busResponse[0]['id'].toString();
            await supabase
                .from('buses')
                .update({
                  'bus_name': driverData['bus_name'],
                  'bus_photo': driverData['bus_photo'],
                })
                .eq('id', busId);
            
            print('Updated existing bus with ID: $busId');
          } else {
            // Create new bus record
            final busData = {
              'bus_name': driverData['bus_name'],
              'vehicle_registration_plate': registrationPlate,
              'bus_photo': driverData['bus_photo'],
            };
            
            final insertResponse = await supabase
                .from('buses')
                .insert(busData)
                .select();
            
            if (insertResponse.isNotEmpty) {
              busId = insertResponse[0]['id'].toString();
              print('Created new bus with ID: $busId');
            }
          }
          
          // Step 4: Update driver with bus_id
          if (busId != null) {
            await supabase
                .from('drivers')
                .update({'bus_id': busId})
                .eq('id', user.id);
            
            print('Updated driver with bus_id: $busId');
          }
        } catch (e) {
          print('Error handling bus data: $e');
          // Continue with the rest of the process even if bus handling fails
        }
        
        // Clear saved data after successful submission
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('driver_data');
        
        // Mark the driver as registered in SharedPreferences
        await prefs.setBool('driver_${user.id}_registered', true);
        print('Driver marked as registered in SharedPreferences');

        // Close loading dialog
        Navigator.pop(context);

        // Show appropriate message based on whether all fields were valid
        if (isComplete) {
          // Show success message and navigate to home
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration completed successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 5),
            ),
          );

          // Navigate to driver home page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const HomePage2(),
            ),
          );
        } else {
          // Show partial success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Information saved with warnings. Some fields are missing or invalid.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5),
            ),
          );
        }
      } catch (e) {
        // Close loading dialog
        Navigator.pop(context);
        
        // Determine the specific error
        String errorMessage = 'An error occurred during registration.';
        
        if (e.toString().contains('duplicate key')) {
          errorMessage = 'A driver with this information already exists.';
        } else if (e.toString().contains('violates foreign key constraint')) {
          errorMessage = 'Invalid reference to another table. Please check your data.';
        } else if (e.toString().contains('violates not-null constraint')) {
          errorMessage = 'Missing required information. Please complete all sections.';
        } else if (e.toString().contains('permission denied')) {
          errorMessage = 'You do not have permission to register as a driver.';
          print('Permission denied error details: $e');
        } else if (e.toString().contains('network')) {
          errorMessage = 'Network error. Please check your internet connection.';
        }
        
        _showErrorMessage('$errorMessage\n\nDetails: ${e.toString()}');
      }
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);
      print('Error: $e');
      _showErrorMessage('حدث خطأ: ${e.toString()}');
    }
  }
  
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
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

  bool _validateDriverData() {
    // Check if we have all required fields from the new schema
    final requiredFields = [
      'first_name', 'last_name', 'date_of_birth',
      'license_number', 'license_image_front', 'license_image_back', 'license_expiration',
      'grey_card_number', 'grey_card_image_front', 'grey_card_image_back', 'grey_card_expiration',
      'vehicle_registration_plate', 'bus_photo', 'email_driver', 'bus_name'
    ];
    
    for (final field in requiredFields) {
      if (!_driverData.containsKey(field) || 
          _driverData[field] == null || 
          _driverData[field].toString().isEmpty) {
        
        // Show specific error message about which field is missing
        String fieldName = field.replaceAll('_', ' ');
        fieldName = fieldName.split(' ').map((word) => 
          word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : word
        ).join(' ');
        
        _showErrorMessage('Missing required field: $fieldName. Please complete all sections.');
        return false;
      }
    }
    
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register as a Driver', style: TextStyle(color: Colors.white)),
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
            children: [
              const SizedBox(height: 32),
              Center(
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: const DecorationImage(
                      image: AssetImage("assets/images/busd.png"),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Complete Your Profile',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please fill in all required information',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 32),
              _buildInfoButton(
                icon: Icons.person_outline_rounded,
                label: 'Basic Information',
                description: 'Name, phone, and contact details',
                onPressed: () {
                  // Save current data before navigating
                  _saveData();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BasicInfoPage(),
                    ),
                  ).then((value) {
                    // Refresh the state when returning from BasicInfoPage
                    setState(() {});
                  });
                },
              ),
              const SizedBox(height: 16),
              _buildInfoButton(
                icon: Icons.badge_outlined,
                label: 'Driver License',
                description: 'License details and verification',
                onPressed: () {
                  // Save current data before navigating
                  _saveData();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DriverLicensePage(driverData: _driverData),
                    ),
                  ).then((value) {
                    // Refresh the state when returning from DriverLicensePage
                    setState(() {});
                  });
                },
              ),
              const SizedBox(height: 16),
              _buildInfoButton(
                icon: Icons.directions_car_outlined,
                label: 'Vehicle Information',
                description: 'Car details and documentation',
                onPressed: () {
                  // Save current data before navigating
                  _saveData();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VehicleInfoPage(driverData: _driverData),
                    ),
                  ).then((value) {
                    // Refresh the state when returning from VehicleInfoPage
                    setState(() {});
                  });
                },
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submitInformation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A52C9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  child: isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Complete Registration',
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

  Widget _buildInfoButton({
    required IconData icon,
    required String label,
    required String description,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF2A52C9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withOpacity(0.6),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}