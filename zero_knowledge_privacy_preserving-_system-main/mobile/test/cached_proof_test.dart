import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/cached_proof.dart';
import 'package:mobile/models/proof_payload.dart';

void main() {
  test('cached proof preserves a shareable payload and expires', () {
    final now = DateTime.now();
    final original = CachedProof(
      id: 'age_request-1',
      payload: ProofPayload(
        proof: Groth16Proof(piA: const ['a'], piB: const [], piC: const ['c']),
        publicInputs: const ['2026', '18', 'request-1'],
        sessionNonce: 'request-1',
        timestamp: now.millisecondsSinceEpoch,
      ),
      encodedPayload: 'base85-proof',
      createdAt: now,
      expiresAt: now.add(const Duration(minutes: 5)),
    );

    final restored = CachedProof.fromJson(original.toJson());
    expect(restored.statement, 'Age is 18 or older');
    expect(restored.encodedPayload, 'base85-proof');
    expect(restored.isExpired, isFalse);
  });
}
