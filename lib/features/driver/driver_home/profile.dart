import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  
  // Driver information
  String _firstName = '';
  String _lastName = '';
  String _email = '';
  String _phone = '';
  String _dateOfBirth = '';
  String? _profileImageBase64;

  @override
  void initState() {
    super.initState();
    _loadDriverProfile();
  }

  Future<void> _loadDriverProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
<<<<<<< HEAD
      final userData = await _getUserData();
      if (userData != null) {
        setState(() {
          _name = userData['full_name'] ?? 'No name';
          _email = _supabase.auth.currentUser?.email ?? 'No email';
          _phone = userData['phone'] ?? 'No phone';
          _profileImageUrl = userData['avatar_url'] ?? '';
=======
      final user = _supabase.auth.currentUser;
      if (user != null) {
        // Get driver information from the drivers table
        final driverData = await _supabase
            .from('drivers')
            .select('*')
            .eq('id', user.id)
            .single();

        // Get user data for phone number
        final userData = await _supabase
            .from('users')
            .select('phone')
            .eq('id', driverData['user_id'])
            .maybeSingle();

        setState(() {
          _firstName = driverData['first_name'] ?? 'No first name';
          _lastName = driverData['last_name'] ?? 'No last name';
          _email = driverData['email_driver'] ?? user.email ?? 'No email';
          _phone = userData != null ? userData['phone'] ?? 'No phone number' : 'No phone number';
          
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
>>>>>>> 2f44519 (حفظ التعديلات قبل جلب التحديثات)
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

  Future<Map<String, dynamic>?> _getUserData() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final data = await _supabase
            .from('user_profiles')
            .select()
            .eq('id', userId)
            .single();
      
      return data;
    } catch (e) {
      print('Error fetching user data: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Profile', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF9CB3F9),
        iconTheme: const IconThemeData(color: Colors.white),
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
                      _buildProfileImage(),
                      const SizedBox(height: 16),
                      Text(
                        '$_firstName $_lastName',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildProfileInfo('Email', _email, Icons.email),
                      const SizedBox(height: 16),
                      _buildProfileInfo('Phone', _phone, Icons.phone),
                      const SizedBox(height: 16),
                      _buildProfileInfo('Date of Birth', _dateOfBirth, Icons.cake),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            // Refresh driver profile data
                            _loadDriverProfile();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2A52C9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Refresh Profile',
                            style: TextStyle(
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
}