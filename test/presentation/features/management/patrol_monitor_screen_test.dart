import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:demo_app/presentation/features/management/patrol_monitor_screen.dart';
import 'package:demo_app/presentation/state/manager_state.dart';

void main() {
  Future<ProviderContainer> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: PatrolMonitorScreen())));
    return container;
  }

  testWidgets('Hiển thị tiến độ ca đang đi tuần', (tester) async {
    await open(tester);
    expect(find.text('Lê Văn C'), findsOneWidget);
    expect(find.textContaining('Đã quét 1/3 điểm'), findsOneWidget);
    expect(find.text('Điểm kế tiếp: Nhà Xe'), findsOneWidget);
    expect(find.text('Nguyễn Văn A'), findsNothing);
  });

  testWidgets('Không có ca nào đang đi tuần', (tester) async {
    final container = await open(tester);
    container
        .read(schedulesProvider.notifier)
        .deleteSchedule('r${DateTime.now().weekday - 1}-p3');
    await tester.pump();
    expect(find.text('Hiện không có ca tuần tra nào đang diễn ra.'),
        findsOneWidget);
  });
}
