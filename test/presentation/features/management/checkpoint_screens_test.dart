import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:demo_app/presentation/features/management/checkpoint_editor_screen.dart';
import 'package:demo_app/presentation/features/management/checkpoints_screen.dart';
import 'package:demo_app/presentation/features/management/qr_code_screen.dart';
import 'package:demo_app/presentation/state/manager_state.dart';
import 'package:demo_app/presentation/widgets/tactical_map.dart';

void main() {
  Future<ProviderContainer> pump(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: c, child: MaterialApp(home: home)));
    await tester.pump();
    return c;
  }

  testWidgets('Thêm địa điểm mới: chọn vị trí, tự sinh mã QR', (tester) async {
    final c = await pump(tester, const CheckpointEditorScreen(routeId: 'r1'));
    expect(find.text('THÊM ĐỊA ĐIỂM'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('cp-name')), 'Cổng Sau');
    await tester.pump();
    expect(
        tester
            .widget<TextField>(find.byKey(const Key('cp-qr')))
            .controller!
            .text,
        'cổng sau');

    await tester.scrollUntilVisible(find.text('LƯU ĐỊA ĐIỂM'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('LƯU ĐỊA ĐIỂM'));
    await tester.pump();
    expect(find.text('Chạm vào bản đồ hoặc dùng GPS để chọn vị trí!'),
        findsOneWidget);
    expect(c.read(routeConfigsProvider).first.checkpoints.length, 3);
    ScaffoldMessenger.of(tester.element(find.byType(ListView)))
        .clearSnackBars();
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.byType(TacticalMap), -200,
        scrollable: find.byType(Scrollable).first);
    await tester.tapAt(tester.getCenter(find.byType(TacticalMap)));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('Vị trí: 10.77'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('LƯU ĐỊA ĐIỂM'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('LƯU ĐỊA ĐIỂM'));
    await tester.pump();

    final points = c.read(routeConfigsProvider).first.checkpoints;
    expect(points.length, 4);
    expect(points.last.name, 'Cổng Sau');
    expect(points.last.expectedQrCode, 'cổng sau');
  });

  testWidgets('Danh sách địa điểm mở mã QR lớn và xóa địa điểm',
      (tester) async {
    final c = await pump(tester, const CheckpointsScreen());
    expect(find.text('ĐỊA ĐIỂM & MÃ QR'), findsOneWidget);
    expect(find.text('Mã: nhà xe • 15 m'), findsOneWidget);

    await tester.tap(find.text('Nhà Xe'));
    await tester.pumpAndSettle();
    expect(find.byType(QrCodeScreen), findsOneWidget);
    expect(find.text('NHÀ XE'), findsOneWidget);
    expect(find.text('Nội dung mã: nhà xe'), findsOneWidget);
    expect(find.text('CHIA SẺ / IN MÃ QR'), findsOneWidget);

    await tester.tap(find.byTooltip('Xóa địa điểm'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('XÓA'));
    await tester.pumpAndSettle();
    expect(c.read(routeConfigsProvider).first.checkpoints.map((p) => p.name),
        ['Nhà Kho', 'Hành Lang']);
    expect(find.text('Mã: nhà xe • 15 m'), findsNothing);
  });
}
