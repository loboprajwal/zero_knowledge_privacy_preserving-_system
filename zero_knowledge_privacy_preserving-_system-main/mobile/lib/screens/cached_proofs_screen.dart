import 'package:flutter/material.dart';

import '../core/vault_service.dart';
import '../models/cached_proof.dart';
import '../widgets/qr_display.dart';

class CachedProofsScreen extends StatefulWidget {
  const CachedProofsScreen({super.key});

  @override
  State<CachedProofsScreen> createState() => _CachedProofsScreenState();
}

class _CachedProofsScreenState extends State<CachedProofsScreen> {
  final VaultService _vault = VaultService();
  late Future<List<CachedProof>> _proofs;

  @override
  void initState() {
    super.initState();
    _proofs = _vault.getCachedProofs();
  }

  void _refresh() => setState(() => _proofs = _vault.getCachedProofs());

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Cached proofs')),
    body: FutureBuilder<List<CachedProof>>(
      future: _proofs,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final proofs = snapshot.data ?? const [];
        if (proofs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(28),
              child: Text(
                'No valid cached proofs. Generate a proof from a fresh verifier request.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: proofs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _CachedProofCard(
            proof: proofs[index],
            onDelete: () async {
              await _vault.removeCachedProof(proofs[index].id);
              _refresh();
            },
          ),
        );
      },
    ),
  );
}

class _CachedProofCard extends StatelessWidget {
  const _CachedProofCard({required this.proof, required this.onDelete});

  final CachedProof proof;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            proof.statement,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text('Expires ${_formatExpiry(proof.expiresAt)}'),
          const SizedBox(height: 4),
          const Text(
            'This QR may only be re-displayed for the same verifier request. It cannot be rebound to a new request.',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.qr_code_2),
            label: const Text('Re-display QR'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => Scaffold(
                  appBar: AppBar(title: const Text('Share cached proof')),
                  body: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: QrDisplay(
                        data: proof.encodedPayload,
                        title: proof.statement,
                        subtitle:
                            'Valid only until ${_formatExpiry(proof.expiresAt)}',
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          TextButton.icon(
            icon: const Icon(Icons.delete_outline),
            label: const Text('Remove cached proof'),
            onPressed: onDelete,
          ),
        ],
      ),
    ),
  );

  String _formatExpiry(DateTime expiry) {
    final local = expiry.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
