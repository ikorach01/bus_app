import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bus_app/features/user/login_page.dart';
import 'package:bus_app/providers/settings_provider.dart';
import 'package:bus_app/features/user/user_home/home_page.dart';

final supabase = Supabase.instance.client;

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late bool _delayAlertsEnabled;
  late String _selectedLanguage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
      setState(() {
        _delayAlertsEnabled = settingsProvider.delayAlertsEnabled;
        _selectedLanguage = settingsProvider.language;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Notifications'),
          SwitchListTile(
            title: const Text('Delay Alerts'),
            value: _delayAlertsEnabled,
            onChanged: (value) async {
              setState(() => _delayAlertsEnabled = value);
              await settingsProvider.updateDelayAlerts(value);
              _showNotificationStatus(value);
            },
          ),

          _buildSectionHeader('Language'),
          ListTile(
            title: const Text('Language'),
            trailing: DropdownButton<String>(
              value: _selectedLanguage,
              items: [
                DropdownMenuItem(
                  value: 'ar',
                  child: Text('العربية', style: TextStyle(
                    color: _selectedLanguage == 'ar' ? Theme.of(context).primaryColor : null,
                  )),
                ),
                DropdownMenuItem(
                  value: 'en',
                  child: Text('English', style: TextStyle(
                    color: _selectedLanguage == 'en' ? Theme.of(context).primaryColor : null,
                  )),
                ),
              ],
              onChanged: (String? newValue) async {
                if (newValue != null) {
                  setState(() => _selectedLanguage = newValue);
                  await settingsProvider.updateLanguage(newValue);
                  _restartApp(context);
                }
              },
            ),
          ),

          _buildSectionHeader('Account'),
          ListTile(
            leading: const Icon(Icons.exit_to_app),
            title: const Text('Logout'),
            onTap: () => _logout(context),
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text(
              'Delete Account',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () => _showDeleteAccountDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }

  void _showNotificationStatus(bool enabled) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          enabled 
            ? 'Delay Alerts enabled'
            : 'Delay Alerts disabled',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _restartApp(BuildContext context) {
    final user = supabase.auth.currentUser;
    
    // Create a widget that will determine the appropriate screen based on authentication
    Widget initialScreen;
    
    if (user != null) {
      final userData = user.userMetadata;
      final role = userData?['role'] as String?;
      
      if (role == 'driver') {
        // Navigate to driver home
        initialScreen = const HomePage();
      } else {
        // Navigate to passenger home
        initialScreen = const HomePage();
      }
    } else {
      // If no user is authenticated, go to login
      initialScreen = const LoginPage();
    }
    
    // Use pushReplacement to replace the current screen without adding to the stack
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => initialScreen),
      (route) => false,
    );
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await supabase.auth.signOut();
      if (!mounted) return;
      await Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: ${e.toString()}')),
      );
    }
  }

  Future<void> _showDeleteAccountDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete your account? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteAccount(context);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext context) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId != null) {
        // Delete user data from user_profiles table
        await supabase.from('user_profiles').delete().eq('id', userId);
        
        // Delete auth user
        await supabase.auth.admin.deleteUser(userId);
        
        // Sign out
        await supabase.auth.signOut();
        
        if (!mounted) return;
        await Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting account: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class RootApp extends StatelessWidget {
  const RootApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoginPage();
  }
}