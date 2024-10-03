
import 'my_net_stat_plugin_platform_interface.dart';

class MyNetStatPlugin {
  Future<String?> getPlatformVersion() {
    return MyNetStatPluginPlatform.instance.getPlatformVersion();
  }

  Stream<String> getCurrentInternetSpeedInString() {
    return MyNetStatPluginPlatform.instance.realtimeInternetSpeedInString();
  }

  Stream<Map<String, double>> getCurrentInternetSpeedInBytes() {
    return MyNetStatPluginPlatform.instance.realtimeInternetSpeedInBytes();
  }

  Future<List<Map<String, int>>> getUsageForDaysInCurrentMonth() async {
    return MyNetStatPluginPlatform.instance.getUsageForDaysInCurrentMonth();
  }

  Future<dynamic> getUsageTotalFrom(
      {required DateTime start, DateTime? end}) async {
    return MyNetStatPluginPlatform.instance.getUsageTotalFrom(start: start);
  }

}
