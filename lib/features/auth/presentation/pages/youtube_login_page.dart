import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../../../../core/services/youtube_cookie_service.dart';

class YoutubeLoginPage extends StatefulWidget {
  const YoutubeLoginPage({super.key});

  @override
  State<YoutubeLoginPage> createState() => _YoutubeLoginPageState();
}

class _YoutubeLoginPageState extends State<YoutubeLoginPage> {
  final GlobalKey webViewKey = GlobalKey();
  InAppWebViewController? webViewController;
  final YoutubeCookieService _cookieService = YoutubeCookieService();
  bool _isLoading = true;

  // The URL to trigger the Google Login flow for YouTube
  final String _loginUrl =
      "https://accounts.google.com/ServiceLogin?service=youtube&continue=https://www.youtube.com/favicon.ico";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sign in to YouTube"),
        backgroundColor: Colors.red,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              webViewController?.reload();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          InAppWebView(
            key: webViewKey,
            initialUrlRequest: URLRequest(url: WebUri(_loginUrl)),
            initialSettings: InAppWebViewSettings(
              userAgent:
                  "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36",
              javaScriptEnabled: true,
              domStorageEnabled: true, // Critical for login sessions
              thirdPartyCookiesEnabled: true,
            ),
            onWebViewCreated: (controller) {
              webViewController = controller;
            },
            onLoadStart: (controller, url) {
              setState(() {
                _isLoading = true;
              });
            },
            onLoadStop: (controller, url) async {
              setState(() {
                _isLoading = false;
              });

              if (url != null) {
                print("WebView URL: $url");
                // Check if login completed
                if (url.toString().contains("favicon.ico") ||
                    url.toString().contains("youtube.com") &&
                        !url.toString().contains("ServiceLogin")) {
                  // Attempt to extract cookies
                  print(
                    "Login potential success detected. Extracting cookies...",
                  );
                  final count = await _cookieService.extractCookiesFromWebView(
                    url.toString(),
                  );

                  if (count > 0 && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Successfully signed in! ($count cookies captured)",
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.of(context).pop(true); // Return success
                  }
                }
              }
            },
          ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Colors.red)),
        ],
      ),
    );
  }
}
