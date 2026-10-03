import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
  ]);

  // 预加载静态内容
  container.read(contentProvider).load().ignore();

  // 用药提醒 + 药箱到期提醒滚动重排（每次启动刷新，避免长期不打开后漏提醒）
  () async {
    try {
      await _rescheduleAll(container);
    } catch (e, st) {
      debugPrint('[boot] reschedule FAILED: $e\n$st');
    }
  }().ignore();

  runApp(UncontrolledProviderScope(
    container: container,
    child: const LingShuApp(),
  ));
}

Future<void> _rescheduleAll(ProviderContainer container) async {
  final db = container.read(dbProvider);
  debugPrint('[boot] reschedule start');
  final meds = await (db.select(db.medications)
        ..where((t) => t.active.equals(true)))
      .get();
  debugPrint('[boot] active meds: ${meds.length}');
  final notif = container.read(notificationServiceProvider);
  for (final m in meds) {
    await notif.rescheduleMedication(
      medicationId: m.id,
      times: (jsonDecode(m.timesOfDay) as List).cast<String>(),
      days: (jsonDecode(m.daysOfWeek ?? '[1,2,3,4,5,6,7]') as List)
          .map((e) => int.parse(e.toString()))
          .toSet(),
      startDate: m.startDate,
      endDate: m.endDate,
      pauses: (jsonDecode(m.pausePeriods ?? '[]') as List)
          .map((e) => (DateTime.parse((e as Map)['f'] as String),
              DateTime.parse(e['t'] as String)))
          .toList(),
      title: '灵枢 · 用药提醒',
      body: '${m.name}${m.dosage?.isNotEmpty == true ? '（${m.dosage}）' : ''}'
          ' · ${m.mealRelation ?? ''}服用',
    );
  }
  // 药箱到期提醒重排（到期前 6/3/1 月 + 过期后每日窗口）
  final boxMeds = await db.select(db.boxMedicines).get();
  debugPrint('[boot] box meds: ${boxMeds.length}');
  for (final bm in boxMeds) {
    await notif.scheduleBoxMedicine(
        boxMedId: bm.id, name: bm.name, expireDate: bm.expireDate);
  }
  debugPrint('[boot] reschedule done');
}
