// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'db.dart';

// ignore_for_file: type=lint
class $ProfilesTable extends Profiles with TableInfo<$ProfilesTable, Profile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _genderMeta = const VerificationMeta('gender');
  @override
  late final GeneratedColumn<String> gender = GeneratedColumn<String>(
    'gender',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _birthdayMeta = const VerificationMeta(
    'birthday',
  );
  @override
  late final GeneratedColumn<DateTime> birthday = GeneratedColumn<DateTime>(
    'birthday',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _idNumberEncMeta = const VerificationMeta(
    'idNumberEnc',
  );
  @override
  late final GeneratedColumn<String> idNumberEnc = GeneratedColumn<String>(
    'id_number_enc',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bloodTypeMeta = const VerificationMeta(
    'bloodType',
  );
  @override
  late final GeneratedColumn<String> bloodType = GeneratedColumn<String>(
    'blood_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rhTypeMeta = const VerificationMeta('rhType');
  @override
  late final GeneratedColumn<String> rhType = GeneratedColumn<String>(
    'rh_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _allergiesMeta = const VerificationMeta(
    'allergies',
  );
  @override
  late final GeneratedColumn<String> allergies = GeneratedColumn<String>(
    'allergies',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _chronicDiseaseMeta = const VerificationMeta(
    'chronicDisease',
  );
  @override
  late final GeneratedColumn<String> chronicDisease = GeneratedColumn<String>(
    'chronic_disease',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _familyHistoryMeta = const VerificationMeta(
    'familyHistory',
  );
  @override
  late final GeneratedColumn<String> familyHistory = GeneratedColumn<String>(
    'family_history',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _emergencyNameMeta = const VerificationMeta(
    'emergencyName',
  );
  @override
  late final GeneratedColumn<String> emergencyName = GeneratedColumn<String>(
    'emergency_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _emergencyPhoneMeta = const VerificationMeta(
    'emergencyPhone',
  );
  @override
  late final GeneratedColumn<String> emergencyPhone = GeneratedColumn<String>(
    'emergency_phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _emergencyRelationMeta = const VerificationMeta(
    'emergencyRelation',
  );
  @override
  late final GeneratedColumn<String> emergencyRelation =
      GeneratedColumn<String>(
        'emergency_relation',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _heightCmMeta = const VerificationMeta(
    'heightCm',
  );
  @override
  late final GeneratedColumn<double> heightCm = GeneratedColumn<double>(
    'height_cm',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _weightKgMeta = const VerificationMeta(
    'weightKg',
  );
  @override
  late final GeneratedColumn<double> weightKg = GeneratedColumn<double>(
    'weight_kg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _constitutionMeta = const VerificationMeta(
    'constitution',
  );
  @override
  late final GeneratedColumn<String> constitution = GeneratedColumn<String>(
    'constitution',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isOwnerMeta = const VerificationMeta(
    'isOwner',
  );
  @override
  late final GeneratedColumn<bool> isOwner = GeneratedColumn<bool>(
    'is_owner',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_owner" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    gender,
    birthday,
    idNumberEnc,
    bloodType,
    rhType,
    allergies,
    chronicDisease,
    familyHistory,
    emergencyName,
    emergencyPhone,
    emergencyRelation,
    heightCm,
    weightKg,
    constitution,
    isOwner,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<Profile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('gender')) {
      context.handle(
        _genderMeta,
        gender.isAcceptableOrUnknown(data['gender']!, _genderMeta),
      );
    } else if (isInserting) {
      context.missing(_genderMeta);
    }
    if (data.containsKey('birthday')) {
      context.handle(
        _birthdayMeta,
        birthday.isAcceptableOrUnknown(data['birthday']!, _birthdayMeta),
      );
    }
    if (data.containsKey('id_number_enc')) {
      context.handle(
        _idNumberEncMeta,
        idNumberEnc.isAcceptableOrUnknown(
          data['id_number_enc']!,
          _idNumberEncMeta,
        ),
      );
    }
    if (data.containsKey('blood_type')) {
      context.handle(
        _bloodTypeMeta,
        bloodType.isAcceptableOrUnknown(data['blood_type']!, _bloodTypeMeta),
      );
    }
    if (data.containsKey('rh_type')) {
      context.handle(
        _rhTypeMeta,
        rhType.isAcceptableOrUnknown(data['rh_type']!, _rhTypeMeta),
      );
    }
    if (data.containsKey('allergies')) {
      context.handle(
        _allergiesMeta,
        allergies.isAcceptableOrUnknown(data['allergies']!, _allergiesMeta),
      );
    }
    if (data.containsKey('chronic_disease')) {
      context.handle(
        _chronicDiseaseMeta,
        chronicDisease.isAcceptableOrUnknown(
          data['chronic_disease']!,
          _chronicDiseaseMeta,
        ),
      );
    }
    if (data.containsKey('family_history')) {
      context.handle(
        _familyHistoryMeta,
        familyHistory.isAcceptableOrUnknown(
          data['family_history']!,
          _familyHistoryMeta,
        ),
      );
    }
    if (data.containsKey('emergency_name')) {
      context.handle(
        _emergencyNameMeta,
        emergencyName.isAcceptableOrUnknown(
          data['emergency_name']!,
          _emergencyNameMeta,
        ),
      );
    }
    if (data.containsKey('emergency_phone')) {
      context.handle(
        _emergencyPhoneMeta,
        emergencyPhone.isAcceptableOrUnknown(
          data['emergency_phone']!,
          _emergencyPhoneMeta,
        ),
      );
    }
    if (data.containsKey('emergency_relation')) {
      context.handle(
        _emergencyRelationMeta,
        emergencyRelation.isAcceptableOrUnknown(
          data['emergency_relation']!,
          _emergencyRelationMeta,
        ),
      );
    }
    if (data.containsKey('height_cm')) {
      context.handle(
        _heightCmMeta,
        heightCm.isAcceptableOrUnknown(data['height_cm']!, _heightCmMeta),
      );
    }
    if (data.containsKey('weight_kg')) {
      context.handle(
        _weightKgMeta,
        weightKg.isAcceptableOrUnknown(data['weight_kg']!, _weightKgMeta),
      );
    }
    if (data.containsKey('constitution')) {
      context.handle(
        _constitutionMeta,
        constitution.isAcceptableOrUnknown(
          data['constitution']!,
          _constitutionMeta,
        ),
      );
    }
    if (data.containsKey('is_owner')) {
      context.handle(
        _isOwnerMeta,
        isOwner.isAcceptableOrUnknown(data['is_owner']!, _isOwnerMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Profile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Profile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      gender: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gender'],
      )!,
      birthday: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}birthday'],
      ),
      idNumberEnc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id_number_enc'],
      ),
      bloodType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}blood_type'],
      ),
      rhType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rh_type'],
      ),
      allergies: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}allergies'],
      ),
      chronicDisease: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chronic_disease'],
      ),
      familyHistory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}family_history'],
      ),
      emergencyName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}emergency_name'],
      ),
      emergencyPhone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}emergency_phone'],
      ),
      emergencyRelation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}emergency_relation'],
      ),
      heightCm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}height_cm'],
      ),
      weightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight_kg'],
      ),
      constitution: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}constitution'],
      ),
      isOwner: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_owner'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ProfilesTable createAlias(String alias) {
    return $ProfilesTable(attachedDatabase, alias);
  }
}

class Profile extends DataClass implements Insertable<Profile> {
  final int id;
  final String name;
  final String gender;
  final DateTime? birthday;
  final String? idNumberEnc;
  final String? bloodType;
  final String? rhType;
  final String? allergies;
  final String? chronicDisease;
  final String? familyHistory;
  final String? emergencyName;
  final String? emergencyPhone;
  final String? emergencyRelation;
  final double? heightCm;
  final double? weightKg;
  final String? constitution;
  final bool isOwner;
  final DateTime createdAt;
  const Profile({
    required this.id,
    required this.name,
    required this.gender,
    this.birthday,
    this.idNumberEnc,
    this.bloodType,
    this.rhType,
    this.allergies,
    this.chronicDisease,
    this.familyHistory,
    this.emergencyName,
    this.emergencyPhone,
    this.emergencyRelation,
    this.heightCm,
    this.weightKg,
    this.constitution,
    required this.isOwner,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['gender'] = Variable<String>(gender);
    if (!nullToAbsent || birthday != null) {
      map['birthday'] = Variable<DateTime>(birthday);
    }
    if (!nullToAbsent || idNumberEnc != null) {
      map['id_number_enc'] = Variable<String>(idNumberEnc);
    }
    if (!nullToAbsent || bloodType != null) {
      map['blood_type'] = Variable<String>(bloodType);
    }
    if (!nullToAbsent || rhType != null) {
      map['rh_type'] = Variable<String>(rhType);
    }
    if (!nullToAbsent || allergies != null) {
      map['allergies'] = Variable<String>(allergies);
    }
    if (!nullToAbsent || chronicDisease != null) {
      map['chronic_disease'] = Variable<String>(chronicDisease);
    }
    if (!nullToAbsent || familyHistory != null) {
      map['family_history'] = Variable<String>(familyHistory);
    }
    if (!nullToAbsent || emergencyName != null) {
      map['emergency_name'] = Variable<String>(emergencyName);
    }
    if (!nullToAbsent || emergencyPhone != null) {
      map['emergency_phone'] = Variable<String>(emergencyPhone);
    }
    if (!nullToAbsent || emergencyRelation != null) {
      map['emergency_relation'] = Variable<String>(emergencyRelation);
    }
    if (!nullToAbsent || heightCm != null) {
      map['height_cm'] = Variable<double>(heightCm);
    }
    if (!nullToAbsent || weightKg != null) {
      map['weight_kg'] = Variable<double>(weightKg);
    }
    if (!nullToAbsent || constitution != null) {
      map['constitution'] = Variable<String>(constitution);
    }
    map['is_owner'] = Variable<bool>(isOwner);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ProfilesCompanion toCompanion(bool nullToAbsent) {
    return ProfilesCompanion(
      id: Value(id),
      name: Value(name),
      gender: Value(gender),
      birthday: birthday == null && nullToAbsent
          ? const Value.absent()
          : Value(birthday),
      idNumberEnc: idNumberEnc == null && nullToAbsent
          ? const Value.absent()
          : Value(idNumberEnc),
      bloodType: bloodType == null && nullToAbsent
          ? const Value.absent()
          : Value(bloodType),
      rhType: rhType == null && nullToAbsent
          ? const Value.absent()
          : Value(rhType),
      allergies: allergies == null && nullToAbsent
          ? const Value.absent()
          : Value(allergies),
      chronicDisease: chronicDisease == null && nullToAbsent
          ? const Value.absent()
          : Value(chronicDisease),
      familyHistory: familyHistory == null && nullToAbsent
          ? const Value.absent()
          : Value(familyHistory),
      emergencyName: emergencyName == null && nullToAbsent
          ? const Value.absent()
          : Value(emergencyName),
      emergencyPhone: emergencyPhone == null && nullToAbsent
          ? const Value.absent()
          : Value(emergencyPhone),
      emergencyRelation: emergencyRelation == null && nullToAbsent
          ? const Value.absent()
          : Value(emergencyRelation),
      heightCm: heightCm == null && nullToAbsent
          ? const Value.absent()
          : Value(heightCm),
      weightKg: weightKg == null && nullToAbsent
          ? const Value.absent()
          : Value(weightKg),
      constitution: constitution == null && nullToAbsent
          ? const Value.absent()
          : Value(constitution),
      isOwner: Value(isOwner),
      createdAt: Value(createdAt),
    );
  }

  factory Profile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Profile(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      gender: serializer.fromJson<String>(json['gender']),
      birthday: serializer.fromJson<DateTime?>(json['birthday']),
      idNumberEnc: serializer.fromJson<String?>(json['idNumberEnc']),
      bloodType: serializer.fromJson<String?>(json['bloodType']),
      rhType: serializer.fromJson<String?>(json['rhType']),
      allergies: serializer.fromJson<String?>(json['allergies']),
      chronicDisease: serializer.fromJson<String?>(json['chronicDisease']),
      familyHistory: serializer.fromJson<String?>(json['familyHistory']),
      emergencyName: serializer.fromJson<String?>(json['emergencyName']),
      emergencyPhone: serializer.fromJson<String?>(json['emergencyPhone']),
      emergencyRelation: serializer.fromJson<String?>(
        json['emergencyRelation'],
      ),
      heightCm: serializer.fromJson<double?>(json['heightCm']),
      weightKg: serializer.fromJson<double?>(json['weightKg']),
      constitution: serializer.fromJson<String?>(json['constitution']),
      isOwner: serializer.fromJson<bool>(json['isOwner']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'gender': serializer.toJson<String>(gender),
      'birthday': serializer.toJson<DateTime?>(birthday),
      'idNumberEnc': serializer.toJson<String?>(idNumberEnc),
      'bloodType': serializer.toJson<String?>(bloodType),
      'rhType': serializer.toJson<String?>(rhType),
      'allergies': serializer.toJson<String?>(allergies),
      'chronicDisease': serializer.toJson<String?>(chronicDisease),
      'familyHistory': serializer.toJson<String?>(familyHistory),
      'emergencyName': serializer.toJson<String?>(emergencyName),
      'emergencyPhone': serializer.toJson<String?>(emergencyPhone),
      'emergencyRelation': serializer.toJson<String?>(emergencyRelation),
      'heightCm': serializer.toJson<double?>(heightCm),
      'weightKg': serializer.toJson<double?>(weightKg),
      'constitution': serializer.toJson<String?>(constitution),
      'isOwner': serializer.toJson<bool>(isOwner),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Profile copyWith({
    int? id,
    String? name,
    String? gender,
    Value<DateTime?> birthday = const Value.absent(),
    Value<String?> idNumberEnc = const Value.absent(),
    Value<String?> bloodType = const Value.absent(),
    Value<String?> rhType = const Value.absent(),
    Value<String?> allergies = const Value.absent(),
    Value<String?> chronicDisease = const Value.absent(),
    Value<String?> familyHistory = const Value.absent(),
    Value<String?> emergencyName = const Value.absent(),
    Value<String?> emergencyPhone = const Value.absent(),
    Value<String?> emergencyRelation = const Value.absent(),
    Value<double?> heightCm = const Value.absent(),
    Value<double?> weightKg = const Value.absent(),
    Value<String?> constitution = const Value.absent(),
    bool? isOwner,
    DateTime? createdAt,
  }) => Profile(
    id: id ?? this.id,
    name: name ?? this.name,
    gender: gender ?? this.gender,
    birthday: birthday.present ? birthday.value : this.birthday,
    idNumberEnc: idNumberEnc.present ? idNumberEnc.value : this.idNumberEnc,
    bloodType: bloodType.present ? bloodType.value : this.bloodType,
    rhType: rhType.present ? rhType.value : this.rhType,
    allergies: allergies.present ? allergies.value : this.allergies,
    chronicDisease: chronicDisease.present
        ? chronicDisease.value
        : this.chronicDisease,
    familyHistory: familyHistory.present
        ? familyHistory.value
        : this.familyHistory,
    emergencyName: emergencyName.present
        ? emergencyName.value
        : this.emergencyName,
    emergencyPhone: emergencyPhone.present
        ? emergencyPhone.value
        : this.emergencyPhone,
    emergencyRelation: emergencyRelation.present
        ? emergencyRelation.value
        : this.emergencyRelation,
    heightCm: heightCm.present ? heightCm.value : this.heightCm,
    weightKg: weightKg.present ? weightKg.value : this.weightKg,
    constitution: constitution.present ? constitution.value : this.constitution,
    isOwner: isOwner ?? this.isOwner,
    createdAt: createdAt ?? this.createdAt,
  );
  Profile copyWithCompanion(ProfilesCompanion data) {
    return Profile(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      gender: data.gender.present ? data.gender.value : this.gender,
      birthday: data.birthday.present ? data.birthday.value : this.birthday,
      idNumberEnc: data.idNumberEnc.present
          ? data.idNumberEnc.value
          : this.idNumberEnc,
      bloodType: data.bloodType.present ? data.bloodType.value : this.bloodType,
      rhType: data.rhType.present ? data.rhType.value : this.rhType,
      allergies: data.allergies.present ? data.allergies.value : this.allergies,
      chronicDisease: data.chronicDisease.present
          ? data.chronicDisease.value
          : this.chronicDisease,
      familyHistory: data.familyHistory.present
          ? data.familyHistory.value
          : this.familyHistory,
      emergencyName: data.emergencyName.present
          ? data.emergencyName.value
          : this.emergencyName,
      emergencyPhone: data.emergencyPhone.present
          ? data.emergencyPhone.value
          : this.emergencyPhone,
      emergencyRelation: data.emergencyRelation.present
          ? data.emergencyRelation.value
          : this.emergencyRelation,
      heightCm: data.heightCm.present ? data.heightCm.value : this.heightCm,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
      constitution: data.constitution.present
          ? data.constitution.value
          : this.constitution,
      isOwner: data.isOwner.present ? data.isOwner.value : this.isOwner,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Profile(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('gender: $gender, ')
          ..write('birthday: $birthday, ')
          ..write('idNumberEnc: $idNumberEnc, ')
          ..write('bloodType: $bloodType, ')
          ..write('rhType: $rhType, ')
          ..write('allergies: $allergies, ')
          ..write('chronicDisease: $chronicDisease, ')
          ..write('familyHistory: $familyHistory, ')
          ..write('emergencyName: $emergencyName, ')
          ..write('emergencyPhone: $emergencyPhone, ')
          ..write('emergencyRelation: $emergencyRelation, ')
          ..write('heightCm: $heightCm, ')
          ..write('weightKg: $weightKg, ')
          ..write('constitution: $constitution, ')
          ..write('isOwner: $isOwner, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    gender,
    birthday,
    idNumberEnc,
    bloodType,
    rhType,
    allergies,
    chronicDisease,
    familyHistory,
    emergencyName,
    emergencyPhone,
    emergencyRelation,
    heightCm,
    weightKg,
    constitution,
    isOwner,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Profile &&
          other.id == this.id &&
          other.name == this.name &&
          other.gender == this.gender &&
          other.birthday == this.birthday &&
          other.idNumberEnc == this.idNumberEnc &&
          other.bloodType == this.bloodType &&
          other.rhType == this.rhType &&
          other.allergies == this.allergies &&
          other.chronicDisease == this.chronicDisease &&
          other.familyHistory == this.familyHistory &&
          other.emergencyName == this.emergencyName &&
          other.emergencyPhone == this.emergencyPhone &&
          other.emergencyRelation == this.emergencyRelation &&
          other.heightCm == this.heightCm &&
          other.weightKg == this.weightKg &&
          other.constitution == this.constitution &&
          other.isOwner == this.isOwner &&
          other.createdAt == this.createdAt);
}

class ProfilesCompanion extends UpdateCompanion<Profile> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> gender;
  final Value<DateTime?> birthday;
  final Value<String?> idNumberEnc;
  final Value<String?> bloodType;
  final Value<String?> rhType;
  final Value<String?> allergies;
  final Value<String?> chronicDisease;
  final Value<String?> familyHistory;
  final Value<String?> emergencyName;
  final Value<String?> emergencyPhone;
  final Value<String?> emergencyRelation;
  final Value<double?> heightCm;
  final Value<double?> weightKg;
  final Value<String?> constitution;
  final Value<bool> isOwner;
  final Value<DateTime> createdAt;
  const ProfilesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.gender = const Value.absent(),
    this.birthday = const Value.absent(),
    this.idNumberEnc = const Value.absent(),
    this.bloodType = const Value.absent(),
    this.rhType = const Value.absent(),
    this.allergies = const Value.absent(),
    this.chronicDisease = const Value.absent(),
    this.familyHistory = const Value.absent(),
    this.emergencyName = const Value.absent(),
    this.emergencyPhone = const Value.absent(),
    this.emergencyRelation = const Value.absent(),
    this.heightCm = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.constitution = const Value.absent(),
    this.isOwner = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ProfilesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String gender,
    this.birthday = const Value.absent(),
    this.idNumberEnc = const Value.absent(),
    this.bloodType = const Value.absent(),
    this.rhType = const Value.absent(),
    this.allergies = const Value.absent(),
    this.chronicDisease = const Value.absent(),
    this.familyHistory = const Value.absent(),
    this.emergencyName = const Value.absent(),
    this.emergencyPhone = const Value.absent(),
    this.emergencyRelation = const Value.absent(),
    this.heightCm = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.constitution = const Value.absent(),
    this.isOwner = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : name = Value(name),
       gender = Value(gender);
  static Insertable<Profile> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? gender,
    Expression<DateTime>? birthday,
    Expression<String>? idNumberEnc,
    Expression<String>? bloodType,
    Expression<String>? rhType,
    Expression<String>? allergies,
    Expression<String>? chronicDisease,
    Expression<String>? familyHistory,
    Expression<String>? emergencyName,
    Expression<String>? emergencyPhone,
    Expression<String>? emergencyRelation,
    Expression<double>? heightCm,
    Expression<double>? weightKg,
    Expression<String>? constitution,
    Expression<bool>? isOwner,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (gender != null) 'gender': gender,
      if (birthday != null) 'birthday': birthday,
      if (idNumberEnc != null) 'id_number_enc': idNumberEnc,
      if (bloodType != null) 'blood_type': bloodType,
      if (rhType != null) 'rh_type': rhType,
      if (allergies != null) 'allergies': allergies,
      if (chronicDisease != null) 'chronic_disease': chronicDisease,
      if (familyHistory != null) 'family_history': familyHistory,
      if (emergencyName != null) 'emergency_name': emergencyName,
      if (emergencyPhone != null) 'emergency_phone': emergencyPhone,
      if (emergencyRelation != null) 'emergency_relation': emergencyRelation,
      if (heightCm != null) 'height_cm': heightCm,
      if (weightKg != null) 'weight_kg': weightKg,
      if (constitution != null) 'constitution': constitution,
      if (isOwner != null) 'is_owner': isOwner,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ProfilesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? gender,
    Value<DateTime?>? birthday,
    Value<String?>? idNumberEnc,
    Value<String?>? bloodType,
    Value<String?>? rhType,
    Value<String?>? allergies,
    Value<String?>? chronicDisease,
    Value<String?>? familyHistory,
    Value<String?>? emergencyName,
    Value<String?>? emergencyPhone,
    Value<String?>? emergencyRelation,
    Value<double?>? heightCm,
    Value<double?>? weightKg,
    Value<String?>? constitution,
    Value<bool>? isOwner,
    Value<DateTime>? createdAt,
  }) {
    return ProfilesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      birthday: birthday ?? this.birthday,
      idNumberEnc: idNumberEnc ?? this.idNumberEnc,
      bloodType: bloodType ?? this.bloodType,
      rhType: rhType ?? this.rhType,
      allergies: allergies ?? this.allergies,
      chronicDisease: chronicDisease ?? this.chronicDisease,
      familyHistory: familyHistory ?? this.familyHistory,
      emergencyName: emergencyName ?? this.emergencyName,
      emergencyPhone: emergencyPhone ?? this.emergencyPhone,
      emergencyRelation: emergencyRelation ?? this.emergencyRelation,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      constitution: constitution ?? this.constitution,
      isOwner: isOwner ?? this.isOwner,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (gender.present) {
      map['gender'] = Variable<String>(gender.value);
    }
    if (birthday.present) {
      map['birthday'] = Variable<DateTime>(birthday.value);
    }
    if (idNumberEnc.present) {
      map['id_number_enc'] = Variable<String>(idNumberEnc.value);
    }
    if (bloodType.present) {
      map['blood_type'] = Variable<String>(bloodType.value);
    }
    if (rhType.present) {
      map['rh_type'] = Variable<String>(rhType.value);
    }
    if (allergies.present) {
      map['allergies'] = Variable<String>(allergies.value);
    }
    if (chronicDisease.present) {
      map['chronic_disease'] = Variable<String>(chronicDisease.value);
    }
    if (familyHistory.present) {
      map['family_history'] = Variable<String>(familyHistory.value);
    }
    if (emergencyName.present) {
      map['emergency_name'] = Variable<String>(emergencyName.value);
    }
    if (emergencyPhone.present) {
      map['emergency_phone'] = Variable<String>(emergencyPhone.value);
    }
    if (emergencyRelation.present) {
      map['emergency_relation'] = Variable<String>(emergencyRelation.value);
    }
    if (heightCm.present) {
      map['height_cm'] = Variable<double>(heightCm.value);
    }
    if (weightKg.present) {
      map['weight_kg'] = Variable<double>(weightKg.value);
    }
    if (constitution.present) {
      map['constitution'] = Variable<String>(constitution.value);
    }
    if (isOwner.present) {
      map['is_owner'] = Variable<bool>(isOwner.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfilesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('gender: $gender, ')
          ..write('birthday: $birthday, ')
          ..write('idNumberEnc: $idNumberEnc, ')
          ..write('bloodType: $bloodType, ')
          ..write('rhType: $rhType, ')
          ..write('allergies: $allergies, ')
          ..write('chronicDisease: $chronicDisease, ')
          ..write('familyHistory: $familyHistory, ')
          ..write('emergencyName: $emergencyName, ')
          ..write('emergencyPhone: $emergencyPhone, ')
          ..write('emergencyRelation: $emergencyRelation, ')
          ..write('heightCm: $heightCm, ')
          ..write('weightKg: $weightKg, ')
          ..write('constitution: $constitution, ')
          ..write('isOwner: $isOwner, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $MedicalRecordsTable extends MedicalRecords
    with TableInfo<$MedicalRecordsTable, MedicalRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MedicalRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<int> profileId = GeneratedColumn<int>(
    'profile_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordDateMeta = const VerificationMeta(
    'recordDate',
  );
  @override
  late final GeneratedColumn<DateTime> recordDate = GeneratedColumn<DateTime>(
    'record_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hospitalMeta = const VerificationMeta(
    'hospital',
  );
  @override
  late final GeneratedColumn<String> hospital = GeneratedColumn<String>(
    'hospital',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _departmentMeta = const VerificationMeta(
    'department',
  );
  @override
  late final GeneratedColumn<String> department = GeneratedColumn<String>(
    'department',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileTypeMeta = const VerificationMeta(
    'fileType',
  );
  @override
  late final GeneratedColumn<String> fileType = GeneratedColumn<String>(
    'file_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
    'lat',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lngMeta = const VerificationMeta('lng');
  @override
  late final GeneratedColumn<double> lng = GeneratedColumn<double>(
    'lng',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _locationTextMeta = const VerificationMeta(
    'locationText',
  );
  @override
  late final GeneratedColumn<String> locationText = GeneratedColumn<String>(
    'location_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _aiSummaryMeta = const VerificationMeta(
    'aiSummary',
  );
  @override
  late final GeneratedColumn<String> aiSummary = GeneratedColumn<String>(
    'ai_summary',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fileHashMeta = const VerificationMeta(
    'fileHash',
  );
  @override
  late final GeneratedColumn<String> fileHash = GeneratedColumn<String>(
    'file_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    profileId,
    title,
    type,
    recordDate,
    hospital,
    department,
    tags,
    note,
    filePath,
    fileType,
    lat,
    lng,
    locationText,
    aiSummary,
    fileHash,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'medical_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<MedicalRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('record_date')) {
      context.handle(
        _recordDateMeta,
        recordDate.isAcceptableOrUnknown(data['record_date']!, _recordDateMeta),
      );
    } else if (isInserting) {
      context.missing(_recordDateMeta);
    }
    if (data.containsKey('hospital')) {
      context.handle(
        _hospitalMeta,
        hospital.isAcceptableOrUnknown(data['hospital']!, _hospitalMeta),
      );
    }
    if (data.containsKey('department')) {
      context.handle(
        _departmentMeta,
        department.isAcceptableOrUnknown(data['department']!, _departmentMeta),
      );
    }
    if (data.containsKey('tags')) {
      context.handle(
        _tagsMeta,
        tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('file_type')) {
      context.handle(
        _fileTypeMeta,
        fileType.isAcceptableOrUnknown(data['file_type']!, _fileTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_fileTypeMeta);
    }
    if (data.containsKey('lat')) {
      context.handle(
        _latMeta,
        lat.isAcceptableOrUnknown(data['lat']!, _latMeta),
      );
    }
    if (data.containsKey('lng')) {
      context.handle(
        _lngMeta,
        lng.isAcceptableOrUnknown(data['lng']!, _lngMeta),
      );
    }
    if (data.containsKey('location_text')) {
      context.handle(
        _locationTextMeta,
        locationText.isAcceptableOrUnknown(
          data['location_text']!,
          _locationTextMeta,
        ),
      );
    }
    if (data.containsKey('ai_summary')) {
      context.handle(
        _aiSummaryMeta,
        aiSummary.isAcceptableOrUnknown(data['ai_summary']!, _aiSummaryMeta),
      );
    }
    if (data.containsKey('file_hash')) {
      context.handle(
        _fileHashMeta,
        fileHash.isAcceptableOrUnknown(data['file_hash']!, _fileHashMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MedicalRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MedicalRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}profile_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      recordDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}record_date'],
      )!,
      hospital: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hospital'],
      ),
      department: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}department'],
      ),
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      fileType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_type'],
      )!,
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      ),
      lng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lng'],
      ),
      locationText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location_text'],
      ),
      aiSummary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ai_summary'],
      ),
      fileHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_hash'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $MedicalRecordsTable createAlias(String alias) {
    return $MedicalRecordsTable(attachedDatabase, alias);
  }
}

class MedicalRecord extends DataClass implements Insertable<MedicalRecord> {
  final int id;
  final int profileId;
  final String title;
  final String type;
  final DateTime recordDate;
  final String? hospital;
  final String? department;
  final String? tags;
  final String? note;
  final String filePath;
  final String fileType;
  final double? lat;
  final double? lng;
  final String? locationText;
  final String? aiSummary;
  final String? fileHash;
  final DateTime createdAt;
  const MedicalRecord({
    required this.id,
    required this.profileId,
    required this.title,
    required this.type,
    required this.recordDate,
    this.hospital,
    this.department,
    this.tags,
    this.note,
    required this.filePath,
    required this.fileType,
    this.lat,
    this.lng,
    this.locationText,
    this.aiSummary,
    this.fileHash,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['profile_id'] = Variable<int>(profileId);
    map['title'] = Variable<String>(title);
    map['type'] = Variable<String>(type);
    map['record_date'] = Variable<DateTime>(recordDate);
    if (!nullToAbsent || hospital != null) {
      map['hospital'] = Variable<String>(hospital);
    }
    if (!nullToAbsent || department != null) {
      map['department'] = Variable<String>(department);
    }
    if (!nullToAbsent || tags != null) {
      map['tags'] = Variable<String>(tags);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['file_path'] = Variable<String>(filePath);
    map['file_type'] = Variable<String>(fileType);
    if (!nullToAbsent || lat != null) {
      map['lat'] = Variable<double>(lat);
    }
    if (!nullToAbsent || lng != null) {
      map['lng'] = Variable<double>(lng);
    }
    if (!nullToAbsent || locationText != null) {
      map['location_text'] = Variable<String>(locationText);
    }
    if (!nullToAbsent || aiSummary != null) {
      map['ai_summary'] = Variable<String>(aiSummary);
    }
    if (!nullToAbsent || fileHash != null) {
      map['file_hash'] = Variable<String>(fileHash);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  MedicalRecordsCompanion toCompanion(bool nullToAbsent) {
    return MedicalRecordsCompanion(
      id: Value(id),
      profileId: Value(profileId),
      title: Value(title),
      type: Value(type),
      recordDate: Value(recordDate),
      hospital: hospital == null && nullToAbsent
          ? const Value.absent()
          : Value(hospital),
      department: department == null && nullToAbsent
          ? const Value.absent()
          : Value(department),
      tags: tags == null && nullToAbsent ? const Value.absent() : Value(tags),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      filePath: Value(filePath),
      fileType: Value(fileType),
      lat: lat == null && nullToAbsent ? const Value.absent() : Value(lat),
      lng: lng == null && nullToAbsent ? const Value.absent() : Value(lng),
      locationText: locationText == null && nullToAbsent
          ? const Value.absent()
          : Value(locationText),
      aiSummary: aiSummary == null && nullToAbsent
          ? const Value.absent()
          : Value(aiSummary),
      fileHash: fileHash == null && nullToAbsent
          ? const Value.absent()
          : Value(fileHash),
      createdAt: Value(createdAt),
    );
  }

  factory MedicalRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MedicalRecord(
      id: serializer.fromJson<int>(json['id']),
      profileId: serializer.fromJson<int>(json['profileId']),
      title: serializer.fromJson<String>(json['title']),
      type: serializer.fromJson<String>(json['type']),
      recordDate: serializer.fromJson<DateTime>(json['recordDate']),
      hospital: serializer.fromJson<String?>(json['hospital']),
      department: serializer.fromJson<String?>(json['department']),
      tags: serializer.fromJson<String?>(json['tags']),
      note: serializer.fromJson<String?>(json['note']),
      filePath: serializer.fromJson<String>(json['filePath']),
      fileType: serializer.fromJson<String>(json['fileType']),
      lat: serializer.fromJson<double?>(json['lat']),
      lng: serializer.fromJson<double?>(json['lng']),
      locationText: serializer.fromJson<String?>(json['locationText']),
      aiSummary: serializer.fromJson<String?>(json['aiSummary']),
      fileHash: serializer.fromJson<String?>(json['fileHash']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'profileId': serializer.toJson<int>(profileId),
      'title': serializer.toJson<String>(title),
      'type': serializer.toJson<String>(type),
      'recordDate': serializer.toJson<DateTime>(recordDate),
      'hospital': serializer.toJson<String?>(hospital),
      'department': serializer.toJson<String?>(department),
      'tags': serializer.toJson<String?>(tags),
      'note': serializer.toJson<String?>(note),
      'filePath': serializer.toJson<String>(filePath),
      'fileType': serializer.toJson<String>(fileType),
      'lat': serializer.toJson<double?>(lat),
      'lng': serializer.toJson<double?>(lng),
      'locationText': serializer.toJson<String?>(locationText),
      'aiSummary': serializer.toJson<String?>(aiSummary),
      'fileHash': serializer.toJson<String?>(fileHash),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  MedicalRecord copyWith({
    int? id,
    int? profileId,
    String? title,
    String? type,
    DateTime? recordDate,
    Value<String?> hospital = const Value.absent(),
    Value<String?> department = const Value.absent(),
    Value<String?> tags = const Value.absent(),
    Value<String?> note = const Value.absent(),
    String? filePath,
    String? fileType,
    Value<double?> lat = const Value.absent(),
    Value<double?> lng = const Value.absent(),
    Value<String?> locationText = const Value.absent(),
    Value<String?> aiSummary = const Value.absent(),
    Value<String?> fileHash = const Value.absent(),
    DateTime? createdAt,
  }) => MedicalRecord(
    id: id ?? this.id,
    profileId: profileId ?? this.profileId,
    title: title ?? this.title,
    type: type ?? this.type,
    recordDate: recordDate ?? this.recordDate,
    hospital: hospital.present ? hospital.value : this.hospital,
    department: department.present ? department.value : this.department,
    tags: tags.present ? tags.value : this.tags,
    note: note.present ? note.value : this.note,
    filePath: filePath ?? this.filePath,
    fileType: fileType ?? this.fileType,
    lat: lat.present ? lat.value : this.lat,
    lng: lng.present ? lng.value : this.lng,
    locationText: locationText.present ? locationText.value : this.locationText,
    aiSummary: aiSummary.present ? aiSummary.value : this.aiSummary,
    fileHash: fileHash.present ? fileHash.value : this.fileHash,
    createdAt: createdAt ?? this.createdAt,
  );
  MedicalRecord copyWithCompanion(MedicalRecordsCompanion data) {
    return MedicalRecord(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      title: data.title.present ? data.title.value : this.title,
      type: data.type.present ? data.type.value : this.type,
      recordDate: data.recordDate.present
          ? data.recordDate.value
          : this.recordDate,
      hospital: data.hospital.present ? data.hospital.value : this.hospital,
      department: data.department.present
          ? data.department.value
          : this.department,
      tags: data.tags.present ? data.tags.value : this.tags,
      note: data.note.present ? data.note.value : this.note,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      fileType: data.fileType.present ? data.fileType.value : this.fileType,
      lat: data.lat.present ? data.lat.value : this.lat,
      lng: data.lng.present ? data.lng.value : this.lng,
      locationText: data.locationText.present
          ? data.locationText.value
          : this.locationText,
      aiSummary: data.aiSummary.present ? data.aiSummary.value : this.aiSummary,
      fileHash: data.fileHash.present ? data.fileHash.value : this.fileHash,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MedicalRecord(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('title: $title, ')
          ..write('type: $type, ')
          ..write('recordDate: $recordDate, ')
          ..write('hospital: $hospital, ')
          ..write('department: $department, ')
          ..write('tags: $tags, ')
          ..write('note: $note, ')
          ..write('filePath: $filePath, ')
          ..write('fileType: $fileType, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('locationText: $locationText, ')
          ..write('aiSummary: $aiSummary, ')
          ..write('fileHash: $fileHash, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    profileId,
    title,
    type,
    recordDate,
    hospital,
    department,
    tags,
    note,
    filePath,
    fileType,
    lat,
    lng,
    locationText,
    aiSummary,
    fileHash,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MedicalRecord &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.title == this.title &&
          other.type == this.type &&
          other.recordDate == this.recordDate &&
          other.hospital == this.hospital &&
          other.department == this.department &&
          other.tags == this.tags &&
          other.note == this.note &&
          other.filePath == this.filePath &&
          other.fileType == this.fileType &&
          other.lat == this.lat &&
          other.lng == this.lng &&
          other.locationText == this.locationText &&
          other.aiSummary == this.aiSummary &&
          other.fileHash == this.fileHash &&
          other.createdAt == this.createdAt);
}

class MedicalRecordsCompanion extends UpdateCompanion<MedicalRecord> {
  final Value<int> id;
  final Value<int> profileId;
  final Value<String> title;
  final Value<String> type;
  final Value<DateTime> recordDate;
  final Value<String?> hospital;
  final Value<String?> department;
  final Value<String?> tags;
  final Value<String?> note;
  final Value<String> filePath;
  final Value<String> fileType;
  final Value<double?> lat;
  final Value<double?> lng;
  final Value<String?> locationText;
  final Value<String?> aiSummary;
  final Value<String?> fileHash;
  final Value<DateTime> createdAt;
  const MedicalRecordsCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.title = const Value.absent(),
    this.type = const Value.absent(),
    this.recordDate = const Value.absent(),
    this.hospital = const Value.absent(),
    this.department = const Value.absent(),
    this.tags = const Value.absent(),
    this.note = const Value.absent(),
    this.filePath = const Value.absent(),
    this.fileType = const Value.absent(),
    this.lat = const Value.absent(),
    this.lng = const Value.absent(),
    this.locationText = const Value.absent(),
    this.aiSummary = const Value.absent(),
    this.fileHash = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  MedicalRecordsCompanion.insert({
    this.id = const Value.absent(),
    required int profileId,
    required String title,
    required String type,
    required DateTime recordDate,
    this.hospital = const Value.absent(),
    this.department = const Value.absent(),
    this.tags = const Value.absent(),
    this.note = const Value.absent(),
    required String filePath,
    required String fileType,
    this.lat = const Value.absent(),
    this.lng = const Value.absent(),
    this.locationText = const Value.absent(),
    this.aiSummary = const Value.absent(),
    this.fileHash = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : profileId = Value(profileId),
       title = Value(title),
       type = Value(type),
       recordDate = Value(recordDate),
       filePath = Value(filePath),
       fileType = Value(fileType);
  static Insertable<MedicalRecord> custom({
    Expression<int>? id,
    Expression<int>? profileId,
    Expression<String>? title,
    Expression<String>? type,
    Expression<DateTime>? recordDate,
    Expression<String>? hospital,
    Expression<String>? department,
    Expression<String>? tags,
    Expression<String>? note,
    Expression<String>? filePath,
    Expression<String>? fileType,
    Expression<double>? lat,
    Expression<double>? lng,
    Expression<String>? locationText,
    Expression<String>? aiSummary,
    Expression<String>? fileHash,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      if (title != null) 'title': title,
      if (type != null) 'type': type,
      if (recordDate != null) 'record_date': recordDate,
      if (hospital != null) 'hospital': hospital,
      if (department != null) 'department': department,
      if (tags != null) 'tags': tags,
      if (note != null) 'note': note,
      if (filePath != null) 'file_path': filePath,
      if (fileType != null) 'file_type': fileType,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (locationText != null) 'location_text': locationText,
      if (aiSummary != null) 'ai_summary': aiSummary,
      if (fileHash != null) 'file_hash': fileHash,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  MedicalRecordsCompanion copyWith({
    Value<int>? id,
    Value<int>? profileId,
    Value<String>? title,
    Value<String>? type,
    Value<DateTime>? recordDate,
    Value<String?>? hospital,
    Value<String?>? department,
    Value<String?>? tags,
    Value<String?>? note,
    Value<String>? filePath,
    Value<String>? fileType,
    Value<double?>? lat,
    Value<double?>? lng,
    Value<String?>? locationText,
    Value<String?>? aiSummary,
    Value<String?>? fileHash,
    Value<DateTime>? createdAt,
  }) {
    return MedicalRecordsCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      title: title ?? this.title,
      type: type ?? this.type,
      recordDate: recordDate ?? this.recordDate,
      hospital: hospital ?? this.hospital,
      department: department ?? this.department,
      tags: tags ?? this.tags,
      note: note ?? this.note,
      filePath: filePath ?? this.filePath,
      fileType: fileType ?? this.fileType,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      locationText: locationText ?? this.locationText,
      aiSummary: aiSummary ?? this.aiSummary,
      fileHash: fileHash ?? this.fileHash,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<int>(profileId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (recordDate.present) {
      map['record_date'] = Variable<DateTime>(recordDate.value);
    }
    if (hospital.present) {
      map['hospital'] = Variable<String>(hospital.value);
    }
    if (department.present) {
      map['department'] = Variable<String>(department.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (fileType.present) {
      map['file_type'] = Variable<String>(fileType.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lng.present) {
      map['lng'] = Variable<double>(lng.value);
    }
    if (locationText.present) {
      map['location_text'] = Variable<String>(locationText.value);
    }
    if (aiSummary.present) {
      map['ai_summary'] = Variable<String>(aiSummary.value);
    }
    if (fileHash.present) {
      map['file_hash'] = Variable<String>(fileHash.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MedicalRecordsCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('title: $title, ')
          ..write('type: $type, ')
          ..write('recordDate: $recordDate, ')
          ..write('hospital: $hospital, ')
          ..write('department: $department, ')
          ..write('tags: $tags, ')
          ..write('note: $note, ')
          ..write('filePath: $filePath, ')
          ..write('fileType: $fileType, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('locationText: $locationText, ')
          ..write('aiSummary: $aiSummary, ')
          ..write('fileHash: $fileHash, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $MetricsTable extends Metrics with TableInfo<$MetricsTable, Metric> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MetricsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<int> profileId = GeneratedColumn<int>(
    'profile_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dualValueMeta = const VerificationMeta(
    'dualValue',
  );
  @override
  late final GeneratedColumn<bool> dualValue = GeneratedColumn<bool>(
    'dual_value',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("dual_value" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _refLowMeta = const VerificationMeta('refLow');
  @override
  late final GeneratedColumn<double> refLow = GeneratedColumn<double>(
    'ref_low',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _refHighMeta = const VerificationMeta(
    'refHigh',
  );
  @override
  late final GeneratedColumn<double> refHigh = GeneratedColumn<double>(
    'ref_high',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _refLow2Meta = const VerificationMeta(
    'refLow2',
  );
  @override
  late final GeneratedColumn<double> refLow2 = GeneratedColumn<double>(
    'ref_low2',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _refHigh2Meta = const VerificationMeta(
    'refHigh2',
  );
  @override
  late final GeneratedColumn<double> refHigh2 = GeneratedColumn<double>(
    'ref_high2',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isCustomMeta = const VerificationMeta(
    'isCustom',
  );
  @override
  late final GeneratedColumn<bool> isCustom = GeneratedColumn<bool>(
    'is_custom',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_custom" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _tagMeta = const VerificationMeta('tag');
  @override
  late final GeneratedColumn<String> tag = GeneratedColumn<String>(
    'tag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _aiInfoMeta = const VerificationMeta('aiInfo');
  @override
  late final GeneratedColumn<String> aiInfo = GeneratedColumn<String>(
    'ai_info',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _followedMeta = const VerificationMeta(
    'followed',
  );
  @override
  late final GeneratedColumn<bool> followed = GeneratedColumn<bool>(
    'followed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("followed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    profileId,
    code,
    name,
    unit,
    dualValue,
    refLow,
    refHigh,
    refLow2,
    refHigh2,
    isCustom,
    tag,
    aiInfo,
    followed,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'metrics';
  @override
  VerificationContext validateIntegrity(
    Insertable<Metric> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    if (data.containsKey('dual_value')) {
      context.handle(
        _dualValueMeta,
        dualValue.isAcceptableOrUnknown(data['dual_value']!, _dualValueMeta),
      );
    }
    if (data.containsKey('ref_low')) {
      context.handle(
        _refLowMeta,
        refLow.isAcceptableOrUnknown(data['ref_low']!, _refLowMeta),
      );
    }
    if (data.containsKey('ref_high')) {
      context.handle(
        _refHighMeta,
        refHigh.isAcceptableOrUnknown(data['ref_high']!, _refHighMeta),
      );
    }
    if (data.containsKey('ref_low2')) {
      context.handle(
        _refLow2Meta,
        refLow2.isAcceptableOrUnknown(data['ref_low2']!, _refLow2Meta),
      );
    }
    if (data.containsKey('ref_high2')) {
      context.handle(
        _refHigh2Meta,
        refHigh2.isAcceptableOrUnknown(data['ref_high2']!, _refHigh2Meta),
      );
    }
    if (data.containsKey('is_custom')) {
      context.handle(
        _isCustomMeta,
        isCustom.isAcceptableOrUnknown(data['is_custom']!, _isCustomMeta),
      );
    }
    if (data.containsKey('tag')) {
      context.handle(
        _tagMeta,
        tag.isAcceptableOrUnknown(data['tag']!, _tagMeta),
      );
    }
    if (data.containsKey('ai_info')) {
      context.handle(
        _aiInfoMeta,
        aiInfo.isAcceptableOrUnknown(data['ai_info']!, _aiInfoMeta),
      );
    }
    if (data.containsKey('followed')) {
      context.handle(
        _followedMeta,
        followed.isAcceptableOrUnknown(data['followed']!, _followedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Metric map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Metric(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}profile_id'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      dualValue: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}dual_value'],
      )!,
      refLow: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ref_low'],
      ),
      refHigh: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ref_high'],
      ),
      refLow2: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ref_low2'],
      ),
      refHigh2: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ref_high2'],
      ),
      isCustom: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_custom'],
      )!,
      tag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tag'],
      ),
      aiInfo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ai_info'],
      ),
      followed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}followed'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $MetricsTable createAlias(String alias) {
    return $MetricsTable(attachedDatabase, alias);
  }
}

class Metric extends DataClass implements Insertable<Metric> {
  final int id;
  final int profileId;
  final String code;
  final String name;
  final String unit;
  final bool dualValue;
  final double? refLow;
  final double? refHigh;
  final double? refLow2;
  final double? refHigh2;
  final bool isCustom;
  final String? tag;
  final String? aiInfo;
  final bool followed;
  final DateTime createdAt;
  const Metric({
    required this.id,
    required this.profileId,
    required this.code,
    required this.name,
    required this.unit,
    required this.dualValue,
    this.refLow,
    this.refHigh,
    this.refLow2,
    this.refHigh2,
    required this.isCustom,
    this.tag,
    this.aiInfo,
    required this.followed,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['profile_id'] = Variable<int>(profileId);
    map['code'] = Variable<String>(code);
    map['name'] = Variable<String>(name);
    map['unit'] = Variable<String>(unit);
    map['dual_value'] = Variable<bool>(dualValue);
    if (!nullToAbsent || refLow != null) {
      map['ref_low'] = Variable<double>(refLow);
    }
    if (!nullToAbsent || refHigh != null) {
      map['ref_high'] = Variable<double>(refHigh);
    }
    if (!nullToAbsent || refLow2 != null) {
      map['ref_low2'] = Variable<double>(refLow2);
    }
    if (!nullToAbsent || refHigh2 != null) {
      map['ref_high2'] = Variable<double>(refHigh2);
    }
    map['is_custom'] = Variable<bool>(isCustom);
    if (!nullToAbsent || tag != null) {
      map['tag'] = Variable<String>(tag);
    }
    if (!nullToAbsent || aiInfo != null) {
      map['ai_info'] = Variable<String>(aiInfo);
    }
    map['followed'] = Variable<bool>(followed);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  MetricsCompanion toCompanion(bool nullToAbsent) {
    return MetricsCompanion(
      id: Value(id),
      profileId: Value(profileId),
      code: Value(code),
      name: Value(name),
      unit: Value(unit),
      dualValue: Value(dualValue),
      refLow: refLow == null && nullToAbsent
          ? const Value.absent()
          : Value(refLow),
      refHigh: refHigh == null && nullToAbsent
          ? const Value.absent()
          : Value(refHigh),
      refLow2: refLow2 == null && nullToAbsent
          ? const Value.absent()
          : Value(refLow2),
      refHigh2: refHigh2 == null && nullToAbsent
          ? const Value.absent()
          : Value(refHigh2),
      isCustom: Value(isCustom),
      tag: tag == null && nullToAbsent ? const Value.absent() : Value(tag),
      aiInfo: aiInfo == null && nullToAbsent
          ? const Value.absent()
          : Value(aiInfo),
      followed: Value(followed),
      createdAt: Value(createdAt),
    );
  }

  factory Metric.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Metric(
      id: serializer.fromJson<int>(json['id']),
      profileId: serializer.fromJson<int>(json['profileId']),
      code: serializer.fromJson<String>(json['code']),
      name: serializer.fromJson<String>(json['name']),
      unit: serializer.fromJson<String>(json['unit']),
      dualValue: serializer.fromJson<bool>(json['dualValue']),
      refLow: serializer.fromJson<double?>(json['refLow']),
      refHigh: serializer.fromJson<double?>(json['refHigh']),
      refLow2: serializer.fromJson<double?>(json['refLow2']),
      refHigh2: serializer.fromJson<double?>(json['refHigh2']),
      isCustom: serializer.fromJson<bool>(json['isCustom']),
      tag: serializer.fromJson<String?>(json['tag']),
      aiInfo: serializer.fromJson<String?>(json['aiInfo']),
      followed: serializer.fromJson<bool>(json['followed']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'profileId': serializer.toJson<int>(profileId),
      'code': serializer.toJson<String>(code),
      'name': serializer.toJson<String>(name),
      'unit': serializer.toJson<String>(unit),
      'dualValue': serializer.toJson<bool>(dualValue),
      'refLow': serializer.toJson<double?>(refLow),
      'refHigh': serializer.toJson<double?>(refHigh),
      'refLow2': serializer.toJson<double?>(refLow2),
      'refHigh2': serializer.toJson<double?>(refHigh2),
      'isCustom': serializer.toJson<bool>(isCustom),
      'tag': serializer.toJson<String?>(tag),
      'aiInfo': serializer.toJson<String?>(aiInfo),
      'followed': serializer.toJson<bool>(followed),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Metric copyWith({
    int? id,
    int? profileId,
    String? code,
    String? name,
    String? unit,
    bool? dualValue,
    Value<double?> refLow = const Value.absent(),
    Value<double?> refHigh = const Value.absent(),
    Value<double?> refLow2 = const Value.absent(),
    Value<double?> refHigh2 = const Value.absent(),
    bool? isCustom,
    Value<String?> tag = const Value.absent(),
    Value<String?> aiInfo = const Value.absent(),
    bool? followed,
    DateTime? createdAt,
  }) => Metric(
    id: id ?? this.id,
    profileId: profileId ?? this.profileId,
    code: code ?? this.code,
    name: name ?? this.name,
    unit: unit ?? this.unit,
    dualValue: dualValue ?? this.dualValue,
    refLow: refLow.present ? refLow.value : this.refLow,
    refHigh: refHigh.present ? refHigh.value : this.refHigh,
    refLow2: refLow2.present ? refLow2.value : this.refLow2,
    refHigh2: refHigh2.present ? refHigh2.value : this.refHigh2,
    isCustom: isCustom ?? this.isCustom,
    tag: tag.present ? tag.value : this.tag,
    aiInfo: aiInfo.present ? aiInfo.value : this.aiInfo,
    followed: followed ?? this.followed,
    createdAt: createdAt ?? this.createdAt,
  );
  Metric copyWithCompanion(MetricsCompanion data) {
    return Metric(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      code: data.code.present ? data.code.value : this.code,
      name: data.name.present ? data.name.value : this.name,
      unit: data.unit.present ? data.unit.value : this.unit,
      dualValue: data.dualValue.present ? data.dualValue.value : this.dualValue,
      refLow: data.refLow.present ? data.refLow.value : this.refLow,
      refHigh: data.refHigh.present ? data.refHigh.value : this.refHigh,
      refLow2: data.refLow2.present ? data.refLow2.value : this.refLow2,
      refHigh2: data.refHigh2.present ? data.refHigh2.value : this.refHigh2,
      isCustom: data.isCustom.present ? data.isCustom.value : this.isCustom,
      tag: data.tag.present ? data.tag.value : this.tag,
      aiInfo: data.aiInfo.present ? data.aiInfo.value : this.aiInfo,
      followed: data.followed.present ? data.followed.value : this.followed,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Metric(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('unit: $unit, ')
          ..write('dualValue: $dualValue, ')
          ..write('refLow: $refLow, ')
          ..write('refHigh: $refHigh, ')
          ..write('refLow2: $refLow2, ')
          ..write('refHigh2: $refHigh2, ')
          ..write('isCustom: $isCustom, ')
          ..write('tag: $tag, ')
          ..write('aiInfo: $aiInfo, ')
          ..write('followed: $followed, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    profileId,
    code,
    name,
    unit,
    dualValue,
    refLow,
    refHigh,
    refLow2,
    refHigh2,
    isCustom,
    tag,
    aiInfo,
    followed,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Metric &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.code == this.code &&
          other.name == this.name &&
          other.unit == this.unit &&
          other.dualValue == this.dualValue &&
          other.refLow == this.refLow &&
          other.refHigh == this.refHigh &&
          other.refLow2 == this.refLow2 &&
          other.refHigh2 == this.refHigh2 &&
          other.isCustom == this.isCustom &&
          other.tag == this.tag &&
          other.aiInfo == this.aiInfo &&
          other.followed == this.followed &&
          other.createdAt == this.createdAt);
}

class MetricsCompanion extends UpdateCompanion<Metric> {
  final Value<int> id;
  final Value<int> profileId;
  final Value<String> code;
  final Value<String> name;
  final Value<String> unit;
  final Value<bool> dualValue;
  final Value<double?> refLow;
  final Value<double?> refHigh;
  final Value<double?> refLow2;
  final Value<double?> refHigh2;
  final Value<bool> isCustom;
  final Value<String?> tag;
  final Value<String?> aiInfo;
  final Value<bool> followed;
  final Value<DateTime> createdAt;
  const MetricsCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.code = const Value.absent(),
    this.name = const Value.absent(),
    this.unit = const Value.absent(),
    this.dualValue = const Value.absent(),
    this.refLow = const Value.absent(),
    this.refHigh = const Value.absent(),
    this.refLow2 = const Value.absent(),
    this.refHigh2 = const Value.absent(),
    this.isCustom = const Value.absent(),
    this.tag = const Value.absent(),
    this.aiInfo = const Value.absent(),
    this.followed = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  MetricsCompanion.insert({
    this.id = const Value.absent(),
    required int profileId,
    required String code,
    required String name,
    required String unit,
    this.dualValue = const Value.absent(),
    this.refLow = const Value.absent(),
    this.refHigh = const Value.absent(),
    this.refLow2 = const Value.absent(),
    this.refHigh2 = const Value.absent(),
    this.isCustom = const Value.absent(),
    this.tag = const Value.absent(),
    this.aiInfo = const Value.absent(),
    this.followed = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : profileId = Value(profileId),
       code = Value(code),
       name = Value(name),
       unit = Value(unit);
  static Insertable<Metric> custom({
    Expression<int>? id,
    Expression<int>? profileId,
    Expression<String>? code,
    Expression<String>? name,
    Expression<String>? unit,
    Expression<bool>? dualValue,
    Expression<double>? refLow,
    Expression<double>? refHigh,
    Expression<double>? refLow2,
    Expression<double>? refHigh2,
    Expression<bool>? isCustom,
    Expression<String>? tag,
    Expression<String>? aiInfo,
    Expression<bool>? followed,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      if (code != null) 'code': code,
      if (name != null) 'name': name,
      if (unit != null) 'unit': unit,
      if (dualValue != null) 'dual_value': dualValue,
      if (refLow != null) 'ref_low': refLow,
      if (refHigh != null) 'ref_high': refHigh,
      if (refLow2 != null) 'ref_low2': refLow2,
      if (refHigh2 != null) 'ref_high2': refHigh2,
      if (isCustom != null) 'is_custom': isCustom,
      if (tag != null) 'tag': tag,
      if (aiInfo != null) 'ai_info': aiInfo,
      if (followed != null) 'followed': followed,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  MetricsCompanion copyWith({
    Value<int>? id,
    Value<int>? profileId,
    Value<String>? code,
    Value<String>? name,
    Value<String>? unit,
    Value<bool>? dualValue,
    Value<double?>? refLow,
    Value<double?>? refHigh,
    Value<double?>? refLow2,
    Value<double?>? refHigh2,
    Value<bool>? isCustom,
    Value<String?>? tag,
    Value<String?>? aiInfo,
    Value<bool>? followed,
    Value<DateTime>? createdAt,
  }) {
    return MetricsCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      code: code ?? this.code,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      dualValue: dualValue ?? this.dualValue,
      refLow: refLow ?? this.refLow,
      refHigh: refHigh ?? this.refHigh,
      refLow2: refLow2 ?? this.refLow2,
      refHigh2: refHigh2 ?? this.refHigh2,
      isCustom: isCustom ?? this.isCustom,
      tag: tag ?? this.tag,
      aiInfo: aiInfo ?? this.aiInfo,
      followed: followed ?? this.followed,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<int>(profileId.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (dualValue.present) {
      map['dual_value'] = Variable<bool>(dualValue.value);
    }
    if (refLow.present) {
      map['ref_low'] = Variable<double>(refLow.value);
    }
    if (refHigh.present) {
      map['ref_high'] = Variable<double>(refHigh.value);
    }
    if (refLow2.present) {
      map['ref_low2'] = Variable<double>(refLow2.value);
    }
    if (refHigh2.present) {
      map['ref_high2'] = Variable<double>(refHigh2.value);
    }
    if (isCustom.present) {
      map['is_custom'] = Variable<bool>(isCustom.value);
    }
    if (tag.present) {
      map['tag'] = Variable<String>(tag.value);
    }
    if (aiInfo.present) {
      map['ai_info'] = Variable<String>(aiInfo.value);
    }
    if (followed.present) {
      map['followed'] = Variable<bool>(followed.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MetricsCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('unit: $unit, ')
          ..write('dualValue: $dualValue, ')
          ..write('refLow: $refLow, ')
          ..write('refHigh: $refHigh, ')
          ..write('refLow2: $refLow2, ')
          ..write('refHigh2: $refHigh2, ')
          ..write('isCustom: $isCustom, ')
          ..write('tag: $tag, ')
          ..write('aiInfo: $aiInfo, ')
          ..write('followed: $followed, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $MetricValuesTable extends MetricValues
    with TableInfo<$MetricValuesTable, MetricValue> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MetricValuesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _metricIdMeta = const VerificationMeta(
    'metricId',
  );
  @override
  late final GeneratedColumn<int> metricId = GeneratedColumn<int>(
    'metric_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _value1Meta = const VerificationMeta('value1');
  @override
  late final GeneratedColumn<double> value1 = GeneratedColumn<double>(
    'value1',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _value2Meta = const VerificationMeta('value2');
  @override
  late final GeneratedColumn<double> value2 = GeneratedColumn<double>(
    'value2',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _measuredAtMeta = const VerificationMeta(
    'measuredAt',
  );
  @override
  late final GeneratedColumn<DateTime> measuredAt = GeneratedColumn<DateTime>(
    'measured_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timeLabelMeta = const VerificationMeta(
    'timeLabel',
  );
  @override
  late final GeneratedColumn<String> timeLabel = GeneratedColumn<String>(
    'time_label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('manual'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    metricId,
    value1,
    value2,
    measuredAt,
    note,
    timeLabel,
    source,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'metric_values';
  @override
  VerificationContext validateIntegrity(
    Insertable<MetricValue> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('metric_id')) {
      context.handle(
        _metricIdMeta,
        metricId.isAcceptableOrUnknown(data['metric_id']!, _metricIdMeta),
      );
    } else if (isInserting) {
      context.missing(_metricIdMeta);
    }
    if (data.containsKey('value1')) {
      context.handle(
        _value1Meta,
        value1.isAcceptableOrUnknown(data['value1']!, _value1Meta),
      );
    } else if (isInserting) {
      context.missing(_value1Meta);
    }
    if (data.containsKey('value2')) {
      context.handle(
        _value2Meta,
        value2.isAcceptableOrUnknown(data['value2']!, _value2Meta),
      );
    }
    if (data.containsKey('measured_at')) {
      context.handle(
        _measuredAtMeta,
        measuredAt.isAcceptableOrUnknown(data['measured_at']!, _measuredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_measuredAtMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('time_label')) {
      context.handle(
        _timeLabelMeta,
        timeLabel.isAcceptableOrUnknown(data['time_label']!, _timeLabelMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MetricValue map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MetricValue(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      metricId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}metric_id'],
      )!,
      value1: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}value1'],
      )!,
      value2: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}value2'],
      ),
      measuredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}measured_at'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      timeLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}time_label'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $MetricValuesTable createAlias(String alias) {
    return $MetricValuesTable(attachedDatabase, alias);
  }
}

class MetricValue extends DataClass implements Insertable<MetricValue> {
  final int id;
  final int metricId;
  final double value1;
  final double? value2;
  final DateTime measuredAt;
  final String? note;
  final String? timeLabel;
  final String source;
  final DateTime createdAt;
  const MetricValue({
    required this.id,
    required this.metricId,
    required this.value1,
    this.value2,
    required this.measuredAt,
    this.note,
    this.timeLabel,
    required this.source,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['metric_id'] = Variable<int>(metricId);
    map['value1'] = Variable<double>(value1);
    if (!nullToAbsent || value2 != null) {
      map['value2'] = Variable<double>(value2);
    }
    map['measured_at'] = Variable<DateTime>(measuredAt);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || timeLabel != null) {
      map['time_label'] = Variable<String>(timeLabel);
    }
    map['source'] = Variable<String>(source);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  MetricValuesCompanion toCompanion(bool nullToAbsent) {
    return MetricValuesCompanion(
      id: Value(id),
      metricId: Value(metricId),
      value1: Value(value1),
      value2: value2 == null && nullToAbsent
          ? const Value.absent()
          : Value(value2),
      measuredAt: Value(measuredAt),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      timeLabel: timeLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(timeLabel),
      source: Value(source),
      createdAt: Value(createdAt),
    );
  }

  factory MetricValue.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MetricValue(
      id: serializer.fromJson<int>(json['id']),
      metricId: serializer.fromJson<int>(json['metricId']),
      value1: serializer.fromJson<double>(json['value1']),
      value2: serializer.fromJson<double?>(json['value2']),
      measuredAt: serializer.fromJson<DateTime>(json['measuredAt']),
      note: serializer.fromJson<String?>(json['note']),
      timeLabel: serializer.fromJson<String?>(json['timeLabel']),
      source: serializer.fromJson<String>(json['source']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'metricId': serializer.toJson<int>(metricId),
      'value1': serializer.toJson<double>(value1),
      'value2': serializer.toJson<double?>(value2),
      'measuredAt': serializer.toJson<DateTime>(measuredAt),
      'note': serializer.toJson<String?>(note),
      'timeLabel': serializer.toJson<String?>(timeLabel),
      'source': serializer.toJson<String>(source),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  MetricValue copyWith({
    int? id,
    int? metricId,
    double? value1,
    Value<double?> value2 = const Value.absent(),
    DateTime? measuredAt,
    Value<String?> note = const Value.absent(),
    Value<String?> timeLabel = const Value.absent(),
    String? source,
    DateTime? createdAt,
  }) => MetricValue(
    id: id ?? this.id,
    metricId: metricId ?? this.metricId,
    value1: value1 ?? this.value1,
    value2: value2.present ? value2.value : this.value2,
    measuredAt: measuredAt ?? this.measuredAt,
    note: note.present ? note.value : this.note,
    timeLabel: timeLabel.present ? timeLabel.value : this.timeLabel,
    source: source ?? this.source,
    createdAt: createdAt ?? this.createdAt,
  );
  MetricValue copyWithCompanion(MetricValuesCompanion data) {
    return MetricValue(
      id: data.id.present ? data.id.value : this.id,
      metricId: data.metricId.present ? data.metricId.value : this.metricId,
      value1: data.value1.present ? data.value1.value : this.value1,
      value2: data.value2.present ? data.value2.value : this.value2,
      measuredAt: data.measuredAt.present
          ? data.measuredAt.value
          : this.measuredAt,
      note: data.note.present ? data.note.value : this.note,
      timeLabel: data.timeLabel.present ? data.timeLabel.value : this.timeLabel,
      source: data.source.present ? data.source.value : this.source,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MetricValue(')
          ..write('id: $id, ')
          ..write('metricId: $metricId, ')
          ..write('value1: $value1, ')
          ..write('value2: $value2, ')
          ..write('measuredAt: $measuredAt, ')
          ..write('note: $note, ')
          ..write('timeLabel: $timeLabel, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    metricId,
    value1,
    value2,
    measuredAt,
    note,
    timeLabel,
    source,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MetricValue &&
          other.id == this.id &&
          other.metricId == this.metricId &&
          other.value1 == this.value1 &&
          other.value2 == this.value2 &&
          other.measuredAt == this.measuredAt &&
          other.note == this.note &&
          other.timeLabel == this.timeLabel &&
          other.source == this.source &&
          other.createdAt == this.createdAt);
}

class MetricValuesCompanion extends UpdateCompanion<MetricValue> {
  final Value<int> id;
  final Value<int> metricId;
  final Value<double> value1;
  final Value<double?> value2;
  final Value<DateTime> measuredAt;
  final Value<String?> note;
  final Value<String?> timeLabel;
  final Value<String> source;
  final Value<DateTime> createdAt;
  const MetricValuesCompanion({
    this.id = const Value.absent(),
    this.metricId = const Value.absent(),
    this.value1 = const Value.absent(),
    this.value2 = const Value.absent(),
    this.measuredAt = const Value.absent(),
    this.note = const Value.absent(),
    this.timeLabel = const Value.absent(),
    this.source = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  MetricValuesCompanion.insert({
    this.id = const Value.absent(),
    required int metricId,
    required double value1,
    this.value2 = const Value.absent(),
    required DateTime measuredAt,
    this.note = const Value.absent(),
    this.timeLabel = const Value.absent(),
    this.source = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : metricId = Value(metricId),
       value1 = Value(value1),
       measuredAt = Value(measuredAt);
  static Insertable<MetricValue> custom({
    Expression<int>? id,
    Expression<int>? metricId,
    Expression<double>? value1,
    Expression<double>? value2,
    Expression<DateTime>? measuredAt,
    Expression<String>? note,
    Expression<String>? timeLabel,
    Expression<String>? source,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (metricId != null) 'metric_id': metricId,
      if (value1 != null) 'value1': value1,
      if (value2 != null) 'value2': value2,
      if (measuredAt != null) 'measured_at': measuredAt,
      if (note != null) 'note': note,
      if (timeLabel != null) 'time_label': timeLabel,
      if (source != null) 'source': source,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  MetricValuesCompanion copyWith({
    Value<int>? id,
    Value<int>? metricId,
    Value<double>? value1,
    Value<double?>? value2,
    Value<DateTime>? measuredAt,
    Value<String?>? note,
    Value<String?>? timeLabel,
    Value<String>? source,
    Value<DateTime>? createdAt,
  }) {
    return MetricValuesCompanion(
      id: id ?? this.id,
      metricId: metricId ?? this.metricId,
      value1: value1 ?? this.value1,
      value2: value2 ?? this.value2,
      measuredAt: measuredAt ?? this.measuredAt,
      note: note ?? this.note,
      timeLabel: timeLabel ?? this.timeLabel,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (metricId.present) {
      map['metric_id'] = Variable<int>(metricId.value);
    }
    if (value1.present) {
      map['value1'] = Variable<double>(value1.value);
    }
    if (value2.present) {
      map['value2'] = Variable<double>(value2.value);
    }
    if (measuredAt.present) {
      map['measured_at'] = Variable<DateTime>(measuredAt.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (timeLabel.present) {
      map['time_label'] = Variable<String>(timeLabel.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MetricValuesCompanion(')
          ..write('id: $id, ')
          ..write('metricId: $metricId, ')
          ..write('value1: $value1, ')
          ..write('value2: $value2, ')
          ..write('measuredAt: $measuredAt, ')
          ..write('note: $note, ')
          ..write('timeLabel: $timeLabel, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $MedicationsTable extends Medications
    with TableInfo<$MedicationsTable, Medication> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MedicationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<int> profileId = GeneratedColumn<int>(
    'profile_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dosageMeta = const VerificationMeta('dosage');
  @override
  late final GeneratedColumn<String> dosage = GeneratedColumn<String>(
    'dosage',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mealRelationMeta = const VerificationMeta(
    'mealRelation',
  );
  @override
  late final GeneratedColumn<String> mealRelation = GeneratedColumn<String>(
    'meal_relation',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timesOfDayMeta = const VerificationMeta(
    'timesOfDay',
  );
  @override
  late final GeneratedColumn<String> timesOfDay = GeneratedColumn<String>(
    'times_of_day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _daysOfWeekMeta = const VerificationMeta(
    'daysOfWeek',
  );
  @override
  late final GeneratedColumn<String> daysOfWeek = GeneratedColumn<String>(
    'days_of_week',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
    'start_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<DateTime> endDate = GeneratedColumn<DateTime>(
    'end_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pausePeriodsMeta = const VerificationMeta(
    'pausePeriods',
  );
  @override
  late final GeneratedColumn<String> pausePeriods = GeneratedColumn<String>(
    'pause_periods',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stockMeta = const VerificationMeta('stock');
  @override
  late final GeneratedColumn<double> stock = GeneratedColumn<double>(
    'stock',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stockUnitMeta = const VerificationMeta(
    'stockUnit',
  );
  @override
  late final GeneratedColumn<String> stockUnit = GeneratedColumn<String>(
    'stock_unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reminderEnabledMeta = const VerificationMeta(
    'reminderEnabled',
  );
  @override
  late final GeneratedColumn<bool> reminderEnabled = GeneratedColumn<bool>(
    'reminder_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("reminder_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    profileId,
    name,
    dosage,
    mealRelation,
    timesOfDay,
    daysOfWeek,
    startDate,
    endDate,
    pausePeriods,
    stock,
    stockUnit,
    reminderEnabled,
    note,
    active,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'medications';
  @override
  VerificationContext validateIntegrity(
    Insertable<Medication> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('dosage')) {
      context.handle(
        _dosageMeta,
        dosage.isAcceptableOrUnknown(data['dosage']!, _dosageMeta),
      );
    }
    if (data.containsKey('meal_relation')) {
      context.handle(
        _mealRelationMeta,
        mealRelation.isAcceptableOrUnknown(
          data['meal_relation']!,
          _mealRelationMeta,
        ),
      );
    }
    if (data.containsKey('times_of_day')) {
      context.handle(
        _timesOfDayMeta,
        timesOfDay.isAcceptableOrUnknown(
          data['times_of_day']!,
          _timesOfDayMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_timesOfDayMeta);
    }
    if (data.containsKey('days_of_week')) {
      context.handle(
        _daysOfWeekMeta,
        daysOfWeek.isAcceptableOrUnknown(
          data['days_of_week']!,
          _daysOfWeekMeta,
        ),
      );
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    }
    if (data.containsKey('pause_periods')) {
      context.handle(
        _pausePeriodsMeta,
        pausePeriods.isAcceptableOrUnknown(
          data['pause_periods']!,
          _pausePeriodsMeta,
        ),
      );
    }
    if (data.containsKey('stock')) {
      context.handle(
        _stockMeta,
        stock.isAcceptableOrUnknown(data['stock']!, _stockMeta),
      );
    }
    if (data.containsKey('stock_unit')) {
      context.handle(
        _stockUnitMeta,
        stockUnit.isAcceptableOrUnknown(data['stock_unit']!, _stockUnitMeta),
      );
    }
    if (data.containsKey('reminder_enabled')) {
      context.handle(
        _reminderEnabledMeta,
        reminderEnabled.isAcceptableOrUnknown(
          data['reminder_enabled']!,
          _reminderEnabledMeta,
        ),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Medication map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Medication(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}profile_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      dosage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dosage'],
      ),
      mealRelation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meal_relation'],
      ),
      timesOfDay: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}times_of_day'],
      )!,
      daysOfWeek: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}days_of_week'],
      ),
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_date'],
      ),
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_date'],
      ),
      pausePeriods: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pause_periods'],
      ),
      stock: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}stock'],
      ),
      stockUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stock_unit'],
      ),
      reminderEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}reminder_enabled'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $MedicationsTable createAlias(String alias) {
    return $MedicationsTable(attachedDatabase, alias);
  }
}

class Medication extends DataClass implements Insertable<Medication> {
  final int id;
  final int profileId;
  final String name;
  final String? dosage;
  final String? mealRelation;
  final String timesOfDay;
  final String? daysOfWeek;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? pausePeriods;
  final double? stock;
  final String? stockUnit;
  final bool reminderEnabled;
  final String? note;
  final bool active;
  final DateTime createdAt;
  const Medication({
    required this.id,
    required this.profileId,
    required this.name,
    this.dosage,
    this.mealRelation,
    required this.timesOfDay,
    this.daysOfWeek,
    this.startDate,
    this.endDate,
    this.pausePeriods,
    this.stock,
    this.stockUnit,
    required this.reminderEnabled,
    this.note,
    required this.active,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['profile_id'] = Variable<int>(profileId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || dosage != null) {
      map['dosage'] = Variable<String>(dosage);
    }
    if (!nullToAbsent || mealRelation != null) {
      map['meal_relation'] = Variable<String>(mealRelation);
    }
    map['times_of_day'] = Variable<String>(timesOfDay);
    if (!nullToAbsent || daysOfWeek != null) {
      map['days_of_week'] = Variable<String>(daysOfWeek);
    }
    if (!nullToAbsent || startDate != null) {
      map['start_date'] = Variable<DateTime>(startDate);
    }
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<DateTime>(endDate);
    }
    if (!nullToAbsent || pausePeriods != null) {
      map['pause_periods'] = Variable<String>(pausePeriods);
    }
    if (!nullToAbsent || stock != null) {
      map['stock'] = Variable<double>(stock);
    }
    if (!nullToAbsent || stockUnit != null) {
      map['stock_unit'] = Variable<String>(stockUnit);
    }
    map['reminder_enabled'] = Variable<bool>(reminderEnabled);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['active'] = Variable<bool>(active);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  MedicationsCompanion toCompanion(bool nullToAbsent) {
    return MedicationsCompanion(
      id: Value(id),
      profileId: Value(profileId),
      name: Value(name),
      dosage: dosage == null && nullToAbsent
          ? const Value.absent()
          : Value(dosage),
      mealRelation: mealRelation == null && nullToAbsent
          ? const Value.absent()
          : Value(mealRelation),
      timesOfDay: Value(timesOfDay),
      daysOfWeek: daysOfWeek == null && nullToAbsent
          ? const Value.absent()
          : Value(daysOfWeek),
      startDate: startDate == null && nullToAbsent
          ? const Value.absent()
          : Value(startDate),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
      pausePeriods: pausePeriods == null && nullToAbsent
          ? const Value.absent()
          : Value(pausePeriods),
      stock: stock == null && nullToAbsent
          ? const Value.absent()
          : Value(stock),
      stockUnit: stockUnit == null && nullToAbsent
          ? const Value.absent()
          : Value(stockUnit),
      reminderEnabled: Value(reminderEnabled),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      active: Value(active),
      createdAt: Value(createdAt),
    );
  }

  factory Medication.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Medication(
      id: serializer.fromJson<int>(json['id']),
      profileId: serializer.fromJson<int>(json['profileId']),
      name: serializer.fromJson<String>(json['name']),
      dosage: serializer.fromJson<String?>(json['dosage']),
      mealRelation: serializer.fromJson<String?>(json['mealRelation']),
      timesOfDay: serializer.fromJson<String>(json['timesOfDay']),
      daysOfWeek: serializer.fromJson<String?>(json['daysOfWeek']),
      startDate: serializer.fromJson<DateTime?>(json['startDate']),
      endDate: serializer.fromJson<DateTime?>(json['endDate']),
      pausePeriods: serializer.fromJson<String?>(json['pausePeriods']),
      stock: serializer.fromJson<double?>(json['stock']),
      stockUnit: serializer.fromJson<String?>(json['stockUnit']),
      reminderEnabled: serializer.fromJson<bool>(json['reminderEnabled']),
      note: serializer.fromJson<String?>(json['note']),
      active: serializer.fromJson<bool>(json['active']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'profileId': serializer.toJson<int>(profileId),
      'name': serializer.toJson<String>(name),
      'dosage': serializer.toJson<String?>(dosage),
      'mealRelation': serializer.toJson<String?>(mealRelation),
      'timesOfDay': serializer.toJson<String>(timesOfDay),
      'daysOfWeek': serializer.toJson<String?>(daysOfWeek),
      'startDate': serializer.toJson<DateTime?>(startDate),
      'endDate': serializer.toJson<DateTime?>(endDate),
      'pausePeriods': serializer.toJson<String?>(pausePeriods),
      'stock': serializer.toJson<double?>(stock),
      'stockUnit': serializer.toJson<String?>(stockUnit),
      'reminderEnabled': serializer.toJson<bool>(reminderEnabled),
      'note': serializer.toJson<String?>(note),
      'active': serializer.toJson<bool>(active),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Medication copyWith({
    int? id,
    int? profileId,
    String? name,
    Value<String?> dosage = const Value.absent(),
    Value<String?> mealRelation = const Value.absent(),
    String? timesOfDay,
    Value<String?> daysOfWeek = const Value.absent(),
    Value<DateTime?> startDate = const Value.absent(),
    Value<DateTime?> endDate = const Value.absent(),
    Value<String?> pausePeriods = const Value.absent(),
    Value<double?> stock = const Value.absent(),
    Value<String?> stockUnit = const Value.absent(),
    bool? reminderEnabled,
    Value<String?> note = const Value.absent(),
    bool? active,
    DateTime? createdAt,
  }) => Medication(
    id: id ?? this.id,
    profileId: profileId ?? this.profileId,
    name: name ?? this.name,
    dosage: dosage.present ? dosage.value : this.dosage,
    mealRelation: mealRelation.present ? mealRelation.value : this.mealRelation,
    timesOfDay: timesOfDay ?? this.timesOfDay,
    daysOfWeek: daysOfWeek.present ? daysOfWeek.value : this.daysOfWeek,
    startDate: startDate.present ? startDate.value : this.startDate,
    endDate: endDate.present ? endDate.value : this.endDate,
    pausePeriods: pausePeriods.present ? pausePeriods.value : this.pausePeriods,
    stock: stock.present ? stock.value : this.stock,
    stockUnit: stockUnit.present ? stockUnit.value : this.stockUnit,
    reminderEnabled: reminderEnabled ?? this.reminderEnabled,
    note: note.present ? note.value : this.note,
    active: active ?? this.active,
    createdAt: createdAt ?? this.createdAt,
  );
  Medication copyWithCompanion(MedicationsCompanion data) {
    return Medication(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      name: data.name.present ? data.name.value : this.name,
      dosage: data.dosage.present ? data.dosage.value : this.dosage,
      mealRelation: data.mealRelation.present
          ? data.mealRelation.value
          : this.mealRelation,
      timesOfDay: data.timesOfDay.present
          ? data.timesOfDay.value
          : this.timesOfDay,
      daysOfWeek: data.daysOfWeek.present
          ? data.daysOfWeek.value
          : this.daysOfWeek,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      pausePeriods: data.pausePeriods.present
          ? data.pausePeriods.value
          : this.pausePeriods,
      stock: data.stock.present ? data.stock.value : this.stock,
      stockUnit: data.stockUnit.present ? data.stockUnit.value : this.stockUnit,
      reminderEnabled: data.reminderEnabled.present
          ? data.reminderEnabled.value
          : this.reminderEnabled,
      note: data.note.present ? data.note.value : this.note,
      active: data.active.present ? data.active.value : this.active,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Medication(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('name: $name, ')
          ..write('dosage: $dosage, ')
          ..write('mealRelation: $mealRelation, ')
          ..write('timesOfDay: $timesOfDay, ')
          ..write('daysOfWeek: $daysOfWeek, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('pausePeriods: $pausePeriods, ')
          ..write('stock: $stock, ')
          ..write('stockUnit: $stockUnit, ')
          ..write('reminderEnabled: $reminderEnabled, ')
          ..write('note: $note, ')
          ..write('active: $active, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    profileId,
    name,
    dosage,
    mealRelation,
    timesOfDay,
    daysOfWeek,
    startDate,
    endDate,
    pausePeriods,
    stock,
    stockUnit,
    reminderEnabled,
    note,
    active,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Medication &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.name == this.name &&
          other.dosage == this.dosage &&
          other.mealRelation == this.mealRelation &&
          other.timesOfDay == this.timesOfDay &&
          other.daysOfWeek == this.daysOfWeek &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.pausePeriods == this.pausePeriods &&
          other.stock == this.stock &&
          other.stockUnit == this.stockUnit &&
          other.reminderEnabled == this.reminderEnabled &&
          other.note == this.note &&
          other.active == this.active &&
          other.createdAt == this.createdAt);
}

class MedicationsCompanion extends UpdateCompanion<Medication> {
  final Value<int> id;
  final Value<int> profileId;
  final Value<String> name;
  final Value<String?> dosage;
  final Value<String?> mealRelation;
  final Value<String> timesOfDay;
  final Value<String?> daysOfWeek;
  final Value<DateTime?> startDate;
  final Value<DateTime?> endDate;
  final Value<String?> pausePeriods;
  final Value<double?> stock;
  final Value<String?> stockUnit;
  final Value<bool> reminderEnabled;
  final Value<String?> note;
  final Value<bool> active;
  final Value<DateTime> createdAt;
  const MedicationsCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.name = const Value.absent(),
    this.dosage = const Value.absent(),
    this.mealRelation = const Value.absent(),
    this.timesOfDay = const Value.absent(),
    this.daysOfWeek = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.pausePeriods = const Value.absent(),
    this.stock = const Value.absent(),
    this.stockUnit = const Value.absent(),
    this.reminderEnabled = const Value.absent(),
    this.note = const Value.absent(),
    this.active = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  MedicationsCompanion.insert({
    this.id = const Value.absent(),
    required int profileId,
    required String name,
    this.dosage = const Value.absent(),
    this.mealRelation = const Value.absent(),
    required String timesOfDay,
    this.daysOfWeek = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.pausePeriods = const Value.absent(),
    this.stock = const Value.absent(),
    this.stockUnit = const Value.absent(),
    this.reminderEnabled = const Value.absent(),
    this.note = const Value.absent(),
    this.active = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : profileId = Value(profileId),
       name = Value(name),
       timesOfDay = Value(timesOfDay);
  static Insertable<Medication> custom({
    Expression<int>? id,
    Expression<int>? profileId,
    Expression<String>? name,
    Expression<String>? dosage,
    Expression<String>? mealRelation,
    Expression<String>? timesOfDay,
    Expression<String>? daysOfWeek,
    Expression<DateTime>? startDate,
    Expression<DateTime>? endDate,
    Expression<String>? pausePeriods,
    Expression<double>? stock,
    Expression<String>? stockUnit,
    Expression<bool>? reminderEnabled,
    Expression<String>? note,
    Expression<bool>? active,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      if (name != null) 'name': name,
      if (dosage != null) 'dosage': dosage,
      if (mealRelation != null) 'meal_relation': mealRelation,
      if (timesOfDay != null) 'times_of_day': timesOfDay,
      if (daysOfWeek != null) 'days_of_week': daysOfWeek,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (pausePeriods != null) 'pause_periods': pausePeriods,
      if (stock != null) 'stock': stock,
      if (stockUnit != null) 'stock_unit': stockUnit,
      if (reminderEnabled != null) 'reminder_enabled': reminderEnabled,
      if (note != null) 'note': note,
      if (active != null) 'active': active,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  MedicationsCompanion copyWith({
    Value<int>? id,
    Value<int>? profileId,
    Value<String>? name,
    Value<String?>? dosage,
    Value<String?>? mealRelation,
    Value<String>? timesOfDay,
    Value<String?>? daysOfWeek,
    Value<DateTime?>? startDate,
    Value<DateTime?>? endDate,
    Value<String?>? pausePeriods,
    Value<double?>? stock,
    Value<String?>? stockUnit,
    Value<bool>? reminderEnabled,
    Value<String?>? note,
    Value<bool>? active,
    Value<DateTime>? createdAt,
  }) {
    return MedicationsCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      mealRelation: mealRelation ?? this.mealRelation,
      timesOfDay: timesOfDay ?? this.timesOfDay,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      pausePeriods: pausePeriods ?? this.pausePeriods,
      stock: stock ?? this.stock,
      stockUnit: stockUnit ?? this.stockUnit,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      note: note ?? this.note,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<int>(profileId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (dosage.present) {
      map['dosage'] = Variable<String>(dosage.value);
    }
    if (mealRelation.present) {
      map['meal_relation'] = Variable<String>(mealRelation.value);
    }
    if (timesOfDay.present) {
      map['times_of_day'] = Variable<String>(timesOfDay.value);
    }
    if (daysOfWeek.present) {
      map['days_of_week'] = Variable<String>(daysOfWeek.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<DateTime>(endDate.value);
    }
    if (pausePeriods.present) {
      map['pause_periods'] = Variable<String>(pausePeriods.value);
    }
    if (stock.present) {
      map['stock'] = Variable<double>(stock.value);
    }
    if (stockUnit.present) {
      map['stock_unit'] = Variable<String>(stockUnit.value);
    }
    if (reminderEnabled.present) {
      map['reminder_enabled'] = Variable<bool>(reminderEnabled.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MedicationsCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('name: $name, ')
          ..write('dosage: $dosage, ')
          ..write('mealRelation: $mealRelation, ')
          ..write('timesOfDay: $timesOfDay, ')
          ..write('daysOfWeek: $daysOfWeek, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('pausePeriods: $pausePeriods, ')
          ..write('stock: $stock, ')
          ..write('stockUnit: $stockUnit, ')
          ..write('reminderEnabled: $reminderEnabled, ')
          ..write('note: $note, ')
          ..write('active: $active, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $MedicationLogsTable extends MedicationLogs
    with TableInfo<$MedicationLogsTable, MedicationLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MedicationLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _medicationIdMeta = const VerificationMeta(
    'medicationId',
  );
  @override
  late final GeneratedColumn<int> medicationId = GeneratedColumn<int>(
    'medication_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scheduledAtMeta = const VerificationMeta(
    'scheduledAt',
  );
  @override
  late final GeneratedColumn<DateTime> scheduledAt = GeneratedColumn<DateTime>(
    'scheduled_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _takenAtMeta = const VerificationMeta(
    'takenAt',
  );
  @override
  late final GeneratedColumn<DateTime> takenAt = GeneratedColumn<DateTime>(
    'taken_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    medicationId,
    scheduledAt,
    takenAt,
    status,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'medication_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<MedicationLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('medication_id')) {
      context.handle(
        _medicationIdMeta,
        medicationId.isAcceptableOrUnknown(
          data['medication_id']!,
          _medicationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_medicationIdMeta);
    }
    if (data.containsKey('scheduled_at')) {
      context.handle(
        _scheduledAtMeta,
        scheduledAt.isAcceptableOrUnknown(
          data['scheduled_at']!,
          _scheduledAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scheduledAtMeta);
    }
    if (data.containsKey('taken_at')) {
      context.handle(
        _takenAtMeta,
        takenAt.isAcceptableOrUnknown(data['taken_at']!, _takenAtMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MedicationLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MedicationLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      medicationId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}medication_id'],
      )!,
      scheduledAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}scheduled_at'],
      )!,
      takenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}taken_at'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $MedicationLogsTable createAlias(String alias) {
    return $MedicationLogsTable(attachedDatabase, alias);
  }
}

class MedicationLog extends DataClass implements Insertable<MedicationLog> {
  final int id;
  final int medicationId;
  final DateTime scheduledAt;
  final DateTime? takenAt;
  final String status;
  final DateTime createdAt;
  const MedicationLog({
    required this.id,
    required this.medicationId,
    required this.scheduledAt,
    this.takenAt,
    required this.status,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['medication_id'] = Variable<int>(medicationId);
    map['scheduled_at'] = Variable<DateTime>(scheduledAt);
    if (!nullToAbsent || takenAt != null) {
      map['taken_at'] = Variable<DateTime>(takenAt);
    }
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  MedicationLogsCompanion toCompanion(bool nullToAbsent) {
    return MedicationLogsCompanion(
      id: Value(id),
      medicationId: Value(medicationId),
      scheduledAt: Value(scheduledAt),
      takenAt: takenAt == null && nullToAbsent
          ? const Value.absent()
          : Value(takenAt),
      status: Value(status),
      createdAt: Value(createdAt),
    );
  }

  factory MedicationLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MedicationLog(
      id: serializer.fromJson<int>(json['id']),
      medicationId: serializer.fromJson<int>(json['medicationId']),
      scheduledAt: serializer.fromJson<DateTime>(json['scheduledAt']),
      takenAt: serializer.fromJson<DateTime?>(json['takenAt']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'medicationId': serializer.toJson<int>(medicationId),
      'scheduledAt': serializer.toJson<DateTime>(scheduledAt),
      'takenAt': serializer.toJson<DateTime?>(takenAt),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  MedicationLog copyWith({
    int? id,
    int? medicationId,
    DateTime? scheduledAt,
    Value<DateTime?> takenAt = const Value.absent(),
    String? status,
    DateTime? createdAt,
  }) => MedicationLog(
    id: id ?? this.id,
    medicationId: medicationId ?? this.medicationId,
    scheduledAt: scheduledAt ?? this.scheduledAt,
    takenAt: takenAt.present ? takenAt.value : this.takenAt,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
  );
  MedicationLog copyWithCompanion(MedicationLogsCompanion data) {
    return MedicationLog(
      id: data.id.present ? data.id.value : this.id,
      medicationId: data.medicationId.present
          ? data.medicationId.value
          : this.medicationId,
      scheduledAt: data.scheduledAt.present
          ? data.scheduledAt.value
          : this.scheduledAt,
      takenAt: data.takenAt.present ? data.takenAt.value : this.takenAt,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MedicationLog(')
          ..write('id: $id, ')
          ..write('medicationId: $medicationId, ')
          ..write('scheduledAt: $scheduledAt, ')
          ..write('takenAt: $takenAt, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, medicationId, scheduledAt, takenAt, status, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MedicationLog &&
          other.id == this.id &&
          other.medicationId == this.medicationId &&
          other.scheduledAt == this.scheduledAt &&
          other.takenAt == this.takenAt &&
          other.status == this.status &&
          other.createdAt == this.createdAt);
}

class MedicationLogsCompanion extends UpdateCompanion<MedicationLog> {
  final Value<int> id;
  final Value<int> medicationId;
  final Value<DateTime> scheduledAt;
  final Value<DateTime?> takenAt;
  final Value<String> status;
  final Value<DateTime> createdAt;
  const MedicationLogsCompanion({
    this.id = const Value.absent(),
    this.medicationId = const Value.absent(),
    this.scheduledAt = const Value.absent(),
    this.takenAt = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  MedicationLogsCompanion.insert({
    this.id = const Value.absent(),
    required int medicationId,
    required DateTime scheduledAt,
    this.takenAt = const Value.absent(),
    required String status,
    this.createdAt = const Value.absent(),
  }) : medicationId = Value(medicationId),
       scheduledAt = Value(scheduledAt),
       status = Value(status);
  static Insertable<MedicationLog> custom({
    Expression<int>? id,
    Expression<int>? medicationId,
    Expression<DateTime>? scheduledAt,
    Expression<DateTime>? takenAt,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (medicationId != null) 'medication_id': medicationId,
      if (scheduledAt != null) 'scheduled_at': scheduledAt,
      if (takenAt != null) 'taken_at': takenAt,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  MedicationLogsCompanion copyWith({
    Value<int>? id,
    Value<int>? medicationId,
    Value<DateTime>? scheduledAt,
    Value<DateTime?>? takenAt,
    Value<String>? status,
    Value<DateTime>? createdAt,
  }) {
    return MedicationLogsCompanion(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      takenAt: takenAt ?? this.takenAt,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (medicationId.present) {
      map['medication_id'] = Variable<int>(medicationId.value);
    }
    if (scheduledAt.present) {
      map['scheduled_at'] = Variable<DateTime>(scheduledAt.value);
    }
    if (takenAt.present) {
      map['taken_at'] = Variable<DateTime>(takenAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MedicationLogsCompanion(')
          ..write('id: $id, ')
          ..write('medicationId: $medicationId, ')
          ..write('scheduledAt: $scheduledAt, ')
          ..write('takenAt: $takenAt, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $FamiliesTable extends Families
    with TableInfo<$FamiliesTable, FamilyRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FamiliesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'families';
  @override
  VerificationContext validateIntegrity(
    Insertable<FamilyRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FamilyRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FamilyRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $FamiliesTable createAlias(String alias) {
    return $FamiliesTable(attachedDatabase, alias);
  }
}

class FamilyRow extends DataClass implements Insertable<FamilyRow> {
  final int id;
  final String name;
  final DateTime createdAt;
  const FamilyRow({
    required this.id,
    required this.name,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  FamiliesCompanion toCompanion(bool nullToAbsent) {
    return FamiliesCompanion(
      id: Value(id),
      name: Value(name),
      createdAt: Value(createdAt),
    );
  }

  factory FamilyRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FamilyRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  FamilyRow copyWith({int? id, String? name, DateTime? createdAt}) => FamilyRow(
    id: id ?? this.id,
    name: name ?? this.name,
    createdAt: createdAt ?? this.createdAt,
  );
  FamilyRow copyWithCompanion(FamiliesCompanion data) {
    return FamilyRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FamilyRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FamilyRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.createdAt == this.createdAt);
}

class FamiliesCompanion extends UpdateCompanion<FamilyRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<DateTime> createdAt;
  const FamiliesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  FamiliesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.createdAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<FamilyRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  FamiliesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<DateTime>? createdAt,
  }) {
    return FamiliesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FamiliesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $FamilyMembersTable extends FamilyMembers
    with TableInfo<$FamilyMembersTable, FamilyMember> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FamilyMembersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _familyIdMeta = const VerificationMeta(
    'familyId',
  );
  @override
  late final GeneratedColumn<int> familyId = GeneratedColumn<int>(
    'family_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<int> profileId = GeneratedColumn<int>(
    'profile_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, familyId, profileId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'family_members';
  @override
  VerificationContext validateIntegrity(
    Insertable<FamilyMember> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('family_id')) {
      context.handle(
        _familyIdMeta,
        familyId.isAcceptableOrUnknown(data['family_id']!, _familyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_familyIdMeta);
    }
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FamilyMember map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FamilyMember(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      familyId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}family_id'],
      )!,
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}profile_id'],
      )!,
    );
  }

  @override
  $FamilyMembersTable createAlias(String alias) {
    return $FamilyMembersTable(attachedDatabase, alias);
  }
}

class FamilyMember extends DataClass implements Insertable<FamilyMember> {
  final int id;
  final int familyId;
  final int profileId;
  const FamilyMember({
    required this.id,
    required this.familyId,
    required this.profileId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['family_id'] = Variable<int>(familyId);
    map['profile_id'] = Variable<int>(profileId);
    return map;
  }

  FamilyMembersCompanion toCompanion(bool nullToAbsent) {
    return FamilyMembersCompanion(
      id: Value(id),
      familyId: Value(familyId),
      profileId: Value(profileId),
    );
  }

  factory FamilyMember.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FamilyMember(
      id: serializer.fromJson<int>(json['id']),
      familyId: serializer.fromJson<int>(json['familyId']),
      profileId: serializer.fromJson<int>(json['profileId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'familyId': serializer.toJson<int>(familyId),
      'profileId': serializer.toJson<int>(profileId),
    };
  }

  FamilyMember copyWith({int? id, int? familyId, int? profileId}) =>
      FamilyMember(
        id: id ?? this.id,
        familyId: familyId ?? this.familyId,
        profileId: profileId ?? this.profileId,
      );
  FamilyMember copyWithCompanion(FamilyMembersCompanion data) {
    return FamilyMember(
      id: data.id.present ? data.id.value : this.id,
      familyId: data.familyId.present ? data.familyId.value : this.familyId,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FamilyMember(')
          ..write('id: $id, ')
          ..write('familyId: $familyId, ')
          ..write('profileId: $profileId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, familyId, profileId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FamilyMember &&
          other.id == this.id &&
          other.familyId == this.familyId &&
          other.profileId == this.profileId);
}

class FamilyMembersCompanion extends UpdateCompanion<FamilyMember> {
  final Value<int> id;
  final Value<int> familyId;
  final Value<int> profileId;
  const FamilyMembersCompanion({
    this.id = const Value.absent(),
    this.familyId = const Value.absent(),
    this.profileId = const Value.absent(),
  });
  FamilyMembersCompanion.insert({
    this.id = const Value.absent(),
    required int familyId,
    required int profileId,
  }) : familyId = Value(familyId),
       profileId = Value(profileId);
  static Insertable<FamilyMember> custom({
    Expression<int>? id,
    Expression<int>? familyId,
    Expression<int>? profileId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (familyId != null) 'family_id': familyId,
      if (profileId != null) 'profile_id': profileId,
    });
  }

  FamilyMembersCompanion copyWith({
    Value<int>? id,
    Value<int>? familyId,
    Value<int>? profileId,
  }) {
    return FamilyMembersCompanion(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      profileId: profileId ?? this.profileId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (familyId.present) {
      map['family_id'] = Variable<int>(familyId.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<int>(profileId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FamilyMembersCompanion(')
          ..write('id: $id, ')
          ..write('familyId: $familyId, ')
          ..write('profileId: $profileId')
          ..write(')'))
        .toString();
  }
}

class $BoxMedicinesTable extends BoxMedicines
    with TableInfo<$BoxMedicinesTable, BoxMedicine> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BoxMedicinesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _familyIdMeta = const VerificationMeta(
    'familyId',
  );
  @override
  late final GeneratedColumn<int> familyId = GeneratedColumn<int>(
    'family_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expireDateMeta = const VerificationMeta(
    'expireDate',
  );
  @override
  late final GeneratedColumn<DateTime> expireDate = GeneratedColumn<DateTime>(
    'expire_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _imagePathMeta = const VerificationMeta(
    'imagePath',
  );
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
    'image_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imagePathsMeta = const VerificationMeta(
    'imagePaths',
  );
  @override
  late final GeneratedColumn<String> imagePaths = GeneratedColumn<String>(
    'image_paths',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _usageMeta = const VerificationMeta('usage');
  @override
  late final GeneratedColumn<String> usage = GeneratedColumn<String>(
    'usage',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    familyId,
    name,
    expireDate,
    imagePath,
    imagePaths,
    usage,
    note,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'box_medicines';
  @override
  VerificationContext validateIntegrity(
    Insertable<BoxMedicine> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('family_id')) {
      context.handle(
        _familyIdMeta,
        familyId.isAcceptableOrUnknown(data['family_id']!, _familyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_familyIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('expire_date')) {
      context.handle(
        _expireDateMeta,
        expireDate.isAcceptableOrUnknown(data['expire_date']!, _expireDateMeta),
      );
    } else if (isInserting) {
      context.missing(_expireDateMeta);
    }
    if (data.containsKey('image_path')) {
      context.handle(
        _imagePathMeta,
        imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta),
      );
    }
    if (data.containsKey('image_paths')) {
      context.handle(
        _imagePathsMeta,
        imagePaths.isAcceptableOrUnknown(data['image_paths']!, _imagePathsMeta),
      );
    }
    if (data.containsKey('usage')) {
      context.handle(
        _usageMeta,
        usage.isAcceptableOrUnknown(data['usage']!, _usageMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BoxMedicine map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BoxMedicine(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      familyId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}family_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      expireDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expire_date'],
      )!,
      imagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_path'],
      ),
      imagePaths: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_paths'],
      ),
      usage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}usage'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $BoxMedicinesTable createAlias(String alias) {
    return $BoxMedicinesTable(attachedDatabase, alias);
  }
}

class BoxMedicine extends DataClass implements Insertable<BoxMedicine> {
  final int id;
  final int familyId;
  final String name;
  final DateTime expireDate;
  final String? imagePath;
  final String? imagePaths;
  final String? usage;
  final String? note;
  final DateTime createdAt;
  const BoxMedicine({
    required this.id,
    required this.familyId,
    required this.name,
    required this.expireDate,
    this.imagePath,
    this.imagePaths,
    this.usage,
    this.note,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['family_id'] = Variable<int>(familyId);
    map['name'] = Variable<String>(name);
    map['expire_date'] = Variable<DateTime>(expireDate);
    if (!nullToAbsent || imagePath != null) {
      map['image_path'] = Variable<String>(imagePath);
    }
    if (!nullToAbsent || imagePaths != null) {
      map['image_paths'] = Variable<String>(imagePaths);
    }
    if (!nullToAbsent || usage != null) {
      map['usage'] = Variable<String>(usage);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  BoxMedicinesCompanion toCompanion(bool nullToAbsent) {
    return BoxMedicinesCompanion(
      id: Value(id),
      familyId: Value(familyId),
      name: Value(name),
      expireDate: Value(expireDate),
      imagePath: imagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(imagePath),
      imagePaths: imagePaths == null && nullToAbsent
          ? const Value.absent()
          : Value(imagePaths),
      usage: usage == null && nullToAbsent
          ? const Value.absent()
          : Value(usage),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory BoxMedicine.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BoxMedicine(
      id: serializer.fromJson<int>(json['id']),
      familyId: serializer.fromJson<int>(json['familyId']),
      name: serializer.fromJson<String>(json['name']),
      expireDate: serializer.fromJson<DateTime>(json['expireDate']),
      imagePath: serializer.fromJson<String?>(json['imagePath']),
      imagePaths: serializer.fromJson<String?>(json['imagePaths']),
      usage: serializer.fromJson<String?>(json['usage']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'familyId': serializer.toJson<int>(familyId),
      'name': serializer.toJson<String>(name),
      'expireDate': serializer.toJson<DateTime>(expireDate),
      'imagePath': serializer.toJson<String?>(imagePath),
      'imagePaths': serializer.toJson<String?>(imagePaths),
      'usage': serializer.toJson<String?>(usage),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  BoxMedicine copyWith({
    int? id,
    int? familyId,
    String? name,
    DateTime? expireDate,
    Value<String?> imagePath = const Value.absent(),
    Value<String?> imagePaths = const Value.absent(),
    Value<String?> usage = const Value.absent(),
    Value<String?> note = const Value.absent(),
    DateTime? createdAt,
  }) => BoxMedicine(
    id: id ?? this.id,
    familyId: familyId ?? this.familyId,
    name: name ?? this.name,
    expireDate: expireDate ?? this.expireDate,
    imagePath: imagePath.present ? imagePath.value : this.imagePath,
    imagePaths: imagePaths.present ? imagePaths.value : this.imagePaths,
    usage: usage.present ? usage.value : this.usage,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
  );
  BoxMedicine copyWithCompanion(BoxMedicinesCompanion data) {
    return BoxMedicine(
      id: data.id.present ? data.id.value : this.id,
      familyId: data.familyId.present ? data.familyId.value : this.familyId,
      name: data.name.present ? data.name.value : this.name,
      expireDate: data.expireDate.present
          ? data.expireDate.value
          : this.expireDate,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      imagePaths: data.imagePaths.present
          ? data.imagePaths.value
          : this.imagePaths,
      usage: data.usage.present ? data.usage.value : this.usage,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BoxMedicine(')
          ..write('id: $id, ')
          ..write('familyId: $familyId, ')
          ..write('name: $name, ')
          ..write('expireDate: $expireDate, ')
          ..write('imagePath: $imagePath, ')
          ..write('imagePaths: $imagePaths, ')
          ..write('usage: $usage, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    familyId,
    name,
    expireDate,
    imagePath,
    imagePaths,
    usage,
    note,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BoxMedicine &&
          other.id == this.id &&
          other.familyId == this.familyId &&
          other.name == this.name &&
          other.expireDate == this.expireDate &&
          other.imagePath == this.imagePath &&
          other.imagePaths == this.imagePaths &&
          other.usage == this.usage &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class BoxMedicinesCompanion extends UpdateCompanion<BoxMedicine> {
  final Value<int> id;
  final Value<int> familyId;
  final Value<String> name;
  final Value<DateTime> expireDate;
  final Value<String?> imagePath;
  final Value<String?> imagePaths;
  final Value<String?> usage;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  const BoxMedicinesCompanion({
    this.id = const Value.absent(),
    this.familyId = const Value.absent(),
    this.name = const Value.absent(),
    this.expireDate = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.imagePaths = const Value.absent(),
    this.usage = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  BoxMedicinesCompanion.insert({
    this.id = const Value.absent(),
    required int familyId,
    required String name,
    required DateTime expireDate,
    this.imagePath = const Value.absent(),
    this.imagePaths = const Value.absent(),
    this.usage = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : familyId = Value(familyId),
       name = Value(name),
       expireDate = Value(expireDate);
  static Insertable<BoxMedicine> custom({
    Expression<int>? id,
    Expression<int>? familyId,
    Expression<String>? name,
    Expression<DateTime>? expireDate,
    Expression<String>? imagePath,
    Expression<String>? imagePaths,
    Expression<String>? usage,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (familyId != null) 'family_id': familyId,
      if (name != null) 'name': name,
      if (expireDate != null) 'expire_date': expireDate,
      if (imagePath != null) 'image_path': imagePath,
      if (imagePaths != null) 'image_paths': imagePaths,
      if (usage != null) 'usage': usage,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  BoxMedicinesCompanion copyWith({
    Value<int>? id,
    Value<int>? familyId,
    Value<String>? name,
    Value<DateTime>? expireDate,
    Value<String?>? imagePath,
    Value<String?>? imagePaths,
    Value<String?>? usage,
    Value<String?>? note,
    Value<DateTime>? createdAt,
  }) {
    return BoxMedicinesCompanion(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      name: name ?? this.name,
      expireDate: expireDate ?? this.expireDate,
      imagePath: imagePath ?? this.imagePath,
      imagePaths: imagePaths ?? this.imagePaths,
      usage: usage ?? this.usage,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (familyId.present) {
      map['family_id'] = Variable<int>(familyId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (expireDate.present) {
      map['expire_date'] = Variable<DateTime>(expireDate.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (imagePaths.present) {
      map['image_paths'] = Variable<String>(imagePaths.value);
    }
    if (usage.present) {
      map['usage'] = Variable<String>(usage.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BoxMedicinesCompanion(')
          ..write('id: $id, ')
          ..write('familyId: $familyId, ')
          ..write('name: $name, ')
          ..write('expireDate: $expireDate, ')
          ..write('imagePath: $imagePath, ')
          ..write('imagePaths: $imagePaths, ')
          ..write('usage: $usage, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProfilesTable profiles = $ProfilesTable(this);
  late final $MedicalRecordsTable medicalRecords = $MedicalRecordsTable(this);
  late final $MetricsTable metrics = $MetricsTable(this);
  late final $MetricValuesTable metricValues = $MetricValuesTable(this);
  late final $MedicationsTable medications = $MedicationsTable(this);
  late final $MedicationLogsTable medicationLogs = $MedicationLogsTable(this);
  late final $FamiliesTable families = $FamiliesTable(this);
  late final $FamilyMembersTable familyMembers = $FamilyMembersTable(this);
  late final $BoxMedicinesTable boxMedicines = $BoxMedicinesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    profiles,
    medicalRecords,
    metrics,
    metricValues,
    medications,
    medicationLogs,
    families,
    familyMembers,
    boxMedicines,
  ];
}

typedef $$ProfilesTableCreateCompanionBuilder =
    ProfilesCompanion Function({
      Value<int> id,
      required String name,
      required String gender,
      Value<DateTime?> birthday,
      Value<String?> idNumberEnc,
      Value<String?> bloodType,
      Value<String?> rhType,
      Value<String?> allergies,
      Value<String?> chronicDisease,
      Value<String?> familyHistory,
      Value<String?> emergencyName,
      Value<String?> emergencyPhone,
      Value<String?> emergencyRelation,
      Value<double?> heightCm,
      Value<double?> weightKg,
      Value<String?> constitution,
      Value<bool> isOwner,
      Value<DateTime> createdAt,
    });
typedef $$ProfilesTableUpdateCompanionBuilder =
    ProfilesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> gender,
      Value<DateTime?> birthday,
      Value<String?> idNumberEnc,
      Value<String?> bloodType,
      Value<String?> rhType,
      Value<String?> allergies,
      Value<String?> chronicDisease,
      Value<String?> familyHistory,
      Value<String?> emergencyName,
      Value<String?> emergencyPhone,
      Value<String?> emergencyRelation,
      Value<double?> heightCm,
      Value<double?> weightKg,
      Value<String?> constitution,
      Value<bool> isOwner,
      Value<DateTime> createdAt,
    });

class $$ProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gender => $composableBuilder(
    column: $table.gender,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get birthday => $composableBuilder(
    column: $table.birthday,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get idNumberEnc => $composableBuilder(
    column: $table.idNumberEnc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bloodType => $composableBuilder(
    column: $table.bloodType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rhType => $composableBuilder(
    column: $table.rhType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get allergies => $composableBuilder(
    column: $table.allergies,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get chronicDisease => $composableBuilder(
    column: $table.chronicDisease,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get familyHistory => $composableBuilder(
    column: $table.familyHistory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get emergencyName => $composableBuilder(
    column: $table.emergencyName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get emergencyPhone => $composableBuilder(
    column: $table.emergencyPhone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get emergencyRelation => $composableBuilder(
    column: $table.emergencyRelation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get heightCm => $composableBuilder(
    column: $table.heightCm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get constitution => $composableBuilder(
    column: $table.constitution,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isOwner => $composableBuilder(
    column: $table.isOwner,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gender => $composableBuilder(
    column: $table.gender,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get birthday => $composableBuilder(
    column: $table.birthday,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get idNumberEnc => $composableBuilder(
    column: $table.idNumberEnc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bloodType => $composableBuilder(
    column: $table.bloodType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rhType => $composableBuilder(
    column: $table.rhType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get allergies => $composableBuilder(
    column: $table.allergies,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get chronicDisease => $composableBuilder(
    column: $table.chronicDisease,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get familyHistory => $composableBuilder(
    column: $table.familyHistory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get emergencyName => $composableBuilder(
    column: $table.emergencyName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get emergencyPhone => $composableBuilder(
    column: $table.emergencyPhone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get emergencyRelation => $composableBuilder(
    column: $table.emergencyRelation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get heightCm => $composableBuilder(
    column: $table.heightCm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get constitution => $composableBuilder(
    column: $table.constitution,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isOwner => $composableBuilder(
    column: $table.isOwner,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get gender =>
      $composableBuilder(column: $table.gender, builder: (column) => column);

  GeneratedColumn<DateTime> get birthday =>
      $composableBuilder(column: $table.birthday, builder: (column) => column);

  GeneratedColumn<String> get idNumberEnc => $composableBuilder(
    column: $table.idNumberEnc,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bloodType =>
      $composableBuilder(column: $table.bloodType, builder: (column) => column);

  GeneratedColumn<String> get rhType =>
      $composableBuilder(column: $table.rhType, builder: (column) => column);

  GeneratedColumn<String> get allergies =>
      $composableBuilder(column: $table.allergies, builder: (column) => column);

  GeneratedColumn<String> get chronicDisease => $composableBuilder(
    column: $table.chronicDisease,
    builder: (column) => column,
  );

  GeneratedColumn<String> get familyHistory => $composableBuilder(
    column: $table.familyHistory,
    builder: (column) => column,
  );

  GeneratedColumn<String> get emergencyName => $composableBuilder(
    column: $table.emergencyName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get emergencyPhone => $composableBuilder(
    column: $table.emergencyPhone,
    builder: (column) => column,
  );

  GeneratedColumn<String> get emergencyRelation => $composableBuilder(
    column: $table.emergencyRelation,
    builder: (column) => column,
  );

  GeneratedColumn<double> get heightCm =>
      $composableBuilder(column: $table.heightCm, builder: (column) => column);

  GeneratedColumn<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => column);

  GeneratedColumn<String> get constitution => $composableBuilder(
    column: $table.constitution,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isOwner =>
      $composableBuilder(column: $table.isOwner, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProfilesTable,
          Profile,
          $$ProfilesTableFilterComposer,
          $$ProfilesTableOrderingComposer,
          $$ProfilesTableAnnotationComposer,
          $$ProfilesTableCreateCompanionBuilder,
          $$ProfilesTableUpdateCompanionBuilder,
          (Profile, BaseReferences<_$AppDatabase, $ProfilesTable, Profile>),
          Profile,
          PrefetchHooks Function()
        > {
  $$ProfilesTableTableManager(_$AppDatabase db, $ProfilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> gender = const Value.absent(),
                Value<DateTime?> birthday = const Value.absent(),
                Value<String?> idNumberEnc = const Value.absent(),
                Value<String?> bloodType = const Value.absent(),
                Value<String?> rhType = const Value.absent(),
                Value<String?> allergies = const Value.absent(),
                Value<String?> chronicDisease = const Value.absent(),
                Value<String?> familyHistory = const Value.absent(),
                Value<String?> emergencyName = const Value.absent(),
                Value<String?> emergencyPhone = const Value.absent(),
                Value<String?> emergencyRelation = const Value.absent(),
                Value<double?> heightCm = const Value.absent(),
                Value<double?> weightKg = const Value.absent(),
                Value<String?> constitution = const Value.absent(),
                Value<bool> isOwner = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ProfilesCompanion(
                id: id,
                name: name,
                gender: gender,
                birthday: birthday,
                idNumberEnc: idNumberEnc,
                bloodType: bloodType,
                rhType: rhType,
                allergies: allergies,
                chronicDisease: chronicDisease,
                familyHistory: familyHistory,
                emergencyName: emergencyName,
                emergencyPhone: emergencyPhone,
                emergencyRelation: emergencyRelation,
                heightCm: heightCm,
                weightKg: weightKg,
                constitution: constitution,
                isOwner: isOwner,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String gender,
                Value<DateTime?> birthday = const Value.absent(),
                Value<String?> idNumberEnc = const Value.absent(),
                Value<String?> bloodType = const Value.absent(),
                Value<String?> rhType = const Value.absent(),
                Value<String?> allergies = const Value.absent(),
                Value<String?> chronicDisease = const Value.absent(),
                Value<String?> familyHistory = const Value.absent(),
                Value<String?> emergencyName = const Value.absent(),
                Value<String?> emergencyPhone = const Value.absent(),
                Value<String?> emergencyRelation = const Value.absent(),
                Value<double?> heightCm = const Value.absent(),
                Value<double?> weightKg = const Value.absent(),
                Value<String?> constitution = const Value.absent(),
                Value<bool> isOwner = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ProfilesCompanion.insert(
                id: id,
                name: name,
                gender: gender,
                birthday: birthday,
                idNumberEnc: idNumberEnc,
                bloodType: bloodType,
                rhType: rhType,
                allergies: allergies,
                chronicDisease: chronicDisease,
                familyHistory: familyHistory,
                emergencyName: emergencyName,
                emergencyPhone: emergencyPhone,
                emergencyRelation: emergencyRelation,
                heightCm: heightCm,
                weightKg: weightKg,
                constitution: constitution,
                isOwner: isOwner,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProfilesTable,
      Profile,
      $$ProfilesTableFilterComposer,
      $$ProfilesTableOrderingComposer,
      $$ProfilesTableAnnotationComposer,
      $$ProfilesTableCreateCompanionBuilder,
      $$ProfilesTableUpdateCompanionBuilder,
      (Profile, BaseReferences<_$AppDatabase, $ProfilesTable, Profile>),
      Profile,
      PrefetchHooks Function()
    >;
typedef $$MedicalRecordsTableCreateCompanionBuilder =
    MedicalRecordsCompanion Function({
      Value<int> id,
      required int profileId,
      required String title,
      required String type,
      required DateTime recordDate,
      Value<String?> hospital,
      Value<String?> department,
      Value<String?> tags,
      Value<String?> note,
      required String filePath,
      required String fileType,
      Value<double?> lat,
      Value<double?> lng,
      Value<String?> locationText,
      Value<String?> aiSummary,
      Value<String?> fileHash,
      Value<DateTime> createdAt,
    });
typedef $$MedicalRecordsTableUpdateCompanionBuilder =
    MedicalRecordsCompanion Function({
      Value<int> id,
      Value<int> profileId,
      Value<String> title,
      Value<String> type,
      Value<DateTime> recordDate,
      Value<String?> hospital,
      Value<String?> department,
      Value<String?> tags,
      Value<String?> note,
      Value<String> filePath,
      Value<String> fileType,
      Value<double?> lat,
      Value<double?> lng,
      Value<String?> locationText,
      Value<String?> aiSummary,
      Value<String?> fileHash,
      Value<DateTime> createdAt,
    });

class $$MedicalRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $MedicalRecordsTable> {
  $$MedicalRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordDate => $composableBuilder(
    column: $table.recordDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hospital => $composableBuilder(
    column: $table.hospital,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get department => $composableBuilder(
    column: $table.department,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileType => $composableBuilder(
    column: $table.fileType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get locationText => $composableBuilder(
    column: $table.locationText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get aiSummary => $composableBuilder(
    column: $table.aiSummary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileHash => $composableBuilder(
    column: $table.fileHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MedicalRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $MedicalRecordsTable> {
  $$MedicalRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordDate => $composableBuilder(
    column: $table.recordDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hospital => $composableBuilder(
    column: $table.hospital,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get department => $composableBuilder(
    column: $table.department,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileType => $composableBuilder(
    column: $table.fileType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get locationText => $composableBuilder(
    column: $table.locationText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get aiSummary => $composableBuilder(
    column: $table.aiSummary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileHash => $composableBuilder(
    column: $table.fileHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MedicalRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MedicalRecordsTable> {
  $$MedicalRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<DateTime> get recordDate => $composableBuilder(
    column: $table.recordDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get hospital =>
      $composableBuilder(column: $table.hospital, builder: (column) => column);

  GeneratedColumn<String> get department => $composableBuilder(
    column: $table.department,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<String> get fileType =>
      $composableBuilder(column: $table.fileType, builder: (column) => column);

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lng =>
      $composableBuilder(column: $table.lng, builder: (column) => column);

  GeneratedColumn<String> get locationText => $composableBuilder(
    column: $table.locationText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get aiSummary =>
      $composableBuilder(column: $table.aiSummary, builder: (column) => column);

  GeneratedColumn<String> get fileHash =>
      $composableBuilder(column: $table.fileHash, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$MedicalRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MedicalRecordsTable,
          MedicalRecord,
          $$MedicalRecordsTableFilterComposer,
          $$MedicalRecordsTableOrderingComposer,
          $$MedicalRecordsTableAnnotationComposer,
          $$MedicalRecordsTableCreateCompanionBuilder,
          $$MedicalRecordsTableUpdateCompanionBuilder,
          (
            MedicalRecord,
            BaseReferences<_$AppDatabase, $MedicalRecordsTable, MedicalRecord>,
          ),
          MedicalRecord,
          PrefetchHooks Function()
        > {
  $$MedicalRecordsTableTableManager(
    _$AppDatabase db,
    $MedicalRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MedicalRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MedicalRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MedicalRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> profileId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<DateTime> recordDate = const Value.absent(),
                Value<String?> hospital = const Value.absent(),
                Value<String?> department = const Value.absent(),
                Value<String?> tags = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<String> fileType = const Value.absent(),
                Value<double?> lat = const Value.absent(),
                Value<double?> lng = const Value.absent(),
                Value<String?> locationText = const Value.absent(),
                Value<String?> aiSummary = const Value.absent(),
                Value<String?> fileHash = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => MedicalRecordsCompanion(
                id: id,
                profileId: profileId,
                title: title,
                type: type,
                recordDate: recordDate,
                hospital: hospital,
                department: department,
                tags: tags,
                note: note,
                filePath: filePath,
                fileType: fileType,
                lat: lat,
                lng: lng,
                locationText: locationText,
                aiSummary: aiSummary,
                fileHash: fileHash,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int profileId,
                required String title,
                required String type,
                required DateTime recordDate,
                Value<String?> hospital = const Value.absent(),
                Value<String?> department = const Value.absent(),
                Value<String?> tags = const Value.absent(),
                Value<String?> note = const Value.absent(),
                required String filePath,
                required String fileType,
                Value<double?> lat = const Value.absent(),
                Value<double?> lng = const Value.absent(),
                Value<String?> locationText = const Value.absent(),
                Value<String?> aiSummary = const Value.absent(),
                Value<String?> fileHash = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => MedicalRecordsCompanion.insert(
                id: id,
                profileId: profileId,
                title: title,
                type: type,
                recordDate: recordDate,
                hospital: hospital,
                department: department,
                tags: tags,
                note: note,
                filePath: filePath,
                fileType: fileType,
                lat: lat,
                lng: lng,
                locationText: locationText,
                aiSummary: aiSummary,
                fileHash: fileHash,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MedicalRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MedicalRecordsTable,
      MedicalRecord,
      $$MedicalRecordsTableFilterComposer,
      $$MedicalRecordsTableOrderingComposer,
      $$MedicalRecordsTableAnnotationComposer,
      $$MedicalRecordsTableCreateCompanionBuilder,
      $$MedicalRecordsTableUpdateCompanionBuilder,
      (
        MedicalRecord,
        BaseReferences<_$AppDatabase, $MedicalRecordsTable, MedicalRecord>,
      ),
      MedicalRecord,
      PrefetchHooks Function()
    >;
typedef $$MetricsTableCreateCompanionBuilder =
    MetricsCompanion Function({
      Value<int> id,
      required int profileId,
      required String code,
      required String name,
      required String unit,
      Value<bool> dualValue,
      Value<double?> refLow,
      Value<double?> refHigh,
      Value<double?> refLow2,
      Value<double?> refHigh2,
      Value<bool> isCustom,
      Value<String?> tag,
      Value<String?> aiInfo,
      Value<bool> followed,
      Value<DateTime> createdAt,
    });
typedef $$MetricsTableUpdateCompanionBuilder =
    MetricsCompanion Function({
      Value<int> id,
      Value<int> profileId,
      Value<String> code,
      Value<String> name,
      Value<String> unit,
      Value<bool> dualValue,
      Value<double?> refLow,
      Value<double?> refHigh,
      Value<double?> refLow2,
      Value<double?> refHigh2,
      Value<bool> isCustom,
      Value<String?> tag,
      Value<String?> aiInfo,
      Value<bool> followed,
      Value<DateTime> createdAt,
    });

class $$MetricsTableFilterComposer
    extends Composer<_$AppDatabase, $MetricsTable> {
  $$MetricsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get dualValue => $composableBuilder(
    column: $table.dualValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get refLow => $composableBuilder(
    column: $table.refLow,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get refHigh => $composableBuilder(
    column: $table.refHigh,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get refLow2 => $composableBuilder(
    column: $table.refLow2,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get refHigh2 => $composableBuilder(
    column: $table.refHigh2,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCustom => $composableBuilder(
    column: $table.isCustom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tag => $composableBuilder(
    column: $table.tag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get aiInfo => $composableBuilder(
    column: $table.aiInfo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get followed => $composableBuilder(
    column: $table.followed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MetricsTableOrderingComposer
    extends Composer<_$AppDatabase, $MetricsTable> {
  $$MetricsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get dualValue => $composableBuilder(
    column: $table.dualValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get refLow => $composableBuilder(
    column: $table.refLow,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get refHigh => $composableBuilder(
    column: $table.refHigh,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get refLow2 => $composableBuilder(
    column: $table.refLow2,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get refHigh2 => $composableBuilder(
    column: $table.refHigh2,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCustom => $composableBuilder(
    column: $table.isCustom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tag => $composableBuilder(
    column: $table.tag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get aiInfo => $composableBuilder(
    column: $table.aiInfo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get followed => $composableBuilder(
    column: $table.followed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MetricsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MetricsTable> {
  $$MetricsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<bool> get dualValue =>
      $composableBuilder(column: $table.dualValue, builder: (column) => column);

  GeneratedColumn<double> get refLow =>
      $composableBuilder(column: $table.refLow, builder: (column) => column);

  GeneratedColumn<double> get refHigh =>
      $composableBuilder(column: $table.refHigh, builder: (column) => column);

  GeneratedColumn<double> get refLow2 =>
      $composableBuilder(column: $table.refLow2, builder: (column) => column);

  GeneratedColumn<double> get refHigh2 =>
      $composableBuilder(column: $table.refHigh2, builder: (column) => column);

  GeneratedColumn<bool> get isCustom =>
      $composableBuilder(column: $table.isCustom, builder: (column) => column);

  GeneratedColumn<String> get tag =>
      $composableBuilder(column: $table.tag, builder: (column) => column);

  GeneratedColumn<String> get aiInfo =>
      $composableBuilder(column: $table.aiInfo, builder: (column) => column);

  GeneratedColumn<bool> get followed =>
      $composableBuilder(column: $table.followed, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$MetricsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MetricsTable,
          Metric,
          $$MetricsTableFilterComposer,
          $$MetricsTableOrderingComposer,
          $$MetricsTableAnnotationComposer,
          $$MetricsTableCreateCompanionBuilder,
          $$MetricsTableUpdateCompanionBuilder,
          (Metric, BaseReferences<_$AppDatabase, $MetricsTable, Metric>),
          Metric,
          PrefetchHooks Function()
        > {
  $$MetricsTableTableManager(_$AppDatabase db, $MetricsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MetricsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MetricsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MetricsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> profileId = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<bool> dualValue = const Value.absent(),
                Value<double?> refLow = const Value.absent(),
                Value<double?> refHigh = const Value.absent(),
                Value<double?> refLow2 = const Value.absent(),
                Value<double?> refHigh2 = const Value.absent(),
                Value<bool> isCustom = const Value.absent(),
                Value<String?> tag = const Value.absent(),
                Value<String?> aiInfo = const Value.absent(),
                Value<bool> followed = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => MetricsCompanion(
                id: id,
                profileId: profileId,
                code: code,
                name: name,
                unit: unit,
                dualValue: dualValue,
                refLow: refLow,
                refHigh: refHigh,
                refLow2: refLow2,
                refHigh2: refHigh2,
                isCustom: isCustom,
                tag: tag,
                aiInfo: aiInfo,
                followed: followed,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int profileId,
                required String code,
                required String name,
                required String unit,
                Value<bool> dualValue = const Value.absent(),
                Value<double?> refLow = const Value.absent(),
                Value<double?> refHigh = const Value.absent(),
                Value<double?> refLow2 = const Value.absent(),
                Value<double?> refHigh2 = const Value.absent(),
                Value<bool> isCustom = const Value.absent(),
                Value<String?> tag = const Value.absent(),
                Value<String?> aiInfo = const Value.absent(),
                Value<bool> followed = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => MetricsCompanion.insert(
                id: id,
                profileId: profileId,
                code: code,
                name: name,
                unit: unit,
                dualValue: dualValue,
                refLow: refLow,
                refHigh: refHigh,
                refLow2: refLow2,
                refHigh2: refHigh2,
                isCustom: isCustom,
                tag: tag,
                aiInfo: aiInfo,
                followed: followed,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MetricsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MetricsTable,
      Metric,
      $$MetricsTableFilterComposer,
      $$MetricsTableOrderingComposer,
      $$MetricsTableAnnotationComposer,
      $$MetricsTableCreateCompanionBuilder,
      $$MetricsTableUpdateCompanionBuilder,
      (Metric, BaseReferences<_$AppDatabase, $MetricsTable, Metric>),
      Metric,
      PrefetchHooks Function()
    >;
typedef $$MetricValuesTableCreateCompanionBuilder =
    MetricValuesCompanion Function({
      Value<int> id,
      required int metricId,
      required double value1,
      Value<double?> value2,
      required DateTime measuredAt,
      Value<String?> note,
      Value<String?> timeLabel,
      Value<String> source,
      Value<DateTime> createdAt,
    });
typedef $$MetricValuesTableUpdateCompanionBuilder =
    MetricValuesCompanion Function({
      Value<int> id,
      Value<int> metricId,
      Value<double> value1,
      Value<double?> value2,
      Value<DateTime> measuredAt,
      Value<String?> note,
      Value<String?> timeLabel,
      Value<String> source,
      Value<DateTime> createdAt,
    });

class $$MetricValuesTableFilterComposer
    extends Composer<_$AppDatabase, $MetricValuesTable> {
  $$MetricValuesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get metricId => $composableBuilder(
    column: $table.metricId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get value1 => $composableBuilder(
    column: $table.value1,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get value2 => $composableBuilder(
    column: $table.value2,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get measuredAt => $composableBuilder(
    column: $table.measuredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timeLabel => $composableBuilder(
    column: $table.timeLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MetricValuesTableOrderingComposer
    extends Composer<_$AppDatabase, $MetricValuesTable> {
  $$MetricValuesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get metricId => $composableBuilder(
    column: $table.metricId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get value1 => $composableBuilder(
    column: $table.value1,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get value2 => $composableBuilder(
    column: $table.value2,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get measuredAt => $composableBuilder(
    column: $table.measuredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timeLabel => $composableBuilder(
    column: $table.timeLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MetricValuesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MetricValuesTable> {
  $$MetricValuesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get metricId =>
      $composableBuilder(column: $table.metricId, builder: (column) => column);

  GeneratedColumn<double> get value1 =>
      $composableBuilder(column: $table.value1, builder: (column) => column);

  GeneratedColumn<double> get value2 =>
      $composableBuilder(column: $table.value2, builder: (column) => column);

  GeneratedColumn<DateTime> get measuredAt => $composableBuilder(
    column: $table.measuredAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get timeLabel =>
      $composableBuilder(column: $table.timeLabel, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$MetricValuesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MetricValuesTable,
          MetricValue,
          $$MetricValuesTableFilterComposer,
          $$MetricValuesTableOrderingComposer,
          $$MetricValuesTableAnnotationComposer,
          $$MetricValuesTableCreateCompanionBuilder,
          $$MetricValuesTableUpdateCompanionBuilder,
          (
            MetricValue,
            BaseReferences<_$AppDatabase, $MetricValuesTable, MetricValue>,
          ),
          MetricValue,
          PrefetchHooks Function()
        > {
  $$MetricValuesTableTableManager(_$AppDatabase db, $MetricValuesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MetricValuesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MetricValuesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MetricValuesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> metricId = const Value.absent(),
                Value<double> value1 = const Value.absent(),
                Value<double?> value2 = const Value.absent(),
                Value<DateTime> measuredAt = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> timeLabel = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => MetricValuesCompanion(
                id: id,
                metricId: metricId,
                value1: value1,
                value2: value2,
                measuredAt: measuredAt,
                note: note,
                timeLabel: timeLabel,
                source: source,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int metricId,
                required double value1,
                Value<double?> value2 = const Value.absent(),
                required DateTime measuredAt,
                Value<String?> note = const Value.absent(),
                Value<String?> timeLabel = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => MetricValuesCompanion.insert(
                id: id,
                metricId: metricId,
                value1: value1,
                value2: value2,
                measuredAt: measuredAt,
                note: note,
                timeLabel: timeLabel,
                source: source,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MetricValuesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MetricValuesTable,
      MetricValue,
      $$MetricValuesTableFilterComposer,
      $$MetricValuesTableOrderingComposer,
      $$MetricValuesTableAnnotationComposer,
      $$MetricValuesTableCreateCompanionBuilder,
      $$MetricValuesTableUpdateCompanionBuilder,
      (
        MetricValue,
        BaseReferences<_$AppDatabase, $MetricValuesTable, MetricValue>,
      ),
      MetricValue,
      PrefetchHooks Function()
    >;
typedef $$MedicationsTableCreateCompanionBuilder =
    MedicationsCompanion Function({
      Value<int> id,
      required int profileId,
      required String name,
      Value<String?> dosage,
      Value<String?> mealRelation,
      required String timesOfDay,
      Value<String?> daysOfWeek,
      Value<DateTime?> startDate,
      Value<DateTime?> endDate,
      Value<String?> pausePeriods,
      Value<double?> stock,
      Value<String?> stockUnit,
      Value<bool> reminderEnabled,
      Value<String?> note,
      Value<bool> active,
      Value<DateTime> createdAt,
    });
typedef $$MedicationsTableUpdateCompanionBuilder =
    MedicationsCompanion Function({
      Value<int> id,
      Value<int> profileId,
      Value<String> name,
      Value<String?> dosage,
      Value<String?> mealRelation,
      Value<String> timesOfDay,
      Value<String?> daysOfWeek,
      Value<DateTime?> startDate,
      Value<DateTime?> endDate,
      Value<String?> pausePeriods,
      Value<double?> stock,
      Value<String?> stockUnit,
      Value<bool> reminderEnabled,
      Value<String?> note,
      Value<bool> active,
      Value<DateTime> createdAt,
    });

class $$MedicationsTableFilterComposer
    extends Composer<_$AppDatabase, $MedicationsTable> {
  $$MedicationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dosage => $composableBuilder(
    column: $table.dosage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mealRelation => $composableBuilder(
    column: $table.mealRelation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timesOfDay => $composableBuilder(
    column: $table.timesOfDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get daysOfWeek => $composableBuilder(
    column: $table.daysOfWeek,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pausePeriods => $composableBuilder(
    column: $table.pausePeriods,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get stock => $composableBuilder(
    column: $table.stock,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stockUnit => $composableBuilder(
    column: $table.stockUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get reminderEnabled => $composableBuilder(
    column: $table.reminderEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MedicationsTableOrderingComposer
    extends Composer<_$AppDatabase, $MedicationsTable> {
  $$MedicationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dosage => $composableBuilder(
    column: $table.dosage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mealRelation => $composableBuilder(
    column: $table.mealRelation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timesOfDay => $composableBuilder(
    column: $table.timesOfDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get daysOfWeek => $composableBuilder(
    column: $table.daysOfWeek,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pausePeriods => $composableBuilder(
    column: $table.pausePeriods,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get stock => $composableBuilder(
    column: $table.stock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stockUnit => $composableBuilder(
    column: $table.stockUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get reminderEnabled => $composableBuilder(
    column: $table.reminderEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MedicationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MedicationsTable> {
  $$MedicationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get dosage =>
      $composableBuilder(column: $table.dosage, builder: (column) => column);

  GeneratedColumn<String> get mealRelation => $composableBuilder(
    column: $table.mealRelation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get timesOfDay => $composableBuilder(
    column: $table.timesOfDay,
    builder: (column) => column,
  );

  GeneratedColumn<String> get daysOfWeek => $composableBuilder(
    column: $table.daysOfWeek,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<DateTime> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<String> get pausePeriods => $composableBuilder(
    column: $table.pausePeriods,
    builder: (column) => column,
  );

  GeneratedColumn<double> get stock =>
      $composableBuilder(column: $table.stock, builder: (column) => column);

  GeneratedColumn<String> get stockUnit =>
      $composableBuilder(column: $table.stockUnit, builder: (column) => column);

  GeneratedColumn<bool> get reminderEnabled => $composableBuilder(
    column: $table.reminderEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$MedicationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MedicationsTable,
          Medication,
          $$MedicationsTableFilterComposer,
          $$MedicationsTableOrderingComposer,
          $$MedicationsTableAnnotationComposer,
          $$MedicationsTableCreateCompanionBuilder,
          $$MedicationsTableUpdateCompanionBuilder,
          (
            Medication,
            BaseReferences<_$AppDatabase, $MedicationsTable, Medication>,
          ),
          Medication,
          PrefetchHooks Function()
        > {
  $$MedicationsTableTableManager(_$AppDatabase db, $MedicationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MedicationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MedicationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MedicationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> profileId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> dosage = const Value.absent(),
                Value<String?> mealRelation = const Value.absent(),
                Value<String> timesOfDay = const Value.absent(),
                Value<String?> daysOfWeek = const Value.absent(),
                Value<DateTime?> startDate = const Value.absent(),
                Value<DateTime?> endDate = const Value.absent(),
                Value<String?> pausePeriods = const Value.absent(),
                Value<double?> stock = const Value.absent(),
                Value<String?> stockUnit = const Value.absent(),
                Value<bool> reminderEnabled = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => MedicationsCompanion(
                id: id,
                profileId: profileId,
                name: name,
                dosage: dosage,
                mealRelation: mealRelation,
                timesOfDay: timesOfDay,
                daysOfWeek: daysOfWeek,
                startDate: startDate,
                endDate: endDate,
                pausePeriods: pausePeriods,
                stock: stock,
                stockUnit: stockUnit,
                reminderEnabled: reminderEnabled,
                note: note,
                active: active,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int profileId,
                required String name,
                Value<String?> dosage = const Value.absent(),
                Value<String?> mealRelation = const Value.absent(),
                required String timesOfDay,
                Value<String?> daysOfWeek = const Value.absent(),
                Value<DateTime?> startDate = const Value.absent(),
                Value<DateTime?> endDate = const Value.absent(),
                Value<String?> pausePeriods = const Value.absent(),
                Value<double?> stock = const Value.absent(),
                Value<String?> stockUnit = const Value.absent(),
                Value<bool> reminderEnabled = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => MedicationsCompanion.insert(
                id: id,
                profileId: profileId,
                name: name,
                dosage: dosage,
                mealRelation: mealRelation,
                timesOfDay: timesOfDay,
                daysOfWeek: daysOfWeek,
                startDate: startDate,
                endDate: endDate,
                pausePeriods: pausePeriods,
                stock: stock,
                stockUnit: stockUnit,
                reminderEnabled: reminderEnabled,
                note: note,
                active: active,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MedicationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MedicationsTable,
      Medication,
      $$MedicationsTableFilterComposer,
      $$MedicationsTableOrderingComposer,
      $$MedicationsTableAnnotationComposer,
      $$MedicationsTableCreateCompanionBuilder,
      $$MedicationsTableUpdateCompanionBuilder,
      (
        Medication,
        BaseReferences<_$AppDatabase, $MedicationsTable, Medication>,
      ),
      Medication,
      PrefetchHooks Function()
    >;
typedef $$MedicationLogsTableCreateCompanionBuilder =
    MedicationLogsCompanion Function({
      Value<int> id,
      required int medicationId,
      required DateTime scheduledAt,
      Value<DateTime?> takenAt,
      required String status,
      Value<DateTime> createdAt,
    });
typedef $$MedicationLogsTableUpdateCompanionBuilder =
    MedicationLogsCompanion Function({
      Value<int> id,
      Value<int> medicationId,
      Value<DateTime> scheduledAt,
      Value<DateTime?> takenAt,
      Value<String> status,
      Value<DateTime> createdAt,
    });

class $$MedicationLogsTableFilterComposer
    extends Composer<_$AppDatabase, $MedicationLogsTable> {
  $$MedicationLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get medicationId => $composableBuilder(
    column: $table.medicationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get takenAt => $composableBuilder(
    column: $table.takenAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MedicationLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $MedicationLogsTable> {
  $$MedicationLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get medicationId => $composableBuilder(
    column: $table.medicationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get takenAt => $composableBuilder(
    column: $table.takenAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MedicationLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MedicationLogsTable> {
  $$MedicationLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get medicationId => $composableBuilder(
    column: $table.medicationId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get takenAt =>
      $composableBuilder(column: $table.takenAt, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$MedicationLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MedicationLogsTable,
          MedicationLog,
          $$MedicationLogsTableFilterComposer,
          $$MedicationLogsTableOrderingComposer,
          $$MedicationLogsTableAnnotationComposer,
          $$MedicationLogsTableCreateCompanionBuilder,
          $$MedicationLogsTableUpdateCompanionBuilder,
          (
            MedicationLog,
            BaseReferences<_$AppDatabase, $MedicationLogsTable, MedicationLog>,
          ),
          MedicationLog,
          PrefetchHooks Function()
        > {
  $$MedicationLogsTableTableManager(
    _$AppDatabase db,
    $MedicationLogsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MedicationLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MedicationLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MedicationLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> medicationId = const Value.absent(),
                Value<DateTime> scheduledAt = const Value.absent(),
                Value<DateTime?> takenAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => MedicationLogsCompanion(
                id: id,
                medicationId: medicationId,
                scheduledAt: scheduledAt,
                takenAt: takenAt,
                status: status,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int medicationId,
                required DateTime scheduledAt,
                Value<DateTime?> takenAt = const Value.absent(),
                required String status,
                Value<DateTime> createdAt = const Value.absent(),
              }) => MedicationLogsCompanion.insert(
                id: id,
                medicationId: medicationId,
                scheduledAt: scheduledAt,
                takenAt: takenAt,
                status: status,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MedicationLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MedicationLogsTable,
      MedicationLog,
      $$MedicationLogsTableFilterComposer,
      $$MedicationLogsTableOrderingComposer,
      $$MedicationLogsTableAnnotationComposer,
      $$MedicationLogsTableCreateCompanionBuilder,
      $$MedicationLogsTableUpdateCompanionBuilder,
      (
        MedicationLog,
        BaseReferences<_$AppDatabase, $MedicationLogsTable, MedicationLog>,
      ),
      MedicationLog,
      PrefetchHooks Function()
    >;
typedef $$FamiliesTableCreateCompanionBuilder =
    FamiliesCompanion Function({
      Value<int> id,
      required String name,
      Value<DateTime> createdAt,
    });
typedef $$FamiliesTableUpdateCompanionBuilder =
    FamiliesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<DateTime> createdAt,
    });

class $$FamiliesTableFilterComposer
    extends Composer<_$AppDatabase, $FamiliesTable> {
  $$FamiliesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FamiliesTableOrderingComposer
    extends Composer<_$AppDatabase, $FamiliesTable> {
  $$FamiliesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FamiliesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FamiliesTable> {
  $$FamiliesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$FamiliesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FamiliesTable,
          FamilyRow,
          $$FamiliesTableFilterComposer,
          $$FamiliesTableOrderingComposer,
          $$FamiliesTableAnnotationComposer,
          $$FamiliesTableCreateCompanionBuilder,
          $$FamiliesTableUpdateCompanionBuilder,
          (FamilyRow, BaseReferences<_$AppDatabase, $FamiliesTable, FamilyRow>),
          FamilyRow,
          PrefetchHooks Function()
        > {
  $$FamiliesTableTableManager(_$AppDatabase db, $FamiliesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FamiliesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FamiliesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FamiliesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => FamiliesCompanion(id: id, name: name, createdAt: createdAt),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<DateTime> createdAt = const Value.absent(),
              }) => FamiliesCompanion.insert(
                id: id,
                name: name,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FamiliesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FamiliesTable,
      FamilyRow,
      $$FamiliesTableFilterComposer,
      $$FamiliesTableOrderingComposer,
      $$FamiliesTableAnnotationComposer,
      $$FamiliesTableCreateCompanionBuilder,
      $$FamiliesTableUpdateCompanionBuilder,
      (FamilyRow, BaseReferences<_$AppDatabase, $FamiliesTable, FamilyRow>),
      FamilyRow,
      PrefetchHooks Function()
    >;
typedef $$FamilyMembersTableCreateCompanionBuilder =
    FamilyMembersCompanion Function({
      Value<int> id,
      required int familyId,
      required int profileId,
    });
typedef $$FamilyMembersTableUpdateCompanionBuilder =
    FamilyMembersCompanion Function({
      Value<int> id,
      Value<int> familyId,
      Value<int> profileId,
    });

class $$FamilyMembersTableFilterComposer
    extends Composer<_$AppDatabase, $FamilyMembersTable> {
  $$FamilyMembersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get familyId => $composableBuilder(
    column: $table.familyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FamilyMembersTableOrderingComposer
    extends Composer<_$AppDatabase, $FamilyMembersTable> {
  $$FamilyMembersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get familyId => $composableBuilder(
    column: $table.familyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FamilyMembersTableAnnotationComposer
    extends Composer<_$AppDatabase, $FamilyMembersTable> {
  $$FamilyMembersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get familyId =>
      $composableBuilder(column: $table.familyId, builder: (column) => column);

  GeneratedColumn<int> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);
}

class $$FamilyMembersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FamilyMembersTable,
          FamilyMember,
          $$FamilyMembersTableFilterComposer,
          $$FamilyMembersTableOrderingComposer,
          $$FamilyMembersTableAnnotationComposer,
          $$FamilyMembersTableCreateCompanionBuilder,
          $$FamilyMembersTableUpdateCompanionBuilder,
          (
            FamilyMember,
            BaseReferences<_$AppDatabase, $FamilyMembersTable, FamilyMember>,
          ),
          FamilyMember,
          PrefetchHooks Function()
        > {
  $$FamilyMembersTableTableManager(_$AppDatabase db, $FamilyMembersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FamilyMembersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FamilyMembersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FamilyMembersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> familyId = const Value.absent(),
                Value<int> profileId = const Value.absent(),
              }) => FamilyMembersCompanion(
                id: id,
                familyId: familyId,
                profileId: profileId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int familyId,
                required int profileId,
              }) => FamilyMembersCompanion.insert(
                id: id,
                familyId: familyId,
                profileId: profileId,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FamilyMembersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FamilyMembersTable,
      FamilyMember,
      $$FamilyMembersTableFilterComposer,
      $$FamilyMembersTableOrderingComposer,
      $$FamilyMembersTableAnnotationComposer,
      $$FamilyMembersTableCreateCompanionBuilder,
      $$FamilyMembersTableUpdateCompanionBuilder,
      (
        FamilyMember,
        BaseReferences<_$AppDatabase, $FamilyMembersTable, FamilyMember>,
      ),
      FamilyMember,
      PrefetchHooks Function()
    >;
typedef $$BoxMedicinesTableCreateCompanionBuilder =
    BoxMedicinesCompanion Function({
      Value<int> id,
      required int familyId,
      required String name,
      required DateTime expireDate,
      Value<String?> imagePath,
      Value<String?> imagePaths,
      Value<String?> usage,
      Value<String?> note,
      Value<DateTime> createdAt,
    });
typedef $$BoxMedicinesTableUpdateCompanionBuilder =
    BoxMedicinesCompanion Function({
      Value<int> id,
      Value<int> familyId,
      Value<String> name,
      Value<DateTime> expireDate,
      Value<String?> imagePath,
      Value<String?> imagePaths,
      Value<String?> usage,
      Value<String?> note,
      Value<DateTime> createdAt,
    });

class $$BoxMedicinesTableFilterComposer
    extends Composer<_$AppDatabase, $BoxMedicinesTable> {
  $$BoxMedicinesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get familyId => $composableBuilder(
    column: $table.familyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expireDate => $composableBuilder(
    column: $table.expireDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imagePaths => $composableBuilder(
    column: $table.imagePaths,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get usage => $composableBuilder(
    column: $table.usage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BoxMedicinesTableOrderingComposer
    extends Composer<_$AppDatabase, $BoxMedicinesTable> {
  $$BoxMedicinesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get familyId => $composableBuilder(
    column: $table.familyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expireDate => $composableBuilder(
    column: $table.expireDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imagePaths => $composableBuilder(
    column: $table.imagePaths,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get usage => $composableBuilder(
    column: $table.usage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BoxMedicinesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BoxMedicinesTable> {
  $$BoxMedicinesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get familyId =>
      $composableBuilder(column: $table.familyId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get expireDate => $composableBuilder(
    column: $table.expireDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<String> get imagePaths => $composableBuilder(
    column: $table.imagePaths,
    builder: (column) => column,
  );

  GeneratedColumn<String> get usage =>
      $composableBuilder(column: $table.usage, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$BoxMedicinesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BoxMedicinesTable,
          BoxMedicine,
          $$BoxMedicinesTableFilterComposer,
          $$BoxMedicinesTableOrderingComposer,
          $$BoxMedicinesTableAnnotationComposer,
          $$BoxMedicinesTableCreateCompanionBuilder,
          $$BoxMedicinesTableUpdateCompanionBuilder,
          (
            BoxMedicine,
            BaseReferences<_$AppDatabase, $BoxMedicinesTable, BoxMedicine>,
          ),
          BoxMedicine,
          PrefetchHooks Function()
        > {
  $$BoxMedicinesTableTableManager(_$AppDatabase db, $BoxMedicinesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BoxMedicinesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BoxMedicinesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BoxMedicinesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> familyId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> expireDate = const Value.absent(),
                Value<String?> imagePath = const Value.absent(),
                Value<String?> imagePaths = const Value.absent(),
                Value<String?> usage = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => BoxMedicinesCompanion(
                id: id,
                familyId: familyId,
                name: name,
                expireDate: expireDate,
                imagePath: imagePath,
                imagePaths: imagePaths,
                usage: usage,
                note: note,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int familyId,
                required String name,
                required DateTime expireDate,
                Value<String?> imagePath = const Value.absent(),
                Value<String?> imagePaths = const Value.absent(),
                Value<String?> usage = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => BoxMedicinesCompanion.insert(
                id: id,
                familyId: familyId,
                name: name,
                expireDate: expireDate,
                imagePath: imagePath,
                imagePaths: imagePaths,
                usage: usage,
                note: note,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BoxMedicinesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BoxMedicinesTable,
      BoxMedicine,
      $$BoxMedicinesTableFilterComposer,
      $$BoxMedicinesTableOrderingComposer,
      $$BoxMedicinesTableAnnotationComposer,
      $$BoxMedicinesTableCreateCompanionBuilder,
      $$BoxMedicinesTableUpdateCompanionBuilder,
      (
        BoxMedicine,
        BaseReferences<_$AppDatabase, $BoxMedicinesTable, BoxMedicine>,
      ),
      BoxMedicine,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProfilesTableTableManager get profiles =>
      $$ProfilesTableTableManager(_db, _db.profiles);
  $$MedicalRecordsTableTableManager get medicalRecords =>
      $$MedicalRecordsTableTableManager(_db, _db.medicalRecords);
  $$MetricsTableTableManager get metrics =>
      $$MetricsTableTableManager(_db, _db.metrics);
  $$MetricValuesTableTableManager get metricValues =>
      $$MetricValuesTableTableManager(_db, _db.metricValues);
  $$MedicationsTableTableManager get medications =>
      $$MedicationsTableTableManager(_db, _db.medications);
  $$MedicationLogsTableTableManager get medicationLogs =>
      $$MedicationLogsTableTableManager(_db, _db.medicationLogs);
  $$FamiliesTableTableManager get families =>
      $$FamiliesTableTableManager(_db, _db.families);
  $$FamilyMembersTableTableManager get familyMembers =>
      $$FamilyMembersTableTableManager(_db, _db.familyMembers);
  $$BoxMedicinesTableTableManager get boxMedicines =>
      $$BoxMedicinesTableTableManager(_db, _db.boxMedicines);
}
