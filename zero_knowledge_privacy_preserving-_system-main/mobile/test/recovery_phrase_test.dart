import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/recovery_phrase.dart';

void main() {
  group('RecoveryPhrase', () {
    test('generates a 12-word phrase with the expected word format', () {
      final phrase = RecoveryPhrase.generate();

      expect(phrase.words, hasLength(RecoveryPhrase.wordCount));
      expect(
        phrase.words.every((word) => RegExp(r'^[a-z]{6}$').hasMatch(word)),
        isTrue,
      );
    });

    test('normalizes whitespace and derives a stable proof secret', () {
      const value =
          'baceba cadaca dadefa fagaha hajaka kalama manapa paqara rasata tavava waxaya zavaza';

      final first = RecoveryPhrase.parse(value);
      final second = RecoveryPhrase.parse('  $value  ');

      expect(second.value, value);
      expect(second.deriveProofSecret(), first.deriveProofSecret());
    });

    test('rejects a phrase that is not exactly 12 valid words', () {
      expect(
        () => RecoveryPhrase.parse('one two three'),
        throwsFormatException,
      );
    });
  });
}
