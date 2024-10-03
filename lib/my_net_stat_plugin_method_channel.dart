import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'my_net_stat_plugin_platform_interface.dart';

/// An implementation of [MyNetStatPluginPlatform] that uses method channels.
class MethodChannelMyNetStatPlugin extends MyNetStatPluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('my_net_stat_plugin');

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<List<Map<String, int>>> getUsageForDaysInCurrentMonth() async {
    var now = DateTime.now();
    late DateTime start, end;
    List<Map<String, int>> data = [];
    try {
      for (int i = now.day; i > 0; i--) {
        start = DateTime(now.year, now.month, i);
        end = DateTime(now.year, now.month, i+1);
        var result = await methodChannel.invokeMethod('getUsageFrom', {
          'start': start.millisecondsSinceEpoch,
          'end': end.millisecondsSinceEpoch
        });

        data.add({'uploadUsage':result['uploadUsage'],'downloadUsage':result['uploadUsage'],'date':start.millisecondsSinceEpoch});
      }
      return data;
    } on PlatformException catch (e) {
      print("Failed to getUsageForDaysInCurrentMonth: '${e.message}'.");
    }
    return data;
  }

  @override
  Future<Map<String, double>> getUsageTotalFrom({required DateTime start, DateTime? end}) async {
    end ??= DateTime.now();
    try {
      var result = await methodChannel.invokeMethod('getUsageFrom', {
        'start': start.millisecondsSinceEpoch,
        'end': end.millisecondsSinceEpoch
      });
      return result;
    } on PlatformException catch (e) {
      print("Failed to get Total Usage : '${e.message}'.");
    }
    return {"error": 0};
  }

  @override
  Stream<Map<String, double>> realtimeInternetSpeedInBytes() async* {
    while (true) {
      yield await getCurrentSpeedInBytes(); // Yield the result of getCurrentSpeed()
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  @override
  Stream<String> realtimeInternetSpeedInString() async* {
    String speedString;
    try {
      yield realtimeInternetSpeedInBytes().toString();
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print("Failed to get realtimeInternetSpeedInString: '${e.message}'.");
      }
      yield '0.0'; // Return a default value if an error occurs
    }
  }

  Future<Map<String, double>> getCurrentSpeedInBytes() async {
    try {
      var speed = await methodChannel.invokeMethod('getSpeed');

      // Return the speed in Bytes per second
      return {
        'uploadSpeed': speed['uploadSpeed'] / 1024,
        'downloadSpeed': speed['downloadSpeed'] / 1024
      };
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print("Failed to getCurrentSpeedInBytes :  '${e.message}'.");
      }
      return {
        'uploadSpeed': 0,
        'downloadSpeed': 0
      }; // Return a default value if an error occurs
    }
  }

  Future<String> getCurrentSpeed() async {
    try {
      var speed = await methodChannel.invokeMethod('getSpeed');
      var newSpeed = speed / 1024;
      String speedUnit;
      double speedValue;

      if (double.parse(newSpeed.toString()) >= 1024) {
        speedUnit = 'MBps';
        speedValue = double.parse(newSpeed.toString()) / 1024;
      } else {
        speedUnit = 'KBps';
        speedValue = double.parse(newSpeed.toString());
      }
      // Return the formatted speed with unit
      return speedValue.toStringAsFixed(2) + speedUnit;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print("Failed to get current speed: '${e.message}'.");
      }
      return '0.0'; // Return a default value if an error occurs
    }
  }
}
