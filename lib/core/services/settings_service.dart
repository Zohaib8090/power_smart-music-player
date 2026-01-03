import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  static const String _dvcKey = 'dvc_enabled';
  static const String _resamplerKey = 'resampler_mode';
  static const String _outputPluginKey = 'output_plugin';
  static const String _chromecastKey = 'chromecast_enabled';
  static const String _crossfadeKey = 'crossfade_duration';
  static const String _fadeKey = 'fade_duration';
  static const String _gaplessKey = 'gapless_playback';
  static const String _bitDepthKey = 'audio_bit_depth';
  static const String _sampleRateKey = 'audio_sample_rate';
  static const String _userNameKey = 'user_name';
  static const String _avatarPathKey = 'avatar_path';

  ThemeMode _themeMode = ThemeMode.system;
  bool _dvcEnabled = true;
  String _resamplerMode = 'Sinc';
  String _outputPlugin = 'AAudio';
  bool _chromecastEnabled = false;
  int _crossfadeDuration = 0;
  int _fadeDuration = 0;
  bool _gaplessPlayback = true;
  String _audioBitDepth = '16';
  String _audioSampleRate = '44.1';
  String _userName = 'Zohaib';
  String _avatarPath = '';

  ThemeMode get themeMode => _themeMode;
  bool get dvcEnabled => _dvcEnabled;
  String get resamplerMode => _resamplerMode;
  String get outputPlugin => _outputPlugin;
  bool get chromecastEnabled => _chromecastEnabled;
  int get crossfadeDuration => _crossfadeDuration;
  int get fadeDuration => _fadeDuration;
  bool get gaplessPlayback => _gaplessPlayback;
  String get audioBitDepth => _audioBitDepth;
  String get audioSampleRate => _audioSampleRate;
  String get userName => _userName;
  String get avatarPath => _avatarPath;

  SettingsService() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Theme
    final themeIndex = prefs.getInt(_themeModeKey);
    if (themeIndex != null) {
      _themeMode = ThemeMode.values[themeIndex];
    }

    // Advanced Audio
    _dvcEnabled = prefs.getBool(_dvcKey) ?? true;
    _resamplerMode = prefs.getString(_resamplerKey) ?? 'Sinc';
    _outputPlugin = prefs.getString(_outputPluginKey) ?? 'AAudio';
    _chromecastEnabled = prefs.getBool(_chromecastKey) ?? false;
    _crossfadeDuration = prefs.getInt(_crossfadeKey) ?? 0;
    _fadeDuration = prefs.getInt(_fadeKey) ?? 0;
    _gaplessPlayback = prefs.getBool(_gaplessKey) ?? true;
    _audioBitDepth = prefs.getString(_bitDepthKey) ?? '16';
    _audioSampleRate = prefs.getString(_sampleRateKey) ?? '44.1';
    _userName = prefs.getString(_userNameKey) ?? 'Zohaib';
    _avatarPath = prefs.getString(_avatarPathKey) ?? '';

    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, mode.index);
  }

  Future<void> setDvcEnabled(bool value) async {
    if (_dvcEnabled == value) return;
    _dvcEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dvcKey, value);
  }

  Future<void> setResamplerMode(String mode) async {
    if (_resamplerMode == mode) return;
    _resamplerMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_resamplerKey, mode);
  }

  Future<void> setOutputPlugin(String plugin) async {
    if (_outputPlugin == plugin) return;
    _outputPlugin = plugin;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_outputPluginKey, plugin);
  }

  Future<void> setChromecastEnabled(bool value) async {
    if (_chromecastEnabled == value) return;
    _chromecastEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_chromecastKey, value);
  }

  Future<void> setCrossfadeDuration(int duration) async {
    if (_crossfadeDuration == duration) return;
    _crossfadeDuration = duration;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_crossfadeKey, duration);
  }

  Future<void> setFadeDuration(int duration) async {
    if (_fadeDuration == duration) return;
    _fadeDuration = duration;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_fadeKey, duration);
  }

  Future<void> setGaplessPlayback(bool value) async {
    if (_gaplessPlayback == value) return;
    _gaplessPlayback = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_gaplessKey, value);
  }

  Future<void> setAudioBitDepth(String value) async {
    if (_audioBitDepth == value) return;
    _audioBitDepth = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_bitDepthKey, value);
  }

  Future<void> setAudioSampleRate(String value) async {
    if (_audioSampleRate == value) return;
    _audioSampleRate = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sampleRateKey, value);
  }

  Future<void> setUserName(String name) async {
    if (_userName == name) return;
    _userName = name;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, name);
  }

  Future<void> setAvatarPath(String path) async {
    if (_avatarPath == path) return;
    _avatarPath = path;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_avatarPathKey, path);
  }
}
