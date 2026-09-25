/// Privacy-safe summary of a local verifier event. It deliberately excludes
/// QR contents, proof points, witness data, and credential claims.
class VerificationRecord {
  const VerificationRecord({
    required this.id,
    required this.proofType,
    required this.success,
    required this.completedAt,
    required this.durationMs,
    required this.proofStatus,
    required this.signatureStatus,
    required this.faceStatus,
    required this.revocationStatus,
    this.failureReason,
  });

  final String id;
  final String proofType;
  final bool success;
  final DateTime completedAt;
  final int durationMs;
  final String proofStatus;
  final String signatureStatus;
  final String faceStatus;
  final String revocationStatus;
  final String? failureReason;

  String get statement =>
      proofType == 'education' ? "Bachelor's degree" : 'Age is 18 or older';

  Map<String, dynamic> toJson() => {
    'id': id,
    'proof_type': proofType,
    'success': success,
    'completed_at': completedAt.millisecondsSinceEpoch,
    'duration_ms': durationMs,
    'proof_status': proofStatus,
    'signature_status': signatureStatus,
    'face_status': faceStatus,
    'revocation_status': revocationStatus,
    'failure_reason': failureReason,
  };

  factory VerificationRecord.fromJson(Map<String, dynamic> json) =>
      VerificationRecord(
        id: json['id'] as String,
        proofType: json['proof_type'] as String,
        success: json['success'] as bool,
        completedAt: DateTime.fromMillisecondsSinceEpoch(
          json['completed_at'] as int,
        ),
        durationMs: json['duration_ms'] as int,
        proofStatus: json['proof_status'] as String,
        signatureStatus: json['signature_status'] as String,
        faceStatus: json['face_status'] as String,
        revocationStatus: json['revocation_status'] as String,
        failureReason: json['failure_reason'] as String?,
      );
}
