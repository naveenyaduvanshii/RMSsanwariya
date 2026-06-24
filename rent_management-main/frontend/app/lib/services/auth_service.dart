import 'api_service.dart';

class AuthService {
  //////////////////////////////////////////////////////
  // DIRECT LOGIN (NO OTP)
  //////////////////////////////////////////////////////

  static Future<Map<String, dynamic>> login(String identifier) async {
    try {
      // Assuming your ApiService.post handles the full URL and JSON encoding
      final response = await ApiService.post(
        "api/login/",
        {"email": identifier},
      );

      print("LOGIN RESPONSE: $response");

      if (response["success"] == true && response["user"] != null) {
        final user = response["user"];

        return {
          "success": true,
          "message": response["message"] ?? "Login successful",
          "user": user, // Returning the user object for navigation logic
        };
      }

      return {
        "success": false,
        "error": response["error"] ?? "Login failed",
      };

    } catch (e) {
      return {
        "success": false,
        "error": e.toString(),
      };
    }
  }
}