import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/native_bridge.dart';
import 'package:mobile/core/nonce_manager.dart';
import 'package:mobile/core/qr_codec.dart';
import 'package:mobile/models/education_credential.dart';
import 'package:mobile/models/proof_payload.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Education Credential Model Tests', () {
    test('default demo credential has valid status and correct demo data', () {
      final demo = EducationCredential.demo();
      expect(demo.studentName, equals('Prashant Pandita'));

      expect(demo.degree, equals('Bachelor of Technology'));
      expect(
        demo.university,
        equals('Fr. C. Rodrigues Institute of Technology'),
      );
      expect(demo.graduationYear, equals(2027));
      expect(demo.credentialId, equals('EDU-DEMO-001'));
      expect(demo.status, equals('VALID'));
      expect(demo.degreeCode, equals(1));
      expect(demo.isValid, isTrue);
    });

    test('toJson and fromJson cycle retains all fields correctly', () {
      final original = EducationCredential(
        studentName: 'Prashant Pandita',
        degree: 'Bachelor of Technology',
        university: 'Fr. C. Rodrigues Institute of Technology',
        graduationYear: 2027,
        credentialId: 'EDU-DEMO-001',
        status: 'VALID',
        degreeCode: 1,
      );

      final json = original.toJson();
      final restored = EducationCredential.fromJson(json);

      expect(restored.studentName, equals(original.studentName));
      expect(restored.degree, equals(original.degree));
      expect(restored.university, equals(original.university));
      expect(restored.graduationYear, equals(original.graduationYear));
      expect(restored.credentialId, equals(original.credentialId));
      expect(restored.status, equals(original.status));
      expect(restored.degreeCode, equals(original.degreeCode));
    });

    test('isValid returns false when status is REVOKED', () {
      final revoked = EducationCredential(
        studentName: 'Test Student',
        degree: 'Master of Science',
        university: 'Test University',
        graduationYear: 2025,
        credentialId: 'EDU-REV-001',
        status: 'REVOKED',
        degreeCode: 2,
      );

      expect(revoked.isValid, isFalse);
    });

    test('credential offer round trip retains the issuer credential', () {
      final original = EducationCredential.demo();

      final imported = EducationCredential.fromOfferJson(
        original.toOfferJson(),
      );

      expect(imported.toJson(), equals(original.toJson()));
    });

    test('proof payloads and incomplete offers cannot be imported', () {
      expect(
        () => EducationCredential.fromOfferJson('{"type":"proof"}'),
        throwsFormatException,
      );
      expect(
        () => EducationCredential.fromOfferJson(
          '{"type":"education_credential","credential":{}}',
        ),
        throwsFormatException,
      );
    });
  });

  group('Education Proof Generation & Verification Engine Tests', () {
    final bridge = NativeBridge();
    final nonceManager = NonceManager();

    test('valid education credential produces verifiable proof', () async {
      final nonce = nonceManager.generateNonce();
      const userSecret = '12345678901234567890';

      final payload = await bridge.generateEducationProof(
        degreeCode: 1, // Bachelor of Technology
        credentialStatus: 'VALID',
        userSecret: userSecret,
        requiredDegreeCode: 1,
        sessionNonce: nonce,
      );

      expect(payload.proofType, equals('education'));
      expect(payload.sessionNonce, equals(nonce));
      expect(payload.publicInputs.length, greaterThanOrEqualTo(2));

      final isValid = await bridge.verifyEducationProof(
        payload: payload,
        expectedDegreeCode: 1,
      );

      expect(isValid, isTrue);
    });

    test('revoked credential status rejects proof generation', () async {
      final nonce = nonceManager.generateNonce();
      const userSecret = '12345678901234567890';

      expect(
        () async => await bridge.generateEducationProof(
          degreeCode: 1,
          credentialStatus: 'REVOKED',
          userSecret: userSecret,
          requiredDegreeCode: 1,
          sessionNonce: nonce,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test(
      'wrong degree code rejects proof generation or verification',
      () async {
        final nonce = nonceManager.generateNonce();
        const userSecret = '12345678901234567890';

        // degreeCode 2 != required 1
        expect(
          () async => await bridge.generateEducationProof(
            degreeCode: 2,
            credentialStatus: 'VALID',
            userSecret: userSecret,
            requiredDegreeCode: 1,
            sessionNonce: nonce,
          ),
          throwsA(isA<Exception>()),
        );
      },
    );

    test('anti-replay nonce consumption invalidates reused proof', () async {
      final nonce = nonceManager.generateNonce();
      const userSecret = '12345678901234567890';

      final payload = await bridge.generateEducationProof(
        degreeCode: 1,
        credentialStatus: 'VALID',
        userSecret: userSecret,
        requiredDegreeCode: 1,
        sessionNonce: nonce,
      );

      // First consumption: Valid
      final firstCheck = nonceManager.validateAndConsumeNonce(
        payload.sessionNonce,
      );
      expect(firstCheck, isTrue);

      // Replay attempt with consumed nonce: Invalid
      final secondCheck = nonceManager.validateAndConsumeNonce(
        payload.sessionNonce,
      );
      expect(secondCheck, isFalse);
    });

    test(
      'QR codec encodes and decodes education proof payload losslessly',
      () async {
        final nonce = nonceManager.generateNonce();
        const userSecret = '12345678901234567890';

        final payload = await bridge.generateEducationProof(
          degreeCode: 1,
          credentialStatus: 'VALID',
          userSecret: userSecret,
          requiredDegreeCode: 1,
          sessionNonce: nonce,
        );

        final encoded = QrCodec.encode(payload);
        final decoded = QrCodec.decode(encoded);

        expect(decoded.proofType, equals('education'));
        expect(decoded.sessionNonce, equals(payload.sessionNonce));
        expect(decoded.publicInputs, equals(payload.publicInputs));
        expect(decoded.proof.piA, equals(payload.proof.piA));
      },
    );
  });
}
