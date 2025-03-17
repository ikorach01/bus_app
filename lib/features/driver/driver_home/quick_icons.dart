import 'package:flutter/material.dart';

class QuickIconsInterface extends StatelessWidget {
  const QuickIconsInterface({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Home'),
        backgroundColor: const Color(0xFF14212F),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(1.00, -0.01),
            end: Alignment(-0.00, 1.00),
            colors: [Color(0xFF9CB3FA), Color(0xFF2A52CA), Color(0xFF2C54CB), Color(0xFF14212F)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildQuickActionButton(),
              _buildRoutesButton(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Settings functionality will be added later
        },
        backgroundColor: const Color(0xFF2A52CA),
        child: const Icon(Icons.settings, color: Colors.white),
      ),
    );
  }

  Widget _buildQuickActionButton() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ElevatedButton(
        onPressed: () {
          // Quick Icons functionality will be added later
        },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(20),
          backgroundColor: Colors.white.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Column(
          children: [
            Icon(Icons.touch_app, size: 40, color: Colors.white),
            SizedBox(height: 8),
            Text('Quick Actions', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutesButton() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ElevatedButton(
        onPressed: () {
          // Routes & Trips functionality will be added later
        },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(20),
          backgroundColor: Colors.white.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Column(
          children: [
            Icon(Icons.map, size: 40, color: Colors.white),
            SizedBox(height: 8),
            Text('Routes & Trips', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}