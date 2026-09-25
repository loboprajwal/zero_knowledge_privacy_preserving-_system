import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'recovery_phrase.dart';
import '../models/cached_proof.dart';
import '../models/education_credential.dart';
import '../models/verification_record.dart';

/// Secure Vault Service managing encrypted user credentials and secrets.
class VaultService {
  static final VaultService _instance = VaultService._internal();
  factory VaultService() => _instance;
  VaultService._internal();

  // Android encrypted preferences are deliberately used for every vault read
  // and write. resetOnError clears only a vault that Android can no longer
  // decrypt (for example, after an OS backup restored ciphertext without its
  // Keystore key); such a vault is unrecoverable on this device anyway.
  static const AndroidOptions _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
    resetOnError: true,
  );

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: _androidOptions,
  );

  static const String _keyBirthYear = 'vault_birth_year';
  static const String _keyUserSecret = 'vault_user_secret';
  static const String _keyDobString = 'vault_dob_string';
  static const String _keyWalletName = 'vault_wallet_name';
  static const String _keyOnboardingComplete = 'vault_onboarding_complete';
  static const String _keyLinkedPhone = 'vault_linked_phone';
  static const String _keyCachedProofs = 'vault_cached_proofs';
  static const String _keyVerificationHistory = 'vault_verification_history';

  // Keys for Education Credential
  static const String _keyEduStudentName = 'vault_edu_student_name';
  static const String _keyEduDegree = 'vault_edu_degree';
  static const String _keyEduDegreeCode = 'vault_edu_degree_code';
  static const String _keyEduUniversity = 'vault_edu_university';
  static const String _keyEduGradYear = 'vault_edu_grad_year';
  static const String _keyEduCredentialId = 'vault_edu_credential_id';
  static const String _keyEduStatus = 'vault_edu_status';

  /// Initializes default identity (DOB & Education Credential) if not set.
  Future<void> initializeDefaultIdentity() async {
    final existingBirthYear = await _storage.read(key: _keyBirthYear);
    if (existingBirthYear == null) {
      final rng = Random.secure();
      final secret = List<int>.generate(
        16,
        (_) => rng.nextInt(256),
      ).map((b) => b.toRadixString(16).padLeft(2, '0')).join();

      await _storage.write(key: _keyDobString, value: '2000-01-01');
      await _storage.write(key: _keyBirthYear, value: '2000');
      await _storage.write(key: _keyUserSecret, value: secret);
    }

    final existingEdu = await _storage.read(key: _keyEduCredentialId);
    if (existingEdu == null) {
      final demo = EducationCredential.demo();
      await updateEducationCredential(demo);
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

  Future<bool> isOnboardingComplete() async =>
      (await _storage.read(key: _keyOnboardingComplete)) == 'true';

  /// Permanently removes only keys owned by this wallet. The recovery phrase is
  /// never stored, so it cannot be removed or recovered by this operation.
  Future<void> wipeWallet() async {
    const keys = [
      _keyBirthYear,
      _keyUserSecret,
      _keyDobString,
      _keyWalletName,
      _keyOnboardingComplete,
      _keyLinkedPhone,
      _keyCachedProofs,
      _keyVerificationHistory,
      _keyEduStudentName,
      _keyEduDegree,
      _keyEduDegreeCode,
      _keyEduUniversity,
      _keyEduGradYear,
      _keyEduCredentialId,
      _keyEduStatus,
    ];
    await Future.wait(keys.map((key) => _storage.delete(key: key)));
  }

  Future<String?> getWalletName() => _storage.read(key: _keyWalletName);

  Future<String?> getLinkedPhone() => _storage.read(key: _keyLinkedPhone);

  /// Stores a self-declared number locally. It is not considered OTP-verified.
  Future<void> saveUnverifiedPhone(String phoneNumber) async {
    await _storage.write(key: _keyLinkedPhone, value: phoneNumber.trim());
  }

  /// Creates the local wallet profile and replaces the proof seed with a seed
  /// derived from the user-held recovery phrase. The phrase is never persisted.
  Future<void> createWallet({
    required String walletName,
    required RecoveryPhrase recoveryPhrase,
  }) async {
    await _storage.write(key: _keyWalletName, value: walletName.trim());
    await _storage.write(
      key: _keyUserSecret,
      value: recoveryPhrase.deriveProofSecret(),
    );
    await _storage.write(key: _keyOnboardingComplete, value: 'true');
  }

  /// Restores the locally derived proof seed. Credentials remain device-local
  /// and must be re-imported from their issuers on a new device.
  Future<void> restoreWallet({
    required RecoveryPhrase recoveryPhrase,
    required String walletName,
  }) async {
    await _storage.write(
      key: _keyUserSecret,
      value: recoveryPhrase.deriveProofSecret(),
    );
    await _storage.write(key: _keyWalletName, value: walletName.trim());
    await _storage.write(key: _keyOnboardingComplete, value: 'true');
  }

  /// Retrieves the stored EducationCredential from secure storage.
  Future<EducationCredential> getEducationCredential() async {
    final studentName =
        await _storage.read(key: _keyEduStudentName) ?? 'Prashant Pandita';
    final degree =
        await _storage.read(key: _keyEduDegree) ?? 'Bachelor of Technology';
    final degreeCodeStr = await _storage.read(key: _keyEduDegreeCode) ?? '1';
    final university =
        await _storage.read(key: _keyEduUniversity) ??
        'Fr. C. Rodrigues Institute of Technology';
    final gradYearStr = await _storage.read(key: _keyEduGradYear) ?? '2027';
    final credentialId =
        await _storage.read(key: _keyEduCredentialId) ?? 'EDU-DEMO-001';
    final status = await _storage.read(key: _keyEduStatus) ?? 'VALID';

    return EducationCredential(
      studentName: studentName,
      degree: degree,
      degreeCode: int.tryParse(degreeCodeStr) ?? 1,
      university: university,
      graduationYear: int.tryParse(gradYearStr) ?? 2027,
      credentialId: credentialId,
      status: status,
    );
  }

  /// Writes an EducationCredential to secure storage.
  Future<void> updateEducationCredential(EducationCredential credential) async {
    await _storage.write(
      key: _keyEduStudentName,
      value: credential.studentName,
    );
    await _storage.write(key: _keyEduDegree, value: credential.degree);
    await _storage.write(
      key: _keyEduDegreeCode,
      value: credential.degreeCode.toString(),
    );
    await _storage.write(key: _keyEduUniversity, value: credential.university);
    await _storage.write(
      key: _keyEduGradYear,
      value: credential.graduationYear.toString(),
    );
    await _storage.write(
      key: _keyEduCredentialId,
      value: credential.credentialId,
    );
    await _storage.write(key: _keyEduStatus, value: credential.status);
  }

  /// Convenience helper to set education credential status ('VALID' / 'REVOKED').
  Future<void> setEducationCredentialStatus(String status) async {
    final current = await getEducationCredential();
    await updateEducationCredential(current.copyWith(status: status));
  }

  /// Returns valid proofs only. The JSON is held by the platform secure store,
  /// not in application preferences or logs.
  Future<List<CachedProof>> getCachedProofs() async {
    final raw = await _storage.read(key: _keyCachedProofs);
    if (raw == null || raw.isEmpty) return const [];

    try {
      final proofs =
          (jsonDecode(raw) as List<dynamic>)
              .map(
                (item) => CachedProof.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .where((proof) => !proof.isExpired)
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return proofs;
    } catch (_) {
      // A corrupt cache must not prevent the wallet or proof engine opening.
      return const [];
    }
  }

  /// Stores at most ten unexpired, nonce-bound proofs for re-display. They
  /// cannot be regenerated or rebound to a different verifier request.
  Future<void> cacheProof(CachedProof proof) async {
    final existing = await getCachedProofs();
    final updated = [
      proof,
      ...existing.where((item) => item.id != proof.id),
    ].take(10).map((item) => item.toJson()).toList();
    await _storage.write(key: _keyCachedProofs, value: jsonEncode(updated));
  }

  Future<void> removeCachedProof(String id) async {
    final remaining = (await getCachedProofs())
        .where((proof) => proof.id != id)
        .map((proof) => proof.toJson())
        .toList();
    await _storage.write(key: _keyCachedProofs, value: jsonEncode(remaining));
  }

  /// Retrieves privacy-safe local verifier history. Raw proof payloads, QR
  /// contents, and credential claims are intentionally never persisted here.
  Future<List<VerificationRecord>> getVerificationHistory() async {
    final raw = await _storage.read(key: _keyVerificationHistory);
    if (raw == null || raw.isEmpty) return const [];

    try {
      final history =
          (jsonDecode(raw) as List<dynamic>)
              .map(
                (item) => VerificationRecord.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList()
            ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
      return history;
    } catch (_) {
      return const [];
    }
  }

  /// Keeps the most recent fifty local verification summaries.
  Future<void> addVerificationRecord(VerificationRecord record) async {
    final records = [
      record,
      ...await getVerificationHistory(),
    ].take(50).map((item) => item.toJson()).toList();
    await _storage.write(
      key: _keyVerificationHistory,
      value: jsonEncode(records),
    );
  }
}
