import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _delayAlertsEnabled = settingsProvider.delayAlertsEnabled;
    _selectedLanguage = settingsProvider.language;
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.settings),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // قسم الإشعارات
          _buildSectionHeader(localizations.notifications),
          SwitchListTile(
            title: Text(localizations.delayAlerts),
            value: _delayAlertsEnabled,
            onChanged: (value) async {
              setState(() => _delayAlertsEnabled = value);
              await settingsProvider.updateDelayAlerts(value);
              _showNotificationStatus(value);
            },
          ),

          // قسم اللغة
          _buildSectionHeader(localizations.language),
          ListTile(
            title: Text(localizations.language),
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

          // قسم الحساب
          _buildSectionHeader(localizations.account),
          ListTile(
            leading: const Icon(Icons.exit_to_app),
            title: Text(localizations.logout),
            onTap: () => _logout(context),
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: Text(
              localizations.deleteAccount,
              style: const TextStyle(color: Colors.red),
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
            ? '${AppLocalizations.of(context)!.delayAlerts} ${AppLocalizations.of(context)!.enabled}'
            : '${AppLocalizations.of(context)!.delayAlerts} ${AppLocalizations.of(context)!.disabled}',
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
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)!.logoutFailed}: ${e.toString()}')),
      );
    }
  }

  Future<void> _showDeleteAccountDialog(BuildContext context) async {
    final localizations = AppLocalizations.of(context)!;
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.confirmDelete),
        content: Text(localizations.deleteAccountWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteAccount(context);
            },
            child: Text(
              localizations.delete,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final localizations = AppLocalizations.of(context)!;
    
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId != null) {
        // 1. حذف بيانات المستخدم من جدول users
        await supabase.from('users').delete().eq('id', userId);

        // 2. حذف تفضيلات المستخدم
        await supabase.from('user_preferences').delete().eq('user_id', userId);

        // 3. حذف الحساب من نظام المصادقة
        // Note: Client-side SDK doesn't have admin.deleteUser method
        // This would typically be handled by a backend function
        // await supabase.auth.admin.deleteUser(userId);

        // 4. تسجيل الخروج
        await supabase.auth.signOut();

        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${localizations.deleteAccountFailed}: ${e.toString()}')),
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