import 'package:flutter/material.dart';

import '../core/vault_service.dart';
import '../models/verification_record.dart';
import '../widgets/wallet_components.dart';
import 'verifier_screen.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final VaultService _vault = VaultService();
  late Future<List<VerificationRecord>> _history;

  @override
  void initState() {
    super.initState();
    _history = _loadHistory();
  }

  Future<List<VerificationRecord>> _loadHistory() async {
    try {
      return await _vault.getVerificationHistory();
    } catch (_) {
      // History is non-essential; a temporary secure-store failure must not
      // break the navigation shell.
      return const [];
    }
  }

  void _refresh() => setState(() => _history = _loadHistory());

  void _openVerifier() => Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => const VerifierScreen()))
      .then((_) => _refresh());

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Activity'),
      actions: [
        IconButton(
          tooltip: 'Refresh history',
          onPressed: _refresh,
          icon: const Icon(Icons.refresh),
        ),
        IconButton(
          tooltip: 'Open verifier mode',
          onPressed: _openVerifier,
          icon: const Icon(Icons.verified_outlined),
        ),
      ],
    ),
    body: FutureBuilder<List<VerificationRecord>>(
      future: _history,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final history = snapshot.data ?? const [];
        if (history.isEmpty) return _EmptyActivity(onVerify: _openVerifier);
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: history.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) => _HistoryCard(record: history[index]),
        );
      },
    ),
  );
}

class _EmptyActivity extends StatelessWidget {
  const _EmptyActivity({required this.onVerify});

  final VoidCallback onVerify;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.history_outlined,
            size: 56,
            color: Color(0xFF26215C),
          ),
          const SizedBox(height: 16),
          const Text(
            'No verification history',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Completed local proof verifications will appear here. Proof contents and credential data are never saved in activity history.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SecondaryButton(
            label: 'Verify a proof',
            icon: Icons.qr_code_scanner,
            onPressed: onVerify,
          ),
        ],
      ),
    ),
  );
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.record});

  final VerificationRecord record;

  @override
  Widget build(BuildContext context) {
    final color = record.success
        ? const Color(0xFF27500A)
        : const Color(0xFF791F1F);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              foregroundColor: color,
              child: Icon(
                record.success ? Icons.verified_outlined : Icons.error_outline,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.statement,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${record.success ? 'Verified' : 'Not verified'} · ${record.durationMs} ms',
                    style: TextStyle(fontSize: 12, color: color),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _formatDate(record.completedAt),
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}
