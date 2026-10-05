import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../core/logo.dart';
import '../../core/services/agent_service.dart';
import '../../core/theme.dart';
import '../../providers.dart';
import 'beidou_background.dart';

/// AI 原生入口（体验版）：北斗呼吸星野 + 单一输入框 + 呼吸语音球。
/// 文本/多图/语音进，智能体自动分派：归档病历 → 档案库；查指标 → 统计+趋势图；
/// 其余 → 大模型直接作答。经典界面不受影响（我的 → AI 健康助手 进入本页）。
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
  final String? chartTitle;
  final bool pending; // 助手思考中
  _Msg({
    this.text = '',
    this.imagePaths = const [],
    required this.user,
    this.chart,
    this.chartTitle,
    this.pending = false,
  });
}

class _AiHomePageState extends ConsumerState<AiHomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breathe =
      AnimationController(vsync: this, duration: const Duration(seconds: 4))
        ..repeat();

  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _attached = <String>[]; // 待发送图片路径
  final _msgs = <_Msg>[];

  bool _sending = false;
  bool _recording = false;
  bool _asrBusy = false; // 停止录音后的转写阶段
  final _recorder = AudioRecorder();

  static const _gold = LingShuColors.gold;
  static const _paper = Color(0xFFF8F4EB);

  @override
  void dispose() {
    _breathe.dispose();
    _recorder.dispose();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // ── 发送 ──

  Future<void> _send() async {
    final text = _input.text.trim();
    if (_sending || (text.isEmpty && _attached.isEmpty)) return;
    setState(() {
      _msgs.insert(0, _Msg(text: text, imagePaths: [..._attached], user: true));
      _msgs.insert(0, _Msg(user: false, pending: true));
      _input.clear();
      _attached.clear();
      _sending = true;
    });
    try {
      final ocr = await ref.read(aiConfigProvider.future);
      final agent = AgentService(ocr: ocr);
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
        imagePaths: _msgs[1].imagePaths, // 刚才那条用户消息里的图
        metricNames: [for (final m in metrics) m.name],
      );
      setState(() => _msgs[0] = _Msg(
          text: r.text, user: false, chart: r.chart, chartTitle: r.chartTitle));
    } catch (e) {
      setState(() => _msgs[0] = _Msg(text: '出了点问题：$e', user: false));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
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
            AnimatedBuilder(
              animation: _breathe,
              builder: (_, _) => BeidouBackground(t: _breathe.value),
            ),
            SafeArea(
              child: Column(
                children: [
                  _header(),
                  Expanded(child: _msgs.isEmpty ? _idleView() : _chatView()),
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
            Text('归档 · 问询 · 问答',
                style: TextStyle(
                    fontSize: 10, letterSpacing: 2, color: _paper.withValues(alpha: 0.55))),
          ]),
          const Spacer(),
          IconButton(
            tooltip: 'AI 设置',
            icon: Icon(Icons.settings_outlined,
                size: 20, color: _paper.withValues(alpha: 0.8)),
            onPressed: () => context.push('/settings'),
          ),
        ]),
      );

  /// 空闲态：星野中央的品牌区 + 示例提示
  Widget _idleView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: _gold.withValues(alpha: 0.35), blurRadius: 30),
              ],
            ),
            child: const LingShuLogo(size: 72, showBackground: false),
          ),
          const SizedBox(height: 18),
          const Text('一句话，我替你打理健康档案',
              style: TextStyle(
                  fontSize: 17,
                  letterSpacing: 2,
                  color: _paper,
                  fontFamily: 'SerifSC')),
          const SizedBox(height: 6),
          Text('传病历照片自动归档 · 说句话查指标趋势 · 养生问答',
              style: TextStyle(
                  fontSize: 11.5, color: _paper.withValues(alpha: 0.68))),
          const SizedBox(height: 26),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (emoji, text) in const [
                ('📊', '看看最近7天的血糖'),
                ('🗂', '帮我把这张病历归档'),
                ('🌿', '晚上睡不着怎么办'),
              ])
                ActionChip(
                  backgroundColor: Colors.white.withValues(alpha: 0.13),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.28)),
                  label: Text('$emoji $text',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white)),
                  onPressed: () => _input.text = text,
                ),
            ],
          ),
        ],
      ),
    );
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
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Row(children: [
            IconButton(
              tooltip: '添加照片（可多选）',
              icon: Icon(Icons.add_circle_outline,
                  size: 24, color: _paper.withValues(alpha: 0.85)),
              onPressed: _pickImages,
            ),
            Expanded(
              child: TextField(
                controller: _input,
                style: const TextStyle(color: _paper, fontSize: 14.5),
                maxLines: 4,
                minLines: 1,
                cursorColor: _gold,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  hintText: '传病历照片归档 / 查指标 / 提问…',
                  hintStyle: TextStyle(
                      color: _paper.withValues(alpha: 0.62), fontSize: 13.5),
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

  /// 呼吸球：金色光晕随 4 秒相位胀缩；录音时转为朱砂色、节奏加快
  Widget _orbButton() {
    return AnimatedBuilder(
      animation: _breathe,
      builder: (_, _) {
        final breathe =
            0.5 + 0.5 * math.sin(_breathe.value * 2 * math.pi);
        final scale = _recording ? 1.0 + 0.10 * breathe : 1.0 + 0.07 * breathe;
        final color = _recording ? WuXing.fire : _gold;
        return GestureDetector(
          onTap: _toggleMic,
          child: Container(
            margin: const EdgeInsets.only(top: 14),
            width: 84 * scale,
            height: 84 * scale,
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
                  : Icon(_recording ? Icons.stop_rounded : Icons.mic_none,
                      size: 32, color: Colors.white),
            ),
          ),
        );
      },
    );
  }
}
