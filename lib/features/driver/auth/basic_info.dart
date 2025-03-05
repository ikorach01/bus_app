import 'package:flutter/material.dart';

class BasicInfoPage extends StatelessWidget {
  const BasicInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(color: Color(0xFFF4F4F4)),
        child: Stack(
          children: [
            // الأشكال البيضاوية في الخلفية
            Positioned(
              left: 198,
              top: -83,
              child: Container(
                width: 367,
                height: 332,
                decoration: const ShapeDecoration(
                  color: Color(0xFF002BAA),
                  shape: OvalBorder(),
                ),
              ),
            ),
            Positioned(
              left: -8,
              top: 371,
              child: Container(
                width: 243,
                height: 169,
                decoration: const ShapeDecoration(
                  color: Color(0xFFD78885),
                  shape: OvalBorder(),
                ),
              ),
            ),
            Positioned(
              left: -139,
              top: 640,
              child: Container(
                width: 343,
                height: 257,
                decoration: ShapeDecoration(
                  color: const Color(0xFF6C8EF3),
                  shape: OvalBorder(side: BorderSide(width: 1)),
                ),
              ),
            ),

            // زر الرجوع في الزاوية العلوية اليسرى
            Positioned(
              left: 16,
              top: 71,
              child: GestureDetector(
                onTap: () {
                  // الرجوع إلى الصفحة السابقة
                  Navigator.pop(context);
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(),
                  child: const Icon(
                    Icons.chevron_left, // أيقونة الرجوع
                    size: 48,
                    color: Colors.black,
                  ),
                ),
              ),
            ),

            // صورة المستخدم
            Positioned(
              left: 125,
              top: 95,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  image: const DecorationImage(
                    image: NetworkImage(
                        "https://placehold.co/160x160"), // صورة المستخدم
                    fit: BoxFit.fill,
                  ),
                  borderRadius: BorderRadius.circular(80), // جعل الصورة دائرية
                ),
              ),
            ),

            // حقول الإدخال
            Positioned(
              left: 33,
              top: 292,
              child: _buildInputField(label: 'First Name'),
            ),
            Positioned(
              left: 33,
              top: 406,
              child: _buildInputField(label: 'Last Name'),
            ),
            Positioned(
              left: 33,
              top: 520,
              child: _buildInputField(label: 'Date of birth'),
            ),
            Positioned(
              left: 33,
              top: 634,
              child: _buildInputField(label: 'Email adresse'),
            ),

            // زر Done
            Positioned(
              left: 84,
              top: 780,
              child: ElevatedButton(
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 10),
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
            ),

            // شريط الحالة (Status Bar)
            Positioned(
              left: 0,
              top: 0,
              child: Container(
                width: 412,
                height: 47,
                padding: const EdgeInsets.only(top: 21),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 16),
                      child: Text(
                        '9:41',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 17,
                          fontFamily: 'SF Pro',
                          fontWeight: FontWeight.w500,
                          height: 1.29,
                        ),
                      ),
                    ),
                    Container(
                      width: 124,
                      height: 10,
                    ),
                    const Padding(
                      padding: EdgeInsets.only(right: 16),
                      child: Icon(
                        Icons.signal_cellular_alt, // أيقونة الإشارة
                        size: 20,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // شريط التمرير (Navigation Bar)
            Positioned(
              left: 0,
              top: 884,
              child: Container(
                width: 412,
                height: 34,
                padding: const EdgeInsets.only(
                    top: 21, left: 10, right: 10, bottom: 8),
                child: Center(
                  child: Container(
                    width: 138,
                    height: 5,
                    decoration: ShapeDecoration(
                      color: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // دالة مساعدة لبناء حقول الإدخال
  Widget _buildInputField({required String label}) {
    return Container(
      width: 359,
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: ShapeDecoration(
        color: const Color(0xFFEAEEFA),
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 1, color: Color(0xFF666666)),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: label,
          hintStyle: const TextStyle(
            color: Color(0xFF666666),
            fontSize: 14,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
