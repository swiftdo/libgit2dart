#include "include/libgit2dart/libgit2dart_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "libgit2dart_plugin.h"

void Libgit2dartPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  libgit2dart::Libgit2dartPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
