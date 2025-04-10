import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Provider class that manages application settings and preferences
class SettingsProvider with ChangeNotifier {
  bool _darkMode = false;
  bool _delayAlertsEnabled = true;
  String _language = 'en';
  bool _notificationsEnabled = true;
  late final String _hereApiKey;

  bool get darkMode => _darkMode;
  bool get delayAlertsEnabled => _delayAlertsEnabled;
  String get language => _language;
  bool get notificationsEnabled => _notificationsEnabled;
  String get hereApiKey => _hereApiKey;

  SettingsProvider() {
    _hereApiKey = dotenv.env['HERE_API_KEY'] ?? '';
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _darkMode = prefs.getBool('darkMode') ?? false;
    _delayAlertsEnabled = prefs.getBool('delayAlertsEnabled') ?? true;
    _language = prefs.getString('language') ?? 'en';
    _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
    // Don't load API key from SharedPreferences for security reasons
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _darkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', value);
    notifyListeners();
  }

  Future<void> setDelayAlertsEnabled(bool value) async {
    _delayAlertsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('delayAlertsEnabled', value);
    notifyListeners();
  }

  Future<void> setLanguage(String value) async {
    _language = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', value);
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', value);
    notifyListeners();
  }
  
  // Added methods to match the ones used in settings_page.dart
  Future<void> updateDelayAlerts(bool value) async {
    return setDelayAlertsEnabled(value);
  }
  
  Future<void> updateLanguage(String value) async {
    return setLanguage(value);
  }
}
