import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {

  // ✅ YOUR PC WIFI IP
  static const String localIp = "http://192.168.29.108:8000";

  // 🌐 BASE URL
  static String get baseUrl {

    // Web
    if (kIsWeb) {
      return "http://127.0.0.1:8000";
    }

    // Android Emulator
    if (defaultTargetPlatform == TargetPlatform.android) {
      return localIp;
    }

    // iOS
    if (defaultTargetPlatform == TargetPlatform.iOS) {
       return "http://localhost:8000";
    }

    // Other
    return localIp;
  }

  // 🔐 TOKEN
  static String? token;

  // 📌 HEADERS
  static Map<String, String> get headers {
    return {
      "Content-Type": "application/json",
      if (token != null)
        "Authorization": "Bearer $token",
    };
  }

  // ===========================
  // 🟢 GET
  // ===========================
  static Future<dynamic> get(String endpoint) async {

    final url = Uri.parse("$baseUrl/$endpoint");

    debugPrint("GET URL: $url");

    final response = await http.get(
      url,
      headers: headers,
    );

    return _handleResponse(response);
  }

  // ===========================
  // 🔵 POST
  // ===========================
  static Future<dynamic> post(
      String endpoint,
      Map data,
      ) async {

    final url = Uri.parse("$baseUrl/$endpoint");

    debugPrint("POST URL: $url");
    debugPrint("BODY: ${jsonEncode(data)}");

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(data),
    );

    return _handleResponse(response);
  }

  // ===========================
  // 🟡 PUT
  // ===========================
  static Future<dynamic> put(
      String endpoint,
      Map data,
      ) async {

    final url = Uri.parse("$baseUrl/$endpoint");

    final response = await http.put(
      url,
      headers: headers,
      body: jsonEncode(data),
    );

    return _handleResponse(response);
  }

  // ===========================
  // 🔴 DELETE
  // ===========================
  static Future<dynamic> delete(String endpoint) async {

    final url = Uri.parse("$baseUrl/$endpoint");

    final response = await http.delete(
      url,
      headers: headers,
    );

    return _handleResponse(response);
  }

  // ===========================
  // ⚠️ RESPONSE HANDLER
  // ===========================
  static dynamic _handleResponse(http.Response response) {

    debugPrint("STATUS: ${response.statusCode}");
    debugPrint("RESPONSE: ${response.body}");

    dynamic data;

    try {
      data = jsonDecode(response.body);
    } catch (e) {
      throw Exception("Invalid server response");
    }

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return data;
    }

    throw Exception(
      data["error"] ??
          data["message"] ??
          "API Error (${response.statusCode})",
    );
  }
}