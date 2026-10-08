import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
// 平台实例与 Android 实现类未从插件主入口导出，测试里直接引
import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';
import 'package:flutter_local_notifications/src/platform_flutter_local_notifications.dart';
import 'package:lingshu/core/services/notification_service.dart';

/// 用药提醒排程回归：权限降级与结果反馈（2026-10 用户真机「保存成功但一条
/// 通知都没排上」——targetSdk≥35 时 Android 14+ 默认不授精确闹钟，
/// zonedSchedule(exact) 抛异常被吞，整窗归零）。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  // 测试环境无真实平台端，手动注册 Android 平台实现（走同一通道 → 命中下方 mock）
  setUpAll(() {
    FlutterLocalNotificationsPlatform.instance =
        AndroidFlutterLocalNotificationsPlugin();
  });

  var exactAllowed = true;
  var notificationsAllowed = true;
  var failIds = <int>{};
  var modes = <String>[];

  setUp(() {
    exactAllowed = true;
    notificationsAllowed = true;
    failIds = {};
    modes = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'initialize':
          return true;
        case 'requestNotificationsPermission':
          return true;
        case 'areNotificationsEnabled':
          return notificationsAllowed;
        case 'canScheduleExactNotifications':
          return exactAllowed;
        case 'zonedSchedule':
          final id = call.arguments['id'] as int;
          if (failIds.contains(id)) throw PlatformException(code: 'X');
          modes.add((call.arguments['platformSpecifics']
                  as Map)['scheduleMode'] as String? ??
              '');
          return null;
        case 'cancel':
        case 'createNotificationChannel':
          return null;
      }
      return null;
    });
  });

  Future<MedScheduleResult> reschedule() =>
      NotificationService().rescheduleMedication(
        medicationId: 1,
        times: const ['08:00'],
        days: {1, 2, 3, 4, 5, 6, 7},
        title: '灵枢 · 用药提醒',
        body: 'TestMedA · 餐后服用',
      );

  test('精确闹钟可用：exact 模式排满窗口并如实计数', () async {
    final r = await reschedule();
    expect(r.exact, isTrue);
    expect(r.notificationsAllowed, isTrue);
    // 60 天窗口每天 08:00 一条；测试时刻可能已过今天 08:00，故 ≥55 容差
    expect(r.scheduled, greaterThanOrEqualTo(55));
    expect(modes, everyElement('exactAllowWhileIdle'));
  });

  test('精确闹钟被拒（Android 14+ 默认态）：降级 inexact 绝不归零', () async {
    exactAllowed = false;
    final r = await reschedule();
    expect(r.exact, isFalse);
    expect(r.scheduled, greaterThanOrEqualTo(55));
    expect(modes, everyElement('inexactAllowWhileIdle'));
  });

  test('通知权限被拒：排程继续，结果标记 notificationsAllowed=false', () async {
    notificationsAllowed = false;
    final r = await reschedule();
    expect(r.notificationsAllowed, isFalse);
    expect(r.scheduled, greaterThanOrEqualTo(55));
  });

  test('单条排程抛错不拖垮整窗：跳过失败条目继续计数', () async {
    // medId=1, slot=0 → window id = 1e6 + day；掐掉第 3、5 天的条目
    failIds = {1000003, 1000005};
    final r = await reschedule();
    expect(r.scheduled, greaterThanOrEqualTo(53));
    expect(r.scheduled, lessThan(60));
  });
}
