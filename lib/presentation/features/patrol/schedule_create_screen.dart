import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/manager_state.dart';
import '../../../domain/entities/models.dart';
import '../../../domain/entities/equipment.dart';

class ScheduleCreateScreen extends ConsumerStatefulWidget {
  const ScheduleCreateScreen({super.key});
  @override
  ConsumerState<ScheduleCreateScreen> createState() =>
      _ScheduleCreateScreenState();
}

class _ScheduleCreateScreenState extends ConsumerState<ScheduleCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  Personnel? _selectedGuard;
  RouteConfig? _selectedRoute;
  final List<Equipment> _selectedEquipments = [];
  final _startCtrl = TextEditingController(text: '06:00');
  final _endCtrl = TextEditingController(text: '14:00');

  @override
  void dispose() {
    _startCtrl.dispose();
    _endCtrl.dispose();
    super.dispose();
  }

  DateTime? _parseTime(String text) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(text.trim());
    if (match == null) return null;
    final h = int.parse(match.group(1)!), m = int.parse(match.group(2)!);
    if (h > 23 || m > 59) return null;
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, h, m);
  }

  @override
  Widget build(BuildContext context) {
    final guards =
        ref.watch(personnelProvider).where((p) => p.role == 'Bảo vệ').toList();
    final availableEquipments = ref
        .watch(equipmentProvider)
        .where((e) => e.status == EquipmentStatus.available)
        .toList();
    final routes = ref.watch(routeConfigsProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        title: const Text('TẠO LỊCH TUẦN TRA',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('1. Cấu hình Lộ trình & Thời gian',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              DropdownButtonFormField<RouteConfig>(
                decoration: const InputDecoration(
                    labelText: 'Chọn Lộ trình đã vẽ',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.map)),
                hint: const Text('Chọn lộ trình...'),
                items: routes
                    .map((r) => DropdownMenuItem(
                        value: r,
                        child:
                            Text('${r.name} (${r.checkpoints.length} chốt)')))
                    .toList(),
                onChanged: (val) => setState(() => _selectedRoute = val),
                validator: (val) =>
                    val == null ? 'Bắt buộc chọn lộ trình' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                      child: TextFormField(
                          controller: _startCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Bắt đầu',
                              hintText: 'HH:mm',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.timer)),
                          validator: (v) => _parseTime(v ?? '') == null
                              ? 'Sai định dạng'
                              : null)),
                  const SizedBox(width: 16),
                  Expanded(
                      child: TextFormField(
                          controller: _endCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Kết thúc',
                              hintText: 'HH:mm',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.timer_off)),
                          validator: (v) {
                            final end = _parseTime(v ?? ''),
                                start = _parseTime(_startCtrl.text);
                            if (end == null) return 'Sai định dạng';
                            if (start != null && !end.isAfter(start)) {
                              return 'Phải sau giờ bắt đầu';
                            }
                            return null;
                          })),
                ],
              ),
              const SizedBox(height: 24),
              const Text('2. Phân công Nhân sự',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              DropdownButtonFormField<Personnel>(
                decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person)),
                hint: const Text('Chọn Bảo vệ thực hiện...'),
                items: guards
                    .map((g) => DropdownMenuItem(
                        value: g, child: Text('${g.name} (${g.username})')))
                    .toList(),
                onChanged: (val) => setState(() => _selectedGuard = val),
                validator: (val) =>
                    val == null ? 'Bắt buộc chọn nhân sự' : null,
              ),
              const SizedBox(height: 24),
              const Text('3. Cấp phát Thiết bị',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Text('Chọn các thiết bị (đang rảnh) từ kho:',
                  style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: availableEquipments.map((eq) {
                  final isSelected = _selectedEquipments.contains(eq);
                  return FilterChip(
                    label: Text('${eq.name} (${eq.code})'),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          _selectedEquipments.add(eq);
                        } else {
                          _selectedEquipments.remove(eq);
                        }
                      });
                    },
                    selectedColor: Colors.green.shade200,
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A)),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final List<Checkpoint> convertedCheckpoints =
                          _selectedRoute!.checkpoints.map<Checkpoint>((config) {
                        return Checkpoint(
                          id: config.id,
                          name: config.name,
                          expectedQrCode: config.expectedQrCode,
                          location: config.location,
                          radiusMeters: config.radiusMeters,
                        );
                      }).toList();

                      final newSchedule = Schedule(
                          id: DateTime.now().toString(),
                          routeId: _selectedRoute!.id,
                          routeName: _selectedRoute!.name,
                          guardId: _selectedGuard!.id,
                          guardName: _selectedGuard!.name,
                          startTime: _parseTime(_startCtrl.text)!,
                          endTime: _parseTime(_endCtrl.text)!,
                          checkpoints: convertedCheckpoints,
                          plannedPath: _selectedRoute!.plannedPath,
                          equipmentIds:
                              _selectedEquipments.map((e) => e.id).toList(),
                          status: ScheduleStatus.pending);

                      ref
                          .read(schedulesProvider.notifier)
                          .addSchedule(newSchedule);

                      ref
                          .read(equipmentProvider.notifier)
                          .markEquipmentsAsInUse(
                              _selectedEquipments.map((e) => e.id).toList());

                      HapticFeedback.mediumImpact();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content:
                              Text('Tạo lịch & Cấp phát thiết bị thành công!'),
                          backgroundColor: Colors.green));
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('LƯU LỊCH TUẦN TRA',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
