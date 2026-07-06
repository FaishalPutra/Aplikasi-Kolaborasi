import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

// Base URL backend. Default: web pakai localhost, Android emulator pakai 10.0.2.2.
// Untuk build production, override lewat --dart-define=API_BASE_URL=https://xxx.up.railway.app/api
const String _apiBaseUrlOverride = String.fromEnvironment('API_BASE_URL');
final String baseUrl = _apiBaseUrlOverride.isNotEmpty
    ? _apiBaseUrlOverride
    : (kIsWeb ? 'http://localhost:3000/api' : 'http://10.0.2.2:3000/api');

// Token sesi (JWT) hasil login. Disetel oleh modul auth.
String? authToken;

Map<String, String> _headers() => {
      'Content-Type': 'application/json',
      if (authToken != null) 'Authorization': 'Bearer $authToken',
    };

Future<dynamic> apiGet(String path) async {
  final res = await http.get(Uri.parse('$baseUrl$path'), headers: _headers());
  return jsonDecode(res.body);
}

Future<dynamic> apiPost(String path, Map<String, dynamic> body) async {
  final res = await http.post(
    Uri.parse('$baseUrl$path'),
    headers: _headers(),
    body: jsonEncode(body),
  );
  return jsonDecode(res.body);
}

Future<dynamic> apiPut(String path, Map<String, dynamic> body) async {
  final res = await http.put(
    Uri.parse('$baseUrl$path'),
    headers: _headers(),
    body: jsonEncode(body),
  );
  return jsonDecode(res.body);
}

Future<dynamic> apiPatch(String path, Map<String, dynamic> body) async {
  final res = await http.patch(
    Uri.parse('$baseUrl$path'),
    headers: _headers(),
    body: jsonEncode(body),
  );
  return jsonDecode(res.body);
}

Future<dynamic> apiDelete(String path) async {
  final res = await http.delete(Uri.parse('$baseUrl$path'), headers: _headers());
  return jsonDecode(res.body);
}
