import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Artificial delay to ensure branding is visible for a moment
    await Future.delayed(const Duration(seconds: 2));

    final storage = const FlutterSecureStorage();
    String? token = await storage.read(key: 'jwt_token');
    String? role = await storage.read(key: 'role');

    if (!mounted) return;

    if (token != null) {
      // Navigate based on role
      if (role == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin-map');
      } else {
        Navigator.pushReplacementNamed(context, '/upload');
      }
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Your App Branding
            const Icon(Icons.shield_rounded, size: 100, color: Colors.blue),
            const SizedBox(height: 20),
            const Text(
              "Smart Reporting System",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(color: Colors.blue),
          ],
        ),
      ),
    );
  }
}