import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  
  // Driver information
  String _firstName = '';
  String _lastName = '';
  String _email = '';
  String _phone = '';
  String _dateOfBirth = '';
  String? _profileImageBase64;
  String? _vehicleRegistrationPlate = '';
  String? _busName = '';
  
  // Controllers for editable fields
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _busNameController = TextEditingController();
  
  // Store original driver data for comparison
  Map<String, dynamic>? _originalDriverData;
  Map<String, dynamic>? _originalUserData;

  @override
  void initState() {
    super.initState();
    _loadDriverProfile();
  }
  
  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _busNameController.dispose();
    super.dispose();
  }

  Future<void> _loadDriverProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        // Get driver information from the drivers table
        final driverData = await _supabase
            .from('drivers')
            .select('*')
            .eq('id', user.id)
            .single();
            
        _originalDriverData = Map<String, dynamic>.from(driverData);

        // Get user data for phone number from the user_profiles table
        final userData = await _supabase
            .from('user_profiles')
            .select('phone, email')
            .eq('id', driverData['user_id'])
            .maybeSingle();
            
        if (userData != null) {
          _originalUserData = Map<String, dynamic>.from(userData);
        }

        setState(() {
          _firstName = driverData['first_name'] ?? 'No first name';
          _lastName = driverData['last_name'] ?? 'No last name';
          _email = driverData['email_driver'] ?? user.email ?? 'No email';
          _phone = userData != null ? userData['phone'] ?? 'No phone number' : 'No phone number';
          _vehicleRegistrationPlate = driverData['vehicle_registration_plate'] ?? 'No plate number';
          _busName = driverData['bus_name'] ?? 'No bus name';
          
          // Set controller values
          _firstNameController.text = _firstName;
          _lastNameController.text = _lastName;
          _emailController.text = _email;
          _phoneController.text = _phone;
          _busNameController.text = _busName ?? '';
          
          // Format date of birth if available
          if (driverData['date_of_birth'] != null) {
            try {
              final DateTime dateOfBirth = DateTime.parse(driverData['date_of_birth'].toString());
              _dateOfBirth = DateFormat('dd/MM/yyyy').format(dateOfBirth);
            } catch (e) {
              _dateOfBirth = 'No date of birth';
              print('Error parsing date of birth: $e');
            }
          } else {
            _dateOfBirth = 'No date of birth';
          }
          
          // Handle profile image (could be from license_image_front)
          if (driverData['license_image_front'] != null) {
            try {
              final List<int> photoBytes = List<int>.from(driverData['license_image_front']);
              _profileImageBase64 = base64Encode(photoBytes);
            } catch (e) {
              print('Error processing profile image: $e');
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
        print('Error loading driver profile: $e');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _saveProfile() async {
    if (_originalDriverData == null) return;
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      
      // Prepare data to update
      final Map<String, dynamic> driverUpdates = {};
      
      // Check which fields have changed
      if (_firstNameController.text != _originalDriverData!['first_name']) {
        driverUpdates['first_name'] = _firstNameController.text;
      }
      
      if (_lastNameController.text != _originalDriverData!['last_name']) {
        driverUpdates['last_name'] = _lastNameController.text;
      }
      
      if (_emailController.text != (_originalDriverData!['email_driver'] ?? user.email)) {
        driverUpdates['email_driver'] = _emailController.text;
      }
      
      if (_busNameController.text != (_originalDriverData!['bus_name'] ?? '')) {
        driverUpdates['bus_name'] = _busNameController.text;
      }
      
      // Update driver data if there are changes
      if (driverUpdates.isNotEmpty) {
        await _supabase
            .from('drivers')
            .update(driverUpdates)
            .eq('id', user.id);
      }
      
      // Update user profile data if phone has changed
      if (_originalUserData != null && 
          _phoneController.text != _originalUserData!['phone']) {
        await _supabase
            .from('user_profiles')
            .update({'phone': _phoneController.text})
            .eq('id', _originalDriverData!['user_id']);
      }
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      // Reload profile data
      await _loadDriverProfile();
      
      // Exit edit mode
      setState(() {
        _isEditing = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
        print('Error updating profile: $e');
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }
  
  Future<void> _pickProfileImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (image == null) return;
      
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      setState(() {
        _profileImageBase64 = base64Image;
      });
      
      // Save the image to the database
      final user = _supabase.auth.currentUser;
      if (user != null) {
        await _supabase
            .from('drivers')
            .update({'license_image_front': bytes})
            .eq('id', user.id);
            
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile image updated'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile image: $e'),
          backgroundColor: Colors.red,
        ),
      );
      print('Error updating profile image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF9CB3F9),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (!_isLoading && !_isEditing)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () {
                setState(() {
                  // Reset controllers to original values
                  _firstNameController.text = _firstName;
                  _lastNameController.text = _lastName;
                  _emailController.text = _email;
                  _phoneController.text = _phone;
                  _busNameController.text = _busName ?? '';
                  _isEditing = false;
                });
              },
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF9CB3F9), Color(0xFF2A52C9), Color(0xFF14202E)],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: _isEditing ? _pickProfileImage : null,
                        child: Stack(
                          children: [
                            _buildProfileImage(),
                            if (_isEditing)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2A52C9),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_isEditing) ...[
                        _buildEditableField('First Name', _firstNameController, Icons.person),
                        const SizedBox(height: 16),
                        _buildEditableField('Last Name', _lastNameController, Icons.person),
                      ] else ...[
                        Text(
                          '$_firstName $_lastName',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      if (_isEditing)
                        _buildEditableField('Email', _emailController, Icons.email)
                      else
                        _buildProfileInfo('Email', _email, Icons.email),
                      const SizedBox(height: 16),
                      if (_isEditing)
                        _buildEditableField('Phone', _phoneController, Icons.phone)
                      else
                        _buildProfileInfo('Phone', _phone, Icons.phone),
                      const SizedBox(height: 16),
                      _buildProfileInfo('Date of Birth', _dateOfBirth, Icons.cake),
                      const SizedBox(height: 16),
                      _buildProfileInfo('Vehicle Plate', _vehicleRegistrationPlate ?? '', Icons.directions_car),
                      const SizedBox(height: 16),
                      if (_isEditing)
                        _buildEditableField('Bus Name', _busNameController, Icons.directions_bus)
                      else
                        _buildProfileInfo('Bus Name', _busName ?? 'No bus name', Icons.directions_bus),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isEditing 
                            ? (_isSaving ? null : _saveProfile)
                            : _loadDriverProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2A52C9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isSaving
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                _isEditing ? 'Save Changes' : 'Refresh Profile',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildProfileImage() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.2),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: _profileImageBase64 != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(60),
              child: Image.memory(
                base64Decode(_profileImageBase64!),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  print('Error loading profile image: $error');
                  return const Icon(Icons.person, size: 60, color: Colors.white);
                },
              ),
            )
          : const Icon(Icons.person, size: 60, color: Colors.white),
    );
  }

  Widget _buildProfileInfo(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEditableField(String label, TextEditingController controller, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                TextField(
                  controller: controller,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}