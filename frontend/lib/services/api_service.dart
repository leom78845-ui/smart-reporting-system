// lib/services/api_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../utils/constants.dart';

class ApiService {
  static String? _accessToken;
  static String? _refreshToken;

  // ---------------------------------------------------------------------------
  // LOGIN (Django JWT)
  // ---------------------------------------------------------------------------
  static Future<Map<String, dynamic>?> login(
      String rollNumber, String password) async {
    try {
      final url = Uri.parse("${AppConstants.baseUrl}/login/");
      final response = await http.post(
        url,
        headers: {HttpHeaders.contentTypeHeader: "application/json"},
        body: jsonEncode({
          "roll_number": rollNumber,
          "password": password,
        }),
      );

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);

      _accessToken = data["access"];
      _refreshToken = data["refresh"];

      return data; // contains: access, refresh, user{}
    } catch (_) {
      return null;
    }
  }

  static Future<void> logout() async {
    _accessToken = null;
    _refreshToken = null;
  }

  static void setTokens(String? access, String? refresh) {
    _accessToken = access;
    _refreshToken = refresh;
  }

  static String? get refreshToken => _refreshToken;



  // ---------------------------------------------------------------------------
  // GENERIC AUTHORIZED GET
  // ---------------------------------------------------------------------------
  static Future<dynamic> authorizedGet(String endpoint) async {
    if (_accessToken == null) return null;

    final url = Uri.parse("${AppConstants.baseUrl}$endpoint");
    final response = await http.get(
      url,
      headers: {HttpHeaders.authorizationHeader: "Bearer $_accessToken"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // GENERIC AUTHORIZED POST
  // ---------------------------------------------------------------------------
  static Future<dynamic> authorizedPost(
      String endpoint, Map<String, dynamic> body) async {
    if (_accessToken == null) return null;

    final url = Uri.parse("${AppConstants.baseUrl}$endpoint");
    final response = await http.post(
      url,
      headers: {
        HttpHeaders.authorizationHeader: "Bearer $_accessToken",
        HttpHeaders.contentTypeHeader: "application/json",
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // UPLOAD MEDIA (image/video)
  // ---------------------------------------------------------------------------
  static Future<String?> uploadMedia(File file) async {
    if (_accessToken == null) return null;

    final url = Uri.parse("${AppConstants.baseUrl}/upload-media/");
    final request = http.MultipartRequest("POST", url);

    request.headers[HttpHeaders.authorizationHeader] = "Bearer $_accessToken";
    request.files.add(await http.MultipartFile.fromPath("file", file.path));

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      return jsonDecode(body)["media_url"];
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // SUBMIT REPORT (Student)
  // ---------------------------------------------------------------------------
  static Future<bool> submitReport({
    required String title,
    required String description,
    required double latitude,
    required double longitude,
    required String mediaUrl,
    required String mediaType,
  }) async {
    final body = {
      "title": title,
      "description": description,
      "latitude": latitude,
      "longitude": longitude,
      "media_url": mediaUrl,
      "media_type": mediaType,
    };

    final result = await authorizedPost("/reports/submit/", body);
    return result != null;
  }

  // ---------------------------------------------------------------------------
  // GET MY REPORTS (Student)
  // ---------------------------------------------------------------------------
  static Future<List<dynamic>> getMyReports() async {
    final data = await authorizedGet("/my-reports/");
    return (data is List) ? data : [];
  }

  // ---------------------------------------------------------------------------
  // GET MY REPORTS STATS (Student)
  // ---------------------------------------------------------------------------
  static Future<Map<String, int>> getMyReportStats() async {
    try {
      final reports = await getMyReports();
      int pending = 0;
      int reviewing = 0;
      int resolved = 0;
      for (var r in reports) {
        final status = (r['status'] as String?)?.toLowerCase();
        if (status == 'pending') {
          pending++;
        } else if (status == 'reviewing') {
          reviewing++;
        } else if (status == 'resolved') {
          resolved++;
        }
      }
      return {
        'pending': pending,
        'reviewing': reviewing,
        'resolved': resolved,
      };
    } catch (_) {
      return {
        'pending': 0,
        'reviewing': 0,
        'resolved': 0,
      };
    }
  }

  // ---------------------------------------------------------------------------
  // GET ALL REPORTS (Admin)
  // ---------------------------------------------------------------------------
  static Future<List<dynamic>> getAllReports() async {
    final data = await authorizedGet("/all-reports/");
    return (data is List) ? data : [];
  }

  // ---------------------------------------------------------------------------
  // UPDATE REPORT STATUS (Admin)
  // ---------------------------------------------------------------------------
  static Future<bool> updateReportStatus(int id, String status) async {
    if (_accessToken == null) return false;

    final url = Uri.parse("${AppConstants.baseUrl}/reports/$id/status/");
    final response = await http.patch(
      url,
      headers: {
        HttpHeaders.authorizationHeader: "Bearer $_accessToken",
        HttpHeaders.contentTypeHeader: "application/json",
      },
      body: jsonEncode({"status": status}),
    );

    return response.statusCode == 200;
  }

  // ---------------------------------------------------------------------------
  // CHANGE PASSWORD
  // ---------------------------------------------------------------------------
  static Future<bool> changePassword(String newPassword) async {
    final result = await authorizedPost("/auth/change-password/", {
      "new_password": newPassword,
    });
    return result != null;
  }

  // ---------------------------------------------------------------------------
  // CREATE SINGLE STUDENT (Admin)
  // ---------------------------------------------------------------------------
  static Future<bool> createStudent({
    required String rollNumber,
    required String name,
    required String program,
    required String password,
  }) async {
    final result = await authorizedPost("/create-student/", {
      "roll_number": rollNumber,
      "name": name,
      "program": program,
      "password": password,
    });
    return result != null;
  }

  // ---------------------------------------------------------------------------
  // BULK CREATE STUDENTS (Admin)
  // ---------------------------------------------------------------------------
  static Future<bool> bulkCreateStudents({
    required String prefix,
    required String start,
    required String end,
    required String program,
    required String password,
  }) async {
    final result = await authorizedPost("/bulk-create/", {
      "prefix": prefix,
      "start": start,
      "end": end,
      "program": program,
      "password": password,
    });
    return result != null;
  }
}
