import 'package:flutter/material.dart';
import 'driver_licence2.dart'; // استيراد الصفحة التالية

class DriverLicensePage extends StatefulWidget {
  const DriverLicensePage({Key? key}) : super(key: key);

  @override
  _DriverLicensePageState createState() => _DriverLicensePageState();
}

class _DriverLicensePageState extends State<DriverLicensePage> {
  final TextEditingController _licenseNumberController = TextEditingController();
  final TextEditingController _expirationDateController = TextEditingController();
  String? _frontImagePath;
  String? _backImagePath;

  Future<void> _pickImage(bool isFront) async {
    // هنا يمكنك إضافة منطق لالتقاط صورة من الكاميرا أو اختيارها من المعرض
    // هذا مثال بسيط لتعيين صورة افتراضية
    setState(() {
      if (isFront) {
        _frontImagePath = "assets/images/photograph1.png";
      } else {
        _backImagePath = "assets/images/photograph1.png";
      }
    });
  }

  void _navigateToNextPage(BuildContext context) {
    if (_licenseNumberController.text.isEmpty ||
        _expirationDateController.text.isEmpty ||
        _frontImagePath == null ||
        _backImagePath == null) {
      // عرض رسالة خطأ إذا كانت البيانات غير مكتملة
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields and upload both images.'),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      // الانتقال إلى الصفحة التالية
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DriverLicense2Page(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: 412,
        height: 917,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(1.00, -0.00),
            end: Alignment(-0.00, 1.00),
            colors: [Color(0xFF9CB3FA), Color(0xFF2A52CA), Color(0xFF14212F)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 18,
              top: 104,
              child: Container(
                width: 379,
                height: 54,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(width: 1, color: Color(0xFF666666)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: TextFormField(
                  controller: _licenseNumberController,
                  decoration: InputDecoration(
                    hintText: 'Driver license number',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.only(left: 11, top: 17),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 49,
              top: 268,
              child: Text(
                'The front of driver’s license',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 24,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Positioned(
              left: 146,
              top: 301,
              child: GestureDetector(
                onTap: () => _pickImage(true),
                child: Container(
                  width: 126,
                  height: 122,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: _frontImagePath != null
                          ? AssetImage(_frontImagePath!)
                          : AssetImage("assets/images/photograph1.png"),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 50,
              top: 482,
              child: Text(
                'The back of driver’s license',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 24,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Positioned(
              left: 143,
              top: 523,
              child: GestureDetector(
                onTap: () => _pickImage(false),
                child: Container(
                  width: 126,
                  height: 122,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: _backImagePath != null
                          ? AssetImage(_backImagePath!)
                          : AssetImage("assets/images/photograph1.png"),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 106,
              top: 694,
              child: Text(
                'Date of expiration',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 24,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Positioned(
              left: 29,
              top: 755,
              child: Container(
                width: 359,
                height: 54,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(width: 1, color: Color(0xFF666666)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: TextFormField(
                  controller: _expirationDateController,
                  decoration: InputDecoration(
                    hintText: 'Date of expiration',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.only(left: 11, top: 17),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 71,
              top: 846,
              child: GestureDetector(
                onTap: () => _navigateToNextPage(context),
                child: Container(
                  width: 254,
                  height: 46,
                  clipBehavior: Clip.antiAlias,
                  decoration: ShapeDecoration(
                    color: Color(0xFF547CF5),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        width: 1,
                        color: Colors.white.withOpacity(0.5),
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Next',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
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
}