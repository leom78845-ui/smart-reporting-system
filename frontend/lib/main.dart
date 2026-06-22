// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'managers/auth_manager.dart';
import 'services/sync_manager.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/upload_screen.dart';
import 'screens/admin_map_screen.dart';
import 'screens/change_password_screen.dart';
import 'screens/create_students_screen.dart';
import 'screens/my_reports_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize offline sync manager (handles background report syncing)
  SyncManager.initialize();

  runApp(const SmartReportingApp());
}

class SmartReportingApp extends StatelessWidget {
  const SmartReportingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthManager(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: "Smart Reporting System",
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: {
          '/': (_) => const SplashScreen(),
          '/login': (_) => const LoginScreen(),
          '/upload': (_) => const UploadScreen(),
          '/adminMap': (_) => const AdminMapScreen(),
          '/myReports': (_) => const MyReportsScreen(),
          '/changePassword': (_) => const ChangePasswordScreen(),
          '/createStudents': (_) => const CreateStudentsScreen(),
        },
      ),
    );
  }
}
