package com.tcm.lingshu

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.AlarmClock
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

// local_auth 要求 FragmentActivity 作为宿主（否则真机生物识别直接报不可用）
class MainActivity : FlutterFragmentActivity() {
    private val alarmChannelName = "lingshu/alarm"
    private val updaterChannelName = "lingshu/updater"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, alarmChannelName)
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
                    // 系统设置 → 应用「灵枢」的通知页：通知权限被拒后系统弹窗
                    // 不再出现，提醒排上了也不显示，只能从这里引导用户开启
                    "openNotificationSettings" -> {
                        try {
                            val i = if (Build.VERSION.SDK_INT >= 26) {
                                Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                                    .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                            } else {
                                Intent(
                                    Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                                    Uri.parse("package:$packageName")
                                )
                            }
                            i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(i)
                            result.success(true)
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, updaterChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    // 应用内更新：FileProvider 授权后拉起系统安装器覆盖安装。
                    // 返回 "opened"=已拉起；"needsPermission"=缺「安装未知应用」
                    // 授权，已带去授权页，授权后 Dart 侧需再次调用
                    "installApk" -> {
                        val path = call.argument<String>("path")
                        if (path == null || !File(path).exists()) {
                            result.error("ARG", "安装包不存在：$path", null)
                            return@setMethodCallHandler
                        }
                        try {
                            if (Build.VERSION.SDK_INT >= 26 &&
                                !packageManager.canRequestPackageInstalls()
                            ) {
                                startActivity(
                                    Intent(
                                        Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                                        Uri.parse("package:$packageName")
                                    ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                )
                                result.success("needsPermission")
                                return@setMethodCallHandler
                            }
                            val uri = FileProvider.getUriForFile(
                                this, "$packageName.update_provider", File(path)
                            )
                            val intent = Intent(Intent.ACTION_VIEW).apply {
                                setDataAndType(
                                    uri, "application/vnd.android.package-archive"
                                )
                                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(intent)
                            result.success("opened")
                        } catch (e: Exception) {
                            result.error("INSTALL_FAILED", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
