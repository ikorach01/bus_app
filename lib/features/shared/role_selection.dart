import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bus_app/features/user/login_page.dart'; // Import login page
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
              // Image
              const SizedBox(
                width: 368,
                height: 320,
                child: Image(
                  image: AssetImage('assets/images/ask.png'),
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 40),

              // Instruction Text
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

              // Passenger Button
              _buildRoleButton(
                context: context,
                label: 'Passenger',
                color: const Color(0xFFEFF0FB),
                textColor: const Color(0xFF002BAA),
                userType: 'passenger',
              ),
              const SizedBox(height: 20),

              // Driver Button
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
            // Update user role using auth.updateUser
            await Supabase.instance.client.auth.updateUser(
              UserAttributes(
                data: {'role': userType},
              ),
            );
            
            // Show success message
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('You are now registered as a $userType'),
                backgroundColor: Colors.green,
              ),
            );
            
            // Navigate to appropriate screen based on role
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
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
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