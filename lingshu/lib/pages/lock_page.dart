import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';

import '../core/branding.dart';
import '../core/logo.dart';
import '../core/theme.dart';
import '../providers.dart';

/// 启动验证：PIN / 生物识别
class LockPage extends ConsumerStatefulWidget {
  const LockPage({super.key});

  @override
  ConsumerState<LockPage> createState() => _LockPageState();
}

class _LockPageState extends ConsumerState<LockPage> {
  final _pin = TextEditingController();
  String _error = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
  }

  Future<void> _tryBiometric() async {
    final auth = ref.read(authProvider);
    if (!auth.pinSet) return;
    if (!auth.biometricEnabled) {
      _toast('请先在「我的 → 设置」开启指纹/面容解锁');
      return;
    }
    try {
      final ok = await LocalAuthentication().authenticate(
        localizedReason: '请验证以解锁灵枢',
        options: const AuthenticationOptions(biometricOnly: false),
      );
      if (!mounted) return;
      if (ok) {
        ref.read(sessionProvider.notifier).unlock();
        // 路由 redirect 不随状态变化自动重算，必须手动跳转（与 PIN 解锁一致）
        context.go('/home');
      }
    } catch (_) {
      if (mounted) _toast('生物识别不可用，请输入 PIN 解锁');
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), width: 320));
  }

  void _submit() {
    final auth = ref.read(authProvider);
    if (!auth.pinSet || auth.verifyPin(_pin.text)) {
      ref.read(sessionProvider.notifier).unlock();
      context.go('/home');
    } else {
      setState(() {
        _error = 'PIN 不正确';
        _pin.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const LingShuLogo(size: 76),
              const SizedBox(height: 16),
              const Text('灵枢已上锁',
                  style: TextStyle(fontSize: 18, letterSpacing: 2)),
              const SizedBox(height: 4),
              const Text('输入守护密码进入',
                  style: TextStyle(color: LingShuColors.inkSoft)),
              const SizedBox(height: 32),
              SizedBox(
                width: 220,
                child: TextField(
                  controller: _pin,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, letterSpacing: 8),
                  maxLength: 6,
                  decoration: InputDecoration(
                    counterText: '',
                    errorText: _error.isEmpty ? null : _error,
                  ),
                  onSubmitted: (_) => _submit(),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _submit,
                child: const Text('解 锁', style: TextStyle(letterSpacing: 4)),
              ),
              TextButton(
                onPressed: _tryBiometric,
                child: const Text('使用生物识别解锁'),
              ),
              const SizedBox(height: 36),
              // 出品品牌钤记
              const MosaicBranding(size: 11),
            ],
          ),
        ),
      ),
    );
  }
}
