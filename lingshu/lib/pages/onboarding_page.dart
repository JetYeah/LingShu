import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/db.dart';
import '../core/lunar_date_picker.dart';
import '../core/logo.dart';
import '../core/theme.dart';
import '../providers.dart';

/// 首次使用：创建主人档案 + 设置 PIN
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _name = TextEditingController();
  final _height = TextEditingController();
  final _weight = TextEditingController();
  String _gender = 'male';
  String? _bloodType;
  final _allergies = TextEditingController();
  DateTime? _birthday;
  final _pin1 = TextEditingController();
  final _pin2 = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // 模拟器/真机 debug 联调：预填表单，免去手工建档（仅 debug 构建）
    if (kDebugMode) {
      _name.text = '联调测试';
      _pin1.text = _pin2.text = '1357';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 24),
              Column(children: [
                const LingShuLogo(size: 84),
                const SizedBox(height: 16),
                const Text('灵 枢',
                    style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 8,
                        color: LingShuColors.ink)),
                const SizedBox(height: 8),
                const Text('身有灵枢 · 健康有度',
                    style: TextStyle(
                        letterSpacing: 3, color: LingShuColors.inkSoft)),
                const SizedBox(height: 6),
                const Text('磨沙客 MOSAIC 出品',
                    style: TextStyle(
                        fontSize: 10.5,
                        letterSpacing: 1.5,
                        color: LingShuColors.gold)),
              ]),
              const SizedBox(height: 40),
              _sectionTitle('创建主人档案'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                    labelText: '姓名', prefixIcon: Icon(Icons.person_outline)),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? '请输入姓名' : null,
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'male', label: Text('男')),
                      ButtonSegment(value: 'female', label: Text('女')),
                    ],
                    selected: {_gender},
                    onSelectionChanged: (s) => setState(() => _gender = s.first),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickBirthday,
                child: InputDecorator(
                  decoration: const InputDecoration(
                      labelText: '出生日期',
                      prefixIcon: Icon(Icons.cake_outlined)),
                  child: Text(_birthday == null
                      ? '请选择'
                      : '${_birthday!.year}-${_birthday!.month.toString().padLeft(2, '0')}-${_birthday!.day.toString().padLeft(2, '0')}'),
                ),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _height,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: '身高 (cm)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _weight,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: '体重 (kg)'),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _bloodType,
                decoration: const InputDecoration(
                    labelText: '血型', prefixIcon: Icon(Icons.water_drop_outlined)),
                items: ['A', 'B', 'O', 'AB']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _bloodType = v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _allergies,
                decoration: const InputDecoration(
                    labelText: '过敏源（选填）',
                    hintText: '如：青霉素、花生、海鲜',
                    prefixIcon: Icon(Icons.health_and_safety_outlined)),
              ),
              const SizedBox(height: 24),
              _sectionTitle('设置守护密码（PIN）'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pin1,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration:
                    const InputDecoration(labelText: 'PIN 码（4-6位数字）'),
                validator: (v) =>
                    (v == null || v.length < 4) ? '至少 4 位数字' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pin2,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(labelText: '确认 PIN 码'),
                validator: (v) =>
                    v == _pin1.text ? null : '两次输入不一致',
              ),
              const SizedBox(height: 8),
              Text(
                '所有健康数据仅加密保存在本机，不会上传云端。',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: LingShuColors.inkSoft),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('启 用 灵 枢',
                          style: TextStyle(letterSpacing: 4)),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '本应用不能替代专业医疗建议，如有不适请及时就医。',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: LingShuColors.inkSoft),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Row(children: [
        Container(width: 4, height: 16, color: WuXing.wood),
        const SizedBox(width: 8),
        Text(text,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: LingShuColors.ink)),
      ]);

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final d = await showLunarDatePicker(
      context,
      initial: _birthday,
      first: DateTime(now.year - 120),
      last: now,
    );
    if (d != null) setState(() => _birthday = d);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final db = ref.read(dbProvider);
    final auth = ref.read(authProvider);
    // 防止重复提交创建多个主人档案
    if (auth.onboarded) {
      ref.read(sessionProvider.notifier).finishOnboarding();
      if (mounted) context.go('/home');
      return;
    }
    setState(() => _saving = true);
    try {
      final id = await db
          .into(db.profiles)
          .insert(ProfilesCompanion.insert(
            name: _name.text.trim(),
            gender: _gender,
            birthday: Value(_birthday),
            bloodType: Value(_bloodType),
            allergies: Value(_allergies.text.trim().isEmpty
                ? null
                : _allergies.text.trim()),
            heightCm: Value(double.tryParse(_height.text)),
            weightKg: Value(double.tryParse(_weight.text)),
            isOwner: const Value(true),
          ));
      await auth.setOwner(id);
      await auth.setPin(_pin1.text);

      // 初始化预设指标
      final content = ref.read(contentProvider);
      await content.load();
      for (final p in content.presets) {
        if (p.code == 'bmi') continue;
        await db.into(db.metrics).insert(MetricsCompanion.insert(
              profileId: id,
              code: p.code,
              name: p.name,
              unit: p.unit,
              dualValue: Value(p.dualValue),
              refLow: Value(p.refLow),
              refHigh: Value(p.refHigh),
              refLow2: Value(p.refLow2),
              refHigh2: Value(p.refHigh2),
            ));
      }
      ref.read(sessionProvider.notifier).finishOnboarding();
      if (mounted) context.go('/home');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
