import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:demo_app/presentation/features/patrol/patrol_active_screen.dart';
import 'package:demo_app/presentation/state/manager_state.dart';

void main() {
  testWidgets('Tải điểm tuần tra từ ca trực và khóa quét khi ở xa',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ProviderScope(
      overrides: [currentGuardIdProvider.overrideWith((ref) => 'p1')],
      child: const MaterialApp(home: PatrolActiveScreen()),
    ));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Nhà Kho'), findsOneWidget);
    expect(find.text('Nhà Xe'), findsOneWidget);
    expect(find.text('Hành Lang'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('QUÁ XA ĐỂ QUÉT'), findsWidgets);

    await tester.tap(find.text('QUÁ XA ĐỂ QUÉT').first);
    await tester.pump();
    expect(find.text('BẠN ĐANG Ở QUÁ XA MỤC TIÊU! KHÔNG THỂ QUÉT.'),
        findsOneWidget);

    for (int i = 0; i < 30; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    expect(find.text('MỞ CAMERA QUÉT QR'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  });
}
