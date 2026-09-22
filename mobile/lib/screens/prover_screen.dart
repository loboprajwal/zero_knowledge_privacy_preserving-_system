import 'package:flutter/material.dart';
import '../core/native_bridge.dart';
import '../core/qr_codec.dart';
import '../core/vault_service.dart';
import '../widgets/qr_display.dart';
import '../widgets/qr_scanner_view.dart';

class ProverScreen extends StatefulWidget {
  const ProverScreen({super.key});

  @override
  State<ProverScreen> createState() => _ProverScreenState();
}

class _ProverScreenState extends State<ProverScreen> {
  final NativeBridge _bridge = NativeBridge();
  final VaultService _vaultService = VaultService();

  final String _proofType = 'Age >= 18';
  final int _ageLimit = 18;
  int _currentYear = DateTime.now().year;
  String _sessionNonce = '';
  final TextEditingController _nonceController = TextEditingController();

  bool _isProving = false;
  String? _encodedPayload;
  double? _executionTimeMs;
  String? _errorMessage;
  bool _isScanningNonce = false;

  @override
  void initState() {
    super.initState();
    _currentYear = DateTime.now().year;
    _sessionNonce = 'req_${DateTime.now().millisecondsSinceEpoch}';
    _nonceController.text = _sessionNonce;
  }

  Future<void> _generateProof() async {
    setState(() {
      _isProving = true;
      _errorMessage = null;
    });

    final stopwatch = Stopwatch()..start();
    try {
      final birthYear = await _vaultService.getBirthYear();
      final userSecret = await _vaultService.getUserSecretKey();
      final nonce = _nonceController.text.trim().isEmpty
          ? _sessionNonce
          : _nonceController.text.trim();

      final payload = await _bridge.generateAgeProof(
        birthYear: birthYear,
        userSecret: userSecret,
        currentYear: _currentYear,
        ageLimit: _ageLimit,
        sessionNonce: nonce,
      );

      stopwatch.stop();
      final base85String = QrCodec.encode(payload);

      setState(() {
        _encodedPayload = base85String;
        _executionTimeMs = stopwatch.elapsedMicroseconds / 1000.0;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isProving = false;
      });
    }
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
      appBar: AppBar(
        title: const Text('ZK Prover'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SELECTED PROOF',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _proofType,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                        Chip(
                          label: Text('Current Year: $_currentYear'),
                          backgroundColor: Colors.indigo.shade50,
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
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.flash_on),
              label: Text(_isProving
                  ? 'Generating Witness & Proof...'
                  : 'Generate Zero-Knowledge Proof'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
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
                title: 'zk-MatchID Age Proof',
                subtitle: 'Present this QR to Verifier offline',
              ),
            ],
          ],
        ),
      ),
    );
  }
}
