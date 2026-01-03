import 'package:shared_preferences/shared_preferences.dart';

class YouTubeCookieService {
  static const String _cookieKey = 'youtube_cookies';
  static const String _uaKey = 'youtube_user_agent';
  static const String _poTokenKey = 'youtube_po_token';
  static final YouTubeCookieService _instance =
      YouTubeCookieService._internal();

  factory YouTubeCookieService() {
    return _instance;
  }

  YouTubeCookieService._internal();

  Future<void> saveCookies(String cookies) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cookieKey, cookies);
  }

  Future<void> saveUserAgent(String ua) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_uaKey, ua);
  }

  Future<void> savePoToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_poTokenKey, token);
  }

  Future<String?> getCookies() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_cookieKey);
  }

  Future<String?> getUserAgent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_uaKey);
  }

  Future<String?> getPoToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_poTokenKey);
  }

  Future<void> clearCookies() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cookieKey);
    await prefs.remove(_uaKey);
    await prefs.remove(_poTokenKey);
  }

  Future<bool> hasCookies() async {
    final cookies = await getCookies();
    return cookies != null && cookies.isNotEmpty;
  }

  /// Helper to convert cookie string to a Map for headers if needed
  Future<Map<String, String>> getCookieHeaders() async {
    final cookies = await getCookies();
    if (cookies == null) return {};
    return {'Cookie': cookies};
  }
}
