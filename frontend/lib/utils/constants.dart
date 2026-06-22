// lib/utils/constants.dart

class AppConstants {
  // ---------------------------------------------------------------------------
  // BACKEND BASE URL
  // ---------------------------------------------------------------------------
  static const String baseUrl = "http://192.168.1.3:8000/api";

  // ---------------------------------------------------------------------------
  // USER ROLES
  // ---------------------------------------------------------------------------
  static const String roleStudent = "student";
  static const String roleAdmin = "admin";

  // ---------------------------------------------------------------------------
  // STORAGE PATHS
  // ---------------------------------------------------------------------------
  static const String reportsStoragePath = "reports/";

  // ---------------------------------------------------------------------------
  // APP SETTINGS
  // ---------------------------------------------------------------------------
  static const int syncIntervalSeconds = 30; // how often SyncManager checks
  static const double defaultMapZoom = 15.0;

  // ---------------------------------------------------------------------------
  // UI STRINGS
  // ---------------------------------------------------------------------------
  static const String appName = "Smart Reporting System";
  static const String offlineMessage =
      "No internet connection. Report saved offline.";
  static const String successMessage = "Report submitted successfully.";
  static const String errorMessage = "Something went wrong. Please try again.";
}
