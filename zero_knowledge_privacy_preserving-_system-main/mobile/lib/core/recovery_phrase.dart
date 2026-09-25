import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// App-specific recovery phrase for restoring the local proof-secret seed.
///
/// This is intentionally not represented as a BIP-39 phrase because this
/// application does not implement an interoperable cryptocurrency wallet.
class RecoveryPhrase {
  const RecoveryPhrase._(this.words);

  final List<String> words;

  static const wordCount = 12;
  static const _consonants = 'bcdfghjklmnpqrstvwxz';
  static const _vowels = 'aeiou';

  factory RecoveryPhrase.generate() {
    final random = Random.secure();
    return RecoveryPhrase._(
      List<String>.generate(
        wordCount,
        (_) => _randomWord(random),
        growable: false,
      ),
    );
  }

  factory RecoveryPhrase.parse(String value) {
    final words = value
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList(growable: false);
    if (words.length != wordCount ||
        words.any((word) => !RegExp(r'^[a-z]{6}$').hasMatch(word))) {
      throw const FormatException('Enter all 12 recovery words.');
    }
    return RecoveryPhrase._(words);
  }

  String get value => words.join(' ');

  /// Derives a stable, device-independent proof-secret seed from this phrase.
  /// The phrase itself is not retained after setup or restore.
  String deriveProofSecret() => sha256.convert(utf8.encode(value)).toString();

  static String _randomWord(Random random) {
    String pick(String characters) =>
        characters[random.nextInt(characters.length)];
    return '${pick(_consonants)}${pick(_vowels)}${pick(_consonants)}${pick(_vowels)}${pick(_consonants)}${pick(_vowels)}';
  }
}
