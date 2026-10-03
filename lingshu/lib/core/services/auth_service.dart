import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 本地账户：PIN 码守护（数据仅存本机）
class AuthService {
  static const _kPinHash = 'lingshu.pin_hash';
  static const _kPinSalt = 'lingshu.pin_salt';
  static const _kOwnerId = 'lingshu.owner_profile_id';
  static const _kCurrentProfileId = 'lingshu.current_profile_id';
  static const _kBiometricEnabled = 'lingshu.biometric_enabled';

  final SharedPreferences prefs;

  AuthService(this.prefs);

  bool get onboarded => prefs.getInt(_kOwnerId) != null;
  int? get ownerId => prefs.getInt(_kOwnerId);
  int? get currentProfileId => prefs.getInt(_kCurrentProfileId) ?? ownerId;

  bool get pinSet => prefs.getString(_kPinHash) != null;
  bool get biometricEnabled => prefs.getBool(_kBiometricEnabled) ?? false;

  Future<void> setOwner(int profileId) async {
    await prefs.setInt(_kOwnerId, profileId);
    await prefs.setInt(_kCurrentProfileId, profileId);
  }

  Future<void> setCurrentProfile(int id) =>
      prefs.setInt(_kCurrentProfileId, id);

  Future<void> setPin(String pin) async {
    final salt = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    await prefs.setString(_kPinSalt, salt);
    await prefs.setString(_kPinHash, _hash(pin, salt));
  }

  Future<void> setBiometricEnabled(bool v) =>
      prefs.setBool(_kBiometricEnabled, v);

  bool verifyPin(String pin) {
    final hash = prefs.getString(_kPinHash);
    final salt = prefs.getString(_kPinSalt);
    if (hash == null || salt == null) return true;
    return _hash(pin, salt) == hash;
  }

  String _hash(String pin, String salt) =>
      sha256.convert(utf8.encode('lingshu.$salt.$pin')).toString();
}
