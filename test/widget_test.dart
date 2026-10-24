import 'package:flutter_test/flutter_test.dart';
import 'package:freedatadiet_mobile/main.dart';
import 'package:freedatadiet_mobile/models/user_settings.dart';

void main() {
  testWidgets('FreeDataDietApp smoke test', (WidgetTester tester) async {
    const settings = UserSettings();
    await tester.pumpWidget(const FreeDataDietApp(initialSettings: settings));
    expect(find.byType(FreeDataDietApp), findsOneWidget);
  });
}
