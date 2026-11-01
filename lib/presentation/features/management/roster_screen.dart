import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/date_utils.dart';
import '../../../domain/entities/workforce.dart';
import '../../state/manager_state.dart';
import '../../state/workforce_state.dart';

class RosterScreen extends ConsumerStatefulWidget {
  const RosterScreen({super.key});

  @override
  ConsumerState<RosterScreen> createState() => _RosterScreenState();
}

class _RosterScreenState extends ConsumerState<RosterScreen> {
  static const _accent = Color(0xFF38BDF8);
  late DateTime _monday;

  @override
  void initState() {
    super.initState();
    _monday = startOfWeek(ref.read(clockProvider)());
  }

  void _toast(String text, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(text),
        backgroundColor: error ? Colors.red : Colors.green));
  }

  Future<void> _pickGuard(DateTime day, ShiftType shift) async {
    final personnel = ref.read(personnelProvider);
    final roster = ref.read(rosterProvider);
    final leaves = ref.read(leavesProvider);
    final candidates = personnel.where((p) {
      if (!p.isActive) return false;
      if (roster.any((e) => e.personnelId == p.id && sameDay(e.date, day))) {
        return false;
      }
      return !leaves.any((l) =>
          l.personnelId == p.id &&
          l.status == LeaveStatus.approved &&
          l.covers(day));
    }).toList();

    final id = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF151E2E),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                  '${shift.label} • ${weekdayName(day)} ${formatDayMonth(day)}',
                  style: const TextStyle(
                      color: _accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ),
            if (candidates.isEmpty)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Text(
                    'Không còn nhân viên trống lịch (đã có ca hoặc nghỉ phép).',
                    style: TextStyle(color: Colors.grey)),
              )
            else
              ...candidates.map((p) => ListTile(
                    leading: const Icon(Icons.person_add, color: _accent),
                    title: Text(p.name,
                        style: const TextStyle(color: Colors.white)),
                    subtitle: Text(p.username,
                        style: const TextStyle(color: Colors.grey)),
                    onTap: () => Navigator.pop(ctx, p.id),
                  )),
          ],
        ),
      ),
    );
    if (id == null || !mounted) return;
    final error = ref.read(rosterProvider.notifier).assign(id, day, shift,
        personnel: ref.read(personnelProvider),
        leaves: ref.read(leavesProvider));
    if (error != null) {
      _toast(error, error: true);
    } else {
      HapticFeedback.selectionClick();
    }
  }

  Future<void> _copyPreviousWeek() async {
    final added = ref.read(rosterProvider.notifier).copyWeek(
        _monday.subtract(const Duration(days: 7)), _monday,
        personnel: ref.read(personnelProvider),
        leaves: ref.read(leavesProvider));
    _toast(added == 0
        ? 'Không có ca nào để sao chép (hoặc đã trùng lịch).'
        : 'Đã sao chép $added ca từ tuần trước.');
  }

  @override
  Widget build(BuildContext context) {
    final roster = ref.watch(rosterProvider);
    final personnel = ref.watch(personnelProvider);
    final leaves = ref.watch(leavesProvider);
    final today = dateOnly(ref.watch(clockProvider)());
    final names = {for (final p in personnel) p.id: p.name};
    final sunday = _monday.add(const Duration(days: 6));
    final weekCount = roster
        .where((e) => !e.date.isBefore(_monday) && !e.date.isAfter(sunday))
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF151E2E),
        iconTheme: const IconThemeData(color: _accent),
        title: const Text('LỊCH TRỰC TUẦN',
            style: TextStyle(color: _accent, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
              tooltip: 'Sao chép lịch tuần trước',
              icon: const Icon(Icons.copy_all, color: _accent),
              onPressed: _copyPreviousWeek),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: const Color(0xFF151E2E),
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Row(
              children: [
                IconButton(
                    tooltip: 'Tuần trước',
                    icon: const Icon(Icons.chevron_left, color: Colors.white),
                    onPressed: () => setState(() =>
                        _monday = _monday.subtract(const Duration(days: 7)))),
                Expanded(
                  child: Column(
                    children: [
                      Text('${formatDayMonth(_monday)} - ${formatDate(sunday)}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      Text('$weekCount ca đã phân',
                          style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
                IconButton(
                    tooltip: 'Tuần sau',
                    icon: const Icon(Icons.chevron_right, color: Colors.white),
                    onPressed: () => setState(
                        () => _monday = _monday.add(const Duration(days: 7)))),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: 7,
              itemBuilder: (context, i) {
                final day = _monday.add(Duration(days: i));
                final onLeave = leaves
                    .where((l) =>
                        l.status == LeaveStatus.approved && l.covers(day))
                    .map((l) => l.personnelName)
                    .toList();
                return _DayCard(
                  day: day,
                  isToday: sameDay(day, today),
                  isPast: day.isBefore(today),
                  onLeave: onLeave,
                  shifts: {
                    for (final s in ShiftType.values)
                      s: rosterForDay(roster, day, s)
                  },
                  names: names,
                  onAdd: (shift) => _pickGuard(day, shift),
                  onRemove: (entry) {
                    ref.read(rosterProvider.notifier).remove(entry.id);
                    HapticFeedback.lightImpact();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  final DateTime day;
  final bool isToday;
  final bool isPast;
  final List<String> onLeave;
  final Map<ShiftType, List<RosterEntry>> shifts;
  final Map<String, String> names;
  final void Function(ShiftType) onAdd;
  final void Function(RosterEntry) onRemove;

  const _DayCard(
      {required this.day,
      required this.isToday,
      required this.isPast,
      required this.onLeave,
      required this.shifts,
      required this.names,
      required this.onAdd,
      required this.onRemove});

  static const _shiftColors = {
    ShiftType.morning: Colors.amber,
    ShiftType.afternoon: Colors.orangeAccent,
    ShiftType.night: Colors.indigoAccent,
  };

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF151E2E),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
              color: isToday ? const Color(0xFF38BDF8) : Colors.white12,
              width: isToday ? 2 : 1)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('${weekdayName(day)} ${formatDayMonth(day)}',
                    style: TextStyle(
                        color: isPast ? Colors.grey : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                if (isToday) ...[
                  const SizedBox(width: 8),
                  const Text('HÔM NAY',
                      style: TextStyle(
                          color: Color(0xFF38BDF8),
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ],
              ],
            ),
            if (onLeave.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Nghỉ phép: ${onLeave.join(', ')}',
                    style: const TextStyle(
                        color: Colors.pinkAccent, fontSize: 12)),
              ),
            const SizedBox(height: 4),
            for (final entry in shifts.entries)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 72,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(entry.key.label,
                              style: TextStyle(
                                  color: _shiftColors[entry.key],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13)),
                          Text(entry.key.timeRange,
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 10)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (entry.value.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text('Chưa phân',
                                  style: TextStyle(
                                      color: Colors.white38,
                                      fontStyle: FontStyle.italic)),
                            ),
                          for (final e in entry.value)
                            InputChip(
                              label: Text(names[e.personnelId] ?? 'Đã xóa',
                                  style: const TextStyle(fontSize: 12)),
                              visualDensity: VisualDensity.compact,
                              onDeleted: isPast ? null : () => onRemove(e),
                            ),
                        ],
                      ),
                    ),
                    if (!isPast)
                      IconButton(
                        tooltip: 'Phân ${entry.key.label}',
                        icon: const Icon(Icons.add_circle_outline,
                            color: Color(0xFF38BDF8)),
                        onPressed: () => onAdd(entry.key),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
