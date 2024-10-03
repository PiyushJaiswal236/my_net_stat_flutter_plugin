import 'package:flutter_test/flutter_test.dart';
import 'package:my_net_stat_plugin/my_net_stat_plugin.dart';
import 'package:my_net_stat_plugin/my_net_stat_plugin_platform_interface.dart';
import 'package:my_net_stat_plugin/my_net_stat_plugin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockMyNetStatPluginPlatform
    with MockPlatformInterfaceMixin
    implements MyNetStatPluginPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final MyNetStatPluginPlatform initialPlatform = MyNetStatPluginPlatform.instance;

  test('$MethodChannelMyNetStatPlugin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelMyNetStatPlugin>());
  });

  test('getPlatformVersion', () async {
    MyNetStatPlugin myNetStatPlugin = MyNetStatPlugin();
    MockMyNetStatPluginPlatform fakePlatform = MockMyNetStatPluginPlatform();
    MyNetStatPluginPlatform.instance = fakePlatform;

    expect(await myNetStatPlugin.getPlatformVersion(), '42');
  });
}
