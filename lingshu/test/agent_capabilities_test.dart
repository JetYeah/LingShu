import 'package:flutter_test/flutter_test.dart';

import 'package:lingshu/core/services/agent_capabilities.dart';

/// 「你能帮我做什么」类问句的本地识别：命中即不走大模型、无 Key 也能发现能力。
/// 关键约束：普通健康诉求（"高血压能吃什么"）不能被误判成能力问询。
void main() {
  test('常见问法全部命中', () {
    const hits = [
      '你能帮我做什么',
      '你能做什么',
      '你能干什么',
      '你都能干些什么',
      '你有哪些能力',
      '你有什么能力',
      '有什么功能',
      '你有什么技能',
      '功能列表',
      '介绍一下你的功能',
      '怎么使用你',
      '你是谁',
      '你是干什么的',
      '你会做些什么',
      '你能帮我做点什么吗？',
    ];
    for (final s in hits) {
      expect(isCapabilityQuestion(s), isTrue, reason: '「$s」应命中');
    }
  });

  test('普通健康诉求不误命中', () {
    const misses = [
      '你能帮我查血糖吗',
      '高血压能吃什么',
      '不能吃什么',
      '血压130/85',
      '看看最近7天的血糖',
      '黄芪的功效和禁忌',
      '晚上睡不着怎么办',
      '帮我归档这张病历',
      '今天吃什么好',
      '心率80正常吗',
      '',
      '   ',
    ];
    for (final s in misses) {
      expect(isCapabilityQuestion(s), isFalse, reason: '「$s」不应命中');
    }
  });

  test('能力目录：与 app 功能模块对齐，示例指令可直接发送', () {
    expect(capabilityCatalog.length, greaterThanOrEqualTo(13));
    final titles = capabilityCatalog.map((c) => c.title).toSet();
    expect(titles.length, capabilityCatalog.length, reason: '标题不重复');
    for (final c in capabilityCatalog) {
      expect(c.example.trim().isNotEmpty, isTrue, reason: '「${c.title}」示例不能为空');
      expect(c.desc.trim().isNotEmpty, isTrue, reason: '「${c.title}」说明不能为空');
    }
    // 核心模块各至少一项
    for (final k in ['病历归档', '指标查询', '口述记指标', '用药管理', '急救指南', '中药图鉴', '穴位查询', '体质与调养', '药箱盘点', '健康概览']) {
      expect(titles.contains(k), isTrue, reason: '缺少能力「$k」');
    }
  });
}
