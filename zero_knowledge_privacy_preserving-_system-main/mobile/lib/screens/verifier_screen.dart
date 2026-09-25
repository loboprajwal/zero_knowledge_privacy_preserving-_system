import 'package:flutter/material.dart';

import '../core/native_bridge.dart';
import '../core/nonce_manager.dart';
import '../core/qr_codec.dart';
import '../core/vault_service.dart';
import '../models/verification_record.dart';
import '../widgets/qr_display.dart';
import '../widgets/qr_scanner_view.dart';
import '../widgets/verification_badge.dart';
import '../widgets/wallet_components.dart';

class VerifierScreen extends StatefulWidget {
  const VerifierScreen({super.key});

  @override
  State<VerifierScreen> createState() => _VerifierScreenState();
}

class _VerifierScreenState extends State<VerifierScreen> {
  final NativeBridge _bridge = NativeBridge();
  final NonceManager _nonceManager = NonceManager();
  final VaultService _vault = VaultService();

  String _verificationType = 'age';
  String _currentSessionNonce = '';
  String _trustedIssuer = 'Mumbai University';
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

  String get _statement => _verificationType == 'education'
      ? "Holds a bachelor's degree"
      : 'Age is 18 or older';

  String get _revocationStatus => _verificationType == 'education'
      ? 'No online registry configured; native proof constraint only'
      : 'Not applicable to this predicate';

  Future<void> _handleScannedQr(String rawData) async {
    final stopwatch = Stopwatch()..start();
    setState(() {
      _isScanning = false;
      _isVerifying = true;
    });

    try {
      final payload = QrCodec.decode(rawData);
      final nonceIsValid = _nonceManager.validateAndConsumeNonce(
        payload.sessionNonce,
      );
      if (!nonceIsValid) {
        await _finishFailure(
          stopwatch,
          'Proof request is expired, unknown, or has already been used.',
          proofStatus: 'Not evaluated: nonce rejected',
        );
        return;
      }

      if (payload.proofType != _verificationType) {
        await _finishFailure(
          stopwatch,
          'The received proof does not satisfy this request’s predicate.',
          proofStatus: 'Not evaluated: predicate mismatch',
        );
        return;
      }

      final isProofValid = _verificationType == 'education'
          ? await _bridge.verifyEducationProof(
              payload: payload,
              expectedDegreeCode: 1,
            )
          : await _bridge.verifyAgeProof(payload: payload);

      if (!isProofValid) {
        await _finishFailure(
          stopwatch,
          'The cryptographic proof did not satisfy the requested constraint.',
          proofStatus: 'Groth16 verification failed',
        );
        return;
      }

      stopwatch.stop();
      final details = {
        'Requirement': _statement,
        'Proof': 'Groth16 / BN254 verified',
        'Nonce': 'Fresh and consumed',
        'Signature': 'Not included in this proof payload',
        'Face match': 'No face attestation supplied',
        'Revocation': _revocationStatus,
        'Time': '${stopwatch.elapsedMilliseconds} ms',
      };
      await _record(
        success: true,
        durationMs: stopwatch.elapsedMilliseconds,
        proofStatus: details['Proof']!,
        failureReason: null,
      );
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _verificationSuccess = true;
        _resultTitle = '$_statement — VERIFIED';
        _resultMessage =
            'The requested fact was verified locally without revealing the underlying credential data.';
        _resultDetails = details;
      });
    } catch (_) {
      await _finishFailure(
        stopwatch,
        'The scanned QR could not be decoded or verified.',
        proofStatus: 'Not evaluated: invalid payload',
      );
    }
  }

  Future<void> _finishFailure(
    Stopwatch stopwatch,
    String message, {
    required String proofStatus,
  }) async {
    stopwatch.stop();
    final details = {
      'Requirement': _statement,
      'Proof': proofStatus,
      'Nonce': 'Rejected or consumed',
      'Signature': 'Not included in this proof payload',
      'Face match': 'No face attestation supplied',
      'Revocation': _revocationStatus,
      'Time': '$stopwatch.elapsedMilliseconds ms',
    };
    await _record(
      success: false,
      durationMs: stopwatch.elapsedMilliseconds,
      proofStatus: proofStatus,
      failureReason: message,
    );
    if (!mounted) return;
    setState(() {
      _isVerifying = false;
      _verificationSuccess = false;
      _resultTitle = 'NOT VERIFIED';
      _resultMessage = message;
      _resultDetails = details;
    });
  }

  Future<void> _record({
    required bool success,
    required int durationMs,
    required String proofStatus,
    required String? failureReason,
  }) => _vault.addVerificationRecord(
    VerificationRecord(
      id: '${DateTime.now().microsecondsSinceEpoch}_$_verificationType',
      proofType: _verificationType,
      success: success,
      completedAt: DateTime.now(),
      durationMs: durationMs,
      proofStatus: proofStatus,
      signatureStatus: 'Unavailable: not included in proof payload',
      faceStatus: 'Unavailable: no face attestation supplied',
      revocationStatus: _revocationStatus,
      failureReason: failureReason,
    ),
  );

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
        title: const Text('Verifier'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Create fresh request',
            onPressed: _isVerifying ? null : _refreshSessionNonce,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'BUILD A VERIFICATION REQUEST',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'age',
                  label: Text('Age ≥ 18'),
                  icon: Icon(Icons.cake_outlined),
                ),
                ButtonSegment(
                  value: 'education',
                  label: Text('Bachelor’s degree'),
                  icon: Icon(Icons.school_outlined),
                ),
              ],
              selected: {_verificationType},
              onSelectionChanged: _isVerifying
                  ? null
                  : (selection) {
                      setState(() => _verificationType = selection.first);
                      _refreshSessionNonce();
                    },
            ),
            const SizedBox(height: 16),
            _RequestCard(statement: _statement),
            if (_verificationType == 'education') ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _trustedIssuer,
                decoration: const InputDecoration(
                  labelText: 'Requested trusted issuer',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Mumbai University',
                    child: Text('Mumbai University'),
                  ),
                ],
                onChanged: _isVerifying
                    ? null
                    : (value) => setState(() => _trustedIssuer = value!),
              ),
              const SizedBox(height: 8),
              const Text(
                'Issuer identity is not encoded in the current proof payload, so this selection is a request label only—not an issuer-signature verification.',
                style: TextStyle(fontSize: 12),
              ),
            ],
            const SizedBox(height: 16),
            const PrivacyMessage(
              message:
                  'Proof verification is local. QR contents, proof points, and credential claims are not stored in verification history.',
            ),
            const SizedBox(height: 20),
            if (_verificationSuccess != null)
              VerificationBadge(
                isSuccess: _verificationSuccess!,
                title: _resultTitle,
                message: _resultMessage,
                details: _resultDetails,
                onReset: _refreshSessionNonce,
              )
            else if (_isVerifying)
              const _VerificationLoading()
            else ...[
              QrDisplay(
                data: _currentSessionNonce,
                title: 'Verification request',
                subtitle:
                    'Scan this short-lived request QR, then present the matching proof QR.',
                size: 200,
              ),
              const SizedBox(height: 12),
              Text(
                'Request: $_statement',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Scan proof QR',
                icon: Icons.qr_code_scanner,
                onPressed: () => setState(() => _isScanning = true),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.statement});

  final String statement;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'REQUESTED PREDICATE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            statement,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            'A fresh nonce makes this request resistant to proof replay.',
          ),
        ],
      ),
    ),
  );
}

class _VerificationLoading extends StatelessWidget {
  const _VerificationLoading();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(40),
    child: Column(
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text('Evaluating the Groth16 proof locally…'),
        SizedBox(height: 6),
        Text(
          'Checking predicate and anti-replay nonce.',
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}
