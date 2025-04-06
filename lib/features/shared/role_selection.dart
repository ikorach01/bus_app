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
            final supabase = Supabase.instance.client;
            
            // Show loading indicator
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Setting up your account...'),
                duration: Duration(seconds: 10),
              ),
            );
            
            // تحويل نوع المستخدم في واجهة المستخدم إلى الدور المناسب في قاعدة البيانات
            String databaseRole = userType;
            if (userType == 'passenger') {
              databaseRole = 'user';
            }
            
            print('Updating user role for ID: $userId');
            print('Email: $userEmail');
            print('Phone: $userPhone');
            print('Selected interface role: $userType');
            print('Database role: $databaseRole');
            
            // Update user role using auth.updateUser
            await supabase.auth.updateUser(
              UserAttributes(
                data: {'role': databaseRole},
              ),
            );
            print('Auth metadata updated successfully');
            
            // Update or insert user data in the users table
            try {
              // First check if the users table exists and is accessible
              try {
                final tableCheck = await supabase.from('users').select('count').limit(1);
                print('Users table check result: $tableCheck');
              } catch (tableError) {
                print('Error checking users table: $tableError');
                print('This may indicate that the users table does not exist or you do not have access to it');
              }
              
              // First check if the user exists in the users table
              print('Checking if user exists in database...');
              final userData = await supabase
                  .from('users')
                  .select()
                  .eq('id', userId)
                  .maybeSingle();
              
              print('User data check result: $userData');
              
              if (userData != null) {
                // User exists, update the role
                print('User exists in database, updating role...');
                try {
                  await supabase
                      .from('users')
                      .update({
                        'role': databaseRole,
                        'updated_at': DateTime.now().toIso8601String()
                      })
                      .eq('id', userId);
                      
                  print('User role updated in users table');
                } catch (updateError) {
                  print('Error updating user role: $updateError');
                  if (updateError is PostgrestException) {
                    print('PostgrestException code: ${updateError.code}');
                    print('PostgrestException message: ${updateError.message}');
                    print('PostgrestException details: ${updateError.details}');
                  }
                }
              } else {
                // User doesn't exist in the table, insert new record
                print('User does not exist in database, creating new record...');
                
                // Try multiple approaches to insert the user
                try {
                  // Approach 1: Standard insert
                  final insertData = {
                    'id': userId,
                    'email': userEmail,
                    'phone': userPhone,
                    'role': databaseRole,
                    'created_at': DateTime.now().toIso8601String(),
                    'email_confirm': true,
                  };
                  
                  print('Attempting to insert with data: $insertData');
                  
                  // تحقق من سياسات RLS قبل الإدخال
                  print('Checking RLS policies before insert...');
                  try {
                    final policies = await supabase.rpc('get_policies_for_table', params: {'table_name': 'users'});
                    print('Current policies for users table: $policies');
                  } catch (policyError) {
                    print('Error checking policies: $policyError');
                  }
                  
                  final response = await supabase.from('users').insert(insertData).select();
                  print('Insert response: $response');
                  print('User inserted into users table with role: $databaseRole');
                  
                  // تحقق من نجاح الإدخال
                  final checkInsert = await supabase
                      .from('users')
                      .select()
                      .eq('id', userId)
                      .maybeSingle();
                  print('Verification after insert: $checkInsert');
                  
                } catch (insertError) {
                  print('Error with standard insert: $insertError');
                  
                  if (insertError is PostgrestException) {
                    print('PostgrestException code: ${insertError.code}');
                    print('PostgrestException message: ${insertError.message}');
                    print('PostgrestException details: ${insertError.details}');
                  }
                  
                  // Approach 2: Try upsert
                  try {
                    print('Trying upsert approach...');
                    final upsertData = {
                      'id': userId,
                      'email': userEmail,
                      'phone': userPhone,
                      'role': databaseRole,
                      'created_at': DateTime.now().toIso8601String(),
                      'email_confirm': true,
                    };
                    
                    final response = await supabase.from('users').upsert(upsertData).select();
                    print('Upsert response: $response');
                    print('User upserted successfully');
                    
                    // تحقق من نجاح الإدخال
                    final checkUpsert = await supabase
                        .from('users')
                        .select()
                        .eq('id', userId)
                        .maybeSingle();
                    print('Verification after upsert: $checkUpsert');
                    
                  } catch (upsertError) {
                    print('Error with upsert: $upsertError');
                    
                    if (upsertError is PostgrestException) {
                      print('PostgrestException code: ${upsertError.code}');
                      print('PostgrestException message: ${upsertError.message}');
                      print('PostgrestException details: ${upsertError.details}');
                    }
                    
                    // Approach 3: Try minimal insert
                    try {
                      print('Trying minimal insert...');
                      await supabase.from('users').insert({
                        'id': userId,
                        'email': userEmail,
                        'role': databaseRole,
                      });
                      print('Minimal user record created');
                    } catch (minimalError) {
                      print('Error with minimal insert: $minimalError');
                      
                      if (minimalError is PostgrestException) {
                        print('PostgrestException code: ${minimalError.code}');
                        print('PostgrestException message: ${minimalError.message}');
                        print('PostgrestException details: ${minimalError.details}');
                      }
                    }
                  }
                }
              }
            } catch (dbError) {
              print('Error updating user data in database: $dbError');
              // Continue with navigation even if database update fails
            }
            
            // Show success message
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).clearSnackBars();
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
            ScaffoldMessenger.of(context).clearSnackBars();
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