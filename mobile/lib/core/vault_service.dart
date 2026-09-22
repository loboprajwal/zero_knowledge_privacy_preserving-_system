import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure Vault Service managing encrypted user credentials and secrets.
class VaultService {
  static final VaultService _instance = VaultService._internal();
  factory VaultService() => _instance;
  VaultService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _keyBirthYear = 'vault_birth_year';
  static const String _keyUserSecret = 'vault_user_secret';
  static const String _keyDobString = 'vault_dob_string';

  /// Initializes the mock test identity (DOB = 2000-01-01) if not already set.
  Future<void> initializeDefaultIdentity() async {
    final existingBirthYear = await _storage.read(key: _keyBirthYear);
    if (existingBirthYear == null) {
      final rng = Random.secure();
      final secret = List<int>.generate(16, (_) => rng.nextInt(256))
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();

      await _storage.write(key: _keyDobString, value: '2000-01-01');
      await _storage.write(key: _keyBirthYear, value: '2000');
      await _storage.write(key: _keyUserSecret, value: secret);
    }
  }

  Future<int> getBirthYear() async {
    final val = await _storage.read(key: _keyBirthYear);
    return int.tryParse(val ?? '2000') ?? 2000;
  }

  Future<String> getDobString() async {
    final val = await _storage.read(key: _keyDobString);
    return val ?? '2000-01-01';
  }

  Future<String> getUserSecretKey() async {
    final val = await _storage.read(key: _keyUserSecret);
    return val ?? '1234567890abcdef1234567890abcdef';
  }

  Future<void> updateIdentity({
    required String dobString,
    required int birthYear,
  }) async {
    await _storage.write(key: _keyDobString, value: dobString);
    await _storage.write(key: _keyBirthYear, value: birthYear.toString());
  }
}
