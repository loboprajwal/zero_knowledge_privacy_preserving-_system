import 'package:flutter/material.dart';
import '../core/native_bridge.dart';
import '../core/qr_codec.dart';
import '../core/vault_service.dart';
import '../models/cached_proof.dart';
import '../models/proof_payload.dart';
import '../widgets/qr_display.dart';
import '../widgets/qr_scanner_view.dart';

class ProverScreen extends StatefulWidget {
  const ProverScreen({super.key, this.initialVerificationType = 'age'});

  final String initialVerificationType;

  @override
  State<ProverScreen> createState() => _ProverScreenState();
}

class _ProverScreenState extends State<ProverScreen> {
  final NativeBridge _bridge = NativeBridge();
  final VaultService _vaultService = VaultService();

  String _verificationType = 'age'; // 'age' or 'education'
  final int _ageLimit = 18;
  int _currentYear = DateTime.now().year;
  String _sessionNonce = '';
  final TextEditingController _nonceController = TextEditingController();

  bool _isProving = false;
  String? _encodedPayload;
  double? _executionTimeMs;
  String? _errorMessage;
  bool _isScanningNonce = false;
  bool _cancelRequested = false;

  @override
  void initState() {
    super.initState();
    _verificationType = widget.initialVerificationType == 'education'
        ? 'education'
        : 'age';
    _currentYear = DateTime.now().year;
    _sessionNonce = 'req_${DateTime.now().millisecondsSinceEpoch}';
    _nonceController.text = _sessionNonce;
  }

  Future<void> _generateProof() async {
    setState(() {
      _isProving = true;
      _errorMessage = null;
      _encodedPayload = null;
      _cancelRequested = false;
    });

    final stopwatch = Stopwatch()..start();
    try {
      final userSecret = await _vaultService.getUserSecretKey();
      final nonce = _nonceController.text.trim().isEmpty
          ? _sessionNonce
          : _nonceController.text.trim();

      ProofPayload payload;

      if (_verificationType == 'age') {
        final birthYear = await _vaultService.getBirthYear();
        payload = await _bridge.generateAgeProof(
          birthYear: birthYear,
          userSecret: userSecret,
          currentYear: _currentYear,
          ageLimit: _ageLimit,
          sessionNonce: nonce,
        );
      } else {
        final edu = await _vaultService.getEducationCredential();
        payload = await _bridge.generateEducationProof(
          degreeCode: edu.degreeCode,
          credentialStatus: edu.status,
          userSecret: userSecret,
          requiredDegreeCode:
              1, // 1 = Bachelor of Technology / Bachelor's Degree
          sessionNonce: nonce,
        );
      }

      stopwatch.stop();
      final base85String = QrCodec.encode(payload);

      if (_cancelRequested) return;
      final now = DateTime.now();
      await _vaultService.cacheProof(
        CachedProof(
          id: '${payload.proofType}_${payload.sessionNonce}_${now.millisecondsSinceEpoch}',
          payload: payload,
          encodedPayload: base85String,
          createdAt: now,
          expiresAt: now.add(const Duration(minutes: 5)),
        ),
      );

      setState(() {
        _encodedPayload = base85String;
        _executionTimeMs = stopwatch.elapsedMicroseconds / 1000.0;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isProving = false;
      });
    }
  }

  @override
  void dispose() {
    _nonceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isScanningNonce) {
      return Scaffold(
        body: QrScannerView(
          onScanned: (scannedNonce) {
            setState(() {
              _nonceController.text = scannedNonce;
              _sessionNonce = scannedNonce;
              _isScanningNonce = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Nonce acquired from Verifier!')),
            );
          },
          onClose: () => setState(() => _isScanningNonce = false),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('ZK Prover')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'SELECT VERIFICATION TYPE',
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
                  label: Text('Age Verification'),
                  icon: Icon(Icons.cake),
                ),
                ButtonSegment(
                  value: 'education',
                  label: Text('Education Verification'),
                  icon: Icon(Icons.school),
                ),
              ],
              selected: {_verificationType},
              onSelectionChanged: (newSelection) {
                setState(() {
                  _verificationType = newSelection.first;
                  _encodedPayload = null;
                  _errorMessage = null;
                });
              },
            ),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _verificationType == 'age'
                              ? Icons.cake
                              : Icons.school,
                          color: Colors.indigo,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _verificationType == 'age'
                                    ? '🎂 Age Verification'
                                    : '🎓 Education Verification',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _verificationType == 'age'
                                    ? 'Prove that age >= $_ageLimit without disclosing birth year.'
                                    : 'Prove that you possess the required educational qualification without revealing your complete credential.',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nonceController,
              decoration: InputDecoration(
                labelText: 'Session Nonce (Anti-Replay)',
                hintText: 'Scan verifier nonce or generate one',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  tooltip: 'Scan Verifier Nonce QR',
                  onPressed: () => setState(() => _isScanningNonce = true),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isProving ? null : _generateProof,
              icon: _isProving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(
                      _verificationType == 'education'
                          ? Icons.school
                          : Icons.flash_on,
                    ),
              label: Text(
                _isProving
                    ? 'Generating Witness & Proof...'
                    : _verificationType == 'education'
                    ? 'Verify Education'
                    : 'Generate Zero-Knowledge Proof',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _verificationType == 'education'
                    ? Colors.teal
                    : Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            if (_isProving) ...[
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: () => setState(() => _cancelRequested = true),
                icon: const Icon(Icons.close),
                label: const Text('Cancel generation'),
              ),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red.shade900),
                ),
              ),
            ],
            if (_encodedPayload != null) ...[
              const SizedBox(height: 24),
              if (_executionTimeMs != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Center(
                    child: Chip(
                      avatar: const Icon(Icons.speed, size: 16),
                      label: Text(
                        'Proving Time: ${_executionTimeMs!.toStringAsFixed(1)} ms (< 2.0s target)',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: Colors.green.shade50,
                    ),
                  ),
                ),
              QrDisplay(
                data: _encodedPayload!,
                title: _verificationType == 'education'
                    ? 'zk-MatchID Education Proof'
                    : 'zk-MatchID Age Proof',
                subtitle: 'Present this QR to Verifier offline',
              ),
              const SizedBox(height: 10),
              const Text(
                'This proof is encrypted in the local cache for five minutes and can only be re-displayed for this verifier request.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
