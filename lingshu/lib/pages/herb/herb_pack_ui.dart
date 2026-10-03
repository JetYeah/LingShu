import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/services/herb_pack.dart';
import '../../core/theme.dart';

/// 中药配图：资源包已安装时读本地文件，未安装时回退占位。
/// [asset] 形如 assets/herb_images/B00339.jpg（herbs.json 的 img/plantImg 拼出）
class HerbImage extends StatefulWidget {
  final String asset;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget Function(BuildContext context)? placeholderBuilder;

  const HerbImage({
    super.key,
    required this.asset,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholderBuilder,
  });

  @override
  State<HerbImage> createState() => _HerbImageState();
}

class _HerbImageState extends State<HerbImage> {
  String? _path;
  var _resolved = false;

  @override
  void initState() {
    super.initState();
    HerbPack.instance.stateStamp.addListener(_resolve);
    _resolve();
  }

  void _resolve() {
    HerbPack.instance.resolveFile(widget.asset).then((path) {
      if (mounted) setState(() { _path = path; _resolved = true; });
    });
  }

  @override
  void didUpdateWidget(covariant HerbImage old) {
    super.didUpdateWidget(old);
    if (old.asset != widget.asset) _resolve();
  }

  @override
  void dispose() {
    HerbPack.instance.stateStamp.removeListener(_resolve);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_resolved) {
      return SizedBox(width: widget.width, height: widget.height);
    }
    if (_path != null) {
      return Image.file(File(_path!),
          fit: widget.fit, width: widget.width, height: widget.height);
    }
    if (widget.placeholderBuilder != null) {
      return widget.placeholderBuilder!(context);
    }
    return Container(
      width: widget.width,
      height: widget.height,
      color: LingShuColors.paperDeep,
      alignment: Alignment.center,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.local_florist_outlined,
            size: 30, color: LingShuColors.gold.withValues(alpha: 0.45)),
        const SizedBox(height: 6),
        Text('安装配图包后显示',
            style: TextStyle(
                fontSize: 11, color: LingShuColors.inkSoft.withValues(alpha: 0.8))),
      ]),
    );
  }
}

/// 配图包横幅：未安装 → 下载入口；安装中 → 进度；已安装 → 不显示。
/// [dismissable] 允许本次会话不再提示。
class HerbPackBanner extends StatefulWidget {
  final bool dismissable;
  const HerbPackBanner({super.key, this.dismissable = true});

  @override
  State<HerbPackBanner> createState() => _HerbPackBannerState();
}

class _HerbPackBannerState extends State<HerbPackBanner> {
  bool? _installed; // null = 查询中
  bool _downloading = false;
  double _progress = 0;
  String _phase = '';
  bool _dismissed = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    HerbPack.instance.installedVersion().then((v) {
      if (mounted) setState(() => _installed = v != null);
    });
  }

  void _start() {
    setState(() {
      _downloading = true;
      _error = null;
      _progress = 0;
      _phase = '准备下载…';
    });
    HerbPack.instance.install((p, phase) {
      if (mounted) setState(() { _progress = p; _phase = phase; });
    }).then((_) {
      if (mounted) setState(() { _installed = true; _downloading = false; });
    }).catchError((e) {
      if (mounted) setState(() { _downloading = false; _error = '$e'; });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_installed == true || _dismissed) return const SizedBox.shrink();
    if (_installed == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: LingShuColors.gold.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LingShuColors.gold.withValues(alpha: 0.35)),
      ),
      child: _downloading
          ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_phase,
                  style: const TextStyle(
                      fontSize: 12.5, color: LingShuColors.ink)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                    value: _progress <= 0 ? null : _progress,
                    minHeight: 6,
                    backgroundColor:
                        LingShuColors.gold.withValues(alpha: 0.15),
                    color: LingShuColors.gold),
              ),
            ])
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.photo_library_outlined,
                    size: 17, color: LingShuColors.gold),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                      _error == null
                          ? '中药配图包未安装（约 ${HerbPack.packSizeMB} MB），药材与原植物图片需下载后显示'
                          : '$_error',
                      style: const TextStyle(
                          fontSize: 12, height: 1.4, color: LingShuColors.inkSoft)),
                ),
                if (widget.dismissable)
                  GestureDetector(
                    onTap: () => setState(() => _dismissed = true),
                    child: Icon(Icons.close,
                        size: 16, color: LingShuColors.inkSoft.withValues(alpha: 0.6)),
                  ),
              ]),
              const SizedBox(height: 8),
              SizedBox(
                height: 32,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14)),
                  onPressed: _start,
                  icon: const Icon(Icons.download_rounded, size: 17),
                  label: const Text('下载配图包',
                      style: TextStyle(fontSize: 12.5)),
                ),
              ),
            ]),
    );
  }
}
