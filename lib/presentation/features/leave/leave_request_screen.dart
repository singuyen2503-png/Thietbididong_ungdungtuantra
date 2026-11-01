import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/date_utils.dart';
import '../../../domain/entities/workforce.dart';
import '../../state/manager_state.dart';
import '../../state/workforce_state.dart';

Color leaveStatusColor(LeaveStatus s) {
  switch (s) {
    case LeaveStatus.pending:
      return Colors.orangeAccent;
    case LeaveStatus.approved:
      return const Color(0xFF00FF9D);
    case LeaveStatus.rejected:
      return Colors.redAccent;
  }
}

class LeaveRequestScreen extends ConsumerStatefulWidget {
  const LeaveRequestScreen({super.key});

  @override
  ConsumerState<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends ConsumerState<LeaveRequestScreen> {
  static const _accent = Colors.pinkAccent;
  final _reasonCtrl = TextEditingController();
  late DateTime _from;
  late DateTime _to;

  @override
  void initState() {
    super.initState();
    _from = dateOnly(ref.read(clockProvider)()).add(const Duration(days: 1));
    _to = _from;
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _pick(bool isFrom) async {
    final today = dateOnly(ref.read(clockProvider)());
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _from : _to,
      firstDate: today,
      lastDate: today.add(const Duration(days: 180)),
      helpText: isFrom ? 'NGHỈ TỪ NGÀY' : 'ĐẾN NGÀY',
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _from = picked;
        if (_to.isBefore(_from)) _to = _from;
      } else {
        _to = picked;
      }
    });
  }

  void _submit() {
    final me = ref.read(currentGuardProvider);
    if (me == null) return;
    final error = ref
        .read(leavesProvider.notifier)
        .submit(me, _from, _to, _reasonCtrl.text, ref.read(clockProvider)());
    if (error != null) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red));
      return;
    }
    HapticFeedback.mediumImpact();
    _reasonCtrl.clear();
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Đã gửi đơn xin nghỉ, chờ Chỉ huy duyệt.'),
        backgroundColor: Colors.green));
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(currentGuardProvider);
    final mine = ref
        .watch(leavesProvider)
        .where((l) => l.personnelId == me?.id)
        .toList();
    final days = _to.difference(_from).inDays + 1;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF151E2E),
        iconTheme: const IconThemeData(color: _accent),
        title: const Text('XIN NGHỈ PHÉP',
            style: TextStyle(color: _accent, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(child: _dateBox('Từ ngày', _from, () => _pick(true))),
              const SizedBox(width: 12),
              Expanded(child: _dateBox('Đến ngày', _to, () => _pick(false))),
            ],
          ),
          const SizedBox(height: 8),
          Text('Tổng cộng: $days ngày',
              style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
          TextField(
            controller: _reasonCtrl,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
                hintText: 'Lý do xin nghỉ...',
                hintStyle: TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Color(0xFF151E2E),
                border: OutlineInputBorder(borderSide: BorderSide.none)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink.shade700),
              icon: const Icon(Icons.send, color: Colors.white),
              label: const Text('GỬI ĐƠN',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: _submit,
            ),
          ),
          const SizedBox(height: 28),
          const Text('ĐƠN CỦA TÔI',
              style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1)),
          const SizedBox(height: 8),
          if (mine.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                  child: Text('Bạn chưa gửi đơn nghỉ phép nào.',
                      style: TextStyle(color: Colors.grey))),
            ),
          ...mine.map((l) => LeaveTile(leave: l)),
        ],
      ),
    );
  }

  Widget _dateBox(String label, DateTime date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: const Color(0xFF151E2E),
            borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.event, color: _accent, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text('${weekdayShort(date)} ${formatDate(date)}',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class LeaveTile extends StatelessWidget {
  final LeaveRequest leave;
  final Widget? actions;
  const LeaveTile({super.key, required this.leave, this.actions});

  @override
  Widget build(BuildContext context) {
    final color = leaveStatusColor(leave.status);
    return Card(
      color: const Color(0xFF151E2E),
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withValues(alpha: 0.5))),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(leave.personnelName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(leave.status.label,
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
                '${formatDate(leave.fromDate)} → ${formatDate(leave.toDate)} '
                '(${leave.days} ngày)',
                style: const TextStyle(color: Colors.white70)),
            Text('Lý do: ${leave.reason}',
                style: const TextStyle(color: Colors.grey)),
            if (leave.reviewNote != null)
              Text('Phản hồi: ${leave.reviewNote}',
                  style: TextStyle(color: color, fontStyle: FontStyle.italic)),
            if (actions != null) ...[const SizedBox(height: 8), actions!],
          ],
        ),
      ),
    );
  }
}
