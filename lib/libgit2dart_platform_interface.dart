import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'libgit2dart_method_channel.dart';

abstract class Libgit2dartPlatform extends PlatformInterface {
  /// Constructs a Libgit2dartPlatform.
  Libgit2dartPlatform() : super(token: _token);

  static final Object _token = Object();

  static Libgit2dartPlatform _instance = MethodChannelLibgit2dart();

  /// The default instance of [Libgit2dartPlatform] to use.
  ///
  /// Defaults to [MethodChannelLibgit2dart].
  static Libgit2dartPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [Libgit2dartPlatform] when
  /// they register themselves.
  static set instance(Libgit2dartPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
