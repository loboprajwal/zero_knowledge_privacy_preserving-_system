import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets('zk-MatchID App renders navigation tabs smoke test',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ZkMatchIdApp());

    expect(find.text('Vault'), findsOneWidget);
    expect(find.text('Prover'), findsOneWidget);
    expect(find.text('Verifier'), findsOneWidget);
    expect(find.text('Benchmark'), findsOneWidget);
  });
}
