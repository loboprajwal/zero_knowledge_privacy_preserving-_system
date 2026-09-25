import 'package:flutter/material.dart';

import '../core/vault_service.dart';
import '../models/education_credential.dart';
import '../widgets/wallet_components.dart';
import 'credential_detail_screen.dart';
import 'credential_import_screen.dart';

class WalletHomeScreen extends StatefulWidget {
  const WalletHomeScreen({super.key});

  @override
  State<WalletHomeScreen> createState() => _WalletHomeScreenState();
}

class _WalletHomeScreenState extends State<WalletHomeScreen> {
  final VaultService _vault = VaultService();
  EducationCredential? _educationCredential;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _loadCredentials();
  }

  Future<void> _loadCredentials() async {
    try {
      await _vault.initializeDefaultIdentity();
      final educationCredential = await _vault.getEducationCredential();
      if (mounted) {
        setState(() {
          _educationCredential = educationCredential;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My credentials'),
        actions: [
          IconButton(
            tooltip: 'Refresh credentials',
            onPressed: _loadCredentials,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Add credential',
            onPressed: _openCredentialImport,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadCredentials,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const PrivacyMessage(
              message:
                  'Credentials stay encrypted on this device. You choose what facts to prove.',
            ),
            const SizedBox(height: 24),
            const Text(
              'CREDENTIALS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 10),
            CredentialCard(
              title: 'Age credential',
              issuer: 'Stored identity claim',
              status: CredentialStatus.valid,
              icon: Icons.cake_outlined,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const CredentialDetailScreen.age(),
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (_educationCredential != null)
              CredentialCard(
                title: _educationCredential!.degree,
                issuer: _educationCredential!.university,
                status: _educationCredential!.isValid
                    ? CredentialStatus.valid
                    : CredentialStatus.revoked,
                icon: Icons.school_outlined,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CredentialDetailScreen.education(
                      credential: _educationCredential!,
                    ),
                  ),
                ),
              )
            else if (_error != null)
              _WalletLoadError(onRetry: _loadCredentials)
            else
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(28),
                  child: CircularProgressIndicator(),
                ),
              ),
            const SizedBox(height: 24),
            SecondaryButton(
              label: 'Add credential',
              icon: Icons.qr_code_scanner,
              onPressed: _openCredentialImport,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCredentialImport() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const CredentialImportScreen()),
    );
    if (added == true) await _loadCredentials();
  }
}

class _WalletLoadError extends StatelessWidget {
  const _WalletLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(height: 8),
            const Text('Credentials could not be loaded on this device.'),
            const SizedBox(height: 12),
            TextButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
