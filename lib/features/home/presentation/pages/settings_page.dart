import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/services/settings_service.dart';
import '../../../../core/services/youtube_cookie_service.dart';
import '../../../auth/presentation/pages/youtube_login_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final youtubeCookies = YouTubeCookieService();

  @override
  Widget build(BuildContext context) {
    final settings = GetIt.I<SettingsService>();

    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: const Text('Settings'),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: ListView(
            children: [
              _buildSectionHeader(context, 'Appearance'),
              ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: const Text('Theme Mode'),
                subtitle: Text(_getThemeModeName(settings.themeMode)),
                onTap: () => _showThemeDialog(context, settings),
              ),
              const Divider(),
              _buildSectionHeader(context, 'Audio Engine (Advanced)'),
              SwitchListTile(
                secondary: const Icon(Icons.volume_up_outlined),
                title: const Text('DVC (Direct Volume Control)'),
                subtitle: const Text(
                  'Directly control hardware volume for better quality',
                ),
                value: settings.dvcEnabled,
                onChanged: (val) => settings.setDvcEnabled(val),
              ),
              ListTile(
                leading: const Icon(Icons.graphic_eq),
                title: const Text('Resampler'),
                subtitle: Text(settings.resamplerMode),
                onTap: () => _showResamplerDialog(context, settings),
              ),
              ListTile(
                leading: const Icon(Icons.settings_input_component),
                title: const Text('Output Plugin'),
                subtitle: Text(settings.outputPlugin),
                onTap: () => _showOutputPluginDialog(context, settings),
              ),
              ListTile(
                leading: const Icon(Icons.data_object),
                title: const Text('Output Bit Depth'),
                subtitle: Text('${settings.audioBitDepth} bit'),
                onTap: () => _showBitDepthDialog(context, settings),
              ),
              ListTile(
                leading: const Icon(Icons.waves),
                title: const Text('Sample Rate'),
                subtitle: Text('${settings.audioSampleRate} kHz'),
                onTap: () => _showSampleRateDialog(context, settings),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.cast),
                title: const Text('Chromecast Output'),
                subtitle: const Text('Enable casting to supported devices'),
                value: settings.chromecastEnabled,
                onChanged: (val) => settings.setChromecastEnabled(val),
              ),
              _buildSliderTile(
                context,
                'Crossfade',
                Icons.shuffle,
                settings.crossfadeDuration,
                10,
                'Seconds',
                (val) => settings.setCrossfadeDuration(val.toInt()),
              ),
              _buildSliderTile(
                context,
                'Fade',
                Icons.trending_down,
                settings.fadeDuration,
                10,
                'Seconds',
                (val) => settings.setFadeDuration(val.toInt()),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.all_inclusive),
                title: const Text('Gapless Playback'),
                subtitle: const Text(
                  'Continuous playback without pauses between tracks',
                ),
                value: settings.gaplessPlayback,
                onChanged: (val) => settings.setGaplessPlayback(val),
              ),
              const Divider(),
              _buildSectionHeader(context, 'YouTube Account'),
              FutureBuilder<bool>(
                future: youtubeCookies.hasCookies(),
                builder: (context, snapshot) {
                  final isLoggedIn = snapshot.data ?? false;
                  return ListTile(
                    leading: Icon(
                      isLoggedIn
                          ? Icons.account_circle
                          : Icons.account_circle_outlined,
                      color: isLoggedIn ? Colors.red : null,
                    ),
                    title: Text(isLoggedIn ? 'Logged In' : 'Not Logged In'),
                    subtitle: Text(
                      isLoggedIn
                          ? 'Tap to log out'
                          : 'Tap to log in and access your playlists',
                    ),
                    onTap: isLoggedIn
                        ? () => _showLogoutDialog(context, youtubeCookies)
                        : () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const YouTubeLoginPage(),
                              ),
                            );
                            if (result == true) {
                              setState(() {}); // Refresh status
                            }
                          },
                  );
                },
              ),
              const Divider(),
              _buildSectionHeader(context, 'About'),
              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Power Smart'),
                subtitle: Text('Version 1.0.0'),
              ),
              const ListTile(
                leading: Icon(Icons.code),
                title: Text('Developers'),
                subtitle: Text('Antigravity & Zohaib'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSliderTile(
    BuildContext context,
    String title,
    IconData icon,
    int value,
    double max,
    String unit,
    Function(double) onChanged,
  ) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon),
          title: Text(title),
          trailing: Text('$value $unit'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Slider(
            value: value.toDouble(),
            min: 0,
            max: max,
            divisions: max.toInt(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  String _getThemeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System Default';
      case ThemeMode.light:
        return 'Light Mode';
      case ThemeMode.dark:
        return 'Dark Mode';
    }
  }

  void _showThemeDialog(BuildContext context, SettingsService settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ThemeMode.values.map((mode) {
            return RadioListTile<ThemeMode>(
              title: Text(_getThemeModeName(mode)),
              value: mode,
              groupValue: settings.themeMode,
              onChanged: (value) {
                if (value != null) {
                  settings.setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showResamplerDialog(BuildContext context, SettingsService settings) {
    final modes = ['Sinc', 'Linear', 'Point'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resampler Mode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: modes.map((mode) {
            return RadioListTile<String>(
              title: Text(mode),
              value: mode,
              groupValue: settings.resamplerMode,
              onChanged: (value) {
                if (value != null) {
                  settings.setResamplerMode(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showOutputPluginDialog(BuildContext context, SettingsService settings) {
    final plugins = ['OpenSL ES', 'Audio Track', 'Hi-Res Output', 'AAudio'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Output Plugin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: plugins.map((plugin) {
            return RadioListTile<String>(
              title: Text(plugin),
              value: plugin,
              groupValue: settings.outputPlugin,
              onChanged: (value) {
                if (value != null) {
                  settings.setOutputPlugin(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showLogoutDialog(
    BuildContext context,
    YouTubeCookieService youtubeCookies,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await youtubeCookies.clearCookies();
              if (mounted) {
                setState(() {}); // Refresh status
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Logged out')));
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showBitDepthDialog(BuildContext context, SettingsService settings) {
    final depths = ['16', '24', '32'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Output Bit Depth'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: depths.map((depth) {
            return RadioListTile<String>(
              title: Text('$depth bit'),
              value: depth,
              groupValue: settings.audioBitDepth,
              onChanged: (value) {
                if (value != null) {
                  settings.setAudioBitDepth(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showSampleRateDialog(BuildContext context, SettingsService settings) {
    final rates = ['44.1', '48', '88.2', '96'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sample Rate'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: rates.map((rate) {
            return RadioListTile<String>(
              title: Text('$rate kHz'),
              value: rate,
              groupValue: settings.audioSampleRate,
              onChanged: (value) {
                if (value != null) {
                  settings.setAudioSampleRate(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
