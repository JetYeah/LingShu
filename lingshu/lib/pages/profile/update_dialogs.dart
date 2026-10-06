import 'package:flutter/material.dart';

import '../../core/services/update_service.dart';
import '../../core/theme.dart';

/// 更新流程：确认弹窗（含更新记录）→ 下载进度 → 拉起系统安装器
Future<void> showUpdateFlow(BuildContext context, UpdateCheck update,
    {UpdateService? service}) async {
  final go = await showDialog<bool>(
    context: context,
    builder: (_) => _UpdateConfirmDialog(update: update),
  );
  if (go == true && context.mounted) {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _UpdateProgressDialog(update: update, service: service),
    );
  }
}

/// 「发现新版本」确认弹窗：标题 + Release 主题 + 完整更新记录
class _UpdateConfirmDialog extends StatelessWidget {
  const _UpdateConfirmDialog({required this.update});
  final UpdateCheck update;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('发现新版本 v${update.latestVersion}'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(update.releaseTitle,
                style: TextStyle(
                    fontSize: 12.5,
                    color: LingShuColors.inkSoft,
                    fontWeight: FontWeight.w600)),
            const Divider(height: 20),
            Flexible(
              child: SingleChildScrollView(
                child: _ChangelogView(lines: update.changelog),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('暂不更新'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('立即更新'),
        ),
      ],
    );
  }
}

/// Release body 渲染：## 标题 / - 列表 / 段落，行内 **加粗**
class _ChangelogView extends StatelessWidget {
  const _ChangelogView({required this.lines});
  final List<ChangelogLine> lines;

  static List<InlineSpan> _spans(String s, TextStyle base) {
    final bold = base.copyWith(fontWeight: FontWeight.w700);
    final out = <InlineSpan>[];
    var start = 0;
    for (final m in RegExp(r'\*\*(.+?)\*\*').allMatches(s)) {
      if (m.start > start) {
        out.add(TextSpan(text: s.substring(start, m.start), style: base));
      }
      out.add(TextSpan(text: m.group(1), style: bold));
      start = m.end;
    }
    if (start < s.length) {
      out.add(TextSpan(text: s.substring(start), style: base));
    }
    return out.isEmpty ? [TextSpan(text: s, style: base)] : out;
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final body = const TextStyle(fontSize: 12.5, height: 1.65);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final l in lines)
          switch (l.kind) {
            ChangelogLineKind.heading => Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 7),
                child: Text.rich(TextSpan(children: _spans(l.text,
                    const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)))),
              ),
            ChangelogLineKind.bullet => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 6, top: 1),
                      child: Text('·', style: TextStyle(fontSize: 15, color: accent)),
                    ),
                    Expanded(child: Text.rich(TextSpan(children: _spans(l.text, body)))),
                  ],
                ),
              ),
            ChangelogLineKind.paragraph => Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Text.rich(TextSpan(children: _spans(l.text, body))),
              ),
          },
      ],
    );
  }
}

enum _Stage { downloading, needsPermission, ready, error }

/// 下载进度弹窗：下载 →（权限引导）→ 拉起安装器。
/// 下载中断自动重试（看门狗+续传），彻底失败保留 .part 供手动重试续传。
class _UpdateProgressDialog extends StatefulWidget {
  const _UpdateProgressDialog({required this.update, this.service});
  final UpdateCheck update;
  final UpdateService? service;

  @override
  State<_UpdateProgressDialog> createState() => _UpdateProgressDialogState();
}

class _UpdateProgressDialogState extends State<_UpdateProgressDialog> {
  late final UpdateService _service;
  _Stage _stage = _Stage.downloading;
  int _received = 0;
  int _total = 0;
  String? _error;
  String? _apkPath;
  bool _cancelled = false;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? UpdateService();
    _total = widget.update.apkSize;
    _start();
  }

  Future<void> _start() async {
    setState(() => _stage = _Stage.downloading);
    try {
      final path = await _service.downloadApk(widget.update,
          onProgress: (received, total) {
        if (mounted) {
          setState(() {
            _received = received;
            _total = total;
          });
        }
      });
      if (!mounted || _cancelled) return; // 用户已取消：静默留 .part 收尾
      _apkPath = path;
      await _openInstaller();
    } catch (e) {
      if (mounted) {
        setState(() {
          _stage = _Stage.error;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _openInstaller() async {
    if (_apkPath == null) return;
    try {
      final r = await _service.installApk(_apkPath!);
      if (!mounted) return;
      setState(() {
        _stage =
            r == 'needsPermission' ? _Stage.needsPermission : _Stage.ready;
      });
    } catch (e) {
      setState(() {
        _stage = _Stage.error;
        _error = e.toString();
      });
    }
  }

  static String _mb(int bytes) => (bytes / 1048576).toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final pct = _total > 0 ? (_received / _total).clamp(0.0, 1.0) : null;
    return PopScope(
      canPop: _stage == _Stage.error || _stage == _Stage.ready,
      child: AlertDialog(
        title: Text(switch (_stage) {
          _Stage.downloading => '正在下载 v${widget.update.latestVersion}',
          _Stage.needsPermission => '需要安装权限',
          _Stage.ready => '下载完成',
          _Stage.error => '下载失败',
        }),
        content: switch (_stage) {
          _Stage.downloading => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(value: pct, minHeight: 6),
                const SizedBox(height: 10),
                Text(
                  _total > 0
                      ? '${_mb(_received)} / ${_mb(_total)} MB（${(pct! * 100).toInt()}%）'
                      : '连接中…',
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 6),
                Text('支持断点续传，网络波动会自动重试',
                    style: TextStyle(
                        fontSize: 11.5, color: LingShuColors.inkSoft)),
              ],
            ),
          _Stage.needsPermission => const Text(
              '首次安装需允许灵枢「安装未知应用」。\n\n'
              '已为你打开系统授权页：找到灵枢并勾选「允许来自此来源的应用」，返回后点击「开始安装」。',
              style: TextStyle(fontSize: 13, height: 1.7)),
          _Stage.ready => const Text(
              '已拉起系统安装器，请在安装页点击「安装」。\n\n'
              '直接覆盖安装，健康数据与设置不丢失。',
              style: TextStyle(fontSize: 13, height: 1.7)),
          _Stage.error => Text(
              '$_error\n\n已保留下载进度，重试将从断点继续。',
              style: const TextStyle(fontSize: 13, height: 1.7)),
        },
        actions: switch (_stage) {
          _Stage.downloading => [
              TextButton(
                onPressed: () {
                  _cancelled = true;
                  Navigator.of(context).pop();
                },
                child: const Text('取消'),
              ),
            ],
          _Stage.needsPermission => [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('关闭'),
              ),
              FilledButton(
                onPressed: _openInstaller,
                child: const Text('开始安装'),
              ),
            ],
          _Stage.ready => [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('关闭'),
              ),
              FilledButton(
                onPressed: _openInstaller,
                child: const Text('重新拉起安装器'),
              ),
            ],
          _Stage.error => [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: _start,
                child: const Text('重试'),
              ),
            ],
        },
      ),
    );
  }
}
