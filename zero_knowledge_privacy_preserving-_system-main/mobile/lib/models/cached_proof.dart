import 'proof_payload.dart';

/// A locally encrypted, short-lived proof that can be re-displayed for the
/// same verifier request. A proof is never valid for a new nonce.
class CachedProof {
  const CachedProof({
    required this.id,
    required this.payload,
    required this.encodedPayload,
    required this.createdAt,
    required this.expiresAt,
  });

  final String id;
  final ProofPayload payload;
  final String encodedPayload;
  final DateTime createdAt;
  final DateTime expiresAt;

  bool get isExpired => !DateTime.now().isBefore(expiresAt);

  String get statement => payload.proofType == 'education'
      ? "Holds a bachelor's degree"
      : 'Age is 18 or older';

  Map<String, dynamic> toJson() => {
    'id': id,
    'payload': payload.toJson(),
    'encoded_payload': encodedPayload,
    'created_at': createdAt.millisecondsSinceEpoch,
    'expires_at': expiresAt.millisecondsSinceEpoch,
  };

  factory CachedProof.fromJson(Map<String, dynamic> json) => CachedProof(
    id: json['id'] as String,
    payload: ProofPayload.fromJson(
      Map<String, dynamic>.from(json['payload'] as Map),
    ),
    encodedPayload: json['encoded_payload'] as String,
    createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at'] as int),
    expiresAt: DateTime.fromMillisecondsSinceEpoch(json['expires_at'] as int),
  );
}
