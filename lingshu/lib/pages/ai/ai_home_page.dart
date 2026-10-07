import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../core/services/agent_capabilities.dart';
import '../../core/services/agent_service.dart';
import '../../core/services/ai_history_store.dart';
import '../../core/theme.dart';
import '../../providers.dart';
import 'beidou_background.dart';

/// AI 原生入口（体验版）：北斗呼吸星野 + 单一输入框 + 呼吸语音球。
/// 文本/多图/语音进，智能体自动分派到 app 全部能力：归档/查指标/记指标/用药/
/// 档案/概览/体质/药箱/急救/中药/穴位/节气，其余由大模型直接作答。
/// 会话历史落盘（ai_history_store）：每次打开默认收起，点历史条展开，
/// 头部按钮清空（需确认）；不点清空绝不丢历史。
/// 经典界面不受影响（我的 → AI 健康管家 进入本页）。
class AiHomePage extends ConsumerStatefulWidget {
  const AiHomePage({super.key});

  @override
  ConsumerState<AiHomePage> createState() => _AiHomePageState();
}

class _Msg {
  final String text;
  final List<String> imagePaths; // 用户附带照片（缩略展示）
  final bool user;
  final Uint8List? chart; // 助手返回的趋势图
  final String? chartPath; // 图表落盘路径（持久化用）
  final String? chartTitle;
  final List<AgentCapability> capabilities; // 能力点选列表（问「你能做什么」时）
  final String? route; // 可跳转的 app 内页面
  final String? routeLabel;
  final bool pending; // 助手思考中
  _Msg({
    this.text = '',
    this.imagePaths = const [],
    required this.user,
    this.chart,
    this.chartPath,
    this.chartTitle,
    this.capabilities = const [],
    this.route,
    this.routeLabel,
    this.pending = false,
  });
}

class _AiHomePageState extends ConsumerState<AiHomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breathe =
      AnimationController(vsync: this, duration: const Duration(seconds: 6))
        ..repeat(); // 呼吸球 6s 一息；星野用 Stopwatch 秒数驱动独立闪烁

  final Stopwatch _clock = Stopwatch()..start(); // 星野闪烁的全局秒数

  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _attached = <String>[]; // 待发送图片路径
  final _msgs = <_Msg>[];

  /// 历史收起态：每次打开页面默认收起（page key 每次入口点击都更换，
  /// State 必为新建）；新提问或点历史条才展开。收起 ≠ 删除，历史落盘。
  bool _historyCollapsed = true;
  bool _sending = false;
  bool _recording = false;
  bool _asrBusy = false; // 停止录音后的转写阶段
  final _recorder = AudioRecorder();

  late final AiHistoryStore _histStore;

  static const _gold = LingShuColors.gold;
  static const _paper = Color(0xFFF8F4EB);

  @override
  void initState() {
    super.initState();
    _histStore = AiHistoryStore(dir: () async {
      final docs = await getApplicationDocumentsDirectory();
      return Directory(p.join(docs.path, 'ai_history'));
    });
    _loadHistory();
  }

  /// 从磁盘加载历史（最新在前）；读失败当作无历史，绝不动原文件
  Future<void> _loadHistory() async {
    try {
      final entries = await _histStore.load();
      if (entries.isEmpty || !mounted) return;
      setState(() {
        // 追加在既有消息之后（正常为空；极早发送时新消息仍在顶部）
        _msgs.addAll([
          for (final e in entries)
            _Msg(
              text: e.text,
              imagePaths: e.imagePaths,
              user: e.user,
              chart: e.chartPath == null
                  ? null
                  : File(e.chartPath!).readAsBytesSync(),
              chartPath: e.chartPath,
              chartTitle: e.chartTitle,
            ),
        ]);
      });
    } catch (e) {
      debugPrint('[ai] load history failed: $e');
    }
  }

  /// 会话落盘（过滤思考中占位；最新在前）。失败仅记日志，不打扰会话。
  Future<void> _persist() async {
    try {
      await _histStore.save([
        for (final m in _msgs)
          if (!m.pending)
            AiHistoryEntry(
              user: m.user,
              text: m.text,
              imagePaths: m.imagePaths,
              chartPath: m.chartPath,
              chartTitle: m.chartTitle,
            ),
      ]);
    } catch (e) {
      debugPrint('[ai] persist history failed: $e');
    }
  }

  @override
  void dispose() {
    _breathe.dispose();
    _clock.stop();
    _recorder.dispose();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // ── 发送 ──

  Future<void> _send() async {
    final text = _input.text.trim();
    if (_sending || (text.isEmpty && _attached.isEmpty)) return;
    final images = [..._attached];
    setState(() {
      _input.clear();
      _attached.clear();
    });
    await _dispatch(text, images);
  }

  /// 能力点选：示例指令直接发送
  Future<void> _sendCapability(AgentCapability cap) async {
    if (_sending) return;
    await _dispatch(cap.example, const []);
  }

  Future<void> _dispatch(String text, List<String> imagePaths) async {
    if (_sending) return;
    setState(() {
      // 新提问即展开会话视图（含收起中的历史）
      _historyCollapsed = false;
      _msgs.insert(0, _Msg(text: text, imagePaths: imagePaths, user: true));
      _msgs.insert(0, _Msg(user: false, pending: true));
      _sending = true;
    });
    _persist();
    try {
      final ocr = await ref.read(aiConfigProvider.future);
      final agent = AgentService(
        ocr: ocr,
        notifications: ref.read(notificationServiceProvider),
        content: ref.read(contentProvider),
      );
      final db = ref.read(dbProvider);
      final profileId = ref.read(currentProfileIdProvider);
      if (profileId == null) throw Exception('请先建立家庭成员档案');
      final metrics = await (db.select(db.metrics)
            ..where((m) => m.profileId.equals(profileId)))
          .get();
      final r = await agent.handle(
        db: db,
        profileId: profileId,
        message: text,
        imagePaths: imagePaths,
        metricNames: [for (final m in metrics) m.name],
      );
      // 趋势图落盘，历史回看才有图（原图表 PNG 只在内存）
      final chartPath =
          r.chart == null ? null : await _histStore.saveChart(r.chart!);
      setState(() => _msgs[0] = _Msg(
          text: r.text,
          user: false,
          chart: r.chart,
          chartPath: chartPath,
          chartTitle: r.chartTitle,
          capabilities: r.capabilities,
          route: r.route,
          routeLabel: r.routeLabel));
    } catch (e) {
      setState(() => _msgs[0] = _Msg(text: '出了点问题：$e', user: false));
    } finally {
      if (mounted) {
        setState(() => _sending = false);
        _persist();
      }
    }
  }

  // ── 清空历史：唯一删除入口，需确认；不点不删 ──

  Future<void> _confirmClear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('清空历史记录'),
        content: Text('将删除全部 ${_msgs.length} 条会话消息（含趋势图），'
            '删除后不可恢复。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: LingShuColors.danger),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('清空'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() {
      _msgs.clear();
      _historyCollapsed = true;
    });
    await _histStore.clear();
    _persist();
  }

  // ── 图片附件 ──

  Future<void> _pickImages() async {
    if (_attached.length >= 9) return;
    final xs = await ImagePicker()
        .pickMultiImage(maxWidth: 2400, imageQuality: 90);
    if (xs.isEmpty) return;
    setState(() => _attached.addAll(xs.map((e) => e.path).take(9 - _attached.length)));
  }

  // ── 语音：呼吸球按一下开始，再按结束并转写进输入框 ──

  Future<void> _toggleMic() async {
    if (_asrBusy) return;
    if (!_recording) {
      try {
        if (!await _recorder.hasPermission()) {
          _toast('未获得麦克风权限');
          return;
        }
        final dir = await getTemporaryDirectory();
        await _recorder.start(
          const RecordConfig(
              encoder: AudioEncoder.wav, numChannels: 1, sampleRate: 16000),
          path: '${dir.path}${Platform.pathSeparator}ls_ai_speech.wav',
        );
        setState(() => _recording = true);
      } catch (e) {
        _toast('无法开始录音：$e');
      }
      return;
    }
    setState(() {
      _recording = false;
      _asrBusy = true;
    });
    try {
      final path = await _recorder.stop();
      final asr = await ref.read(asrConfigProvider.future);
      if (asr.apiKey.isEmpty) {
        _toast('未配置语音识别：请到「我的 → 设置」填写（可复用 AI 识别的 Key）');
        return;
      }
      if (path == null) {
        _toast('录音失败，请重试');
        return;
      }
      final bytes = await File(path).readAsBytes();
      if (bytes.length < 2000) {
        _toast('录音太短');
        return;
      }
      final text = await asr.transcribe(bytes);
      setState(() {
        _input.text = _input.text.isEmpty ? text : '${_input.text} $text';
      });
    } catch (e) {
      _toast('语音识别失败：$e');
    } finally {
      if (mounted) setState(() => _asrBusy = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), width: 340));
  }

  /// 子午流注读数：当前时辰 · 当令经 · 养生提示。
  /// 数据源 ContentRepo.shichen（solar_terms.json），main 启动时已预加载。
  String _shichenTip() {
    final s = BeidouBackground.shichenOf(DateTime.now()); // 如「戌时」
    final branch = s.substring(0, s.length - 1);
    final hit = ref
        .read(contentProvider)
        .shichen
        .where((e) => e.branch == branch)
        .firstOrNull;
    if (hit == null) return s;
    final tip =
        hit.tip.endsWith('。') ? hit.tip.substring(0, hit.tip.length - 1) : hit.tip;
    return '$s · ${hit.meridian} · $tip';
  }

  // ── UI ──

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: LingShuColors.stageBottom,
        body: Stack(
          children: [
            // 星野动画只重建背景层；会话/输入区不随帧重建
            // 星野层用真实秒数：北斗闪烁相位独立于呼吸球
            AnimatedBuilder(
              animation: _breathe,
              builder: (_, _) => BeidouBackground(
                  t: _clock.elapsedMilliseconds / 1000.0),
            ),
            SafeArea(
              child: Column(
                children: [
                  _header(),
                  Expanded(
                    // 收起时回到空闲视图（历史不显示但保留），新会话直接开始
                    child: (_msgs.isEmpty || _historyCollapsed)
                        ? _idleView()
                        : _chatView(),
                  ),
                  _inputArea(),
                  _orbButton(),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() => Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
        child: Row(children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                size: 20, color: _paper),
            onPressed: () => context.pop(),
          ),
          const Spacer(),
          Column(children: [
            Text('灵枢 · AI 健康管家',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                    color: _paper,
                    fontFamily: 'SerifSC')),
            const SizedBox(height: 2),
            Text('档案 · 指标 · 用药 · 百科 · 急救',
                style: TextStyle(
                    fontSize: 10, letterSpacing: 2, color: _paper.withValues(alpha: 0.55))),
          ]),
          const Spacer(),
          // 清空历史：唯一删除入口（有历史时才出现，点击需确认）
          if (_msgs.isNotEmpty)
            IconButton(
              tooltip: '清空历史记录',
              icon: Icon(Icons.delete_sweep_outlined,
                  size: 21, color: _paper.withValues(alpha: 0.8)),
              onPressed: _confirmClear,
            ),
          IconButton(
            tooltip: 'AI 设置',
            icon: Icon(Icons.settings_outlined,
                size: 20, color: _paper.withValues(alpha: 0.8)),
            onPressed: () => context.push('/settings'),
          ),
        ]),
      );

  /// 空闲态：星野即主视觉（北斗绕北天极流转），标语贴近底部输入区
  Widget _idleView() {
    return const SizedBox.expand(); // 星野留白；标语已并入 _inputArea 顶部
  }

  Widget _chatView() {
    return ListView.builder(
      controller: _scroll,
      reverse: true,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      itemCount: _msgs.length,
      itemBuilder: (_, i) => Align(
        alignment: _msgs[i].user ? Alignment.centerRight : Alignment.centerLeft,
        child: _bubble(_msgs[i]),
      ),
    );
  }

  Widget _bubble(_Msg m) {
    final bubble = Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      constraints:
          BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
      decoration: BoxDecoration(
        color: m.user
            ? _gold.withValues(alpha: 0.22)
            : Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(m.user ? 16 : 4),
          bottomRight: Radius.circular(m.user ? 4 : 16),
        ),
        border: Border.all(
            color: m.user
                ? _gold.withValues(alpha: 0.45)
                : Colors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (m.imagePaths.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final path in m.imagePaths)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(File(path),
                        width: 64, height: 64, fit: BoxFit.cover),
                  ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          if (m.pending)
            Row(mainAxisSize: MainAxisSize.min, children: [
              const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 1.6, color: _gold)),
              const SizedBox(width: 10),
              Text('思考中…',
                  style: TextStyle(
                      fontSize: 12.5, color: _paper.withValues(alpha: 0.6))),
            ])
          else if (m.text.isNotEmpty)
            Text(m.text,
                style: const TextStyle(
                    fontSize: 14, height: 1.55, color: _paper)),
          // 能力点选列表（问「你能做什么」时）：点一行直接替用户发出示例指令
          if (m.capabilities.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final cap in m.capabilities)
              GestureDetector(
                onTap: () => _sendCapability(cap),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 9),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.14)),
                  ),
                  child: Row(children: [
                    Text(cap.emoji, style: const TextStyle(fontSize: 17)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(cap.title,
                              style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: _paper)),
                          const SizedBox(height: 2),
                          Text(cap.desc,
                              style: TextStyle(
                                  fontSize: 11,
                                  height: 1.3,
                                  color: _paper.withValues(alpha: 0.55))),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_outward,
                        size: 15, color: _paper.withValues(alpha: 0.4)),
                  ]),
                ),
              ),
          ],
          if (m.route != null && m.routeLabel != null) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () => context.push(m.route!),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _gold.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _gold.withValues(alpha: 0.5)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.open_in_new,
                        size: 13, color: _gold.withValues(alpha: 0.9)),
                    const SizedBox(width: 6),
                    Text('打开 · ${m.routeLabel}',
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: _gold.withValues(alpha: 0.95))),
                  ]),
                ),
              ),
            ),
          ],
          if (m.chart != null) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _showChart(m),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
              child: Image.memory(m.chart!,
                  width: double.infinity, fit: BoxFit.contain),
              ),
            ),
          ],
        ],
      ),
    );
    return bubble;
  }

  void _showChart(_Msg m) {
    showDialog(
      context: context,
      builder: (c) => Dialog(
        backgroundColor: Colors.black87,
        child: InteractiveViewer(
          maxScale: 4,
          child: Image.memory(m.chart!, fit: BoxFit.contain),
        ),
      ),
    );
  }

  Widget _inputArea() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
      child: Column(children: [
        // 空闲态标语：贴在快捷按钮上方一点点（历史收起时同属"新会话"观感）
        if (_msgs.isEmpty || _historyCollapsed) ...[
          Text('一句话，我替你打理健康档案',
              style: const TextStyle(
                  fontSize: 15,
                  letterSpacing: 2,
                  color: _paper,
                  fontFamily: 'SerifSC')),
          const SizedBox(height: 5),
          // 子午流注读数：当前时辰 · 当令经 · 养生提示（ContentRepo.shichen
          // 此前只在数据层从未上界面）
          Text(_shichenTip(),
              style: TextStyle(
                  fontSize: 11.5,
                  letterSpacing: 1,
                  color: _paper.withValues(alpha: 0.55))),
          const SizedBox(height: 8),
        ],
        // 历史收起提示条：历史在但不显示，点按展开（不点不删）
        if (_historyCollapsed && _msgs.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: GestureDetector(
              onTap: () => setState(() => _historyCollapsed = false),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.30)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.history,
                      size: 15, color: Colors.white.withValues(alpha: 0.75)),
                  const SizedBox(width: 7),
                  Text('历史会话 ${_msgs.length} 条 · 点击展开',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.9))),
                ]),
              ),
            ),
          ),
        // 快捷功能：贴在输入框上方（空闲无会话或历史收起时显示），可换行不超屏
        if (_msgs.isEmpty || _historyCollapsed)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (emoji, text) in const [
                  ('🏥', '我的健康概览'),
                  ('📊', '看看最近7天的血糖'),
                  ('🗂', '帮我把这张病历归档'),
                  ('✨', '你能帮我做什么'),
                ])
                  // 自绘胶囊而非 ActionChip：应用主题会把 chip 背景强制成
                  // 不透明 surface（白色），白字落在白底上会隐形（真机踩坑）
                  GestureDetector(
                    onTap: () => _input.text = text,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.30)),
                      ),
                      child: Text('$emoji $text',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                    ),
                  ),
              ],
            ),
          ),
        if (_attached.isNotEmpty)
          SizedBox(
            height: 64,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final path in _attached)
                  Stack(children: [
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(File(path),
                            width: 60, height: 60, fit: BoxFit.cover),
                      ),
                    ),
                    Positioned(
                      right: 2,
                      top: 2,
                      child: GestureDetector(
                        onTap: () => setState(() => _attached.remove(path)),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                              color: Colors.black54, shape: BoxShape.circle),
                          child: const Icon(Icons.close,
                              size: 12, color: Colors.white),
                        ),
                      ),
                    ),
                  ]),
              ],
            ),
          ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Row(children: [
            IconButton(
              tooltip: '添加照片（可多选）',
              icon: Icon(Icons.add_circle_outline,
                  size: 24, color: LingShuColors.inkSoft),
              onPressed: _pickImages,
            ),
            Expanded(
              child: TextField(
                controller: _input,
                style: const TextStyle(color: LingShuColors.ink, fontSize: 14.5),
                maxLines: 4,
                minLines: 1,
                cursorColor: LingShuColors.ink,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  hintText: '健康事务一句话：记录 · 查询 · 归档 · 百科…',
                  hintStyle: TextStyle(
                      color: LingShuColors.inkSoft.withValues(alpha: 0.85),
                      fontSize: 13.5),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 4),
            _sending
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: _gold))
                : IconButton(
                    tooltip: '发送',
                    icon: const Icon(Icons.arrow_upward, size: 22, color: _gold),
                    onPressed: _send,
                  ),
          ]),
        ),
      ]),
    );
  }

  /// 呼吸球：金色光晕随 4 秒相位胀缩；录音时转为朱砂色。
  /// 外框固定尺寸、内部用 Transform.scale 缩放——不占布局，
  /// 输入框和文字不会跟着上下晃
  Widget _orbButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: SizedBox(
        width: 104,
        height: 96, // 84 × 最大 1.10 缩放 ≈ 92.4，留足余量
        child: AnimatedBuilder(
          animation: _breathe,
          builder: (_, _) {
            // 呼吸球 6 秒一息（value 0..1 即相位）
            final breathe =
                0.5 + 0.5 * math.sin(_breathe.value * 2 * math.pi);
            final scale =
                _recording ? 1.0 + 0.10 * breathe : 1.0 + 0.07 * breathe;
            final color = _recording ? WuXing.fire : _gold;
            return Center(
              child: Transform.scale(
                scale: scale,
                child: GestureDetector(
                  onTap: _toggleMic,
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        color.withValues(alpha: 0.95),
                        color.withValues(alpha: 0.55),
                      ]),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.35 + 0.35 * breathe),
                          blurRadius: 26 + 18 * breathe,
                          spreadRadius: 2 + 4 * breathe,
                        ),
                      ],
                    ),
                    child: Center(
                      child: _asrBusy
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Icon(
                              _recording ? Icons.stop_rounded : Icons.mic_none,
                              size: 32,
                              color: Colors.white),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
