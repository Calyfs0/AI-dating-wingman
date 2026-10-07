import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wingman/core/di/service_locator.dart';
import 'package:wingman/app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await getIt.reset();
    await configureDependencies();
  });

  testWidgets('Wingman boots to splash', (tester) async {
    await tester.pumpWidget(const WingmanApp());
    await tester.pump();
    expect(find.text('Wingman'), findsWidgets);
    expect(find.textContaining('private AI dating coach'), findsOneWidget);
    // Advance splash animation + short handoff delay, then settle.
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
  });
}
