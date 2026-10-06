import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingshu/core/services/update_service.dart';

/// 应用内更新：版本比较、changelog 解析、GitHub latest API 解析（本地
/// HttpServer 模拟，含 v 前缀 tag / digest / 无 APK 异常路径）。
void main() {
  group('compareVersions', () {
    test('点分数字逐段比较', () {
      expect(UpdateService.compareVersions('0.1.44', '0.1.43'), greaterThan(0));
      expect(UpdateService.compareVersions('0.1.43', '0.1.43'), 0);
      expect(UpdateService.compareVersions('0.2.0', '0.1.99'), greaterThan(0));
      expect(UpdateService.compareVersions('0.10.0', '0.9.9'), greaterThan(0));
      expect(UpdateService.compareVersions('1.0.0', '0.99.99'), greaterThan(0));
      expect(UpdateService.compareVersions('0.1.42', '0.1.43'), lessThan(0));
    });

    test('容忍 v 前缀与位数不齐', () {
      expect(UpdateService.compareVersions('v0.1.44', '0.1.43'), greaterThan(0));
      expect(UpdateService.compareVersions('0.1', '0.1.0'), 0);
      expect(UpdateService.compareVersions('0.1.43.1', '0.1.43'), greaterThan(0));
    });

    test('带 +build 的本机版本与同点分 tag 视为相等（不提示更新）', () {
      expect(UpdateService.compareVersions('0.1.43+9912', '0.1.43'), 0);
    });
  });

  group('parseChangelog', () {
    test('识别标题 / 列表 / 段落并剥离语法壳', () {
      final lines = UpdateService.parseChangelog(
          '## 更新内容\n\n**★ 语音记录升级**\n\n- **血压**：分时段\n- 血糖语音\n');
      expect(lines.map((l) => l.kind), [
        ChangelogLineKind.heading,
        ChangelogLineKind.paragraph,
        ChangelogLineKind.bullet,
        ChangelogLineKind.bullet,
      ]);
      expect(lines[0].text, '更新内容');
      expect(lines[1].text, '**★ 语音记录升级**'); // 行内加粗留给展示层
      expect(lines[2].text, '**血压**：分时段');
      expect(lines[3].text, '血糖语音');
    });

    test('空 body 与空行', () {
      expect(UpdateService.parseChangelog(''), isEmpty);
      expect(UpdateService.parseChangelog('\n\n \n'), isEmpty);
    });
  });

  group('checkLatest', () {
    late HttpServer server;
    late Directory tmp;

    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('update_test_');
      server = await HttpServer.bind('127.0.0.1', 0);
    });

    tearDown(() async {
      await server.close(force: true);
      await tmp.delete(recursive: true);
    });

    void serve(String body, {int status = 200}) {
      server.listen((req) async {
        req.response.statusCode = status;
        req.response.headers.contentType = ContentType.json;
        req.response.write(body);
        await req.response.close();
      });
    }

    test('正常解析：v 前缀 tag、changelog、apk 资产、digest', () async {
      serve(jsonEncode({
        'tag_name': 'v0.1.44',
        'name': '灵枢 v0.1.44 · 测试主题',
        'body': '## 更新内容\n\n- **新增** A\n- 修复 B',
        'assets': [
          {
            'name': 'lingshu_v0.1.44_release_arm64.apk',
            'size': 33346698,
            'digest': 'sha256:abc123',
            'browser_download_url':
                'https://github.com/JetYeah/LingShu/releases/download/v0.1.44/lingshu_v0.1.44_release_arm64.apk',
          },
          {'name': 'checksums.txt', 'size': 300, 'browser_download_url': 'x'},
        ],
      }));
      final svc = UpdateService(
          apiBase: Uri.parse('http://127.0.0.1:${server.port}/releases/latest'),
          currentVersionOverride: '0.1.43');
      final u = await svc.checkLatest();

      expect(u.latestVersion, '0.1.44');
      expect(u.currentVersion, '0.1.43');
      expect(u.hasUpdate, isTrue);
      expect(u.releaseTitle, '灵枢 v0.1.44 · 测试主题');
      expect(u.changelog.length, 3);
      expect(u.changelog.first.kind, ChangelogLineKind.heading);
      expect(u.apkName, 'lingshu_v0.1.44_release_arm64.apk');
      expect(u.apkSize, 33346698);
      expect(u.apkSha256, 'abc123');
      expect(u.apkUrl, contains('v0.1.44'));
    });

    test('本机已是最新 → hasUpdate 为假', () async {
      serve(jsonEncode({
        'tag_name': 'v0.1.43',
        'name': '灵枢 v0.1.43',
        'body': '',
        'assets': [
          {'name': 'a.apk', 'size': 1, 'browser_download_url': 'u'},
        ],
      }));
      final svc = UpdateService(
          apiBase: Uri.parse('http://127.0.0.1:${server.port}/x'),
          currentVersionOverride: '0.1.43');
      expect((await svc.checkLatest()).hasUpdate, isFalse);
    });

    test('Release 未附 APK → 抛异常', () async {
      serve(jsonEncode({
        'tag_name': 'v0.1.44',
        'assets': [],
      }));
      final svc = UpdateService(
          apiBase: Uri.parse('http://127.0.0.1:${server.port}/x'),
          currentVersionOverride: '0.1.43');
      expect(svc.checkLatest(), throwsException);
    });

    test('API 非 200 → 抛异常', () async {
      serve('{"message": "rate limited"}', status: 403);
      final svc = UpdateService(
          apiBase: Uri.parse('http://127.0.0.1:${server.port}/x'),
          currentVersionOverride: '0.1.43');
      expect(svc.checkLatest(), throwsException);
    });

    test('无 digest 字段 → apkSha256 为 null（仅按大小校验）', () async {
      serve(jsonEncode({
        'tag_name': 'v0.1.44',
        'assets': [
          {'name': 'a.apk', 'size': 10, 'browser_download_url': 'u'},
        ],
      }));
      final svc = UpdateService(
          apiBase: Uri.parse('http://127.0.0.1:${server.port}/x'),
          currentVersionOverride: '0.1.43');
      expect((await svc.checkLatest()).apkSha256, isNull);
    });
  });
}
