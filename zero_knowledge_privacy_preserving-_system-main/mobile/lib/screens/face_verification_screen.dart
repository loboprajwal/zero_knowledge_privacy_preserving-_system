import 'package:flutter/material.dart';

import '../widgets/wallet_components.dart';
import 'prover_screen.dart';

/// An explicit, truthful status screen. This app has no liveness provider, so
/// it must never claim that a face check or face binding occurred.
class FaceVerificationScreen extends StatelessWidget {
  const FaceVerificationScreen({super.key, required this.proofType});

  final String proofType;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Face verification')),
    body: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          const Icon(Icons.face_retouching_off_outlined, size: 68),
          const SizedBox(height: 18),
          Text(
            'Face attestation is unavailable',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'No face or liveness provider is configured in this build. Continuing generates only the selected zero-knowledge credential proof; it does not include, send, or claim a face match.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          const PrivacyMessage(
            message: 'Face data is not captured or retained by this flow.',
          ),
          const Spacer(),
          PrimaryButton(
            label: 'Continue without face attestation',
            icon: Icons.arrow_forward,
            onPressed: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) =>
                    ProverScreen(initialVerificationType: proofType),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SecondaryButton(
            label: 'Back',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    ),
  );
}
