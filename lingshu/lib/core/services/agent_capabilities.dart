/// AI 管家能力目录 +「你能做什么」类问题的本地识别。
/// 目录是单一事实源：会话里的点选列表、路由提示词的能力边界说明都取自这里。
library;

/// 一项可向用户展示、点选即用的能力
class AgentCapability {
  final String emoji;
  final String title;
  final String desc; // 一句话说明
  final String example; // 点选后直接发送的示例指令
  const AgentCapability(this.emoji, this.title, this.desc, this.example);
}

/// 全能力目录（与 app 功能模块一一对应）
const capabilityCatalog = <AgentCapability>[
  AgentCapability('🗂', '病历归档', '发病历/检验单照片，识别后存入档案库并自动录入指标', '帮我把这张病历归档'),
  AgentCapability('📊', '指标查询', '血压/血糖等指标的统计与趋势图', '看看最近7天的血糖'),
  AgentCapability('✍️', '口述记指标', '一句话记录血压、心率、血糖、体重等测量值', '记一下 血压130/85 心率76'),
  AgentCapability('🏥', '健康概览', '汇总档案、指标、用药与药箱的一次体检式报告', '我的健康概览'),
  AgentCapability('💊', '用药管理', '查看在用药物安排，创建或停用用药提醒', '提醒我每天早晚8点各吃一次降压药'),
  AgentCapability('🧾', '档案查询', '查阅已归档的病历、报告清单', '我最近有哪些检验报告？'),
  AgentCapability('☯️', '体质与调养', '查看体质辨识结论与食养起居建议', '我的体质怎么样，怎么调养？'),
  AgentCapability('🧰', '药箱盘点', '家庭小药箱临期/过期药品检查', '药箱里有什么药快过期了？'),
  AgentCapability('🚑', '急救指南', '26 个常见急救场景的分步指引', '烫伤了怎么急救？'),
  AgentCapability('🌿', '中药图鉴', '879 味中药的功效、性味归经、禁忌与验方', '黄芪的功效和禁忌'),
  AgentCapability('⚡', '穴位查询', '穴位定位、主治与按揉手法', '合谷穴在哪里，有什么用？'),
  AgentCapability('🗓', '节气养生', '今日节气与应季调养提示', '今天是什么节气，怎么养生？'),
  AgentCapability('💬', '健康问答', '养生咨询、看图答疑、闲聊解闷', '晚上睡不着，有什么调理建议？'),
];

/// 「你能帮我做什么/你能干什么/你有哪些能力」类问题本地识别：
/// 命中则不请求大模型，直接返回能力点选列表（无 API Key 也可用）。
/// 只放宽到「问能力」的说法，普通诉求（"你能帮我查血糖吗"）不会误命中。
bool isCapabilityQuestion(String message) {
  var t = message.trim();
  // 去掉句尾语气词与标点
  while (t.isNotEmpty) {
    final last = t[t.length - 1];
    if ('?？!！。，,、呢啊呀嘛哦吗'.contains(last)) {
      t = t.substring(0, t.length - 1);
    } else {
      break;
    }
  }
  if (t.isEmpty || t.length > 24) return false;
  // 主语限定「你/您」+ 动词白名单：避免「高血压能吃什么」这类健康问句误命中
  final patterns = [
    RegExp('[你您](都|全部)?(能|会)(帮忙|帮)?(我)?(做|干|办|处理|搞定)(点|些)?什么'),
    RegExp('(有哪些|有什么?|具备哪些?)能力'),
    RegExp('有什么?(功能|技能|本事|用途)'),
    RegExp('功能(列表|清单|介绍|大全|一览)'),
    RegExp('(都)?会(做|干)(点|些)?什么'),
    RegExp('介绍(一下)?(你|你自己|你的功能)'),
    RegExp('怎么(使用|用)(你|你个|这个助手|本助手)'),
    RegExp(r'^(你是谁|你叫什么|你是啥)$'),
    RegExp(r'^你(是|到底)?(个)?(做|干)什么的$'),
  ];
  return patterns.any((re) => re.hasMatch(t));
}
