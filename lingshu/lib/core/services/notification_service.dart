import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// 用药提醒排程结果：给调用方如实反馈「提醒到底设上没有」
class MedScheduleResult {
  final int scheduled; // 成功排上的未来通知条数（0=一条都没排上）
  final bool exact; // true=精确闹钟；false=本机未授「闹钟和提醒」，已降级非精确（触发可能延迟数分钟）
  final bool notificationsAllowed; // 系统通知权限（false=排了也不显示）
  const MedScheduleResult({
    required this.scheduled,
    required this.exact,
    required this.notificationsAllowed,
  });
}

/// 本地通知（用药提醒）
class NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _inited = false;

  Future<void> init() async {
    if (_inited) return;
    tzdata.initializeTimeZones();
    // 中国无夏令时，固定为东八区
    tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    // 不在这里 requestExactAlarmsPermission：未授权时插件会强跳系统
    // 「闹钟和提醒」设置页，启动重排也会走 init → 每次开 App 都被弹走。
    // 精确闹钟引导只在用药保存流程做（保存反馈里带「去开启」）；
    // 未授权时排程已降级非精确，提醒仍然生效。
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        'lingshu_med',
        '用药提醒',
        description: '按时服药提醒',
        importance: Importance.high,
      ),
    );
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        'lingshu_box',
        '药箱到期提醒',
        description: '家庭小药箱药品临期/过期提醒',
        importance: Importance.high,
      ),
    );
    _inited = true;
  }

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'lingshu_med',
      '用药提醒',
      channelDescription: '按时服药提醒',
      importance: Importance.high,
      priority: Priority.high,
      ongoing: false,
    ),
    iOS: DarwinNotificationDetails(),
  );

  static const _alarmChannel = MethodChannel('lingshu/alarm');

  /// 引导用户去系统设置开通知（通知权限被永久拒绝时系统弹窗不再出现，
  /// 只能从应用设置进入）。失败静默——仅是引导路径，不影响主流程
  Future<void> openNotificationSettings() async {
    try {
      await _alarmChannel.invokeMethod('openNotificationSettings');
    } catch (e) {
      debugPrint('[notify] open settings failed: $e');
    }
  }

  /// 引导开启「闹钟和提醒」（精确闹钟）：插件跳系统授权页，开启后下次重排生效
  Future<void> requestExactAlarmPermission() async {
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestExactAlarmsPermission();
    } catch (e) {
      debugPrint('[notify] request exact alarm permission failed: $e');
    }
  }


  /// 窗口式逐日调度：为未来 60 天内每个符合条件的日期×时间点建一次性通知。
  /// 条件 = 周几选中 ∩ 服用区间内 ∩ 不在暂停时段。
  /// （周重复式通知无法表达开始/结束日期与暂停，故改为滚动窗口 +
  ///  打开用药页/App 启动时重排）
  ///
  /// 权限降级：targetSdk≥35 时 Android 14+ 默认不授 SCHEDULE_EXACT_ALARM，
  /// 精确排程会直接抛异常（此前被调用方吞掉→用户以为设好了实际一条没排）。
  /// 现查 canScheduleExactNotifications，未授权时降级 inexactAllowWhileIdle
  /// 继续排（Doze 下触发可能延迟数分钟），绝不因权限让提醒归零。
  Future<MedScheduleResult> rescheduleMedication({
    required int medicationId,
    required List<String> times,
    required Set<int> days, // Dart weekday；空=每天
    DateTime? startDate,
    DateTime? endDate,
    List<(DateTime, DateTime)> pauses = const [],
    required String title,
    required String body,
  }) async {
    await init();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final notificationsAllowed =
        await android?.areNotificationsEnabled() ?? true;
    final exact = await android?.canScheduleExactNotifications() ?? true;
    final mode = exact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
    await cancelForMedication(medicationId, slots: times.length);
    final effective = days.isEmpty ? {1, 2, 3, 4, 5, 6, 7} : days;
    DateTime ds(DateTime d) => DateTime(d.year, d.month, d.day);
    final today = ds(DateTime.now());
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = 0;
    for (var offset = 0; offset < 60; offset++) {
      final d = today.add(Duration(days: offset));
      if (!effective.contains(d.weekday)) continue;
      if (startDate != null && d.isBefore(ds(startDate))) continue;
      if (endDate != null && !d.isBefore(ds(endDate).add(const Duration(days: 1)))) continue;
      if (pauses.any((pg) =>
          !d.isBefore(ds(pg.$1)) &&
          d.isBefore(ds(pg.$2).add(const Duration(days: 1))))) continue;
      for (var slot = 0; slot < times.length; slot++) {
        final parts = times[slot].split(':');
        final when = tz.TZDateTime(
            tz.local, d.year, d.month, d.day, int.parse(parts[0]), int.parse(parts[1]));
        if (!when.isAfter(now)) continue;
        try {
          await _plugin.zonedSchedule(
            _windowId(medicationId, slot, offset),
            title,
            body,
            when,
            _details,
            androidScheduleMode: mode,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
          scheduled++;
        } catch (e) {
          // 单条失败不拖垮整个窗口（部分 ROM 逐条偶发），计数留给调用方反馈
          debugPrint(
              '[notify] schedule med=$medicationId slot=$slot day=$offset failed: $e');
        }
      }
    }
    return MedScheduleResult(
      scheduled: scheduled,
      exact: exact,
      notificationsAllowed: notificationsAllowed,
    );
  }

  /// 窗口式通知 id：medId*1e6 + slot*1e3 + 天偏移(0..59)，与历史两代 id 段不重叠
  int _windowId(int medId, int slot, int dayOffset) =>
      medId * 1000000 + slot * 1000 + dayOffset;

  /// 单条撤销兜底：插件层异常（如平台缓存损坏）不允许打断调用方的
  /// await 链——删除药品时若 cancel 抛错，抽屉将停在已删数据上
  Future<void> _cancelSafe(int id) async {
    try {
      await _plugin.cancel(id);
    } catch (e) {
      debugPrint('[notify] cancel $id failed: $e');
    }
  }

  Future<void> cancelForMedication(int medicationId,
      {int slots = 8}) async {
    for (var i = 0; i < slots; i++) {
      // 最早一代：每日重复 medId*100+slot
      await _cancelSafe(medicationId * 100 + i);
      // 第二代：周几重复 medId*10000+slot*100+dow
      for (var dow = 1; dow <= 7; dow++) {
        await _cancelSafe(medicationId * 10000 + i * 100 + dow);
      }
      // 第三代：滚动窗口 medId*1e6+slot*1e3+day(0..59)
      for (var day = 0; day < 60; day++) {
        await _cancelSafe(_windowId(medicationId, i, day));
      }
    }
  }

  static const _boxDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'lingshu_box',
      '药箱到期提醒',
      channelDescription: '家庭小药箱药品临期/过期提醒',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  /// 药箱到期提醒：到期前 6/3/1 个月各一次 + 过期后每天一次。
  /// 与用药提醒的 60 天滚动窗口不同，到期节点跨度长达半年，
  /// 故直接为每个节点排一次性未来通知；「过期后每天」用每日重复
  /// （从过期次日 9:00 起），删除/编辑药品时调用 cancelBoxMedicine 撤销。
  Future<void> scheduleBoxMedicine({
    required int boxMedId,
    required String name,
    required DateTime expireDate,
  }) async {
    await init();
    debugPrint('[box] init ok');
    await cancelBoxMedicine(boxMedId);
    debugPrint('[box] cancelled');
    final base = 1900000000 + boxMedId * 10; // 独立 id 段，避开用药提醒
    final now = tz.TZDateTime.now(tz.local);
    final y = expireDate.year, m = expireDate.month, d = expireDate.day;
    final expireDay =
        tz.TZDateTime(tz.local, y, m, d, 9); // 到期当天上午 9 点视为「已过期」起点

    final ahead = [6, 3, 1];
    for (var i = 0; i < ahead.length; i++) {
      var am = m - ahead[i];
      var ay = y;
      while (am <= 0) {
        am += 12;
        ay -= 1;
      }
      final when = tz.TZDateTime(tz.local, ay, am, d, 9);
      if (!when.isAfter(now) || !when.isBefore(expireDay)) continue;
      await _plugin.zonedSchedule(
        base + i,
        '灵枢 · 药箱提醒',
        '「$name」将于 $y 年 $m 月 $d 日到期，还剩约 ${ahead[i]} 个月，建议尽早补货更换',
        when,
        _boxDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint('[box] scheduled ahead[$i] $when');
    }

    // 打开 App 时已过期的药：立即补发一次当日提醒
    if (expireDay.isBefore(now)) {
      await _plugin.show(
        base + 3,
        '灵枢 · 药箱提醒',
        '「$name」已过期，请勿再服用，建议尽早更换',
        _boxDetails,
      );
    }

    // 过期后每天 9:00 一次：60 天滚动窗口逐日一次性通知
    // （matchDateTimeComponents 每日重复式在此插件/镜像组合上会挂死，
    //   与用药提醒同思路——窗口排期 + 启动时滚动重排）
    final startDate = expireDay.isAfter(now)
        ? expireDay
        : tz.TZDateTime(tz.local, now.year, now.month, now.day, 9);
    for (var off = 0; off <= 60; off++) {
      final when = tz.TZDateTime(
          tz.local, startDate.year, startDate.month, startDate.day + off, 9);
      if (!when.isAfter(now)) continue;
      await _plugin.zonedSchedule(
        base + 4 + off,
        '灵枢 · 药箱提醒',
        '「$name」已过期，请勿再服用，建议尽早更换',
        when,
        _boxDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      if (off % 10 == 0) debugPrint('[box] expired window off=$off');
    }
  }

  /// 撤销某药品的全部到期提醒
  Future<void> cancelBoxMedicine(int boxMedId) async {
    final base = 1900000000 + boxMedId * 10;
    for (var i = 0; i < 4; i++) {
      await _cancelSafe(base + i);
    }
    for (var off = 0; off <= 60; off++) {
      await _cancelSafe(base + 4 + off);
    }
  }
}
