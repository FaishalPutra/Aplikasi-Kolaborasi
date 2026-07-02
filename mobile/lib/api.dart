import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

// Base URL backend. Web (Chrome) pakai localhost; Android emulator pakai 10.0.2.2.
final String baseUrl =
    kIsWeb ? 'http://localhost:3000/api' : 'http://10.0.2.2:3000/api';

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

Future<dynamic> apiPatch(String path, Map<String, dynamic> body) async {
  final res = await http.patch(
    Uri.parse('$baseUrl$path'),
    headers: _headers(),
    body: jsonEncode(body),
  );
  return jsonDecode(res.body);
}
