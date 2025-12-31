#include "include/power_player/power_player_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "power_player_plugin.h"

void PowerPlayerPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  power_player::PowerPlayerPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
