import 'package:flutter/material.dart';

import '../core/vault_service.dart';
import '../models/education_credential.dart';
import '../widgets/qr_scanner_view.dart';
import '../widgets/wallet_components.dart';

/// Imports an issuer-provided education credential into the existing vault.
/// The accepted QR payload is an `education_credential` offer, not a proof.
class CredentialImportScreen extends StatefulWidget {
  const CredentialImportScreen({super.key});

  @override
  State<CredentialImportScreen> createState() => _CredentialImportScreenState();
}

class _CredentialImportScreenState extends State<CredentialImportScreen> {
  final VaultService _vault = VaultService();
  final TextEditingController _issuerLinkController = TextEditingController();

  bool _isScanning = false;
  bool _showManualLink = false;
  bool _isSaving = false;
  EducationCredential? _offer;

  @override
  void dispose() {
    _issuerLinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isScanning) {
      return Scaffold(
        body: QrScannerView(
          onScanned: _readCredentialOffer,
          onClose: () => setState(() => _isScanning = false),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_offer == null ? 'Add credential' : 'Credential received'),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: _goBack,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _offer != null
              ? _acceptanceView(_offer!)
              : _showManualLink
              ? _manualLinkView()
              : _importChoiceView(),
        ),
      ),
    );
  }

  Widget _importChoiceView() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text(
        'Add a credential from a trusted issuer. It is encrypted and stored only on this device.',
        style: TextStyle(height: 1.45, color: Color(0xFF62616A)),
      ),
      const SizedBox(height: 24),
      _ImportOption(
        icon: Icons.qr_code_scanner,
        title: 'Scan credential QR',
        subtitle: 'Scan an issuer-provided education credential offer.',
        onTap: () => setState(() => _isScanning = true),
      ),
      const SizedBox(height: 12),
      _ImportOption(
        icon: Icons.link_outlined,
        title: 'Use issuer link',
        subtitle: 'Start a credential request with an issuer link.',
        onTap: () => setState(() => _showManualLink = true),
      ),
      const SizedBox(height: 24),
      const PrivacyMessage(
        message:
            'Only credential offers are accepted here. Shared ZK proofs cannot be imported as credentials.',
      ),
    ],
  );

  Widget _manualLinkView() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text(
        'Issuer link',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 10),
      const Text(
        'Paste a credential-request link from a trusted issuer.',
        style: TextStyle(height: 1.45, color: Color(0xFF62616A)),
      ),
      const SizedBox(height: 24),
      TextField(
        controller: _issuerLinkController,
        keyboardType: TextInputType.url,
        decoration: const InputDecoration(
          labelText: 'Issuer link',
          hintText: 'https://issuer.example/credential-request',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 12),
      const PrivacyMessage(
        message:
            'Issuer-link retrieval is not configured in this offline build. No link is opened or transmitted. Scan the issuer credential QR instead.',
      ),
      const Spacer(),
      SecondaryButton(
        label: 'Scan credential QR instead',
        icon: Icons.qr_code_scanner,
        onPressed: () => setState(() {
          _showManualLink = false;
          _isScanning = true;
        }),
      ),
    ],
  );

  Widget _acceptanceView(EducationCredential offer) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Icon(
        Icons.mark_email_read_outlined,
        size: 58,
        color: Color(0xFF26215C),
      ),
      const SizedBox(height: 16),
      const Text(
        'Review credential',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 8),
      const Text(
        'Confirm that the issuer and qualification are correct before saving.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xFF62616A), height: 1.4),
      ),
      const SizedBox(height: 24),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(child: Icon(Icons.school_outlined)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      offer.degree,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  StatusBadge(
                    status: offer.isValid
                        ? CredentialStatus.valid
                        : CredentialStatus.revoked,
                  ),
                ],
              ),
              const Divider(height: 28),
              _OfferDetail(label: 'Issuer', value: offer.university),
              _OfferDetail(label: 'Credential ID', value: offer.credentialId),
              _OfferDetail(
                label: 'Graduation year',
                value: offer.graduationYear.toString(),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      const PrivacyMessage(
        message:
            'Saving this replaces the existing education credential in this local wallet. It does not share any data with the issuer.',
      ),
      const Spacer(),
      PrimaryButton(
        label: _isSaving ? 'Saving credential…' : 'Accept and store',
        icon: Icons.lock_outline,
        onPressed: _isSaving ? null : () => _acceptOffer(offer),
      ),
      const SizedBox(height: 10),
      SecondaryButton(label: 'Decline', onPressed: _declineOffer),
    ],
  );

  void _readCredentialOffer(String rawOffer) {
    try {
      final offer = EducationCredential.fromOfferJson(rawOffer);
      setState(() {
        _isScanning = false;
        _offer = offer;
      });
    } on FormatException catch (error) {
      setState(() => _isScanning = false);
      _showMessage(error.message);
    }
  }

  Future<void> _acceptOffer(EducationCredential offer) async {
    setState(() => _isSaving = true);
    try {
      await _vault.updateEducationCredential(offer);
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted)
        _showMessage(
          'Credential could not be saved on this device. Please try again.',
        );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _declineOffer() {
    setState(() => _offer = null);
    _showMessage('Credential offer declined. Nothing was saved.');
  }

  void _goBack() {
    if (_offer != null) {
      setState(() => _offer = null);
    } else if (_showManualLink) {
      setState(() => _showManualLink = false);
    } else {
      Navigator.of(context).pop(false);
    }
  }

  void _showMessage(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
}

class _ImportOption extends StatelessWidget {
  const _ImportOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(child: Icon(icon)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
    ),
  );
}

class _OfferDetail extends StatelessWidget {
  const _OfferDetail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: Color(0xFF62616A))),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}
