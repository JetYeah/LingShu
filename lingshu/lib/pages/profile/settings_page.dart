import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../core/branding.dart';
import '../../core/theme.dart';
import '../../providers.dart';

/// 设置：AI 配置 / 安全 / 关于
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late final TextEditingController _baseUrl;
  late final TextEditingController _apiKey;
  late final TextEditingController _model;
  bool _biometric = false;
  bool _canBiometric = false;

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(sharedPreferencesProvider);
    _baseUrl = TextEditingController(
        text: prefs.getString('ai.base_url') ?? '');
    _apiKey = TextEditingController(text: prefs.getString('ai.api_key') ?? '');
    _model =
        TextEditingController(text: prefs.getString('ai.model') ?? '');
    _biometric = ref.read(authProvider).biometricEnabled;
    LocalAuthentication().canCheckBiometrics.then((v) {
      if (mounted) setState(() => _canBiometric = v);
    });
  }

  Future<void> _saveAI() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(
        'ai.base_url',
        _baseUrl.text.trim().isEmpty
            ? 'https://open.bigmodel.cn/api/paas/v4'
            : _baseUrl.text.trim());
    await prefs.setString('ai.api_key', _apiKey.text.trim());
    await prefs.setString(
        'ai.model', _model.text.trim().isEmpty ? 'glm-4v-flash' : _model.text.trim());
    ref.invalidate(aiConfigProvider);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('AI 配置已保存')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('AI 病历识别（OpenAI 兼容接口）',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 4),
          Text('默认使用智谱 glm-4v-flash（免费），也可配置其他兼容服务。',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: LingShuColors.inkSoft)),
          const SizedBox(height: 10),
          TextField(
            controller: _baseUrl,
            decoration: const InputDecoration(
                labelText: 'Base URL', hintText: 'https://open.bigmodel.cn/api/paas/v4'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _apiKey,
            obscureText: true,
            decoration: const InputDecoration(
                labelText: 'API Key', hintText: '在服务方控制台获取'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _model,
            decoration: const InputDecoration(
                labelText: '模型', hintText: 'glm-4v-flash'),
          ),
          const SizedBox(height: 10),
          FilledButton(onPressed: _saveAI, child: const Text('保存 AI 配置')),
          const SizedBox(height: 24),
          const Text('安全',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('生物识别解锁', style: TextStyle(fontSize: 14)),
            subtitle: Text(
              _canBiometric ? '指纹 / 面容解锁应用' : '本机不支持生物识别',
              style: const TextStyle(fontSize: 12),
            ),
            value: _biometric,
            onChanged: _canBiometric
                ? (v) async {
                    await ref.read(authProvider).setBiometricEnabled(v);
                    setState(() => _biometric = v);
                  }
                : null,
          ),
          const Divider(height: 32),
          const Text('隐私声明',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 8),
          Text(
            '· 全部健康数据（档案、指标、用药记录）均加密存储于本机，不上传任何服务器。\n'
            '· 使用 AI 识别时，照片将发送至你配置的识别服务，请自行确认该服务的隐私条款。\n'
            '· 穴位与养生内容整理自公开中医资料，急救内容参考 IFRC《国际急救、复苏和教育指南》，仅供学习与养生参考，不构成医疗建议；如有不适请及时就医。',
            style: const TextStyle(fontSize: 12.5, height: 1.7),
          ),
          const SizedBox(height: 24),
          const Center(child: AppFooter()),
        ],
      ),
    );
  }
}
