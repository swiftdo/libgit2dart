#ifndef FLUTTER_PLUGIN_LIBGIT2DART_PLUGIN_H_
#define FLUTTER_PLUGIN_LIBGIT2DART_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace libgit2dart {

class Libgit2dartPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  Libgit2dartPlugin();

  virtual ~Libgit2dartPlugin();

  // Disallow copy and assign.
  Libgit2dartPlugin(const Libgit2dartPlugin&) = delete;
  Libgit2dartPlugin& operator=(const Libgit2dartPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace libgit2dart

#endif  // FLUTTER_PLUGIN_LIBGIT2DART_PLUGIN_H_
