import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  // REPLACE this with your actual live URL once deployed to Render
  static const String _baseUrl = "https://your-app-name.onrender.com";

  static final Dio _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    headers: {
      'Accept': 'application/json',
    },
  ));

  static const _storage = FlutterSecureStorage();

  static void init() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          debugPrint("ApiService Error [${e.response?.statusCode}]: ${e.message}");
          return handler.next(e);
        },
      ),
    );
  }

  static Future<void> logout() async {
    await _storage.deleteAll();
  }

  static Future<String?> _getToken() => _storage.read(key: 'jwt_token');

  static Future<Map<String, dynamic>?> login(String rollNumber, String password) async {
    try {
      final response = await _dio.post("/api/login/", data: {
        "roll_number": rollNumber,
        "password": password,
      });

      if (response.statusCode == 200) {
        await _storage.write(key: 'jwt_token', value: response.data['access']);
        await _storage.write(key: 'refresh_token', value: response.data['refresh']);
        await _storage.write(key: 'role', value: response.data['role']);
        return response.data;
      }
    } on DioException catch (e) {
      debugPrint("Login error: ${e.response?.data ?? e.message}");
    }
    return null;
  }

  static Future<bool> submitReport({
    required String title,
    required String description,
    required double latitude,
    required double longitude,
    required String filePath,
    required String mediaType,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        "title": title,
        "description": description,
        "latitude": latitude,
        "longitude": longitude,
        "file": await MultipartFile.fromFile(filePath, filename: "report.jpg"),
        "media_type": mediaType,
      });

      final response = await _dio.post("/api/reports/submit/", data: formData);
      return response.statusCode == 201;
    } catch (e) {
      debugPrint("SubmitReport Error: $e");
      return false;
    }
  }

  static Future<List<dynamic>> getMyReports() async {
    try {
      final response = await _dio.get("/api/my-reports/");
      return response.data is List ? response.data : [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<dynamic>> getAllReports() async {
    try {
      final response = await _dio.get("/api/all-reports/");
      return response.data is List ? response.data : [];
    } catch (e) {
      return [];
    }
  }

  static Future<void> updateReportStatus(int id, String status) async {
    try {
      await _dio.patch("/api/reports/$id/status/", data: {"status": status});
    } catch (e) {
      debugPrint("Update error: $e");
    }
  }

  static Future<bool> changePassword(String oldPassword, String newPassword) async {
    try {
      final response = await _dio.post("/api/change-password/", data: {
        "old_password": oldPassword,
        "new_password": newPassword,
      });
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}