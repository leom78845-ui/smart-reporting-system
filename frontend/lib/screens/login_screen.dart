import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _storage = const FlutterSecureStorage();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    // Call the updated ApiService.login which returns a Map
    final authData = await ApiService.login(username, password);

    setState(() => _isLoading = false);

    // Check if authData is not null (success)
    // Django sends 'access', 'role', and 'is_first_login'
    if (authData != null && authData['access'] != null) {
      
      // Save data securely using the keys the backend actually sends
      await _storage.write(key: 'jwt_token', value: authData['access']);
      await _storage.write(key: 'role', value: authData['role']);

      if (!mounted) return;

      // Navigate based on Role
      if (authData['role'] == 'student') {
        // Handle first login requirement
        if (authData['is_first_login'] == true) {
          Navigator.pushReplacementNamed(context, '/change-password');
        } else {
          Navigator.pushReplacementNamed(context, '/upload');
        }
      } else {
        // Admin role
        Navigator.pushReplacementNamed(context, '/admin-map');
      }
    } else {
      _showErrorDialog("Login Failed", "Invalid credentials or account restricted.");
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(color: Colors.red)),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Icon(Icons.security, size: 80, color: Colors.blue),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: 'Roll Number', border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 24),
                _isLoading 
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _handleLogin,
                      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                      child: const Text('Login'),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}