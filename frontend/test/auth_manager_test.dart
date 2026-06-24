import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_reporting_system/managers/auth_manager.dart';

class MockHttpOverrides extends HttpOverrides {
  final String mockResponse;
  MockHttpOverrides(this.mockResponse);

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return MockHttpClient(mockResponse);
  }
}

class MockHttpClient implements HttpClient {
  final String mockResponse;
  MockHttpClient(this.mockResponse);

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    return MockHttpClientRequest(mockResponse);
  }

  @override
  Future<HttpClientRequest> postUrl(Uri url) async {
    return MockHttpClientRequest(mockResponse);
  }

  @override
  Future<HttpClientRequest> post(String host, int port, String path) async {
    return MockHttpClientRequest(mockResponse);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockHttpClientRequest implements HttpClientRequest {
  final String mockResponse;
  MockHttpClientRequest(this.mockResponse);

  @override
  HttpHeaders get headers => MockHttpHeaders();

  @override
  void write(Object? obj) {}

  @override
  Future<dynamic> addStream(Stream<List<int>> stream) async {
    return;
  }

  @override
  Future<HttpClientResponse> close() async {
    return MockHttpClientResponse(mockResponse);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockHttpHeaders implements HttpHeaders {
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockHttpClientResponse implements HttpClientResponse {
  final String mockResponse;
  MockHttpClientResponse(this.mockResponse);

  @override
  int get statusCode => 200;

  @override
  bool get isRedirect => false;

  @override
  bool get persistentConnection => false;

  @override
  List<RedirectInfo> get redirects => const [];

  @override
  String get reasonPhrase => 'OK';

  @override
  int get contentLength => utf8.encode(mockResponse).length;

  @override
  HttpHeaders get headers => MockHttpHeaders();

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    final stream = Stream<List<int>>.fromIterable([utf8.encode(mockResponse)]);
    return stream.listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthManager Name Update Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        "user_role": "student",
        "roll_number": "CS-123",
        "access_token": "mock_access",
        "refresh_token": "mock_refresh",
        "user_name": "Initial Name",
      });
    });

    test('updateName successfully updates user name in memory and local storage', () async {
      // Mock response payload from backend UpdateProfileAPI
      final mockBackendResponse = jsonEncode({
        "message": "Profile name updated successfully",
        "user": {
          "roll_number": "CS-123",
          "name": "Updated Name",
          "role": "student",
          "program": "bs"
        }
      });

      HttpOverrides.runWithHttpOverrides(() async {
        final manager = AuthManager();
        
        // Load initial user
        final loaded = await manager.loadUser();
        expect(loaded, isTrue);
        expect(manager.user?['name'], equals('Initial Name'));

        // Track if listeners are notified
        bool wasNotified = false;
        manager.addListener(() {
          wasNotified = true;
        });

        // Run updateName
        final success = await manager.updateName('Updated Name');
        expect(success, isTrue);
        
        // Verify state is updated
        expect(manager.user?['name'], equals('Updated Name'));
        expect(wasNotified, isTrue);

        // Verify shared preferences is updated
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString("user_name"), equals("Updated Name"));

      }, MockHttpOverrides(mockBackendResponse));
    });
  });
}
