import 'dart:convert';
import 'dart:io';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:http/http.dart' as http;
import 'local_extractor.dart';
import 'webview_extractor.dart';
import 'youtube_cookie_service.dart';

class YouTubeService {
  // Use a very standard Windows Chrome User-Agent
  static const String browserUserAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

  late final YoutubeExplode _yt;

  YouTubeService() {
    _yt = YoutubeExplode();
  }

  // YouTube Data API v3 Key - for Windows
  static const String _youtubeApiKey =
      "AIzaSyAyWLs9wViOYKqNIoE_WumDb4qHjrKl914";

  Future<List<Video>> searchVideos(String query) async {
    if (Platform.isWindows) {
      return _searchWithApi(query);
    } else {
      return _searchNative(query);
    }
  }

  // Production Backend URL (Live Render Python Extractor)
  static const String _pythonBackendUrl =
      "https://web-backend-3wfv.onrender.com";

  Future<Map<String, dynamic>?> getAudioUrl(String videoId) async {
    // ------------------------------------------------------------------------------
    // STRATEGY: Backend First -> Fallback to Local/WebView
    // ------------------------------------------------------------------------------

    // 1. Try Backend Extraction (Prioritized)
    print("Attempting Backend Extraction for $videoId...");
    try {
      final backendResult = await _extractViaBackend(videoId);
      if (backendResult != null) {
        print("✅ Backend Extraction Success!");
        return backendResult;
      }
    } catch (e) {
      print("⚠️ Backend Extraction Failed (will try local fallback): $e");
    }

    // 2. Fallback: Local Extraction (Windows) or WebView (Mobile)
    print("Falling back to Local/WebView Extraction...");

    if (Platform.isWindows) {
      // Windows Local Fallback
      try {
        final localUrl = await LocalExtractor().extractAudioUrl(videoId);
        if (localUrl != null) {
          int duration = 0;
          try {
            var video = await _yt.videos.get(videoId);
            duration = video.duration?.inSeconds ?? 0;
          } catch (_) {}
          return {
            'stream_url': localUrl,
            'duration': duration,
            'title': '',
            'artist': '',
          };
        }
      } catch (e) {
        print("❌ Windows Local Fallback Failed: $e");
      }
    } else {
      // Mobile WebView Fallback
      try {
        final webViewResult = await WebViewExtractor().extractStream(videoId);
        if (webViewResult != null) {
          int duration = 0;
          try {
            var video = await _yt.videos.get(videoId);
            duration = video.duration?.inSeconds ?? 0;
          } catch (_) {}

          return {
            'stream_url': webViewResult['stream_url'],
            'duration': duration,
            'title': '',
            'artist': '',
            'headers': {'User-Agent': webViewResult['user_agent']},
          };
        }
      } catch (e) {
        print("❌ Mobile WebView Fallback Failed: $e");
      }
    }

    print("❌ All extraction methods failed for $videoId");
    return null;
  }

  // Helper method for the backend logic to keep code clean
  Future<Map<String, dynamic>?> _extractViaBackend(String videoId) async {
    // 2. Fallback or Mobile: Use Render Backend
    int retryCount = 0;
    const int maxRetries = 1; // Lower retries since we have a fallback

    while (retryCount <= maxRetries) {
      try {
        final cookieService = YouTubeCookieService();
        final cookieHeaders = await cookieService.getCookieHeaders();
        final savedUa = await cookieService.getUserAgent();
        final poToken = await cookieService.getPoToken();

        final response = await http
            .get(
              Uri.parse("$_pythonBackendUrl/extract?id=$videoId"),
              headers: {
                ...cookieHeaders,
                'User-Agent': savedUa ?? browserUserAgent,
                'Referer': 'https://www.youtube.com/',
                if (poToken != null && poToken.isNotEmpty)
                  'X-PO-Token': poToken,
              },
            )
            .timeout(const Duration(seconds: 40));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['stream_url'] != null) {
            return data; // Return full map
          }
          throw Exception(
            data['error'] ?? "Backend returned success but no URL",
          );
        }

        if (response.statusCode == 500) {
          final data = json.decode(response.body);
          String error = data['error'] ?? "";
          if (error.contains("Sign in to confirm you're not a bot")) {
            // This is critical, but we can try fallback.
            print("🛑 Identity verification required (Bot suspected).");
          }
          throw Exception(error);
        }

        throw Exception("Server responded with status: ${response.statusCode}");
      } catch (e) {
        retryCount++;
        print("Backend attempt $retryCount failed: $e");
        if (retryCount > maxRetries)
          rethrow; // Pass error up to trigger fallback
        await Future.delayed(Duration(seconds: 1));
      }
    }
    return null;
  }

  // --- Native Implementation ---
  Future<List<Video>> _searchNative(String query) async {
    try {
      final searchList = await _yt.search.search(query);
      return searchList.toList();
    } catch (e) {
      print("Error searching YouTube (Native): $e");
      return [];
    }
  }

  // --- Windows API Implementation ---
  Future<List<Video>> _searchWithApi(String query) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://www.googleapis.com/youtube/v3/search?part=snippet&q=$query&type=video&maxResults=10&key=$_youtubeApiKey',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List items = data['items'] ?? [];

        return items.map((item) {
          final snippet = item['snippet'];
          return Video(
            VideoId(item['id']['videoId']),
            snippet['title'],
            snippet['channelTitle'],
            ChannelId(snippet['channelId']),
            null,
            null,
            null,
            snippet['description'] ?? '',
            null,
            ThumbnailSet(item['id']['videoId']),
            [],
            Engagement(0, 0, 0),
            false,
          );
        }).toList();
      }
      return [];
    } catch (e) {
      print("Error searching YouTube (API): $e");
      return [];
    }
  }

  void dispose() {
    _yt.close();
  }
}
