// lib/managers/auth_manager.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class AuthManager extends ChangeNotifier {
  Map<String, dynamic>? _user;
  String? _role;
  bool _isLoading = false;

  Map<String, dynamic>? get user => _user;
  String? get role => _role;
  bool get isLoggedIn => _user != null;
  bool get isAdmin => _role == AppConstants.roleAdmin;
  bool get isStudent => _role == AppConstants.roleStudent;
  bool get isLoadingState => _isLoading;

  // ---------------------------------------------------------------------------
  // LOGIN (Django JWT)
  // ---------------------------------------------------------------------------
  Future<bool> login(String rollNumber, String password) async {
    _isLoading = true;
    notifyListeners();

    final result = await ApiService.login(rollNumber, password);

    if (result == null) {
      _isLoading = false;
      notifyListeners();
      return false;
    }

    // Save user info
    _user = result["user"];
    _role = result["user"]["role"];

    // Save tokens + user info locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("access_token", result["access"]);
    await prefs.setString("refresh_token", result["refresh"]);
    await prefs.setString("user_role", _role!);
    await prefs.setString("roll_number", result["user"]["roll_number"]);
    await prefs.setString("user_name", result["user"]["name"] ?? "");

    _isLoading = false;
    notifyListeners();
    return true;
  }

  // ---------------------------------------------------------------------------
  // LOAD USER FROM LOCAL STORAGE (Auto-login)
  // ---------------------------------------------------------------------------
  Future<bool> loadUser() async {
    final prefs = await SharedPreferences.getInstance();

    final role = prefs.getString("user_role");
    final roll = prefs.getString("roll_number");
    final access = prefs.getString("access_token");
    final refresh = prefs.getString("refresh_token");
    final name = prefs.getString("user_name") ?? "";

    if (role == null || roll == null || access == null) {
      return false;
    }

    _role = role;
    _user = {
      "role": role,
      "roll_number": roll,
      "name": name,
    };

    // Restore tokens in ApiService
    ApiService.setTokens(access, refresh);

    notifyListeners();
    return true;
  }

  // ---------------------------------------------------------------------------
  // UPDATE DISPLAY NAME
  // ---------------------------------------------------------------------------
  Future<bool> updateName(String newName) async {
    _isLoading = true;
    notifyListeners();

    final result = await ApiService.updateProfileName(newName);

    if (result == null) {
      _isLoading = false;
      notifyListeners();
      return false;
    }

    // Save locally
    _user = result["user"];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("user_name", _user!["name"] ?? "");

    _isLoading = false;
    notifyListeners();
    return true;
  }

  // ---------------------------------------------------------------------------
  // LOGOUT
  // ---------------------------------------------------------------------------
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    _user = null;
    _role = null;

    await ApiService.logout();

    notifyListeners();
  }
}

