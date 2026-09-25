import 'package:flutter/material.dart';

import '../core/recovery_phrase.dart';
import '../core/vault_service.dart';
import '../widgets/wallet_components.dart';

enum _OnboardingStep {
  welcome,
  phone,
  otp,
  face,
  walletDetails,
  backup,
  confirmBackup,
  restore,
}

/// Wallet setup UI. Phone and liveness binding remain explicitly unavailable
/// until a real provider and liveness implementation are integrated.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final VaultService _vault = VaultService();
  final _phoneController = TextEditingController();
  final _walletNameController = TextEditingController();
  final _restoreController = TextEditingController();
  final _firstCheckController = TextEditingController();
  final _secondCheckController = TextEditingController();
  final _thirdCheckController = TextEditingController();

  _OnboardingStep _step = _OnboardingStep.welcome;
  RecoveryPhrase? _recoveryPhrase;
  bool _saving = false;
  bool _skippedPhoneVerification = false;

  static const _checkIndexes = [1, 5, 9];

  @override
  void dispose() {
    _phoneController.dispose();
    _walletNameController.dispose();
    _restoreController.dispose();
    _firstCheckController.dispose();
    _secondCheckController.dispose();
    _thirdCheckController.dispose();
    super.dispose();
  }

  void _goTo(_OnboardingStep step) => setState(() => _step = step);

  void _beginCreateFlow() {
    _recoveryPhrase = RecoveryPhrase.generate();
    _skippedPhoneVerification = false;
    _goTo(_OnboardingStep.phone);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _step == _OnboardingStep.welcome
          ? null
          : AppBar(
              leading: IconButton(
                tooltip: 'Back',
                onPressed: _saving ? null : _goBack,
                icon: const Icon(Icons.arrow_back),
              ),
              title: const Text('Set up your wallet'),
            ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: switch (_step) {
            _OnboardingStep.welcome => _welcome(),
            _OnboardingStep.phone => _phone(),
            _OnboardingStep.otp => _otp(),
            _OnboardingStep.face => _face(),
            _OnboardingStep.walletDetails => _walletDetails(),
            _OnboardingStep.backup => _backup(),
            _OnboardingStep.confirmBackup => _confirmBackup(),
            _OnboardingStep.restore => _restore(),
          },
        ),
      ),
    );
  }

  Widget _welcome() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Spacer(),
      const Icon(
        Icons.verified_user_outlined,
        size: 76,
        color: Color(0xFF26215C),
      ),
      const SizedBox(height: 24),
      const Text(
        'Welcome to zk-MatchID',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 12),
      const Text(
        'Create a wallet to keep credentials and proof witnesses on this device.',
        textAlign: TextAlign.center,
        style: TextStyle(height: 1.45, color: Color(0xFF62616A)),
      ),
      const Spacer(),
      PrimaryButton(
        label: 'Create new wallet',
        icon: Icons.add,
        onPressed: _beginCreateFlow,
      ),
      const SizedBox(height: 12),
      SecondaryButton(
        label: 'Restore from backup',
        icon: Icons.restore,
        onPressed: () => _goTo(_OnboardingStep.restore),
      ),
      const SizedBox(height: 16),
      TextButton(
        onPressed: _showWhatIsWallet,
        child: const Text('What is a wallet?'),
      ),
    ],
  );

  Widget _phone() => _StepLayout(
    title: 'Link a phone number',
    description:
        'A verified number can be used for account recovery and future proof binding.',
    child: Column(
      children: [
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Phone number',
            hintText: '+91 98765 43210',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        const PrivacyMessage(
          message:
              'Phone verification is not configured in this offline build. Your number will not be stored or marked as verified.',
        ),
      ],
    ),
    primaryLabel: 'Continue to verification',
    onPrimary: _continueToOtp,
    secondaryLabel: 'Set up without a phone',
    onSecondary: () {
      _skippedPhoneVerification = true;
      _goTo(_OnboardingStep.face);
    },
  );

  Widget _otp() => _StepLayout(
    title: 'Verify your number',
    description: 'Enter the one-time code sent to your phone.',
    child: const Column(
      children: [
        TextField(
          enabled: false,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'One-time code',
            hintText: 'OTP verification unavailable',
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 12),
        PrivacyMessage(
          message:
              'No SMS or OTP service is connected to this build, so a phone number cannot be verified. No code is generated or accepted.',
        ),
      ],
    ),
    primaryLabel: 'Continue without verification',
    onPrimary: () => _goTo(_OnboardingStep.face),
    secondaryLabel: 'Change phone number',
    onSecondary: () => _goTo(_OnboardingStep.phone),
  );

  Widget _face() => _StepLayout(
    title: 'Face binding',
    description:
        'Optionally bind live-face verification to sensitive proof requests.',
    child: const Column(
      children: [
        _UnavailableCameraArea(),
        SizedBox(height: 12),
        PrivacyMessage(
          message:
              'Live face capture and liveness checks are not configured in this build. No biometric information is captured or stored.',
        ),
      ],
    ),
    primaryLabel: 'Continue without face binding',
    onPrimary: () => _goTo(_OnboardingStep.walletDetails),
  );

  Widget _walletDetails() => _StepLayout(
    title: 'Name your wallet',
    description: 'Choose a local label for this wallet on this device.',
    child: TextField(
      controller: _walletNameController,
      textCapitalization: TextCapitalization.words,
      maxLength: 40,
      decoration: const InputDecoration(
        labelText: 'Wallet name',
        hintText: 'My identity wallet',
        border: OutlineInputBorder(),
      ),
    ),
    primaryLabel: 'Create backup phrase',
    onPrimary: _continueToBackup,
  );

  Widget _backup() {
    final phrase = _recoveryPhrase;
    if (phrase == null) return const SizedBox.shrink();
    return _StepLayout(
      title: 'Secure your wallet',
      description:
          'Write down these 12 words in order. They are shown once and are never stored by the app.',
      child: Column(
        children: [
          _WordGrid(words: phrase.words),
          const SizedBox(height: 16),
          const PrivacyMessage(
            message:
                'Keep this phrase private. Anyone with it can restore the wallet proof secret.',
          ),
        ],
      ),
      primaryLabel: "I've saved it",
      onPrimary: () => _goTo(_OnboardingStep.confirmBackup),
    );
  }

  Widget _confirmBackup() {
    final phrase = _recoveryPhrase;
    if (phrase == null) return const SizedBox.shrink();
    final controllers = [
      _firstCheckController,
      _secondCheckController,
      _thirdCheckController,
    ];
    return _StepLayout(
      title: 'Confirm your backup',
      description:
          'Enter the requested words to confirm that your recovery phrase was saved.',
      child: Column(
        children: List<Widget>.generate(_checkIndexes.length, (index) {
          final wordNumber = _checkIndexes[index] + 1;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextField(
              controller: controllers[index],
              autocorrect: false,
              textCapitalization: TextCapitalization.none,
              decoration: InputDecoration(
                labelText: 'Word $wordNumber',
                border: const OutlineInputBorder(),
              ),
            ),
          );
        }),
      ),
      primaryLabel: 'Verify and create wallet',
      onPrimary: _saving ? null : () => _createWallet(phrase),
    );
  }

  Widget _restore() => _StepLayout(
    title: 'Restore wallet',
    description:
        'Enter your 12-word recovery phrase. It is used only to derive the local proof secret.',
    child: Column(
      children: [
        TextField(
          controller: _walletNameController,
          maxLength: 40,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Wallet name',
            hintText: 'Restored wallet',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _restoreController,
          minLines: 3,
          maxLines: 5,
          autocorrect: false,
          textCapitalization: TextCapitalization.none,
          decoration: const InputDecoration(
            labelText: 'Recovery phrase',
            hintText: 'Enter all 12 words separated by spaces',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        const PrivacyMessage(
          message:
              'Credentials remain device-local and must be re-imported from their issuers after restoring.',
        ),
      ],
    ),
    primaryLabel: 'Restore wallet',
    onPrimary: _saving ? null : _restoreWallet,
  );

  void _continueToOtp() {
    if (_phoneController.text.trim().isEmpty) {
      _showError('Enter a phone number or choose “Set up without a phone”.');
      return;
    }
    _skippedPhoneVerification = false;
    _goTo(_OnboardingStep.otp);
  }

  void _continueToBackup() {
    if (_walletNameController.text.trim().isEmpty) {
      _showError('Give this wallet a name first.');
      return;
    }
    _goTo(_OnboardingStep.backup);
  }

  Future<void> _createWallet(RecoveryPhrase phrase) async {
    final entries = [
      _firstCheckController.text,
      _secondCheckController.text,
      _thirdCheckController.text,
    ];
    final matches = List<bool>.generate(
      entries.length,
      (index) =>
          entries[index].trim().toLowerCase() ==
          phrase.words[_checkIndexes[index]],
    );
    if (matches.any((match) => !match)) {
      _showError(
        'The recovery words do not match. Check the phrase and try again.',
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await _vault.createWallet(
        walletName: _walletNameController.text,
        recoveryPhrase: phrase,
      );
      if (mounted) widget.onComplete();
    } catch (error) {
      debugPrint('Wallet creation failed: $error');
      if (mounted) {
        _showError(
          'Wallet secure storage could not be initialized. Please reopen the app and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _restoreWallet() async {
    try {
      final phrase = RecoveryPhrase.parse(_restoreController.text);
      setState(() => _saving = true);
      await _vault.restoreWallet(
        recoveryPhrase: phrase,
        walletName: _walletNameController.text.trim().isEmpty
            ? 'Restored wallet'
            : _walletNameController.text,
      );
      if (mounted) widget.onComplete();
    } on FormatException catch (error) {
      _showError(error.message);
    } catch (error) {
      debugPrint('Wallet restoration failed: $error');
      if (mounted) {
        _showError(
          'Wallet secure storage could not be initialized. Please reopen the app and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _goBack() {
    switch (_step) {
      case _OnboardingStep.welcome:
        return;
      case _OnboardingStep.phone:
      case _OnboardingStep.restore:
        _goTo(_OnboardingStep.welcome);
      case _OnboardingStep.otp:
        _goTo(_OnboardingStep.phone);
      case _OnboardingStep.face:
        _goTo(
          _skippedPhoneVerification
              ? _OnboardingStep.phone
              : _OnboardingStep.otp,
        );
      case _OnboardingStep.walletDetails:
        _goTo(_OnboardingStep.face);
      case _OnboardingStep.backup:
        _goTo(_OnboardingStep.walletDetails);
      case _OnboardingStep.confirmBackup:
        _goTo(_OnboardingStep.backup);
    }
  }

  void _showWhatIsWallet() => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('What is a wallet?'),
      content: const Text(
        'Your wallet keeps identity credentials and the secret material used for local proof generation on this device. It only shares the fact you choose to prove.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Got it'),
        ),
      ],
    ),
  );

  void _showError(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
}

class _StepLayout extends StatelessWidget {
  const _StepLayout({
    required this.title,
    required this.description,
    required this.child,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String title;
  final String description;
  final Widget child;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: 24),
      Text(
        title,
        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 10),
      Text(
        description,
        style: const TextStyle(height: 1.45, color: Color(0xFF62616A)),
      ),
      const SizedBox(height: 28),
      child,
      const Spacer(),
      PrimaryButton(label: primaryLabel, onPressed: onPrimary),
      if (secondaryLabel != null) ...[
        const SizedBox(height: 10),
        SecondaryButton(label: secondaryLabel!, onPressed: onSecondary),
      ],
    ],
  );
}

class _WordGrid extends StatelessWidget {
  const _WordGrid({required this.words});

  final List<String> words;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFF4F3FA),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List<Widget>.generate(
        words.length,
        (index) => Chip(label: Text('${index + 1}. ${words[index]}')),
      ),
    ),
  );
}

class _UnavailableCameraArea extends StatelessWidget {
  const _UnavailableCameraArea();

  @override
  Widget build(BuildContext context) => Container(
    height: 180,
    width: double.infinity,
    decoration: BoxDecoration(
      color: const Color(0xFFF4F3FA),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFD7D6E7)),
    ),
    child: const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.camera_alt_outlined, color: Color(0xFF62616A), size: 34),
        SizedBox(height: 8),
        Text(
          'Camera unavailable',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}
