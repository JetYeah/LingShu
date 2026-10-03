import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../../core/services/herb_repo.dart';
import '../../core/services/ocr_service.dart';
import '../../core/theme.dart';
import '../../providers.dart';
import 'herb_detail_page.dart';

/// 拍照识别中药：拍药材/饮片/植物照片，AI 给出初步判断；
/// 命中图鉴库（879 味）可跳转详情并收入图鉴
class HerbIdentifyPage extends ConsumerStatefulWidget {
  const HerbIdentifyPage({super.key});

  @override
  ConsumerState<HerbIdentifyPage> createState() => _HerbIdentifyPageState();
}

class _HerbIdentifyPageState extends ConsumerState<HerbIdentifyPage> {
  String? _photo;
  HerbGuess? _result;
  bool _running = false;

  Future<void> _pick(ImageSource source) async {
    final x = await ImagePicker()
        .pickImage(source: source, maxWidth: 1600, imageQuality: 88);
    if (x == null) return;
    setState(() {
      _photo = x.path;
      _result = null;
    });
    _run();
  }

  Future<Uint8List> _compress(String path) async {
    final raw = await File(path).readAsBytes();
    final decoded = img.decodeImage(raw);
    if (decoded == null) return raw;
    final c =
        decoded.width > 1280 ? img.copyResize(decoded, width: 1280) : decoded;
    return Uint8List.fromList(img.encodeJpg(c, quality: 85));
  }

  Future<void> _run() async {
    if (_photo == null) return;
    final cfg = await ref.read(aiConfigProvider.future);
    if (cfg.apiKey.isEmpty) {
      _toast('请先在「我的 → 设置」配置视觉模型 API Key');
      return;
    }
    setState(() => _running = true);
    try {
      final bytes = await _compress(_photo!);
      final r = await cfg.identifyHerb(bytes);
      if (mounted) setState(() => _result = r);
    } catch (e) {
      _toast('识别失败：$e');
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  /// 识别名与图鉴库匹配（精确名或包含），命中返回该味
  Future<Herb?> _matchInRepo(String name) async {
    if (name.isEmpty || name == '未能识别') return null;
    final all = await HerbRepo().all();
    final exact = all.where((h) => h.name == name).firstOrNull;
    if (exact != null) return exact;
    return all
        .where((h) => name.contains(h.name) || h.name.contains(name))
        .firstOrNull;
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), width: 320));
  }

  @override
  Widget build(BuildContext context) {
    final r = _result;
    return Scaffold(
      appBar: AppBar(title: const Text('拍照识药')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: WuXing.wood.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: WuXing.wood.withValues(alpha: 0.25)),
            ),
            child: Row(children: [
              const Icon(Icons.eco_outlined, color: WuXing.wood, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                    '拍下中药材、饮片或药用植物，AI 给出初步判断；'
                    '命中图鉴可查看详情并收藏。仅供学习参考。',
                    style: TextStyle(fontSize: 11.5, height: 1.5)),
              ),
            ]),
          ),
          const SizedBox(height: 14),
          if (_photo == null)
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pick(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('拍照'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pick(ImageSource.gallery),
                  icon: const Icon(Icons.photo_outlined),
                  label: const Text('相册'),
                ),
              ),
            ])
          else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(File(_photo!),
                  height: 230, width: double.infinity, fit: BoxFit.cover),
            ),
            const SizedBox(height: 10),
            Row(children: [
              TextButton.icon(
                onPressed: _running ? null : () => setState(() => _photo = null),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('重选'),
              ),
              const Spacer(),
              if (_running)
                const Row(children: [
                  SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 8),
                  Text('识别中…', style: TextStyle(fontSize: 12)),
                ])
              else
                FilledButton.tonal(
                  onPressed: _run,
                  child: const Text('重新识别'),
                ),
            ]),
          ],
          if (r != null) ...[
            const SizedBox(height: 6),
            _resultCard(r),
          ],
        ],
      ),
    );
  }

  Widget _resultCard(HerbGuess r) {
    final confColor = r.confidence == '高'
        ? WuXing.wood
        : r.confidence == '中'
            ? LingShuColors.gold
            : LingShuColors.inkSoft;
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: LingShuColors.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(r.name,
                style: const TextStyle(
                    fontFamily: 'SerifSC',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: confColor.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: confColor.withValues(alpha: 0.4))),
              child: Text('把握 ${r.confidence}',
                  style: TextStyle(fontSize: 11, color: confColor)),
            ),
          ]),
          if (r.latin?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(r.latin!,
                  style: TextStyle(
                      fontSize: 11.5,
                      fontStyle: FontStyle.italic,
                      color: LingShuColors.inkSoft.withValues(alpha: 0.85))),
            ),
          const SizedBox(height: 10),
          if (r.features.isNotEmpty)
            _kv('识别特征', r.features),
          if (r.usage?.isNotEmpty == true) _kv('常见功效', r.usage!),
          if (r.caution?.isNotEmpty == true)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: WuXing.fire.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: WuXing.fire.withValues(alpha: 0.35), width: 0.8),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.warning_amber_rounded,
                    size: 15, color: WuXing.fire),
                const SizedBox(width: 7),
                Expanded(
                    child: Text(r.caution!,
                        style: const TextStyle(fontSize: 12.5, height: 1.5))),
              ]),
            ),
          const SizedBox(height: 12),
          FutureBuilder<Herb?>(
            future: _matchInRepo(r.name),
            builder: (context, snap) {
              final hit = snap.data;
              if (snap.connectionState != ConnectionState.done) {
                return const SizedBox.shrink();
              }
              if (hit == null) {
                return const Text('图鉴库中暂无此味，仅供参考',
                    style: TextStyle(
                        fontSize: 11.5, color: LingShuColors.inkSoft));
              }
              return SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => HerbDetailPage(herb: hit))),
                  child: const Text('查看图鉴详情（可收藏）'),
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          const Text('照片识别仅为初步参考，不能替代专业鉴定；用药请遵医嘱。',
              style: TextStyle(fontSize: 10.5, color: LingShuColors.inkSoft)),
        ]),
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: 62,
            child: Text(k,
                style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: LingShuColors.primary)),
          ),
          Expanded(
            child: Text(v,
                style: const TextStyle(fontSize: 13, height: 1.55)),
          ),
        ]),
      );
}
