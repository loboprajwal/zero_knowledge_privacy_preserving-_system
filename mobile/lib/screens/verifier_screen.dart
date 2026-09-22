import 'package:flutter/material.dart';
import '../core/native_bridge.dart';
import '../core/nonce_manager.dart';
import '../core/qr_codec.dart';
import '../models/proof_payload.dart';
import '../widgets/qr_display.dart';
import '../widgets/qr_scanner_view.dart';
import '../widgets/verification_badge.dart';

class VerifierScreen extends StatefulWidget {
  const VerifierScreen({super.key});

  @override
  State<VerifierScreen> createState() => _VerifierScreenState();
}

class _VerifierScreenState extends State<VerifierScreen> {
  final NativeBridge _bridge = NativeBridge();
  final NonceManager _nonceManager = NonceManager();

  String _currentSessionNonce = '';
  bool _isScanning = false;
  bool _isVerifying = false;
  bool? _verificationSuccess;
  String _resultTitle = '';
  String _resultMessage = '';
  Map<String, String>? _resultDetails;

  @override
  void initState() {
    super.initState();
    _refreshSessionNonce();
  }

  void _refreshSessionNonce() {
    setState(() {
      _currentSessionNonce = _nonceManager.generateNonce();
      _verificationSuccess = null;
      _resultTitle = '';
      _resultMessage = '';
      _resultDetails = null;
    });
  }

  Future<void> _handleScannedQr(String rawData) async {
    setState(() {
      _isScanning = false;
      _isVerifying = true;
    });

    try {
      // 1. Base85 decompression
      final ProofPayload payload = QrCodec.decode(rawData);

      // 2. Anti-Replay Nonce Validation
      final isNonceValid =
          _nonceManager.validateAndConsumeNonce(payload.sessionNonce);

      if (!isNonceValid) {
        setState(() {
          _isVerifying = false;
          _verificationSuccess = false;
          _resultTitle = 'REPLAY ATTACK PREVENTED';
          _resultMessage =
              'This proof was generated for an expired or previously consumed session nonce.';
        });
        return;
      }

      // 3. Cryptographic Groth16 Evaluation
      final isProofValid = await _bridge.verifyAgeProof(payload: payload);

      if (isProofValid) {
        setState(() {
          _isVerifying = false;
          _verificationSuccess = true;
          _resultTitle = 'VERIFIED: Age >= 18';
          _resultMessage =
              'Offline Groth16 cryptographic proof successfully evaluated with ZERO PII disclosed.';
          _resultDetails = {
            'Protocol': 'Groth16 / BN254',
            'Session Nonce': payload.sessionNonce,
            'Public Nullifier': payload.publicInputs.length > 3
                ? payload.publicInputs[3]
                : 'Poseidon Hash',
            'Timestamp': DateTime.fromMillisecondsSinceEpoch(payload.timestamp)
                .toIso8601String(),
          };
        });
      } else {
        setState(() {
          _isVerifying = false;
          _verificationSuccess = false;
          _resultTitle = 'VERIFICATION FAILED';
          _resultMessage =
              'The cryptographic proof points do not satisfy the BN254 pairing constraints.';
        });
      }
    } catch (e) {
      setState(() {
        _isVerifying = false;
        _verificationSuccess = false;
        _resultTitle = 'PAYLOAD ERROR';
        _resultMessage = 'Could not parse incoming QR payload: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isScanning) {
      return Scaffold(
        body: QrScannerView(
          onScanned: _handleScannedQr,
          onClose: () => setState(() => _isScanning = false),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Verifier'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Generate Fresh Session Nonce',
            onPressed: _refreshSessionNonce,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_verificationSuccess != null) ...[
              VerificationBadge(
                isSuccess: _verificationSuccess!,
                title: _resultTitle,
                message: _resultMessage,
                details: _resultDetails,
                onReset: _refreshSessionNonce,
              ),
            ] else if (_isVerifying) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Evaluating Groth16 Proof on BN254 curve...'),
                    ],
                  ),
                ),
              ),
            ] else ...[
              QrDisplay(
                data: _currentSessionNonce,
                title: 'Request Age Verification',
                subtitle:
                    'Prover can scan this dynamic nonce QR to bind proof',
                size: 200,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => setState(() => _isScanning = true),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Scan Prover QR Offline'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
