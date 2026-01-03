import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_windows/webview_windows.dart' as win;
import '../../../../core/services/youtube_cookie_service.dart';

class YouTubeLoginPage extends StatefulWidget {
  const YouTubeLoginPage({super.key});

  @override
  State<YouTubeLoginPage> createState() => _YouTubeLoginPageState();
}

class _YouTubeLoginPageState extends State<YouTubeLoginPage> {
  // Mobile Controller
  late final WebViewController _mobileController;

  // Windows Controller
  final _winController = win.WebviewController();
  bool _isWinInitialized = false;

  @override
  void initState() {
    super.initState();
    if (!Platform.isWindows) {
      _initMobile();
    } else {
      _initWindows();
    }
  }

  void _initMobile() {
    _mobileController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) async {
            // Check for cookies when page finishes
            final cookies =
                await _mobileController.runJavaScriptReturningResult(
                      'document.cookie',
                    )
                    as String;

            if (cookies.contains('LOGIN_INFO') ||
                cookies.contains('VISITOR_INFO1_LIVE')) {
              // Also capture the exact User-Agent used by this WebView
              final ua =
                  await _mobileController.runJavaScriptReturningResult(
                        'navigator.userAgent',
                      )
                      as String;

              // Capture possible PO token markers from ytcfg
              final poToken =
                  await _mobileController.runJavaScriptReturningResult(
                        'try { (function(){ if(window.ytcfg) { return window.ytcfg.get("VISITOR_DATA") || window.ytcfg.get("PO_TOKEN") || ""; } return ""; })() } catch(e){ "" }',
                      )
                      as String;

              final cookieService = YouTubeCookieService();
              await cookieService.saveCookies(cookies.replaceAll('"', ''));
              await cookieService.saveUserAgent(ua.replaceAll('"', ''));

              if (poToken.isNotEmpty && poToken != '""' && poToken != 'null') {
                await cookieService.savePoToken(poToken.replaceAll('"', ''));
              }

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('YouTube login captured!')),
                );
                Navigator.pop(context, true);
              }
            }
          },
        ),
      )
      ..loadRequest(
        Uri.parse(
          'https://accounts.google.com/ServiceLogin?service=youtube&uilel=3&continue=https://www.youtube.com/signin?next=/',
        ),
      );
  }

  Future<void> _initWindows() async {
    try {
      await _winController.initialize();
      await _winController.setPopupWindowPolicy(
        win.WebviewPopupWindowPolicy.deny,
      );
      await _winController.loadUrl(
        'https://accounts.google.com/ServiceLogin?service=youtube&uilel=3&continue=https://www.youtube.com/signin?next=/',
      );

      _winController.url.listen((url) async {
        // Evaluate JS to get cookies on Windows
        final cookies = await _winController.executeScript('document.cookie');
        if (cookies.contains('LOGIN_INFO') ||
            cookies.contains('VISITOR_INFO1_LIVE')) {
          final ua = await _winController.executeScript('navigator.userAgent');
          final cookieService = YouTubeCookieService();
          await cookieService.saveCookies(cookies.replaceAll('"', ''));
          await cookieService.saveUserAgent(ua.replaceAll('"', ''));

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('YouTube login captured!')),
            );
            Navigator.pop(context, true);
          }
        }
      });

      if (mounted) {
        setState(() {
          _isWinInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Windows WebView Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login to YouTube'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Platform.isWindows
          ? (_isWinInitialized
                ? win.Webview(_winController)
                : const Center(child: CircularProgressIndicator()))
          : WebViewWidget(controller: _mobileController),
    );
  }

  @override
  void dispose() {
    if (Platform.isWindows) {
      _winController.dispose();
    }
    super.dispose();
  }
}
