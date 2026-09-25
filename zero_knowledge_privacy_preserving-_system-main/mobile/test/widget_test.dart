import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';
import 'package:mobile/screens/credential_import_screen.dart';
import 'package:mobile/screens/proof_home_screen.dart';
import 'package:mobile/screens/verifier_screen.dart';

void main() {
  testWidgets('zk-MatchID starts with wallet onboarding', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ZkMatchIdApp());
    await tester.pump();

    expect(find.text('Welcome to zk-MatchID'), findsOneWidget);
    expect(find.text('Create new wallet'), findsOneWidget);
    expect(find.text('Restore from backup'), findsOneWidget);
  });

  testWidgets('Phase 1 navigation renders its core tabs', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: MainNavigationScreen()));

    expect(find.text('Wallet'), findsOneWidget);
    expect(find.text('Prove'), findsOneWidget);
    expect(find.text('Activity'), findsOneWidget);
    expect(find.text('Settings'), findsWidgets);
  });

  testWidgets('Phase 1 navigation opens Prove, Activity, and Settings', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: MainNavigationScreen()));

    await tester.tap(find.text('Prove'));
    await tester.pump();
    expect(find.text('Prove a fact'), findsOneWidget);

    await tester.tap(find.text('Activity'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Activity'), findsWidgets);

    await tester.tap(find.text('Settings'));
    await tester.pump();
    expect(find.text('Settings'), findsWidgets);
    expect(find.text('Verifier mode'), findsOneWidget);
  });

  testWidgets('credential import offers QR and offline issuer-link paths', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: CredentialImportScreen()));

    expect(find.text('Scan credential QR'), findsOneWidget);
    expect(find.text('Use issuer link'), findsOneWidget);

    await tester.tap(find.text('Use issuer link'));
    await tester.pump();

    expect(find.text('Issuer link'), findsWidgets);
    expect(find.text('Scan credential QR instead'), findsOneWidget);
  });

  testWidgets('proof flow requires consent and declares face status', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ProofHomeScreen()));

    await tester.tap(find.text('Age ≥ 18'));
    await tester.pumpAndSettle();
    expect(find.text('Proof consent'), findsOneWidget);
    expect(find.text('Will not be revealed'), findsOneWidget);

    await tester.tap(find.text('I consent — continue'));
    await tester.pumpAndSettle();
    expect(find.text('Face attestation is unavailable'), findsOneWidget);
    expect(find.text('Continue without face attestation'), findsOneWidget);
  });

  testWidgets('verifier builds an age request', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: VerifierScreen()));
    await tester.pump();

    expect(find.text('BUILD A VERIFICATION REQUEST'), findsOneWidget);
    expect(find.text('Age ≥ 18'), findsOneWidget);
    expect(find.text('Scan proof QR'), findsOneWidget);
  });
}
