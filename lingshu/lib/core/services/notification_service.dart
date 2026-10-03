import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

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
    await android?.requestExactAlarmsPermission();
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


  /// 窗口式逐日调度：为未来 60 天内每个符合条件的日期×时间点建一次性通知。
  /// 条件 = 周几选中 ∩ 服用区间内 ∩ 不在暂停时段。
  /// （周重复式通知无法表达开始/结束日期与暂停，故改为滚动窗口 +
  ///  打开用药页/App 启动时重排）
  Future<void> rescheduleMedication({
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
    await cancelForMedication(medicationId, slots: times.length);
    final effective = days.isEmpty ? {1, 2, 3, 4, 5, 6, 7} : days;
    DateTime ds(DateTime d) => DateTime(d.year, d.month, d.day);
    final today = ds(DateTime.now());
    final now = tz.TZDateTime.now(tz.local);
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
        await _plugin.zonedSchedule(
          _windowId(medicationId, slot, offset),
          title,
          body,
          when,
          _details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }
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
