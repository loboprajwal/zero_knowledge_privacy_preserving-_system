import 'package:flutter/material.dart';

import '../core/vault_service.dart';
import '../widgets/wallet_components.dart';
import 'benchmark_dashboard.dart';
import 'verifier_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, this.onWalletWiped});

  final VoidCallback? onWalletWiped;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final VaultService _vault = VaultService();

  Future<void> _confirmWipe() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Wipe this wallet?'),
        content: const Text(
          'This permanently removes local credentials, proof cache, verification history, and wallet settings from this device. Your recovery phrase is required to restore your wallet.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Wipe wallet'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _vault.wipeWallet();
    if (!mounted) return;
    widget.onWalletWiped?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const PrivacyMessage(
            message:
                'This wallet keeps credentials and proof witnesses encrypted on-device.',
          ),
          const SizedBox(height: 24),
          const _SectionLabel('WALLET'),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              _NavigationSetting(
                icon: Icons.delete_forever_outlined,
                title: 'Wipe wallet',
                subtitle: 'Permanently remove all local wallet data',
                destructive: true,
                onTap: _confirmWipe,
              ),
            ],
          ),
          const SizedBox(height: 20),
          const _SectionLabel('TOOLS'),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              _NavigationSetting(
                icon: Icons.verified_outlined,
                title: 'Verifier mode',
                subtitle: 'Scan and verify a locally shared proof',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const VerifierScreen(),
                  ),
                ),
              ),
              _NavigationSetting(
                icon: Icons.bar_chart_outlined,
                title: 'Benchmarks',
                subtitle:
                    'Run and compare local proof performance measurements',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const BenchmarkDashboard(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Offline mode',
              style: TextStyle(color: Color(0xFF62616A), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.1,
      color: Colors.grey,
    ),
  );
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Card(child: Column(children: children));
}

class _NavigationSetting extends StatelessWidget {
  const _NavigationSetting({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;
  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    leading: Icon(
      icon,
      color: destructive ? Colors.red.shade700 : const Color(0xFF26215C),
    ),
    title: Text(
      title,
      style: destructive ? TextStyle(color: Colors.red.shade700) : null,
    ),
    subtitle: Text(subtitle),
    trailing: const Icon(Icons.chevron_right),
  );
}
