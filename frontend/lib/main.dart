import 'package:flutter/material.dart';
// Import your service
import 'services/api_service.dart';

// Import screens
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/upload_screen.dart';
import 'screens/my_reports_screen.dart';
import 'screens/admin_map_screen.dart';
import 'screens/change_password_screen.dart';
import 'screens/map_verification_screen.dart';

void main() {
  // CRITICAL: Initialize API Service to register interceptors before the app starts.
  // This ensures your JWT tokens are automatically attached to every request.
  WidgetsFlutterBinding.ensureInitialized();
  ApiService.init(); 
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Reporting System',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/upload': (context) => const UploadScreen(),
        '/my-reports': (context) => const MyReportsScreen(),
        '/admin-map': (context) => const AdminMapScreen(),
        '/change-password': (context) => const ChangePasswordScreen(),
        // Default coordinates for route initialization
        '/map-verification': (context) => const MapVerificationScreen(lat: 0.0, lng: 0.0),
      },
    );
  }
}