import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bus_app/providers/settings_provider.dart';

class ChangeLanguagesPage extends StatefulWidget {
  const ChangeLanguagesPage({Key? key}) : super(key: key);

  @override
  State<ChangeLanguagesPage> createState() => _ChangeLanguagesPageState();
}

class _ChangeLanguagesPageState extends State<ChangeLanguagesPage> {
  String _selectedLanguage = 'en'; // Default language code

  @override
  void initState() {
    super.initState();
    // Load the current language from the provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
      setState(() {
        _selectedLanguage = settingsProvider.language;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Language Settings', style: TextStyle(color: Colors.white)),
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
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Language',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _buildLanguageOption('en', 'English', 'assets/images/us_flag.png'),
              const SizedBox(height: 16),
              _buildLanguageOption('ar', 'العربية', 'assets/images/arabic_flag.png'),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    // Save language preference and go back
                    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
                    await settingsProvider.setLanguage(_selectedLanguage);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Language updated successfully')),
                      );
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A52C9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Save',
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
    );
  }

  Widget _buildLanguageOption(String languageCode, String languageName, String flagAsset) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _selectedLanguage == languageCode
              ? Colors.white
              : Colors.white.withOpacity(0.3),
        ),
      ),
      child: RadioListTile<String>(
        title: Row(
          children: [
            // Uncomment this when you add flag assets
            // Image.asset(
            //   flagAsset,
            //   width: 24,
            //   height: 24,
            // ),
            // const SizedBox(width: 12),
            Text(
              languageName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
        value: languageCode,
        groupValue: _selectedLanguage,
        onChanged: (value) {
          setState(() {
            _selectedLanguage = value!;
          });
        },
        activeColor: Colors.white,
      ),
    );
  }
}