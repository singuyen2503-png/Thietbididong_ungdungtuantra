import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:demo_app/core/utils/lat_lng.dart';
import 'package:demo_app/presentation/state/manager_state.dart';
import 'package:demo_app/presentation/widgets/tactical_map.dart';

void main() {
  testWidgets('Bản đồ hiển thị điểm tuần tra và trả tọa độ khi chạm',
      (tester) async {
    LatLng? tapped;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 400,
          height: 400,
          child: TacticalMap(
            checkpoints: seedCheckpoints,
            plannedPath: seedCheckpoints.map((c) => c.location).toList(),
            onTap: (p) => tapped = p,
          ),
        ),
      ),
    ));
    await tester.pump();

    expect(find.text('Nhà Kho'), findsOneWidget);
    expect(find.text('Hành Lang'), findsOneWidget);

    await tester.tapAt(const Offset(200, 200));
    await tester.pump(const Duration(milliseconds: 400));
    expect(tapped, isNotNull);
    expect(tapped!.latitude, closeTo(10.7771, 0.002));
    expect(tapped!.longitude, closeTo(106.7009, 0.002));
  });
}
