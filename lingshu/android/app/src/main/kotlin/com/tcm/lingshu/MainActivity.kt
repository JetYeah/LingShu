package com.tcm.lingshu

import android.content.Intent
import android.provider.AlarmClock
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// local_auth 要求 FragmentActivity 作为宿主（否则真机生物识别直接报不可用）
class MainActivity : FlutterFragmentActivity() {
    private val channelName = "lingshu/alarm"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setAlarm" -> {
                        // 参数：name 提醒内容 / hour,minute / days=[周一..周日的 Dart
                        // DateTime.weekday 1..7]，null 或空 = 每天
                        val name = call.argument<String>("name") ?: ""
                        val hour = call.argument<Int>("hour") ?: 8
                        val minute = call.argument<Int>("minute") ?: 0
                        val daysArg = call.argument<List<Int>>("days")
                        // Dart weekday(1=周一..7=周日) → Calendar 常量
                        val dartToCalendar = mapOf(
                            1 to java.util.Calendar.MONDAY,
                            2 to java.util.Calendar.TUESDAY,
                            3 to java.util.Calendar.WEDNESDAY,
                            4 to java.util.Calendar.THURSDAY,
                            5 to java.util.Calendar.FRIDAY,
                            6 to java.util.Calendar.SATURDAY,
                            7 to java.util.Calendar.SUNDAY,
                        )
                        try {
                            val intent = Intent(AlarmClock.ACTION_SET_ALARM).apply {
                                putExtra(AlarmClock.EXTRA_MESSAGE, name)
                                putExtra(AlarmClock.EXTRA_HOUR, hour)
                                putExtra(AlarmClock.EXTRA_MINUTES, minute)
                                putExtra(AlarmClock.EXTRA_VIBRATE, true)
                                putExtra(AlarmClock.EXTRA_SKIP_UI, true)
                                if (!daysArg.isNullOrEmpty()) {
                                    val calDays =
                                        daysArg.mapNotNull { dartToCalendar[it] }
                                    if (calDays.isNotEmpty()) {
                                        putIntegerArrayListExtra(
                                            AlarmClock.EXTRA_DAYS,
                                            ArrayList(calDays)
                                        )
                                    }
                                }
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            // 无时钟应用或权限异常时回传失败，Dart 侧提示用户手动建
                            result.success(false)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
