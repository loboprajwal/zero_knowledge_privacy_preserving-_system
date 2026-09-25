import 'package:flutter/material.dart';

import '../models/education_credential.dart';
import '../widgets/wallet_components.dart';

class CredentialDetailScreen extends StatelessWidget {
  const CredentialDetailScreen.age({super.key})
    : credential = null,
      isAge = true;

  const CredentialDetailScreen.education({super.key, required this.credential})
    : isAge = false;

  final EducationCredential? credential;
  final bool isAge;

  @override
  Widget build(BuildContext context) {
    final title = isAge ? 'Age credential' : credential!.degree;
    final status = !isAge && !credential!.isValid
        ? CredentialStatus.revoked
        : CredentialStatus.valid;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    isAge
                        ? Icons.verified_user_outlined
                        : Icons.school_outlined,
                    color: Colors.green.shade700,
                    size: 40,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Credential status',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  StatusBadge(status: status),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _DetailRow(
            label: 'Issuer',
            value: isAge ? 'Stored identity claim' : credential!.university,
          ),
          _DetailRow(
            label: 'Credential ID',
            value: isAge ? 'Protected locally' : credential!.credentialId,
          ),
          _DetailRow(
            label: isAge ? 'Date of birth claim' : 'Qualification claim',
            value: isAge
                ? 'Protected — never shown in a proof'
                : 'Bachelor-level credential',
          ),
          if (!isAge)
            _DetailRow(
              label: 'Graduation year',
              value: credential!.graduationYear.toString(),
            ),
          const SizedBox(height: 20),
          const PrivacyMessage(
            message:
                'Raw claims are not shown here. Proof generation reveals only the requested fact.',
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: TextStyle(color: Colors.grey.shade700)),
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
}
