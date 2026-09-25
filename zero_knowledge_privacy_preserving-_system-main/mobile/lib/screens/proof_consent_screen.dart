import 'package:flutter/material.dart';

import '../widgets/wallet_components.dart';
import 'face_verification_screen.dart';

class ProofConsentScreen extends StatelessWidget {
  const ProofConsentScreen({super.key, required this.proofType});

  final String proofType;

  bool get _isEducation => proofType == 'education';

  @override
  Widget build(BuildContext context) {
    final statement = _isEducation
        ? "I hold a bachelor's degree"
        : 'I am 18 years or older';
    return Scaffold(
      appBar: AppBar(title: const Text('Proof consent')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(Icons.privacy_tip_outlined, size: 44),
          const SizedBox(height: 14),
          Text(
            'Confirm what you share',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          _DisclosureCard(
            title: 'Will be revealed',
            color: const Color(0xFFEAF3DE),
            icon: Icons.check_circle_outline,
            lines: [statement],
          ),
          const SizedBox(height: 12),
          const _DisclosureCard(
            title: 'Will not be revealed',
            color: Color(0xFFF3F1FF),
            icon: Icons.visibility_off_outlined,
            lines: [
              'Exact date of birth',
              'Name, address, or Aadhaar number',
              'Full education credential or proof witness',
            ],
          ),
          const SizedBox(height: 20),
          const PrivacyMessage(
            message:
                'The proof is calculated on this device and bound to one verifier request. It expires shortly after creation.',
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'I consent — continue',
            icon: Icons.arrow_forward,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => FaceVerificationScreen(proofType: proofType),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SecondaryButton(
            label: 'Cancel',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _DisclosureCard extends StatelessWidget {
  const _DisclosureCard({
    required this.title,
    required this.color,
    required this.icon,
    required this.lines,
  });

  final String title;
  final Color color;
  final IconData icon;
  final List<String> lines;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 10),
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text('• $line'),
          ),
      ],
    ),
  );
}
