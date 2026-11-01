import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/manager_state.dart';
import '../../../domain/entities/equipment.dart';

class EquipmentScreen extends ConsumerWidget {
  const EquipmentScreen({super.key});

  void _showFormDialog(BuildContext context, WidgetRef ref,
      [Equipment? equipment]) {
    final isEdit = equipment != null;
    final nameController = TextEditingController(text: equipment?.name ?? '');
    final codeController = TextEditingController(text: equipment?.code ?? '');
    String selectedStatus = equipment?.status ?? EquipmentStatus.available;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF151E2E),
            title: Text(isEdit ? 'CẬP NHẬT THIẾT BỊ' : 'THÊM THIẾT BỊ MỚI',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.orangeAccent)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                          labelText: 'Tên thiết bị',
                          labelStyle: TextStyle(color: Colors.grey))),
                  const SizedBox(height: 12),
                  TextField(
                      controller: codeController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                          labelText: 'Mã thiết bị',
                          labelStyle: TextStyle(color: Colors.grey))),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    dropdownColor: const Color(0xFF151E2E),
                    initialValue: selectedStatus,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                        labelText: 'Trạng thái',
                        labelStyle: TextStyle(color: Colors.grey)),
                    items: [EquipmentStatus.available, EquipmentStatus.inUse]
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (val) => setState(() => selectedStatus = val!),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                  },
                  child:
                      const Text('HỦY', style: TextStyle(color: Colors.grey))),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.trim().isEmpty ||
                      codeController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Vui lòng điền đủ thông tin!')));
                    return;
                  }

                  final newEq = Equipment(
                    id: isEdit ? equipment.id : DateTime.now().toString(),
                    name: nameController.text.trim(),
                    code: codeController.text.trim(),
                    status: selectedStatus,
                  );

                  if (isEdit) {
                    ref.read(equipmentProvider.notifier).updateEquipment(newEq);
                  } else {
                    ref.read(equipmentProvider.notifier).addEquipment(newEq);
                  }

                  HapticFeedback.heavyImpact();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade800),
                child: const Text('LƯU', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eqList = ref.watch(equipmentProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF151E2E),
        title: const Text('QUẢN LÝ THIẾT BỊ',
            style: TextStyle(
                color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.orangeAccent),
      ),
      body: eqList.isEmpty
          ? const Center(
              child: Text('Kho chưa có thiết bị nào',
                  style: TextStyle(fontSize: 18, color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: eqList.length,
              itemBuilder: (context, index) {
                final eq = eqList[index];
                return Dismissible(
                  key: Key(eq.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    ref.read(equipmentProvider.notifier).deleteEquipment(eq.id);
                    HapticFeedback.heavyImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Đã xóa ${eq.name}')));
                  },
                  child: Card(
                    color: const Color(0xFF151E2E),
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Icon(Icons.build,
                          color: eq.status == EquipmentStatus.available
                              ? Colors.green
                              : Colors.orange),
                      title: Text(eq.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.white)),
                      subtitle: Text('Mã: ${eq.code}',
                          style: const TextStyle(color: Colors.white70)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                                color: eq.status == EquipmentStatus.available
                                    ? Colors.green.shade800
                                    : Colors.orange.shade800,
                                borderRadius: BorderRadius.circular(12)),
                            child: Text(
                              eq.status,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit,
                                color: Colors.orangeAccent),
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              _showFormDialog(context, ref, eq);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          HapticFeedback.selectionClick();
          _showFormDialog(context, ref);
        },
        backgroundColor: Colors.orange.shade800,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
