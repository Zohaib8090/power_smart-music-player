import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewExtractor {
  static final WebViewExtractor _instance = WebViewExtractor._internal();
  factory WebViewExtractor() => _instance;

  late final WebViewController _controller;
  bool _isInitialized = false;

  WebViewExtractor._internal() {
    _initController();
  }

  void _initController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36",
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            print("WebViewExtractor: Page loaded: $url");
          },
          onWebResourceError: (error) {
            print("WebViewExtractor error: ${error.description}");
          },
        ),
      );
    _isInitialized = true;
  }

  /// Returns the widget to be mounted in the widget tree (hidden).
  Widget buildHiddenWebView() {
    if (!_isInitialized) _initController();
    return SizedBox(
      width: 1,
      height: 1,
      child: WebViewWidget(controller: _controller),
    );
  }

  /// Extract the audio/stream URL for a given videoId.
  Future<Map<String, dynamic>?> extractStream(String videoId) async {
    final completer = Completer<Map<String, dynamic>?>();

    // Safety timeout
    final timeoutTimer = Timer(const Duration(seconds: 15), () {
      if (!completer.isCompleted) {
        print("WebViewExtractor: Timeout reached.");
        completer.complete(null);
      }
    });

    try {
      print("WebViewExtractor: Loading video $videoId");
      // Load the video page
      _controller.loadRequest(
        Uri.parse('https://m.youtube.com/watch?v=$videoId'),
      );

      // Start polling immediately (and continue as page loads)
      _pollForVideoSrc(_controller, completer);
    } catch (e) {
      print("WebViewExtractor Request Error: $e");
      if (!completer.isCompleted) completer.complete(null);
    }

    return completer.future.whenComplete(() => timeoutTimer.cancel());
  }

  void _pollForVideoSrc(
    WebViewController controller,
    Completer<Map<String, dynamic>?> completer,
  ) async {
    int attempts = 0;
    // Check every 500ms for 25 attempts (12.5 seconds effective polling)
    while (!completer.isCompleted && attempts < 25) {
      if (attempts > 0) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
      attempts++;

      try {
        final result = await controller.runJavaScriptReturningResult('''
          (function() {
            var video = document.querySelector('video');
            if (video) {
              video.muted = true; 
              return video.src;
            }
            return "";
          })();
        ''');

        var src = result.toString();
        if (src.startsWith('"') && src.endsWith('"')) {
          src = src.substring(1, src.length - 1);
        }

        // print("WebViewExtractor poll ($attempts): $src"); // verbose

        if (src.isNotEmpty && src.startsWith("http")) {
          // Success!
          completer.complete({
            'stream_url': src,
            'user_agent':
                "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36",
          });
          return;
        }

        // Auto-play attempt
        if (attempts % 5 == 0) {
          await controller.runJavaScript('''
              var video = document.querySelector('video');
              if (video) video.play();
            ''');
        }
      } catch (e) {
        // print("WebViewExtractor poll error: $e");
      }
    }
  }
}
