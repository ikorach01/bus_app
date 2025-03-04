import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class AskLocationScreen extends StatefulWidget {
  const AskLocationScreen({super.key});

  @override
  State<AskLocationScreen> createState() => _AskLocationScreenState();
}

class _AskLocationScreenState extends State<AskLocationScreen> {
  // Function to request location permission
  Future<void> _requestLocationPermission() async {
    try {
      var status = await Permission.location.request();

      if (status.isDenied) {
        if (!mounted) return;
        // Show a dialog explaining why the permission is needed
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Location Permission Needed'),
              content: const Text(
                'Busway services require your location for a better experience. Please allow location access.',
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Skip'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const Scaffold(body: Center(child: Text('Home Page')))),
                    );
                  },
                ),
                TextButton(
                  child: const Text('Open Settings'),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await openAppSettings();
                  },
                ),
              ],
            );
          },
        );
      } else if (status.isPermanentlyDenied) {
        if (!mounted) return;
        // Show a dialog to guide user to app settings
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Location Permission Required'),
              content: const Text(
                'Location permission is required for core features. Please enable it in app settings.',
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Skip'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const Scaffold(body: Center(child: Text('Home Page')))),
                    );
                  },
                ),
                TextButton(
                  child: const Text('Open Settings'),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await openAppSettings();
                  },
                ),
              ],
            );
          },
        );
      } else if (status.isGranted) {
        if (!mounted) return;
        // Navigate to home page when permission is granted
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Scaffold(body: Center(child: Text('Home Page')))),
        );
      }
    } catch (e) {
      if (!mounted) return;
      // Show error dialog if permission request fails
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to request permission: $e'),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const Scaffold(body: Center(child: Text('Home Page')))),
                  );
                },
              ),
            ],
          );
        },
      );
    }
  }

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
          child: Stack(
            children: [
              Positioned(
                left: 50,
                top: 50,
                right: 50,
                child: Container(
                  height: 200,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage("assets/images/map.png"),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 20,
                top: 300,
                right: 20,
                child: const Text(
                  'Busway services require your\nlocation',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontFamily: 'Instrument Sans',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Positioned(
                left: 20,
                top: 400,
                right: 20,
                child: const Text(
                  'For a better experience, please turn on your device location',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'Instrument Sans',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              Positioned(
                left: 50,
                top: 500,
                right: 50,
                child: ElevatedButton(
                  onPressed: _requestLocationPermission,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF547CF5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text(
                    'Turn on location services',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 50,
                top: 570,
                right: 50,
                child: TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const Scaffold(body: Center(child: Text('Home Page')))),
                    );
                  },
                  child: Text(
                    'SKIP...',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 20,
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
    );
  }
}