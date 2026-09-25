import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/verification_record.dart';

void main() {
  test('verification record is privacy-safe and serializable', () {
    final original = VerificationRecord(
      id: 'record-1',
      proofType: 'education',
      success: true,
      completedAt: DateTime(2026, 9, 25, 12),
      durationMs: 42,
      proofStatus: 'Groth16 / BN254 verified',
      signatureStatus: 'Unavailable: not included in proof payload',
      faceStatus: 'Unavailable: no face attestation supplied',
      revocationStatus: 'No online registry configured',
    );

    final restored = VerificationRecord.fromJson(original.toJson());
    expect(restored.statement, "Bachelor's degree");
    expect(restored.success, isTrue);
    expect(restored.durationMs, 42);
    expect(restored.failureReason, isNull);
  });
}
