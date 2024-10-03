package com.example.my_net_stat_plugin

import androidx.annotation.NonNull

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** MyNetStatPlugin */
class MyNetStatPlugin : FlutterPlugin, MethodCallHandler {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel
    private lateinit var context: Context // Store the context for later use
    private var lastRxBytes = 0L
    private var lastTxBytes = 0L
    private var lastUpdateTime = System.currentTimeMillis()
    private var rxSpeedList = mutableListOf<Double>()
    private var txSpeedList = mutableListOf<Double>()
    private val NUM_SAMPLES = 5 // Number of samples to average
    private lateinit var networkStatsManager: NetworkStatsManager
    private lateinit var connectivityManager: ConnectivityManager

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "my_net_stat_plugin")
        networkStatsManager =
            context.getSystemService(Context.NETWORK_STATS_SERVICE) as NetworkStatsManager
        connectivityManager =
            context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager

        channel.setMethodCallHandler(this)
        lastRxBytes = TrafficStats.getTotalRxBytes()
        lastTxBytes = TrafficStats.getTotalTxBytes()
        lastUpdateTime = System.currentTimeMillis()
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        if (call.method == "getPlatformVersion") {
            result.success("Android ${android.os.Build.VERSION.RELEASE}")
        } else if (call.method == "getSpeed") {
            val speed = getNetworkSpeed()
            result.success(speed)
        } else if (call.method == "getUsageFrom") {
            if (!hasUsageStatsPermission()) {
                requestUsageStatsPermission()
            } else {
                getUsageFrom(result, call.arguments)
                result.success(speed)
            }
        } else {
            result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    private fun getNetworkSpeed(): Map<String, Long> {

        if (isInternetAvailable()) {
            val rxBytes = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                TrafficStats.getTotalRxBytes()
            } else {
                TrafficStats.getTotalRxBytes() + TrafficStats.getTotalRxPackets()
            }
            val txBytes = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                TrafficStats.getTotalTxBytes()
            } else {
                TrafficStats.getTotalTxBytes() + TrafficStats.getTotalTxPackets()
            }
            val currentTime = System.currentTimeMillis()
            val elapsedTime = currentTime - lastUpdateTime
            val rxSpeed = ((rxBytes - lastRxBytes) * 1000.0) / elapsedTime // Bytes per second
            val txSpeed = ((txBytes - lastTxBytes) * 1000.0) / elapsedTime // Bytes per second
            lastRxBytes = rxBytes
            lastTxBytes = txBytes
            lastUpdateTime = currentTime

            rxSpeedList.add(rxSpeed)
            txSpeedList.add(txSpeed)

            // Keep only the last NUM_SAMPLES samples
            if (rxSpeedList.size > NUM_SAMPLES) {
                rxSpeedList.removeAt(0)
                txSpeedList.removeAt(0)
            }

            // Calculate average speed
            val avgRxSpeed = rxSpeedList.average()
            val avgTxSpeed = txSpeedList.average()

            return  mapOf(
                "downloadSpeed" to downloadSpeed,
                "uploadSpeed" to uploadSpeed
            ) // Combined network speed
        } else {
            return mapOf(
                "downloadSpeed" to 0L,
                "uploadSpeed" to 0L
            )
        }
    }

    @RequiresApi(Build.VERSION_CODES.M)
    private fun getUsageFrom(result: MethodChannel.Result, timeData: Any) {

        try {
            handler.post {
                if (isInternetAvailable()) {
                    result.success(getTheUsage(timeData as Map<*, *>))
                } else {
                    result.error("NO_INTERNET", "No internet connection available", null)
                }
            }
        } catch (e: Exception) {
            Log.e("getUsageFrom", "Error: ${e.message}")
            result.error("ERROR_USAGE_STATS", "Failed to retrieve usage data", null)
        }
    }

    @RequiresApi(Build.VERSION_CODES.M)
    private fun isInternetAvailable(): Boolean {
        val network = connectivityManager.activeNetwork ?: return false
        val networkCapabilities =
            connectivityManager.getNetworkCapabilities(network) ?: return false
        return networkCapabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
    }

    @RequiresApi(Build.VERSION_CODES.M)
    private fun getTheUsage(timeData: Map<*, *>): Map<String, Long> {
        try {
            val bucket: Bucket = networkStatsManager.querySummaryForDevice(
                ConnectivityManager.TYPE_WIFI,
                "",
                timeData["start"] as Long,
                System.currentTimeMillis()
            )
            return mapOf("uploadUsage" to bucket.rxBytes, "downloadUsage" to bucket.txBytes);
        } catch (e: Exception) {
            android.util.Log.d("error", "getTheUsage: " + e)
        }
        return mapOf("error" to 0L)
    }

    private fun hasUsageStatsPermission(): Boolean {
        val appOpsManager = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOpsManager.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                packageName
            )
        } else {
            appOpsManager.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                packageName
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun requestUsageStatsPermission() {
        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
        startActivity(intent)
    }


}


