import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // لإضافة القدرة على التقاط الصور
import 'dart:io'; // للتعامل مع الملفات
import 'add_information.dart'; // استيراد الصفحة التالية

class DriverLicense2Page extends StatefulWidget {
  const DriverLicense2Page({Key? key}) : super(key: key);

  @override
  _DriverLicense2PageState createState() => _DriverLicense2PageState();
}

class _DriverLicense2PageState extends State<DriverLicense2Page> {
  final TextEditingController _licenseNumberController = TextEditingController();
  final TextEditingController _expirationDateController = TextEditingController();
  File? _frontImage;
  File? _backImage;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(bool isFront) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        if (isFront) {
          _frontImage = File(pickedFile.path);
        } else {
          _backImage = File(pickedFile.path);
        }
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _expirationDateController.text =
            "${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year.toString().substring(2)}";
      });
    }
  }

  void _navigateToNextPage(BuildContext context) {
    if (_licenseNumberController.text.isEmpty ||
        _expirationDateController.text.isEmpty ||
        _frontImage == null ||
        _backImage == null) {
      // عرض رسالة خطأ إذا كانت البيانات غير مكتملة
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields and upload both images.'),
          backgroundColor: Colors.red,
        ),
      );
    } else if (!RegExp(r'^\d{2}/\d{2}/\d{2}$').hasMatch(_expirationDateController.text)) {
      // التحقق من صحة تنسيق التاريخ
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid date in MM/DD/YY format.'),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      // الانتقال إلى الصفحة التالية
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddInformationPage(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grey Card', style: TextStyle(color: Colors.white)),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.article_rounded,
                        size: 48,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Grey Card Details',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              _buildTextField(
                controller: _licenseNumberController,
                label: 'Grey Card Number',
                icon: Icons.credit_card_rounded,
              ),
              const SizedBox(height: 24),
              _buildDateField(context),
              const SizedBox(height: 32),
              Text(
                'Upload Grey Card Photos',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildImageUploadCard(
                      title: 'Front Side',
                      image: _frontImage,
                      onTap: () => _pickImage(true),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildImageUploadCard(
                      title: 'Back Side',
                      image: _backImage,
                      onTap: () => _pickImage(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => _navigateToNextPage(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A52C9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Done',
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
    );
  }

  Widget _buildImageUploadCard({
    required String title,
    required File? image,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (image != null)
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    image,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              )
            else
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo_rounded,
                    size: 40,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to upload',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 16,
          ),
          prefixIcon: Icon(
            icon,
            color: Colors.white.withOpacity(0.7),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildDateField(BuildContext context) {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: TextField(
          controller: _expirationDateController,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
          enabled: false,
          decoration: InputDecoration(
            labelText: 'Expiration Date',
            labelStyle: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
            prefixIcon: Icon(
              Icons.calendar_today_rounded,
              color: Colors.white.withOpacity(0.7),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ),
    );
  }
}