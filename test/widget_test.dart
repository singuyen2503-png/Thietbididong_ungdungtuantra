import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:demo_app/main.dart';
import 'package:demo_app/presentation/features/auth/login_screen.dart';

void main() {
  testWidgets('PatrolApp khởi động vào màn hình đăng nhập',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: PatrolApp()));
    await tester.pump();

    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
