import 'package:flutter_test/flutter_test.dart';
import 'package:libgit2dart/libgit2dart.dart';
import 'package:libgit2dart/libgit2dart_platform_interface.dart';
import 'package:libgit2dart/libgit2dart_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockLibgit2dartPlatform
    with MockPlatformInterfaceMixin
    implements Libgit2dartPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final Libgit2dartPlatform initialPlatform = Libgit2dartPlatform.instance;

  test('$MethodChannelLibgit2dart is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelLibgit2dart>());
  });

  test('getPlatformVersion', () async {
    Libgit2dart libgit2dartPlugin = Libgit2dart();
    MockLibgit2dartPlatform fakePlatform = MockLibgit2dartPlatform();
    Libgit2dartPlatform.instance = fakePlatform;

    expect(await libgit2dartPlugin.getPlatformVersion(), '42');
  });
}
