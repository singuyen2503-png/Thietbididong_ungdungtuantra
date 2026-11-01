import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/workforce.dart';
import '../../state/workforce_state.dart';
import 'leave_request_screen.dart';

class LeaveApprovalScreen extends ConsumerWidget {
  const LeaveApprovalScreen({super.key});

  Future<void> _review(BuildContext context, WidgetRef ref, LeaveRequest leave,
      bool approve) async {
    final noteCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(approve ? 'Duyệt đơn nghỉ?' : 'Từ chối đơn nghỉ?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${leave.personnelName} nghỉ ${leave.days} ngày.'),
            if (approve)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                    'Các ca trực của nhân viên trong những ngày này sẽ được gỡ khỏi lịch.',
                    style: TextStyle(fontSize: 12)),
              ),
            TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(
                    labelText: 'Ghi chú (không bắt buộc)')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('HỦY')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(approve ? 'DUYỆT' : 'TỪ CHỐI',
                  style: TextStyle(
                      color: approve ? Colors.green : Colors.redAccent))),
        ],
      ),
    );
    final note = noteCtrl.text;
    noteCtrl.dispose();
    if (ok != true) return;
    HapticFeedback.mediumImpact();
    String message;
    if (approve) {
      final removed = approveLeave(ref, leave, note);
      message = removed > 0
          ? 'Đã duyệt, gỡ $removed ca khỏi lịch trực.'
          : 'Đã duyệt đơn nghỉ.';
    } else {
      ref
          .read(leavesProvider.notifier)
          .review(leave.id, LeaveStatus.rejected, note);
      message = 'Đã từ chối đơn nghỉ.';
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaves = ref.watch(leavesProvider);
    final pending =
        leaves.where((l) => l.status == LeaveStatus.pending).toList();
    final done = leaves.where((l) => l.status != LeaveStatus.pending).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF151E2E),
        iconTheme: const IconThemeData(color: Colors.pinkAccent),
        title: const Text('DUYỆT NGHỈ PHÉP',
            style: TextStyle(
                color: Colors.pinkAccent, fontWeight: FontWeight.bold)),
      ),
      body: leaves.isEmpty
          ? const Center(
              child: Text('Chưa có đơn nghỉ phép nào.',
                  style: TextStyle(color: Colors.grey, fontSize: 16)))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('CHỜ DUYỆT (${pending.length})',
                    style: const TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1)),
                const SizedBox(height: 8),
                if (pending.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Không có đơn nào đang chờ.',
                        style: TextStyle(color: Colors.grey)),
                  ),
                for (final l in pending)
                  LeaveTile(
                    leave: l,
                    actions: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                                side:
                                    const BorderSide(color: Colors.redAccent)),
                            onPressed: () => _review(context, ref, l, false),
                            child: const Text('TỪ CHỐI',
                                style: TextStyle(color: Colors.redAccent)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green),
                            onPressed: () => _review(context, ref, l, true),
                            child: const Text('DUYỆT',
                                style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (done.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text('ĐÃ XỬ LÝ',
                      style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1)),
                  const SizedBox(height: 8),
                  ...done.map((l) => LeaveTile(leave: l)),
                ],
              ],
            ),
    );
  }
}
