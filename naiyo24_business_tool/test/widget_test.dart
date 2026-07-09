import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:naiyo24_business_tool/providers/shared_prefs_provider.dart';

import 'package:naiyo24_business_tool/app_shell.dart';

void main() {
  testWidgets('App shell smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final sharedPrefs = await SharedPreferences.getInstance();

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPrefsProvider.overrideWithValue(sharedPrefs),
        ],
        child: const AppShell(),
      ),
    );

    // Verify that the app loads without errors
    expect(find.byType(AppShell), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });
}
