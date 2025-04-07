import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bus_app/features/user/ask_location.dart';
import 'package:bus_app/features/shared/role_selection.dart';
import 'package:bus_app/features/driver/auth/add_information.dart';
import 'dart:ui';

final supabase = Supabase.instance.client;

class LoginPage extends StatefulWidget {
  final String? userType; // Nullable to allow selection for new users
  const LoginPage({super.key, this.userType});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool isLogin = true;
  bool isLoading = false;

  Future<void> _authenticate() async {
    setState(() => isLoading = true);

    try {
      if (isLogin) {
        print('Attempting to sign in with email: ${emailController.text.trim()}');
        
        // Check if email exists in auth.users
        try {
          final existingUser = await supabase
              .rpc('check_email_exists', params: {
                'check_email': emailController.text.trim(),
              });

          if (existingUser == false) {
            throw Exception(
              'This email is not registered. Please sign up first or use a different email address.'
            );
          }
        } catch (e) {
          if (e is PostgrestException) {
            print('Error checking email: ${e.message}');
          } else {
            rethrow;
          }
        }
        
        final response = await supabase.auth.signInWithPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        final user = response.user;
        if (user == null) {
          throw Exception('Login failed. Please check your credentials.');
        }
        
        print('User signed in successfully: ${user.id}');
        
        if (user.emailConfirmedAt == null) {
          throw Exception('Please confirm your email before logging in.');
        }

        // جلب بيانات المستخدم من Supabase
        final session = supabase.auth.currentSession;
        final userData = session?.user.userMetadata;
        final userType = userData?['user_type'] as String?;
        
        print('User metadata: $userData');
        print('User type: $userType');
        
        // Check if user exists in the database and insert if not
        await _checkAndInsertUserData(user, userType);

        if (userType == null) {
          // المستخدم يسجل الدخول لأول مرة ولم يحدد نوعه بعد
          print('First-time login detected. Redirecting to role selection.');
          if (!context.mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => RoleSelectionPage(
                userId: user.id,
                userEmail: user.email ?? '',
                userPhone: userData?['phone'] as String? ?? '',
              ),
            ),
          );
        } else {
          // المستخدم لديه نوع مسجل، الانتقال بناءً على النوع
          print('Existing user detected with type: $userType. Redirecting accordingly.');
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
        }
      } else {
        if (passwordController.text != confirmPasswordController.text) {
          throw Exception("Passwords do not match.");
        }

        // Check if email already exists in auth.users
        try {
          final existingUser = await supabase
              .rpc('check_email_exists', params: {
                'check_email': emailController.text.trim(),
              });

          if (existingUser == true) {
            throw Exception(
              'This email is already registered. Please try logging in instead, or use a different email address.'
            );
          }
        } catch (e) {
          if (e is PostgrestException) {
            print('Error checking email: ${e.message}');
          } else {
            rethrow;
          }
        }

        print('Attempting to sign up with email: ${emailController.text.trim()}');
        
        final response = await supabase.auth.signUp(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
          emailRedirectTo: 'bus_app://auth/callback',
          data: {
            'phone': phoneController.text.trim(),
            'user_type': null, // لم يتم تحديد النوع بعد، سيتم تحديده لاحقًا
          },
        );

        final user = response.user;
        if (user != null) {
          print('User signed up successfully: ${user.id}');
          
          // Insert user data into user_profiles table
          try {
            print('Attempting to insert user data into user_profiles table...');
            
            final profileData = {
              'id': user.id,
              'email': emailController.text.trim(),
              'phone': phoneController.text.trim(),
              'user_type': null,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            };
            
            await supabase.from('user_profiles').upsert(profileData);
            print('User profile created successfully');
            
          } catch (dbError) {
            print('Error in database operations: $dbError');
            if (dbError is PostgrestException) {
              print('PostgrestException code: ${dbError.code}');
              print('PostgrestException message: ${dbError.message}');
            }
          }
          
          _showMessage('Registration successful! Please check your email to confirm your account.', Colors.green);
          
          setState(() {
            isLogin = true; // التبديل إلى وضع تسجيل الدخول
          });
        }
      }
    } catch (e) {
      print('Authentication error: $e');
      _showMessage(e.toString(), Colors.red);
    }

    setState(() => isLoading = false);
  }
  
  // Helper function to check if user exists in database and insert if not
  Future<void> _checkAndInsertUserData(User user, String? userType) async {
    try {
      print('Checking if user exists in database: ${user.id}');
      
      // Check if user exists in the user_profiles table
      final existingUser = await supabase
          .from('user_profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      
      print('Existing user check result: $existingUser');
      
      if (existingUser == null) {
        print('User not found in database, inserting now...');
        
        final profileData = {
          'id': user.id,
          'email': user.email,
          'phone': user.userMetadata?['phone'],
          'user_type': userType,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };
        
        await supabase.from('user_profiles').upsert(profileData);
        print('User profile created successfully');
        
      } else if (userType != null && existingUser['user_type'] != userType) {
        print('Updating user type to: $userType');
        
        await supabase
            .from('user_profiles')
            .update({
              'user_type': userType,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', user.id);
        
        print('User type updated successfully');
      }
    } catch (error) {
      print('Error in database operations: $error');
      if (error is PostgrestException) {
        print('PostgrestException code: ${error.code}');
        print('PostgrestException message: ${error.message}');
      }
    }
  }

  void _showMessage(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF14212F),
      body: Center(
        child: Container(
          width: 350,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isLogin ? 'Sign In' : 'Sign Up',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 16),
              _buildTextField(emailController, 'Email', Icons.email),
              if (!isLogin) _buildTextField(phoneController, 'Phone Number', Icons.phone),
              _buildTextField(passwordController, 'Password', Icons.lock, isPassword: true),
              if (!isLogin) _buildTextField(confirmPasswordController, 'Confirm Password', Icons.lock, isPassword: true),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: isLoading ? null : _authenticate,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: const Color(0xFF2A52CA),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(isLogin ? 'Login' : 'Register', style: const TextStyle(fontSize: 18, color: Colors.white)),
              ),
              TextButton(
                onPressed: () => setState(() => isLogin = !isLogin),
                child: Text(
                  isLogin ? 'Create an account' : 'Already have an account? Sign in',
                  style: const TextStyle(color: Color(0xFF9CB3FA)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.7)),
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
    );
  }
}