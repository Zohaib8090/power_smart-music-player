import 'dart:convert';
import 'dart:io';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:http/http.dart' as http;

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

  Future<String?> getAudioUrl(String videoId) async {
    int retryCount = 0;
    const int maxRetries = 2;

    while (retryCount <= maxRetries) {
      try {
        final response = await http
            .get(Uri.parse("$_pythonBackendUrl/extract?id=$videoId"))
            .timeout(
              const Duration(seconds: 40),
            ); // Increased for Render cold start

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['stream_url'] != null) {
            return data['stream_url'] as String;
          }
          throw Exception(
            data['error'] ?? "Backend returned success but no URL",
          );
        }

        throw Exception("Server responded with status: ${response.statusCode}");
      } catch (e) {
        retryCount++;
        print("Extraction attempt $retryCount failed for $videoId: $e");

        if (retryCount > maxRetries) {
          return null; // Let the UI handle the failure
        }
        // Exponential backoff
        await Future.delayed(Duration(seconds: 2 * retryCount));
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
