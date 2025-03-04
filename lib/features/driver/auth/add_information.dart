import 'package:flutter/material.dart';

class AddInformationPage extends StatelessWidget {
  const AddInformationPage({super.key});

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
            children: [
              // العنوان الرئيسي
              const Padding(
                padding: EdgeInsets.only(top: 96),
                child: Text(
                  'Register as a driver',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 35,
                    fontFamily: 'Lalezar',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),

              const SizedBox(height: 40), // مسافة بين العنوان والعناصر

              // زر Basic info
              _buildInfoButton(
                icon: Icons.person, // أيقونة Basic info
                label: 'Basic info',
                onPressed: () {
                  // الانتقال إلى صفحة Basic info
                },
              ),

              const SizedBox(height: 20), // مسافة بين العناصر

              // زر Driver licence
              _buildInfoButton(
                icon: Icons.drive_eta, // أيقونة Driver licence
                label: 'Driver licence',
                onPressed: () {
                  // الانتقال إلى صفحة Driver licence
                },
              ),

              const SizedBox(height: 20), // مسافة بين العناصر

              // زر Vehicle info
              _buildInfoButton(
                icon: Icons.directions_car, // أيقونة Vehicle info
                label: 'Vehicle info',
                onPressed: () {
                  // الانتقال إلى صفحة Vehicle info
                },
              ),

              const SizedBox(height: 40), // مسافة بين العناصر وزر Done

              // زر Done
              ElevatedButton(
                onPressed: () {
                  // إضافة منطق عند النقر على زر Done
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF547CF5), // لون الزر
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                    side: BorderSide(
                      width: 1,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 10),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // دالة مساعدة لبناء زر المعلومات
  Widget _buildInfoButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 368,
        height: 68,
        decoration: BoxDecoration(
          color: const Color(0xFFAAB6E4),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x3F000000),
              blurRadius: 4,
              offset: Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 16), // مسافة من الحافة اليسرى
            Icon(icon, size: 32, color: Colors.black), // أيقونة
            const SizedBox(width: 16), // مسافة بين الأيقونة والنص
            Text(
              label,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}