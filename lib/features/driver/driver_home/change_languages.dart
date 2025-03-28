import 'package:flutter/material.dart';

class ChangeLanguagesPage extends StatefulWidget {
  const ChangeLanguagesPage({Key? key}) : super(key: key);

  @override
  State<ChangeLanguagesPage> createState() => _ChangeLanguagesPageState();
}

class _ChangeLanguagesPageState extends State<ChangeLanguagesPage> {
  String _selectedLanguage = 'English'; // Default language

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
              _buildLanguageOption('English'),
              const SizedBox(height: 16),
              _buildLanguageOption('Français'),
              const SizedBox(height: 16),
              _buildLanguageOption('العربية'),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    // Save language preference and go back
                    // In a real app, you would use a localization package
                    Navigator.pop(context);
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

  Widget _buildLanguageOption(String language) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _selectedLanguage == language
              ? Colors.white
              : Colors.white.withOpacity(0.3),
        ),
      ),
      child: RadioListTile<String>(
        title: Text(
          language,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        value: language,
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