import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme.dart';
import 'pages/acupoint/acupoint_page.dart';
import 'pages/ai/ai_home_page.dart';
import 'pages/firstaid/firstaid_detail_page.dart';
import 'pages/firstaid/firstaid_page.dart';
import 'pages/home_shell.dart';
import 'pages/lock_page.dart';
import 'pages/metrics/metric_chart_page.dart';
import 'pages/metrics/metrics_page.dart';
import 'pages/onboarding_page.dart';
import 'pages/profile/backup_page.dart';
import 'pages/profile/constitution_page.dart';
import 'pages/medicine_box/box_page.dart';
import 'pages/profile/family_page.dart';
import 'pages/profile/medications_page.dart';
import 'pages/profile/med_edit_page.dart';
import 'pages/profile/profile_page.dart';
import 'pages/profile/settings_page.dart';
import 'pages/records/record_detail_page.dart';
import 'pages/records/record_import_page.dart';
import 'pages/records/records_page.dart';
import 'providers.dart';

GoRouter buildRouter(WidgetRef ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final session = ref.read(sessionProvider);
      final loc = state.matchedLocation;
      if (session == SessionState.loading) return null;
      if (session == SessionState.needOnboarding) {
        return loc == '/onboarding' ? null : '/onboarding';
      }
      if (session == SessionState.locked) {
        return loc == '/lock' ? null : '/lock';
      }
      if (loc == '/' || loc == '/onboarding' || loc == '/lock') return '/ai';
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (c, s) => const OnboardingPage(),
      ),
      GoRoute(path: '/lock', builder: (c, s) => const LockPage()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/home', builder: (c, s) => const AcupointPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/records', builder: (c, s) => const RecordsPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/metrics', builder: (c, s) => const MetricsPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/firstaid', builder: (c, s) => const FirstAidPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/profile', builder: (c, s) => const ProfilePage()),
          ]),
        ],
      ),
      GoRoute(
        path: '/records/import',
        builder: (c, s) => const RecordImportPage(),
      ),
      // AI 健康管家：登录后默认首页（redirect 把 / 指到这里）。
      // page key 绑定会话代次：入口点击 bump 一次，强制全新 State——
      // 每次打开都是收起的历史 + 干净的新会话视图
      GoRoute(
        path: '/ai',
        pageBuilder: (c, s) => CustomTransitionPage(
          key: ValueKey('ai-${ref.read(aiSessionProvider)}'),
          child: const AiHomePage(),
          transitionsBuilder: (c, animation, secondary, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),
      GoRoute(
        path: '/records/:id',
        builder: (c, s) =>
            RecordDetailPage(recordId: int.parse(s.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/metrics/:id',
        builder: (c, s) =>
            MetricChartPage(metricId: int.parse(s.pathParameters['id']!)),
      ),
      GoRoute(path: '/family', builder: (c, s) => const FamilyPage()),
      GoRoute(
        path: '/family/edit',
        builder: (c, s) => FamilyEditPage(
          memberId: s.uri.queryParameters['id'] == null
              ? null
              : int.parse(s.uri.queryParameters['id']!),
          firstRun: s.uri.queryParameters['first'] == '1',
        ),
      ),
      GoRoute(
          path: '/medications', builder: (c, s) => const MedicationsPage()),
      GoRoute(
        path: '/medications/edit',
        builder: (c, s) => MedEditPage(
          medId: s.uri.queryParameters['id'] == null
              ? null
              : int.parse(s.uri.queryParameters['id']!),
        ),
      ),
      GoRoute(path: '/settings', builder: (c, s) => const SettingsPage()),
      GoRoute(path: '/backup', builder: (c, s) => const BackupPage()),
      GoRoute(
          path: '/constitution', builder: (c, s) => const ConstitutionPage()),
      GoRoute(path: '/box', builder: (c, s) => const BoxPage()),
      GoRoute(
        path: '/firstaid/:id',
        builder: (c, s) =>
            FirstAidDetailPage(scenarioId: s.pathParameters['id']!),
      ),
    ],
  );
}

class LingShuApp extends ConsumerStatefulWidget {
  const LingShuApp({super.key});

  @override
  ConsumerState<LingShuApp> createState() => _LingShuAppState();
}

class _LingShuAppState extends ConsumerState<LingShuApp> {
  // router 只建一次：build 里重建 GoRouter 会重置导航栈
  //（字体档位等任何触发本 widget rebuild 的状态都会把用户弹回首页）
  late final GoRouter _router = buildRouter(ref);

  @override
  Widget build(BuildContext context) {
    final fontScale = ref.watch(fontScaleProvider);
    return MaterialApp.router(
      title: '灵枢',
      debugShowCheckedModeBanner: false,
      theme: buildLingShuTheme(),
      locale: const Locale('zh', 'CN'),
      supportedLocales: const [Locale('zh', 'CN'), Locale('en', 'US')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: _router,
      builder: (context, child) {
        // 字体档位叠加在系统「字体大小」之上：TextScaler 作用于全部
        // Text（含字面量 fontSize），布局用弹性约束自适应
        final system = MediaQuery.textScalerOf(context).scale(1.0);
        return MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(system * fontScale)),
          child: child!,
        );
      },
    );
  }
}
