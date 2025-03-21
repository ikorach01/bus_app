import 'package:flutter/material.dart';
import 'package:bus_app/features/user/login_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: 412,
        height: 917,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-0.20, -0.98),
            end: Alignment(0.2, 0.98),
            colors: [Color(0xFF9CB3F9), Color(0xFF2A52C9), Color(0xFF14202E)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 73,
              top: 155,
              child: Container(
                width: 265,
                height: 265,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/images/transport_13636924.png"),
                    fit: BoxFit.fill,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 110,
              top: 612,
              child: GestureDetector(
                onTap: () {
                  // Navigate to Login Page instead of Role Selection
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginPage(),
                    ),
                  );
                },
                child: Container(
                  width: 193,
                  height: 64,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x3F000000),
                        blurRadius: 4,
                        offset: Offset(0, 4),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 2.04,
                        top: 0,
                        child: Container(
                          width: 190.96,
                          height: 54.74,
                          decoration: ShapeDecoration(
                            color: Color(0xFFEFF0FB),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 5,
                        top: 5,
                        child: SizedBox(
                          width: 141,
                          height: 50,
                          child: Text(
                            'skip..',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF002BAA),
                              fontSize: 30,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 40,
              top: 433,
              child: SizedBox(
                width: 333,
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Welcome! Start your journey now with ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontFamily: 'Instrument Sans',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(
                        text: 'Busway',
                        style: TextStyle(
                          color: Color(0xFFBDDDF6),
                          fontSize: 25,
                          fontFamily: 'Instrument Sans',
                          fontWeight: FontWeight.w700,
                          height: 1.22,
                        ),
                      ),
                      TextSpan(
                        text: ', the smart solution for bus transportation.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontFamily: 'Instrument Sans',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}