import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/db.dart';
import '../../core/lunar_date_picker.dart';
import '../../core/theme.dart';
import '../../providers.dart';

/// 家庭成员管理
class FamilyPage extends ConsumerWidget {
  const FamilyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profiles = ref.watch(profilesProvider).valueOrNull ?? const [];
    // 「本人」= 当前正在使用的成员（随切换移动），不再是建库时的固定标记
    final currentId = ref.watch(currentProfileIdProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('家庭成员')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_member',
        onPressed: () => context.push('/family/edit'),
        icon: const Icon(Icons.person_add_alt),
        label: const Text('添加成员'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: profiles.length,
        itemBuilder: (context, i) {
          final p = profiles[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              leading: CircleAvatar(
                backgroundColor: (p.gender == 'female'
                        ? WuXing.fire
                        : WuXing.water)
                    .withValues(alpha: 0.14),
                child: Text(
                  p.name.characters.first,
                  style: TextStyle(
                      color: p.gender == 'female'
                          ? WuXing.fire
                          : WuXing.water,
                      fontWeight: FontWeight.bold),
                ),
              ),
              title: Row(children: [
                Text(p.name),
                if (p.id == currentId)
                  Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: WuXing.earth.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('本人',
                        style: TextStyle(fontSize: 10, color: WuXing.earth)),
                  ),
              ]),
              subtitle: Text(
                [
                  p.gender == 'female' ? '女' : '男',
                  if (p.birthday != null)
                    '${DateFormat('yyyy-MM-dd').format(p.birthday!)}',
                  if (p.bloodType != null) '${p.bloodType}型',
                ].join(' · '),
                style: const TextStyle(fontSize: 12),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // 切换当前成员：写入持久化（重启不退回）并更新内存状态
                ref.read(authProvider).setCurrentProfile(p.id);
                ref.read(currentProfileIdProvider.notifier).state = p.id;
                context.push('/family/edit?id=${p.id}');
              },
            ),
          );
        },
      ),
    );
  }
}

/// 成员新建/编辑
class FamilyEditPage extends ConsumerStatefulWidget {
  final int? memberId;
  final bool firstRun;
  const FamilyEditPage({super.key, this.memberId, this.firstRun = false});

  @override
  ConsumerState<FamilyEditPage> createState() => _FamilyEditPageState();
}

class _FamilyEditPageState extends ConsumerState<FamilyEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _idNumber = TextEditingController();
  final _allergies = TextEditingController();
  final _chronic = TextEditingController();
  final _familyHistory = TextEditingController();
  final _height = TextEditingController();
  final _weight = TextEditingController();
  final _emName = TextEditingController();
  final _emPhone = TextEditingController();
  String _gender = 'male';
  String? _bloodType;
  String? _rh;
  String? _emRelation; // 紧急联系人与该成员的关系
  DateTime? _birthday;
  bool _loaded = false;

  /// 关系选项随成员性别适配：配偶父母对男性成员是岳父岳母、对女性成员是公婆
  List<String> get _relationOptions => [
        '本人',
        '夫妻',
        '父母',
        _gender == 'male' ? '岳父岳母' : '公婆',
        '爷孙',
        '子女',
        '兄弟姐妹',
        '朋友',
        '其他',
        // 已保存但不在当前选项里的值（如后来改了性别）仍要能显示
        if (_emRelation != null &&
            !['本人', '夫妻', '父母', '岳父岳母', '公婆', '爷孙', '子女', '兄弟姐妹', '朋友', '其他']
                .contains(_emRelation))
          _emRelation!,
      ];

  @override
  void initState() {
    super.initState();
    if (widget.memberId != null) _loadMember();
  }

  Future<void> _loadMember() async {
    final db = ref.read(dbProvider);
    final p = await db.getProfile(widget.memberId!);
    if (p == null) return;
    _name.text = p.name;
    _idNumber.text = p.idNumberEnc ?? '';
    _allergies.text = p.allergies ?? '';
    _chronic.text = p.chronicDisease ?? '';
    _familyHistory.text = p.familyHistory ?? '';
    _height.text = p.heightCm?.toString() ?? '';
    _weight.text = p.weightKg?.toString() ?? '';
    _emName.text = p.emergencyName ?? '';
    _emPhone.text = p.emergencyPhone ?? '';
    _emRelation = p.emergencyRelation;
    _gender = p.gender;
    _bloodType = p.bloodType;
    _rh = p.rhType;
    _birthday = p.birthday;
    if (mounted) setState(() => _loaded = true);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final db = ref.read(dbProvider);
    if (widget.memberId == null) {
      final id = await db.into(db.profiles).insert(ProfilesCompanion.insert(
            name: _name.text.trim(),
            gender: _gender,
            birthday: Value(_birthday),
            idNumberEnc: Value(_idNumber.text.trim().isEmpty ? null : _idNumber.text.trim()),
            bloodType: Value(_bloodType),
            rhType: Value(_rh),
            allergies: Value(_allergies.text.trim().isEmpty ? null : _allergies.text.trim()),
            chronicDisease: Value(_chronic.text.trim().isEmpty ? null : _chronic.text.trim()),
            familyHistory:
                Value(_familyHistory.text.trim().isEmpty ? null : _familyHistory.text.trim()),
            heightCm: Value(double.tryParse(_height.text)),
            weightKg: Value(double.tryParse(_weight.text)),
            emergencyName: Value(_emName.text.trim().isEmpty ? null : _emName.text.trim()),
            emergencyPhone: Value(_emPhone.text.trim().isEmpty ? null : _emPhone.text.trim()),
            emergencyRelation: Value(_emRelation),
          ));
      ref.read(currentProfileIdProvider.notifier).state = id;
    } else {
      await (db.update(db.profiles)..where((t) => t.id.equals(widget.memberId!)))
          .write(ProfilesCompanion(
        name: Value(_name.text.trim()),
        gender: Value(_gender),
        birthday: Value(_birthday),
        idNumberEnc:
            Value(_idNumber.text.trim().isEmpty ? null : _idNumber.text.trim()),
        bloodType: Value(_bloodType),
        rhType: Value(_rh),
        allergies:
            Value(_allergies.text.trim().isEmpty ? null : _allergies.text.trim()),
        chronicDisease:
            Value(_chronic.text.trim().isEmpty ? null : _chronic.text.trim()),
        familyHistory: Value(
            _familyHistory.text.trim().isEmpty ? null : _familyHistory.text.trim()),
        heightCm: Value(double.tryParse(_height.text)),
        weightKg: Value(double.tryParse(_weight.text)),
        emergencyName:
            Value(_emName.text.trim().isEmpty ? null : _emName.text.trim()),
        emergencyPhone:
            Value(_emPhone.text.trim().isEmpty ? null : _emPhone.text.trim()),
        emergencyRelation: Value(_emRelation),
      ));
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title:
              Text(widget.memberId == null ? '添加成员' : '编辑档案')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(
            onPressed: _save,
            child: const Text('保 存', style: TextStyle(letterSpacing: 4)),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: '姓名 *'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '必填' : null,
            ),
            const SizedBox(height: 10),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'male', label: Text('男')),
                ButtonSegment(value: 'female', label: Text('女')),
              ],
              selected: {_gender},
              onSelectionChanged: (s) => setState(() => _gender = s.first),
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: () async {
                final now = DateTime.now();
                final d = await showLunarDatePicker(
                  context,
                  initial: _birthday,
                  first: DateTime(now.year - 120),
                  last: now,
                );
                if (d != null) setState(() => _birthday = d);
              },
              child: InputDecorator(
                decoration: const InputDecoration(labelText: '出生日期'),
                child: Text(_birthday == null
                    ? '请选择'
                    : DateFormat('yyyy-MM-dd').format(_birthday!)),
              ),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _bloodType,
                  decoration: const InputDecoration(labelText: '血型'),
                  items: ['A', 'B', 'O', 'AB']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setState(() => _bloodType = v),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _rh,
                  decoration: const InputDecoration(labelText: 'Rh 因子'),
                  // 存储仍为 +/-（数据库兼容），界面以阴阳表示
                  items: const [
                    DropdownMenuItem(value: '+', child: Text('阳')),
                    DropdownMenuItem(value: '-', child: Text('阴')),
                  ],
                  onChanged: (v) => setState(() => _rh = v),
                ),
              ),
            ]),
            const SizedBox(height: 10),
            TextFormField(
              controller: _idNumber,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: '身份证号（选填，仅存本机）'),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _height,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '身高 (cm)'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _weight,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '体重 (kg)'),
                ),
              ),
            ]),
            const SizedBox(height: 10),
            TextFormField(
              controller: _allergies,
              decoration: const InputDecoration(
                  labelText: '过敏源', hintText: '如：青霉素、海鲜'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _chronic,
              decoration: const InputDecoration(
                  labelText: '慢病史', hintText: '如：高血压 10 年'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _familyHistory,
              decoration: const InputDecoration(
                  labelText: '家族史', hintText: '如：父亲糖尿病'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _emRelation,
              decoration: const InputDecoration(
                  labelText: '与紧急联系人的关系', hintText: '如：父母'),
              items: _relationOptions
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _emRelation = v),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _emName,
                  decoration: const InputDecoration(labelText: '紧急联系人'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _emPhone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: '紧急电话'),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
