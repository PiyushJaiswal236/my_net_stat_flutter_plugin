import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'my_net_stat_plugin_method_channel.dart';

abstract class MyNetStatPluginPlatform extends PlatformInterface {
  /// Constructs a MyNetStatPluginPlatform.
  MyNetStatPluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static MyNetStatPluginPlatform _instance = MethodChannelMyNetStatPlugin();

  /// The default instance of [MyNetStatPluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelMyNetStatPlugin].
  static MyNetStatPluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [MyNetStatPluginPlatform] when
  /// they register themselves.
  static set instance(MyNetStatPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<List<Map<String, int>>> getUsageForDaysInCurrentMonth(){
    throw UnimplementedError(
        'getUsageForDaysInMonth() has not been implemented.');
  }
  Future<dynamic> getUsageTotalFrom({required DateTime start, DateTime? end}) {
    throw UnimplementedError(
        'getUsageTotalFrom() has not been implemented.');
  }

  Stream<String> realtimeInternetSpeedInString() {
    throw UnimplementedError(
        'realtimeInternetSpeed() has not been implemented.');
  }

  Stream<Map<String,double>> realtimeInternetSpeedInBytes(){
    throw UnimplementedError(
        'realtimeInternetSpeedInBytes() has not been implemented.'
    );
  }

}
