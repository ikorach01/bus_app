import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'basic_info.dart';
import 'driver_licence.dart';
import 'vehicle_info.dart';
import '../driver_home/quick_icons.dart'; // Updated import path

final supabase = Supabase.instance.client;

class AddInformationPage extends StatefulWidget {
  const AddInformationPage({Key? key}) : super(key: key);

  @override
  _AddInformationPageState createState() => _AddInformationPageState();
}

class _AddInformationPageState extends State<AddInformationPage> {
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController licenseNumberController = TextEditingController();
  final TextEditingController vehicleModelController = TextEditingController();
  final TextEditingController vehiclePlateController = TextEditingController();

  bool isLoading = false;

  Future<void> _submitInformation() async {
    setState(() => isLoading = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in.');
      }

      // Insert data into the `drivers` table
      final response = await supabase.from('drivers').insert({
        'user_id': user.id,
        'full_name': fullNameController.text.trim(),
        'license_number': licenseNumberController.text.trim(),
        'vehicle_model': vehicleModelController.text.trim(),
        'vehicle_plate': vehiclePlateController.text.trim(),
      });

      if (response.error != null) {
        throw Exception(response.error!.message);
      }

      // Show success message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Information submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to the QuickIconsInterface
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => QuickIconsInterface(),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register as a Driver'),
        backgroundColor: const Color(0xFF14212F),
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 40),
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
              const SizedBox(height: 40),
              _buildInfoButton(
                icon: Icons.person,
                label: 'Basic info',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BasicInfoPage(), // Removed const
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              _buildInfoButton(
                icon: Icons.drive_eta,
                label: 'Driver licence',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DriverLicensePage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              _buildInfoButton(
                icon: Icons.directions_car,
                label: 'Vehicle info',
                onPressed: () {
                  // Navigate to VehicleInfoPage
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VehicleInfoPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  // Navigate directly to QuickIconsInterface
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const QuickIconsInterface(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  backgroundColor: Colors.white.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

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
            const SizedBox(width: 16),
            Icon(icon, size: 32, color: Colors.black),
            const SizedBox(width: 16),
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

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.7)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF2A52CA)),
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
        ),
      ),
    );
  }
}