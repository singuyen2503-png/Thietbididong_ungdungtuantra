import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../domain/entities/models.dart';
import '../../state/manager_state.dart';
import '../../state/workforce_state.dart';
import '../../widgets/tactical_map.dart';
import 'route_drawing_screen.dart';

class RouteListScreen extends ConsumerWidget {
  const RouteListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routes = ref.watch(routeConfigsProvider);
    final schedules = ref.watch(schedulesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF151E2E),
        title: const Text('LỘ TRÌNH TUẦN TRA',
            style: TextStyle(
                color: Colors.purpleAccent, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.purpleAccent),
      ),
      body: routes.isEmpty
          ? const Center(
              child: Text('Chưa có lộ trình nào. Nhấn "VẼ LỘ TRÌNH" để tạo.',
                  style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: routes.length,
              itemBuilder: (context, index) {
                final route = routes[index];
                final inUse = schedules.any((s) =>
                    s.routeId == route.id &&
                    s.status != ScheduleStatus.completed);
                return Dismissible(
                  key: Key(route.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    decoration: BoxDecoration(
                        color: Colors.red.shade800,
                        borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (_) async {
                    if (inUse) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text(
                              'Lộ trình đang được dùng trong lịch tuần tra, không thể xóa!'),
                          backgroundColor: Colors.red));
                      return false;
                    }
                    return showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Xóa lộ trình?'),
                        content:
                            Text('Bạn chắc chắn muốn xóa "${route.name}"?'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('HỦY')),
                          TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('XÓA',
                                  style: TextStyle(color: Colors.redAccent))),
                        ],
                      ),
                    );
                  },
                  onDismissed: (_) {
                    HapticFeedback.heavyImpact();
                    ref
                        .read(routeConfigsProvider.notifier)
                        .deleteRoute(route.id);
                  },
                  child: Card(
                    color: const Color(0xFF151E2E),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const Icon(Icons.route,
                          color: Colors.purpleAccent, size: 32),
                      title: Text(route.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18)),
                      subtitle: Text(
                          '${route.checkpoints.length} điểm: ${route.checkpoints.map((c) => c.name).join(' → ')}',
                          style: const TextStyle(color: Colors.white70)),
                      trailing:
                          const Icon(Icons.qr_code_2, color: Colors.white70),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => RouteDetailScreen(route: route))),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const RouteDrawingScreen())),
        backgroundColor: Colors.purpleAccent,
        icon: const Icon(Icons.draw, color: Colors.black),
        label: const Text('VẼ LỘ TRÌNH',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class RouteDetailScreen extends ConsumerWidget {
  final RouteConfig route;
  const RouteDetailScreen({super.key, required this.route});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkpoints = route.checkpoints
        .map((c) => Checkpoint(
            id: c.id,
            name: c.name,
            expectedQrCode: c.expectedQrCode,
            location: c.location,
            radiusMeters: c.radiusMeters))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF151E2E),
        title: Text(route.name,
            style: const TextStyle(
                color: Colors.purpleAccent, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.purpleAccent),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            height: 260,
            decoration: BoxDecoration(
                color: const Color(0xFF05080D),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: TacticalMap(
                  siteTracks: ref.watch(siteTrackPointsProvider),
                  plannedPath: route.plannedPath,
                  checkpoints: checkpoints),
            ),
          ),
          const SizedBox(height: 16),
          const Text('MÃ QR TẠI CÁC ĐIỂM (in và dán đúng vị trí)',
              style:
                  TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...route.checkpoints.asMap().entries.map((e) {
            final cp = e.value;
            return Card(
              color: const Color(0xFF151E2E),
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(6),
                      child: QrImageView(
                          data: cp.expectedQrCode,
                          size: 110,
                          backgroundColor: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${e.key + 1}. ${cp.name}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18)),
                          const SizedBox(height: 6),
                          Text('Mã: ${cp.expectedQrCode}',
                              style: const TextStyle(color: Colors.white70)),
                          Text(
                              'GPS: ${cp.location.latitude.toStringAsFixed(5)}, ${cp.location.longitude.toStringAsFixed(5)}',
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 12)),
                          Text(
                              'Bán kính: ${cp.radiusMeters.toStringAsFixed(0)} m',
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
