import 'package:flutter/material.dart';

class BasicInfoPage extends StatefulWidget {
  @override
  _BasicInfoPageState createState() => _BasicInfoPageState();
}

class _BasicInfoPageState extends State<BasicInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: 412,
        height: 917,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(1.00, -0.02),
            end: Alignment(0.00, 1.00),
            colors: [Color(0xFF9CB3FA), Color(0xFF2A52CA), Color(0xFF14212F)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 125,
              top: 95,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/images/driver3.png"),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 23,
              top: 292,
              child: Text(
                'First Name',
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
              left: 22,
              top: 406,
              child: Text(
                'Last Name',
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
              left: 24,
              top: 520,
              child: Text(
                'Date of birth',
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
              left: 24,
              top: 634,
              child: Text(
                'Email adresse',
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
              left: 33,
              top: 337,
              child: Container(
                width: 359,
                height: 54,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: ShapeDecoration(
                  color: Color(0xFFEAEEFA),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(width: 1, color: Color(0xFF666666)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: TextFormField(
                  controller: _firstNameController,
                  decoration: InputDecoration(
                    hintText: 'First Name',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.only(left: 11, top: 17),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 33,
              top: 451,
              child: Container(
                width: 359,
                height: 54,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: ShapeDecoration(
                  color: Color(0xFFEAEEFA),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(width: 1, color: Color(0xFF666666)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: TextFormField(
                  controller: _lastNameController,
                  decoration: InputDecoration(
                    hintText: 'Last Name',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.only(left: 11, top: 17),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 33,
              top: 563,
              child: Container(
                width: 359,
                height: 54,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: ShapeDecoration(
                  color: Color(0xFFEAEEFA),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(width: 1, color: Color(0xFF666666)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: TextFormField(
                  controller: _dateOfBirthController,
                  decoration: InputDecoration(
                    hintText: 'Date of birth',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.only(left: 11, top: 17),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 33,
              top: 683,
              child: Container(
                width: 359,
                height: 54,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: ShapeDecoration(
                  color: Color(0xFFEAEEFA),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(width: 1, color: Color(0xFF666666)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    hintText: 'Email adresse',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.only(left: 11, top: 17),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 84,
              top: 780,
              child: GestureDetector(
                onTap: () {
                  if (_formKey.currentState!.validate()) {
                    // Navigate to the next page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddInformationPage(),
                      ),
                    );
                  }
                },
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
                      'Done',
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

class AddInformationPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Add Information Page'),
      ),
    );
  }
}