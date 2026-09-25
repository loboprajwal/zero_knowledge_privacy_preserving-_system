import 'package:flutter/material.dart';

import '../widgets/wallet_components.dart';
import 'cached_proofs_screen.dart';
import 'proof_consent_screen.dart';
import 'verifier_screen.dart';

class ProofHomeScreen extends StatelessWidget {
  const ProofHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prove a fact')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Select what you would like to prove. Only the required fact is shared.',
            style: TextStyle(color: Color(0xFF62616A)),
          ),
          const SizedBox(height: 20),
          _ProofOption(
            title: 'Age ≥ 18',
            description:
                'Uses your age credential without revealing your date of birth.',
            icon: Icons.cake_outlined,
            onTap: () => _openConsent(context, 'age'),
          ),
          const SizedBox(height: 12),
          _ProofOption(
            title: 'Bachelor\'s degree',
            description:
                'Uses your existing education credential without disclosing raw claims.',
            icon: Icons.school_outlined,
            onTap: () => _openConsent(context, 'education'),
          ),
          const SizedBox(height: 24),
          const PrivacyMessage(
            message:
                'Proof computation occurs locally. A proof request must be bound to a fresh verifier nonce.',
          ),
          const SizedBox(height: 24),
          SecondaryButton(
            label: 'View cached proofs',
            icon: Icons.history,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const CachedProofsScreen(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SecondaryButton(
            label: 'Open verifier mode',
            icon: Icons.verified_outlined,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const VerifierScreen()),
            ),
          ),
        ],
      ),
    );
  }

  void _openConsent(BuildContext context, String type) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProofConsentScreen(proofType: type),
      ),
    );
  }
}

class _ProofOption extends StatelessWidget {
  const _ProofOption({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(child: Icon(icon)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward),
            ],
          ),
        ),
      ),
    );
  }
}
