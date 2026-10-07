import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:lingshu/core/services/ai_history_store.dart';

/// AI 管家会话历史落盘：round-trip、损坏容错、清空。
/// 目录注入临时路径，不碰真机文档目录。
void main() {
  late Directory tmp;
  late AiHistoryStore store;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('ai_hist_test');
    store = AiHistoryStore(dir: () async => tmp);
  });

  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  test('save/load round-trip：文本/角色/图表路径保序', () async {
    final chart = File('${tmp.path}/chart_1.png');
    chart.createSync();
    await store.save([
      const AiHistoryEntry(
          user: true, text: '看看血糖', imagePaths: ['/tmp/a.jpg']),
      AiHistoryEntry(
          user: false,
          text: '血糖 6.2',
          chartPath: chart.path,
          chartTitle: '血糖趋势'),
    ]);
    final loaded = await store.load();
    expect(loaded.length, 2);
    expect(loaded[0].user, isTrue);
    expect(loaded[0].text, '看看血糖');
    expect(loaded[1].chartPath, chart.path);
    expect(loaded[1].chartTitle, '血糖趋势');
  });

  test('加载时过滤已消失的图片与图表文件，文本保留', () async {
    await store.save(const [
      AiHistoryEntry(user: true, text: '带图消息', imagePaths: ['/no/such/a.jpg']),
      AiHistoryEntry(user: false, text: '回复', chartPath: '/no/such/c.png'),
    ]);
    final loaded = await store.load();
    expect(loaded[0].imagePaths, isEmpty);
    expect(loaded[0].text, '带图消息');
    expect(loaded[1].chartPath, isNull);
  });

  test('JSON 损坏返回空表且不删除原文件（不静默清用户数据）', () async {
    await store.save(const [AiHistoryEntry(user: true, text: '重要历史')]);
    File('${tmp.path}/messages.json').writeAsStringSync('{broken json');
    expect(await store.load(), isEmpty);
    expect(File('${tmp.path}/messages.json').existsSync(), isTrue);
    // 修复后可恢复
    await store.save(const [AiHistoryEntry(user: true, text: '重要历史')]);
    expect((await store.load()).single.text, '重要历史');
  });

  test('save 上限裁剪（列表头部 300 条，尾部落选）', () async {
    await store.save([
      for (var i = 0; i < 350; i++) AiHistoryEntry(user: true, text: 'm$i'),
    ]);
    final loaded = await store.load();
    expect(loaded.length, 300);
    expect(loaded.first.text, 'm0');
    expect(loaded.map((e) => e.text), isNot(contains('m349')),
        reason: '列表尾部的旧条目被裁掉');
  });

  test('clear 删除整个目录（含图表 PNG）；空目录 clear 返回 false', () async {
    await store.saveChart([1, 2, 3]);
    await store.save(const [AiHistoryEntry(user: true, text: 'x')]);
    expect(await store.clear(), isTrue);
    expect(tmp.existsSync(), isFalse);
    expect(await store.load(), isEmpty);
    expect(await store.clear(), isFalse);
  });
}
