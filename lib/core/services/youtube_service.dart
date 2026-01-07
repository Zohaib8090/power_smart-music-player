import 'dart:convert';
import 'dart:io';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:http/http.dart' as http;
import 'package:get_it/get_it.dart';
import 'package:flutter/services.dart';
import 'settings_service.dart';
import 'webview_extractor.dart';
import 'youtube_cookie_service.dart';

class YouTubeService {
  // 1. Consistent User-Agent is KEY to avoiding 403 Forbidden errors
  static const String browserUserAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

  late final YoutubeExplode _yt;

  // 2. Concurrency Lock: Prevents the "5 attempts in 4 seconds" spam
  final Set<String> _activeExtractions = {};

  YouTubeService() {
    _yt = YoutubeExplode();
  }

  // NOTE: Replace this key immediately as it was exposed in logs!
  static const String _youtubeApiKey =
      "AIzaSyAyWLs9wViOYKqNIoE_WumDb4qHjrKl914";
  static const String _pythonBackendUrl =
      "https://web-backend-3wfv.onrender.com";

  Future<Map<String, dynamic>?> getAudioUrl(String videoId) async {
    // Stop duplicate requests for the same ID
    if (_activeExtractions.contains(videoId)) {
      print("⚠️ Already extracting $videoId, skipping duplicate call.");
      return null;
    }
    _activeExtractions.add(videoId);

    try {
      final mode = GetIt.I<SettingsService>().extractionMode;
      print("🚀 Extraction Mode: $mode");

      switch (mode) {
        case ExtractionMode.native:
          return await _extractNative(videoId);
        case ExtractionMode.backend:
          return await _extractViaBackend(videoId);
        case ExtractionMode.webview:
          return await _extractViaWebView(videoId);
        case ExtractionMode.newPipe:
          return await _extractNewPipe(videoId);
      }
    } catch (e) {
      print("❌ Extraction Error ($videoId): $e");
      // The provided snippet seems to be trying to add UI-related error handling here,
      // but this class (YouTubeService) should ideally only handle extraction logic
      // and propagate exceptions or return null.
      // The UI update logic (like `extractionStatus.add` or `playbackState.add`)
      // should reside in the `AudioPlayerHandler` or a higher-level service that
      // calls `getAudioUrl`.
      // For now, I'm keeping the original `return null;` as this class's responsibility.
      return null;
    } finally {
      _activeExtractions.remove(videoId);
    }
  }

  // Improved Native Extractor with proper Headers
  Future<Map<String, dynamic>?> _extractNative(String videoId) async {
    try {
      // Mimic the same identity for both extraction and playback
      var manifest = await _yt.videos.streamsClient.getManifest(videoId);
      var audioStream = manifest.audioOnly.withHighestBitrate();

      var video = await _yt.videos.get(videoId);

      // CRITICAL: Use Android User-Agent for Native (Mobile) Extraction
      // Windows UA here causes 403 on playback because signature assumes mobile client
      final mobileUserAgent =
          'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Mobile Safari/537.36';

      return {
        'stream_url': audioStream.url.toString(),
        'duration': video.duration?.inSeconds ?? 0,
        'title': video.title,
        'artist': video.author,
        'headers': {
          'User-Agent': mobileUserAgent,
          'Referer': 'https://www.youtube.com/',
        },
      };
    } catch (e) {
      print("Native Error: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> _extractViaBackend(String videoId) async {
    try {
      final response = await http
          .get(
            Uri.parse("$_pythonBackendUrl/extract?id=$videoId"),
            headers: {
              'User-Agent': browserUserAgent,
              'Referer': 'https://www.youtube.com/',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print("Backend Error: $e");
    }
    return null;
  }

  Future<Map<String, dynamic>?> _extractViaWebView(String videoId) async {
    print("Attempting WebView Extraction for $videoId...");
    try {
      final result = await WebViewExtractor().extractStream(videoId);
      if (result != null) {
        // Fetch metadata separately (optional, but good for UI)
        var title = "Unknown";
        var artist = "Unknown";
        var duration = 0;
        try {
          var video = await _yt.videos.get(videoId);
          title = video.title;
          artist = video.author;
          duration = video.duration?.inSeconds ?? 0;
        } catch (_) {}

        return {
          'stream_url': result['stream_url'],
          'duration':
              duration, // WebView doesn't provide this, so we default or fetch
          'title': title,
          'artist': artist,
          'headers': {
            'User-Agent': result['user_agent'],
            'Referer': 'https://www.youtube.com/',
          },
        };
      }
    } catch (e) {
      print("WebView Error: $e");
    }
    return null;
  }

  static const _platform = MethodChannel('extractor_channel');

  Future<Map<String, dynamic>?> _extractNewPipe(String videoId) async {
    if (!Platform.isAndroid) {
      print("NewPipe is Android only.");
      return null;
    }
    print("Attempting NewPipe Extraction for $videoId...");
    try {
      // Get authenticated cookies if available
      String? cookies = await YoutubeCookieService().getCookieHeader();
      print("🔐 Authenticated Cookies Present: ${cookies != null}");

      final Map<dynamic, dynamic>? result = await _platform.invokeMethod(
        'extract',
        {'videoId': videoId, 'cookies': cookies},
      );

      if (result != null) {
        return {
          'stream_url': result['url'],
          'title': result['title'] ?? 'Unknown',
          'artist': result['uploader'] ?? 'Unknown',
          'duration': result['duration'] ?? 0,
          'headers': {'User-Agent': result['userAgent'] ?? browserUserAgent},
        };
      }
    } catch (e) {
      print("NewPipe MethodChannel Error: $e");
      rethrow; // Propagate PlatformException for better diagnostics
    }
    // Added to satisfy lint, though rethrow should prevent reaching here
    return null;
  }

  // --- Search Logic ---
  Future<List<Video>> searchVideos(String query) async {
    if (Platform.isWindows) {
      return _searchWithApi(query);
    } else {
      try {
        final searchList = await _yt.search.search(query);
        return searchList.toList();
      } catch (e) {
        print("Search Error: $e");
        return [];
      }
    }
  }

  Future<List<Video>> _searchWithApi(String query) async {
    // API logic remains largely the same, but ensure you use a fresh Key
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
    } catch (_) {}
    return [];
  }

  void dispose() {
    _yt.close();
  }
}
