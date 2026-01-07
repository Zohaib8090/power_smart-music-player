#include "include/local_audio/local_audio_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "local_audio_plugin.h"

void LocalAudioPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  local_audio::LocalAudioPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
