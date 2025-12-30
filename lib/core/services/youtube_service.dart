import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:http/http.dart' as http;

class YouTubeService {
  final YoutubeExplode _yt = YoutubeExplode();

  // TODO: Replace with your Render deployed URL later
  static const String _backendUrl = "http://localhost:3000";

  Future<List<Video>> searchVideos(String query) async {
    if (kIsWeb) {
      return _searchWeb(query);
    } else {
      return _searchNative(query);
    }
  }

  Future<String?> getAudioUrl(String videoId) async {
    if (kIsWeb) {
      // For Web, return our server's stream URL directly
      return "$_backendUrl/audio?id=$videoId";
    } else {
      return _getAudioNative(videoId);
    }
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

  Future<String?> _getAudioNative(String videoId) async {
    try {
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);
      final audioOnly = manifest.audioOnly;
      if (audioOnly.isEmpty) return null;
      return audioOnly.withHighestBitrate().url.toString();
    } catch (e) {
      print("Error getting audio URL (Native): $e");
      return null;
    }
  }

  // --- Web Implementation ---
  Future<List<Video>> _searchWeb(String query) async {
    try {
      final response = await http.get(
        Uri.parse("$_backendUrl/search?q=$query"),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        // Map JSON back to Video objects
        // Constructor likely: Video(id, title, author, channelId, uploadDate, uploadDateRaw, publishDate, description, duration, thumbnails, keywords, engagement, isLive)
        // We will try to pass logical defaults or nulls.
        return data
            .map(
              (json) => Video(
                VideoId(json['id']),
                json['title'],
                json['author'],
                ChannelId(''),
                null, // uploadDate (DateTime?)
                null, // uploadDateRaw (String?)
                null, // publishDate (DateTime?)
                '', // description (String?)
                null, // duration (Duration?)
                ThumbnailSet(json['thumbnail']),
                [], // keywords (Iterable<String>)
                Engagement(0, 0, 0),
                false, // isLive
              ),
            )
            .toList();
      }
      return [];
    } catch (e) {
      print("Error searching YouTube (Web): $e");
      return [];
    }
  }

  void dispose() {
    _yt.close();
  }
}
