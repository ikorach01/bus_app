import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bus_app/features/user/login_page.dart';
import 'package:bus_app/features/user/ask_location.dart';
import 'package:bus_app/features/driver/auth/add_information.dart';

class RoleSelectionPage extends StatelessWidget {
  final String userId;
  final String userEmail;
  final String userPhone;

  const RoleSelectionPage({
    super.key, 
    required this.userId, 
    required this.userEmail, 
    required this.userPhone
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 368,
                height: 320,
                child: Image(
                  image: AssetImage('assets/images/ask.png'),
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 40),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'To get started, choose your account type: Are you a passenger or a driver?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 40),

              _buildRoleButton(
                context: context,
                label: 'Passenger',
                color: const Color(0xFFEFF0FB),
                textColor: const Color(0xFF002BAA),
                userType: 'passenger',
              ),
              const SizedBox(height: 20),

              _buildRoleButton(
                context: context,
                label: 'Driver',
                color: const Color(0xFF547CF5),
                textColor: const Color(0xFFE9EBF8),
                userType: 'driver',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleButton({
    required BuildContext context,
    required String label,
    required Color color,
    required Color textColor,
    required String userType,
  }) {
    return SizedBox(
      width: 200,
      height: 60,
      child: ElevatedButton(
        onPressed: () async {
          try {
            final supabase = Supabase.instance.client;
            
            // Show loading indicator
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Setting up your account...'),
                duration: Duration(seconds: 2),
              ),
            );

            // Update auth metadata with user type
            await supabase.auth.updateUser(
              UserAttributes(
                data: {'user_type': userType},
              ),
            );
            print('Auth metadata updated successfully');

            // Save to user_profiles table
            final profileData = {
              'id': userId,
              'email': userEmail,
              'phone': userPhone,
              'user_type': userType,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            };

            await supabase.from('user_profiles').upsert(profileData);
            print('Profile saved successfully');

            // Show success message
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('You are now registered as a $userType'),
                backgroundColor: Colors.green,
              ),
            );

            // Navigate based on user type
            if (!context.mounted) return;
            if (userType == 'passenger') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const AskLocationScreen()),
              );
            } else if (userType == 'driver') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const AddInformationPage()),
              );
            }
          } catch (e) {
            print('Error saving profile: $e');
            if (e is PostgrestException) {
              print('PostgrestException code: ${e.code}');
              print('PostgrestException message: ${e.message}');
            }

            if (!context.mounted) return;
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}