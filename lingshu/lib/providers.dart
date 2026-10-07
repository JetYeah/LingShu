import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/db.dart';
import 'core/services/herb_repo.dart';
import 'core/services/asr_service.dart';
import 'core/services/auth_service.dart';
import 'core/services/content_loader.dart';
import 'core/services/location_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/ocr_service.dart';

/// 基础服务
final sharedPreferencesProvider =
    Provider<SharedPreferences>((ref) => throw UnimplementedError());

final dbProvider = Provider<AppDatabase>((ref) => AppDatabase());

final authProvider = Provider<AuthService>(
    (ref) => AuthService(ref.watch(sharedPreferencesProvider)));

final contentProvider = Provider<ContentRepo>((ref) => ContentRepo());

final locationServiceProvider = Provider<LocationService>((ref) => LocationService());

final notificationServiceProvider =
    Provider<NotificationService>((ref) => NotificationService());

/// AI 识别配置
final aiConfigProvider = FutureProvider<OcrService>((ref) async {
  final prefs = ref.watch(sharedPreferencesProvider);
  final base = prefs.getString('ai.base_url') ?? OcrService.defaultBaseUrl;
  final key = prefs.getString('ai.api_key') ?? '';
  final model = prefs.getString('ai.model') ?? OcrService.defaultModel;
  return OcrService(baseUrl: base, apiKey: key, model: model);
});

/// 语音识别配置：asr.* 留空时逐项回退到 AI 识别的配置（同一服务商时只配一次 Key）
final asrConfigProvider = FutureProvider<AsrService>((ref) async {
  final prefs = ref.watch(sharedPreferencesProvider);
  final base = _firstNonEmpty(
      prefs.getString('asr.base_url'), prefs.getString('ai.base_url'));
  final key = _firstNonEmpty(
      prefs.getString('asr.api_key'), prefs.getString('ai.api_key'));
  final model = _firstNonEmpty(
      prefs.getString('asr.model'), AsrService.defaultModel);
  return AsrService(
      baseUrl: base ?? OcrService.defaultBaseUrl,
      apiKey: key ?? '',
      model: model!);
});

String? _firstNonEmpty(String? a, String? b) {
  if (a != null && a.trim().isNotEmpty) return a.trim();
  if (b != null && b.trim().isNotEmpty) return b.trim();
  return null;
}

/// 会话状态
enum SessionState { loading, needOnboarding, locked, ready }

class SessionNotifier extends StateNotifier<SessionState> {
  final AuthService auth;
  SessionNotifier(this.auth) : super(SessionState.loading) {
    if (!auth.onboarded) {
      state = SessionState.needOnboarding;
    } else {
      state = SessionState.locked; // 每次启动需验证 PIN
    }
  }

  void unlock() => state = SessionState.ready;

  void finishOnboarding() {
    if (auth.pinSet) {
      state = SessionState.locked;
    } else {
      state = SessionState.ready;
    }
  }
}

final sessionProvider =
    StateNotifierProvider<SessionNotifier, SessionState>((ref) {
  return SessionNotifier(ref.watch(authProvider));
});

/// 当前选中成员
final currentProfileIdProvider =
    StateProvider<int?>((ref) => ref.read(authProvider).currentProfileId);

final currentProfileProvider = StreamProvider<Profile?>((ref) {
  final db = ref.watch(dbProvider);
  final id = ref.watch(currentProfileIdProvider);
  if (id == null) return Stream.value(null);
  return (db.select(db.profiles)..where((u) => u.id.equals(id)))
      .watchSingleOrNull();
});

final profilesProvider = StreamProvider<List<Profile>>((ref) {
  final db = ref.watch(dbProvider);
  return (db.select(db.profiles)
        ..orderBy([(u) => OrderingTerm.asc(u.id)]))
      .watch();
});

/// 医疗档案
final recordsProvider = StreamProvider<List<MedicalRecord>>((ref) {
  final db = ref.watch(dbProvider);
  final profileId = ref.watch(currentProfileIdProvider);
  if (profileId == null) return Stream.value(const []);
  return (db.select(db.medicalRecords)
        ..where((r) => r.profileId.equals(profileId))
        ..orderBy([(r) => OrderingTerm.desc(r.recordDate)]))
      .watch();
});

/// 健康指标
final metricsProvider = StreamProvider<List<Metric>>((ref) {
  final db = ref.watch(dbProvider);
  final profileId = ref.watch(currentProfileIdProvider);
  if (profileId == null) return Stream.value(const []);
  return (db.select(db.metrics)
        ..where((m) => m.profileId.equals(profileId))
        ..orderBy([(m) => OrderingTerm.asc(m.id)]))
      .watch();
});

Stream<List<MetricValue>> watchMetricValues(AppDatabase db, int metricId) {
  return (db.select(db.metricValues)
        ..where((v) => v.metricId.equals(metricId))
        ..orderBy([(v) => OrderingTerm.desc(v.measuredAt)]))
      .watch();
}

/// 药物
final medicationsProvider = StreamProvider<List<Medication>>((ref) {
  final db = ref.watch(dbProvider);
  final profileId = ref.watch(currentProfileIdProvider);
  if (profileId == null) return Stream.value(const []);
  return (db.select(db.medications)
        ..where((m) => m.profileId.equals(profileId) & m.active.equals(true))
        ..orderBy([(m) => OrderingTerm.asc(m.id)]))
      .watch();
});

Stream<List<MedicationLog>> watchMedLogs(AppDatabase db, int medId) {
  return (db.select(db.medicationLogs)
        ..where((l) => l.medicationId.equals(medId))
        ..orderBy([(l) => OrderingTerm.desc(l.scheduledAt)]))
      .watch();
}

/// 药物名集合（供成员档案展示紧急健康卡）
Future<List<Medication>> activeMeds(AppDatabase db, int profileId) {
  return (db.select(db.medications)
        ..where((m) => m.profileId.equals(profileId) & m.active.equals(true)))
      .get();
}

/// 中药图鉴收藏集（bump version 触发 UI 刷新）
final collectedHerbsProvider = Provider<CollectedHerbs>(
    (ref) => CollectedHerbs(ref.watch(sharedPreferencesProvider)));
final collectedVersionProvider = StateProvider<int>((ref) => 0);

/// AI 会话视图代次：每次从入口进入递增，作 /ai 路由的 page key——
/// 每次打开都得到全新会话视图（历史从磁盘加载且默认收起）
final aiSessionProvider = StateProvider<int>((ref) => 0);

/// 全部中药（FutureProvider 全局缓存，避免每处 HerbRepo() 新建实例重复解析 879 味 JSON）
final allHerbsProvider =
    FutureProvider<List<Herb>>((ref) => HerbRepo().all());
