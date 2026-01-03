import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'youtube_cookie_service.dart';

class LocalExtractor {
  static final LocalExtractor _instance = LocalExtractor._internal();
  factory LocalExtractor() => _instance;
  LocalExtractor._internal();

  static const String _ytdlpUrl =
      'https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe';

  Future<String?> getBinaryPath() async {
    final dir = await getApplicationSupportDirectory();
    final file = File('${dir.path}/yt-dlp.exe');
    if (await file.exists()) {
      return file.path;
    }
    return null;
  }

  Future<void> ensureBinaryExists() async {
    final path = await getBinaryPath();
    if (path == null) {
      print('Downloading yt-dlp.exe...');
      final dir = await getApplicationSupportDirectory();
      final response = await http.get(Uri.parse(_ytdlpUrl));
      if (response.statusCode == 200) {
        final file = File('${dir.path}/yt-dlp.exe');
        await file.writeAsBytes(response.bodyBytes);
        print('yt-dlp.exe downloaded to ${file.path}');
      }
    }
  }

  Future<String?> extractAudioUrl(String videoId) async {
    final binaryPath = await getBinaryPath();
    if (binaryPath == null) {
      await ensureBinaryExists();
    }

    final finalPath = await getBinaryPath();
    if (finalPath == null) return null;

    final cookieString = await YouTubeCookieService().getCookies();

    // yt-dlp prefers Netscape format, but can sometimes parse flat headers if formatted correctly
    // However, we can also just pass --add-header "Cookie: ..."

    List<String> args = [
      '--get-url',
      '--format',
      'bestaudio',
      '--no-playlist',
      'https://www.youtube.com/watch?v=$videoId',
    ];

    if (cookieString != null && cookieString.isNotEmpty) {
      // We can try passing as a header since we have a flat string from document.cookie
      args.addAll(['--add-header', 'Cookie: $cookieString']);
    }

    // Add User-Agent and Referer to look more like a browser
    args.addAll([
      '--user-agent',
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      '--referer',
      'https://www.youtube.com/',
    ]);

    try {
      final result = await Process.run(finalPath, args);
      if (result.exitCode == 0) {
        final output = result.stdout.toString().trim();
        // Sometimes it returns multiple URLs (if multiple formats found), take first
        return output.split('\n').first;
      } else {
        print('yt-dlp error: ${result.stderr}');
        return null;
      }
    } catch (e) {
      print('Local extraction error: $e');
      return null;
    }
  }
}
