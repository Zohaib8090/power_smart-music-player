import 'dart:io';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class YoutubeCookieService {
  static final YoutubeCookieService _instance =
      YoutubeCookieService._internal();
  factory YoutubeCookieService() => _instance;
  YoutubeCookieService._internal();

  final _storage = const FlutterSecureStorage();
  static const _kCookiesKey = 'youtube_cookies_netscape';

  // Important cookies to capture
  static const List<String> _kImportantCookies = [
    'SAPISID',
    'HSID',
    'SSID',
    'SID',
    'LOGIN_INFO',
    '__Secure-3PSID',
    '__Secure-3PAPISID',
  ];

  /// Extract cookies from the given [url] using [CookieManager].
  /// Returns count of new cookies found.
  Future<int> extractCookiesFromWebView(String url) async {
    final cookieManager = CookieManager.instance();
    final cookies = await cookieManager.getCookies(url: WebUri(url));

    if (cookies.isEmpty) return 0;

    // Filter and format cookies
    final cookieLines = <String>['# Netscape HTTP Cookie File'];

    int importantFound = 0;
    for (var cookie in cookies) {
      if (_kImportantCookies.contains(cookie.name)) {
        importantFound++;
      }

      // Format: domain, include_subdomains, path, secure, expiry, name, value
      final domain = cookie.domain?.startsWith('.') == true
          ? cookie.domain
          : '.${cookie.domain}';
      final includeSubdomains = 'TRUE';
      final path = cookie.path ?? '/';
      final secure = cookie.isSecure == true ? 'TRUE' : 'FALSE';
      final expiry = cookie.expiresDate != null
          ? (cookie.expiresDate! / 1000).round().toString()
          : (DateTime.now()
                        .add(const Duration(days: 365))
                        .millisecondsSinceEpoch /
                    1000)
                .round()
                .toString();

      cookieLines.add(
        '$domain\t$includeSubdomains\t$path\t$secure\t$expiry\t${cookie.name}\t${cookie.value}',
      );
    }

    // Save only if we found meaningful cookies
    if (cookieLines.length > 1) {
      final netscapeString = cookieLines.join('\n');
      await _storage.write(key: _kCookiesKey, value: netscapeString);
      print(
        "🍪 Saved ${cookieLines.length - 1} cookies (Important: $importantFound)",
      );
      return cookieLines.length - 1;
    }

    return 0;
  }

  /// Get the Netscape cookie file content string.
  Future<String?> getNetscapeCookies() async {
    return await _storage.read(key: _kCookiesKey);
  }

  /// Get cookies formatted for HTTP Cookie header.
  /// Format: key1=value1; key2=value2
  Future<String?> getCookieHeader() async {
    final netscapeContent = await getNetscapeCookies();
    if (netscapeContent == null) return null;

    final lines = netscapeContent.split('\n');
    final Map<String, String> cookieMap = {};

    for (var line in lines) {
      if (line.trim().isEmpty || line.startsWith('#')) continue;

      final parts = line.split('\t');
      if (parts.length >= 7) {
        cookieMap[parts[5]] = parts[6];
      }
    }

    if (cookieMap.isEmpty) return null;

    return cookieMap.entries.map((e) => '${e.key}=${e.value}').join('; ');
  }

  Future<bool> isAuthenticated() async {
    final cookies = await getNetscapeCookies();
    // A simple check is looking for a SID or LOGIN_INFO
    return cookies != null &&
        (cookies.contains('SID') || cookies.contains('LOGIN_INFO'));
  }

  Future<void> clearCookies() async {
    await _storage.delete(key: _kCookiesKey);
    final cookieManager = CookieManager.instance();
    await cookieManager.deleteAllCookies();
    print("🍪 Cookies cleared.");
  }
}
