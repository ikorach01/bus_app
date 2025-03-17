import 'package:flutter/material.dart';
import 'add_information.dart'; // تأكد من استيراد الصفحة بشكل صحيح

class BasicInfoPage extends StatefulWidget {
  const BasicInfoPage({Key? key}) : super(key: key);

  @override
  _BasicInfoPageState createState() => _BasicInfoPageState();
}

class _BasicInfoPageState extends State<BasicInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _emailController = TextEditingController();

  void _validateAndNavigate(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      // التحقق من أن جميع الحقول غير فارغة
      if (_firstNameController.text.isEmpty ||
          _lastNameController.text.isEmpty ||
          _dateOfBirthController.text.isEmpty ||
          _emailController.text.isEmpty) {
        // عرض رسالة خطأ إذا كانت البيانات غير صحيحة
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill all fields correctly.'),
            backgroundColor: Colors.red,
          ),
        );
      } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
          .hasMatch(_emailController.text)) {
        // التحقق من صحة البريد الإلكتروني
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid email address.'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        // الانتقال إلى صفحة add_information.dart إذا كانت البيانات صحيحة
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddInformationPage(),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Basic Information', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF9CB3F9),
        elevation: 0,
      ),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                Center(
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: const DecorationImage(
                        image: AssetImage("assets/images/driver3.png"),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Personal Details',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please provide your personal information',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _buildTextField(
                  controller: _firstNameController,
                  label: 'First Name',
                  icon: Icons.person_outline_rounded,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your first name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _lastNameController,
                  label: 'Last Name',
                  icon: Icons.person_outline_rounded,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your last name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _dateOfBirthController,
                  label: 'Date of Birth',
                  icon: Icons.calendar_today_outlined,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your date of birth';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  icon: Icons.email_outlined,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email address';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => _validateAndNavigate(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2A52C9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Save & Continue',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.7)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF2A52C9), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.red.withOpacity(0.5)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      ),
      validator: validator,
    );
  }
}