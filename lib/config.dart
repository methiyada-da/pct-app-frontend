// config.dart
// ตั้งค่ากลางของแอป — แก้ที่นี่ที่เดียวเมื่อ IP หรือ path เปลี่ยน

/// Override with: flutter run --dart-define=API_BASE_URL=https://example.com/api
const String kBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://127.0.0.1/mini_backend',
);

const Duration kApiTimeout = Duration(seconds: 15);

Map<String, String> apiHeaders([Map<String, dynamic>? session]) {
  final headers = <String, String>{'Content-Type': 'application/json'};
  final token = session?['_token']?.toString();
  if (token != null && token.isNotEmpty) {
    headers['Authorization'] = 'Bearer $token';
  }
  return headers;
}

Map<String, dynamic> attachToken(Map<String, dynamic> user, dynamic token) {
  if (token != null && token.toString().isNotEmpty) {
    user['_token'] = token.toString();
  }
  return user;
}
