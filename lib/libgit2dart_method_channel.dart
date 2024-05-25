import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'libgit2dart_platform_interface.dart';

/// An implementation of [Libgit2dartPlatform] that uses method channels.
class MethodChannelLibgit2dart extends Libgit2dartPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('libgit2dart');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
