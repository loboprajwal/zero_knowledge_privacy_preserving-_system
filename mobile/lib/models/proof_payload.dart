import 'dart:convert';

/// Represents the Groth16 zero-knowledge proof points on the BN254 elliptic curve.
class Groth16Proof {
  final List<String> piA;
  final List<List<String>> piB;
  final List<String> piC;
  final String protocol;
  final String curve;

  Groth16Proof({
    required this.piA,
    required this.piB,
    required this.piC,
    this.protocol = 'groth16',
    this.curve = 'bn128',
  });

  Map<String, dynamic> toJson() => {
        'pi_a': piA,
        'pi_b': piB,
        'pi_c': piC,
        'protocol': protocol,
        'curve': curve,
      };

  factory Groth16Proof.fromJson(Map<String, dynamic> json) {
    return Groth16Proof(
      piA: List<String>.from(json['pi_a'] ?? []),
      piB: (json['pi_b'] as List<dynamic>? ?? [])
          .map((row) => List<String>.from(row))
          .toList(),
      piC: List<String>.from(json['pi_c'] ?? []),
      protocol: json['protocol'] ?? 'groth16',
      curve: json['curve'] ?? 'bn128',
    );
  }
}

/// The complete proof payload exchanged during the offline QR handshake.
class ProofPayload {
  final Groth16Proof proof;
  final List<String> publicInputs;
  final String sessionNonce;
  final int timestamp;

  ProofPayload({
    required this.proof,
    required this.publicInputs,
    required this.sessionNonce,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'proof': proof.toJson(),
        'public_inputs': publicInputs,
        'session_nonce': sessionNonce,
        'timestamp': timestamp,
      };

  factory ProofPayload.fromJson(Map<String, dynamic> json) {
    return ProofPayload(
      proof: Groth16Proof.fromJson(json['proof'] as Map<String, dynamic>),
      publicInputs: List<String>.from(json['public_inputs'] ?? []),
      sessionNonce: json['session_nonce'] ?? '',
      timestamp: json['timestamp'] ?? 0,
    );
  }

  String toRawJson() => jsonEncode(toJson());

  factory ProofPayload.fromRawJson(String raw) =>
      ProofPayload.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}
