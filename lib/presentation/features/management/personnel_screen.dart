import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/manager_state.dart';
import '../../state/workforce_state.dart';
import '../../../domain/entities/models.dart';
import 'personnel_detail_screen.dart';

class PersonnelScreen extends ConsumerWidget {
  const PersonnelScreen({super.key});

  void _showFormDialog(BuildContext context, WidgetRef ref,
      [Personnel? personnel]) {
    final isEdit = personnel != null;
    final nameCtrl = TextEditingController(text: personnel?.name ?? '');
    final usernameCtrl = TextEditingController(text: personnel?.username ?? '');
    final phoneCtrl = TextEditingController(text: personnel?.phone ?? '');
    final ageCtrl =
        TextEditingController(text: personnel?.age.toString() ?? '');
    final notesCtrl = TextEditingController(text: personnel?.notes ?? '');
    final pinCtrl = TextEditingController(text: personnel?.pin ?? '');
    String gender = personnel?.gender ?? 'Nam';
    bool isActive = personnel?.isActive ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF151E2E),
            title: Text(isEdit ? 'CẬP NHẬT NHÂN SỰ' : 'THÊM NHÂN SỰ MỚI',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.blueAccent)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                      controller: nameCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                          labelText: 'Họ và tên',
                          labelStyle: TextStyle(color: Colors.grey))),
                  const SizedBox(height: 12),
                  TextField(
                      controller: usernameCtrl,
                      enabled: !isEdit,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                          labelText: 'Mã nhân viên (tài khoản)',
                          labelStyle: TextStyle(color: Colors.grey))),
                  const SizedBox(height: 12),
                  TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                          labelText: 'Số điện thoại (10 số)',
                          labelStyle: TextStyle(color: Colors.grey))),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                          child: TextField(
                              controller: ageCtrl,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                  labelText: 'Tuổi',
                                  labelStyle: TextStyle(color: Colors.grey)))),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          dropdownColor: const Color(0xFF151E2E),
                          initialValue: gender,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                              labelText: 'Giới tính',
                              labelStyle: TextStyle(color: Colors.grey)),
                          items: ['Nam', 'Nữ']
                              .map((g) =>
                                  DropdownMenuItem(value: g, child: Text(g)))
                              .toList(),
                          onChanged: (val) => setState(() => gender = val!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                      controller: pinCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                          labelText: 'Mã PIN đăng nhập (4 số)',
                          labelStyle: TextStyle(color: Colors.grey),
                          counterText: '')),
                  const SizedBox(height: 12),
                  TextField(
                      controller: notesCtrl,
                      maxLines: 2,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                          labelText: 'Ghi chú / Kinh nghiệm',
                          labelStyle: TextStyle(color: Colors.grey))),
                  if (isEdit)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Đang làm việc',
                          style: TextStyle(color: Colors.white)),
                      subtitle: Text(
                          isActive
                              ? 'Tắt khi nhân viên đã nghỉ việc'
                              : 'Đã nghỉ việc – không thể đăng nhập',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12)),
                      value: isActive,
                      onChanged: (v) => setState(() => isActive = v),
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
                  final error = _validate(
                      ref,
                      nameCtrl.text,
                      usernameCtrl.text,
                      phoneCtrl.text,
                      ageCtrl.text,
                      pinCtrl.text,
                      personnel?.id);
                  if (error != null) {
                    HapticFeedback.heavyImpact();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(error), backgroundColor: Colors.red));
                    return;
                  }

                  final p = Personnel(
                    id: isEdit
                        ? personnel.id
                        : DateTime.now().millisecondsSinceEpoch.toString(),
                    username: usernameCtrl.text.trim(),
                    name: nameCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                    role: personnel?.role ?? 'Bảo vệ',
                    gender: gender,
                    age: int.parse(ageCtrl.text.trim()),
                    notes: notesCtrl.text.trim(),
                    pin: pinCtrl.text.trim(),
                    isActive: isActive,
                  );

                  if (isEdit) {
                    ref.read(personnelProvider.notifier).updatePersonnel(p);
                    if (!isActive) {
                      ref
                          .read(rosterProvider.notifier)
                          .removeFor(p.id, from: ref.read(clockProvider)());
                    }
                  } else {
                    ref.read(personnelProvider.notifier).addPersonnel(p);
                  }

                  HapticFeedback.mediumImpact();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A)),
                child: const Text('LƯU', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  String? _validate(WidgetRef ref, String name, String username, String phone,
      String age, String pin, String? editingId) {
    final others = ref.read(personnelProvider).where((p) => p.id != editingId);
    if (name.trim().isEmpty || username.trim().isEmpty) {
      return 'Vui lòng nhập Họ tên và Mã nhân viên!';
    }
    if (others.any((p) => p.username == username.trim())) {
      return 'Mã nhân viên đã tồn tại!';
    }
    if (!RegExp(r'^0\d{9}$').hasMatch(phone.trim())) {
      return 'Số điện thoại phải gồm 10 chữ số, bắt đầu bằng 0!';
    }
    final parsedAge = int.tryParse(age.trim());
    if (parsedAge == null || parsedAge < 18 || parsedAge > 65) {
      return 'Tuổi phải từ 18 đến 65!';
    }
    if (!RegExp(r'^\d{4}$').hasMatch(pin.trim())) {
      return 'Mã PIN phải gồm đúng 4 chữ số!';
    }
    if (pin.trim() == kCommanderPin || others.any((p) => p.pin == pin.trim())) {
      return 'Mã PIN đã được sử dụng, hãy chọn mã khác!';
    }
    return null;
  }

  Future<void> _deleteResigned(
      BuildContext context, WidgetRef ref, int count) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa nhân viên đã nghỉ?'),
        content: Text(
            'Xóa vĩnh viễn hồ sơ $count nhân viên đã nghỉ việc và lịch trực của họ.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('HỦY')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  const Text('XÓA', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (ok != true) return;
    final removed = removeResignedStaff(ref);
    HapticFeedback.heavyImpact();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã xóa $removed nhân viên đã nghỉ')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personnelList = ref.watch(personnelProvider);
    final resignedCount = personnelList.where((p) => !p.isActive).length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        title: const Text('QUẢN LÝ NHÂN SỰ',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          if (resignedCount > 0)
            TextButton.icon(
              key: const Key('delete-resigned'),
              onPressed: () => _deleteResigned(context, ref, resignedCount),
              icon: const Icon(Icons.person_remove, color: Colors.white),
              label: Text('XÓA ($resignedCount)',
                  style: const TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: personnelList.isEmpty
          ? const Center(
              child: Text('Chưa có nhân sự nào.',
                  style: TextStyle(fontSize: 18, color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: personnelList.length,
              itemBuilder: (context, index) {
                final p = personnelList[index];
                return Dismissible(
                  key: Key(p.id),
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
                  confirmDismiss: (_) => showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Xóa nhân sự?'),
                      content:
                          Text('Bạn chắc chắn muốn xóa hồ sơ "${p.name}"?'),
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
                  ),
                  onDismissed: (_) {
                    HapticFeedback.heavyImpact();
                    ref.read(rosterProvider.notifier).removeFor(p.id);
                    ref.read(personnelProvider.notifier).deletePersonnel(p.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Đã xóa ${p.name}')));
                  },
                  child: Card(
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                          backgroundColor:
                              p.isActive ? Colors.blueAccent : Colors.grey,
                          child: const Icon(Icons.person, color: Colors.white)),
                      title: Row(
                        children: [
                          Flexible(
                            child: Text(p.name,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: p.isActive ? null : Colors.grey)),
                          ),
                          if (!p.isActive) ...[
                            const SizedBox(width: 8),
                            const Text('ĐÃ NGHỈ',
                                style: TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ],
                      ),
                      subtitle: Text(
                          '${p.role} - Mã NV: ${p.username}\nSĐT: ${p.phone}'),
                      isThreeLine: true,
                      trailing: IconButton(
                          icon:
                              const Icon(Icons.edit, color: Colors.blueAccent),
                          onPressed: () => _showFormDialog(context, ref, p)),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  PersonnelDetailScreen(personnel: p))),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFormDialog(context, ref),
        backgroundColor: const Color(0xFF1E3A8A),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
