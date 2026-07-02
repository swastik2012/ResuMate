import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resume_builder/main.dart';
import 'package:resume_builder/features/auth/presentation/login_screen.dart';
import 'package:resume_builder/features/home/presentation/home_screen.dart';

void main() {
  testWidgets('Test sign in with mock fallback and guest mode', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(),
      ),
    );

    // Let the initial stream subscription event fire and rebuild
    await tester.pump();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Try Demo Account'), findsOneWidget);

    // Click on the Try Demo Account button
    await tester.tap(find.text('Try Demo Account'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
