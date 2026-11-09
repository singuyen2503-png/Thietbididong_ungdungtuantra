import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../domain/entities/workforce.dart';
import '../../state/manager_state.dart';
import '../../state/workforce_state.dart';
import 'patrol_monitor_screen.dart';

class RosterScreen extends ConsumerStatefulWidget {
  const RosterScreen({super.key});

  @override
  ConsumerState<RosterScreen> createState() => _RosterScreenState();
}

class _RosterScreenState extends ConsumerState<RosterScreen> {
  static const _accent = AppColors.roster;
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
    final routes = ref.read(routeConfigsProvider);
    final equipment = ref.read(equipmentProvider);
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

    String? routeId = routes.firstOrNull?.id;
    final equipmentIds = <String>{};

    final id = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.85),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      '${shift.label} • ${weekdayName(day)} ${formatDayMonth(day)}',
                      style: const TextStyle(
                          color: _accent,
                          fontWeight: FontWeight.bold,
                          fontSize: 17)),
                  Text(shift.timeRange,
                      style: const TextStyle(color: AppColors.textMuted)),
                  const SizedBox(height: 16),
                  const _SheetLabel('LỘ TRÌNH TUẦN TRA'),
                  if (routes.isEmpty)
                    const Text('Chưa có lộ trình – ca này chỉ chấm công.',
                        style: TextStyle(color: AppColors.textMuted))
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final r in routes)
                          ChoiceChip(
                            label: Text(
                                '${r.name} (${r.checkpoints.length} điểm)'),
                            selected: routeId == r.id,
                            onSelected: (_) => setSheet(() => routeId = r.id),
                          ),
                      ],
                    ),
                  const SizedBox(height: 12),
                  const _SheetLabel('THIẾT BỊ CẤP KHI VÀO CA'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final e in equipment)
                        FilterChip(
                          label: Text('${e.name} (${e.code})'),
                          selected: equipmentIds.contains(e.id),
                          onSelected: (on) => setSheet(() => on
                              ? equipmentIds.add(e.id)
                              : equipmentIds.remove(e.id)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const _SheetLabel('CHỌN BẢO VỆ'),
                  if (candidates.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Text(
                          'Không còn nhân viên trống lịch (đã có ca hoặc nghỉ phép).',
                          style: TextStyle(color: AppColors.textMuted)),
                    )
                  else
                    ...candidates.map((p) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                              backgroundColor: _accent.withValues(alpha: 0.15),
                              child:
                                  const Icon(Icons.person_add, color: _accent)),
                          title: Text(p.name,
                              style: const TextStyle(color: Colors.white)),
                          subtitle: Text(p.username,
                              style:
                                  const TextStyle(color: AppColors.textMuted)),
                          onTap: () => Navigator.pop(ctx, p.id),
                        )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (id == null || !mounted) return;
    final error = ref.read(rosterProvider.notifier).assign(id, day, shift,
        personnel: ref.read(personnelProvider),
        leaves: ref.read(leavesProvider),
        routeId: routeId,
        equipmentIds: equipmentIds.toList());
    if (error != null) {
      _toast(error, error: true);
    } else {
      HapticFeedback.selectionClick();
    }
  }

  void _remove(RosterEntry entry) {
    final error = removeRosterEntry(ref, entry);
    if (error != null) {
      _toast(error, error: true);
    } else {
      HapticFeedback.lightImpact();
    }
  }

  Future<void> _showEntry(RosterEntry entry, bool editable) async {
    final person =
        ref.read(personnelProvider).where((p) => p.id == entry.personnelId);
    final routes = ref.read(routeConfigsProvider);
    final schedule =
        ref.read(schedulesProvider).where((s) => s.id == entry.id).firstOrNull;
    final route = routes.where((r) => r.id == entry.routeId).firstOrNull;
    final equipment = ref
        .read(equipmentProvider)
        .where((e) => entry.equipmentIds.contains(e.id))
        .map((e) => '${e.name} (${e.code})')
        .toList();
    final state = shiftStateOf(entry, ref.read(attendanceProvider),
        ref.read(schedulesProvider), ref.read(clockProvider)());
    final scanned = schedule?.checkpoints.where((c) => c.isScanned).length;

    final remove = await showModalBottomSheet<bool>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(person.firstOrNull?.name ?? 'Đã xóa',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                  ),
                  _StateBadge(state),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                  '${entry.shift.label} ${entry.shift.timeRange} • '
                  '${weekdayName(entry.date)} ${formatDayMonth(entry.date)}',
                  style: const TextStyle(color: AppColors.textMuted)),
              const Divider(height: 28),
              _InfoRow(Icons.route, 'Lộ trình',
                  schedule?.routeName ?? route?.name ?? 'Không tuần tra'),
              if (scanned != null)
                _InfoRow(Icons.qr_code_scanner, 'Tiến độ',
                    'Đã quét $scanned/${schedule!.checkpoints.length} điểm'),
              _InfoRow(Icons.build, 'Thiết bị',
                  equipment.isEmpty ? 'Không cấp' : equipment.join(', ')),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (state == ShiftState.patrolling)
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.radar),
                        label: const Text('GIÁM SÁT'),
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const PatrolMonitorScreen()));
                        },
                      ),
                    ),
                  if (editable && state != ShiftState.patrolling)
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.danger),
                        icon: const Icon(Icons.person_remove),
                        label: const Text('GỠ KHỎI CA'),
                        onPressed: () => Navigator.pop(ctx, true),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (remove == true && mounted) _remove(entry);
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
    final attendance = ref.watch(attendanceProvider);
    final schedules = ref.watch(schedulesProvider);
    final now = ref.watch(clockProvider)();
    final today = dateOnly(now);
    final names = {for (final p in personnel) p.id: p.name};
    final sunday = _monday.add(const Duration(days: 6));
    final weekCount = roster
        .where((e) => !e.date.isBefore(_monday) && !e.date.isAfter(sunday))
        .length;

    return Scaffold(
      appBar: AppBar(
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
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 4),
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border)),
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
                          style: const TextStyle(color: AppColors.textMuted)),
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
          const _Legend(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              itemCount: 7,
              itemBuilder: (context, i) {
                final day = _monday.add(Duration(days: i));
                final onLeave = leaves
                    .where((l) =>
                        l.status == LeaveStatus.approved && l.covers(day))
                    .map((l) => l.personnelName)
                    .toList();
                final isPast = day.isBefore(today);
                return _DayCard(
                  day: day,
                  isToday: sameDay(day, today),
                  isPast: isPast,
                  onLeave: onLeave,
                  shifts: {
                    for (final s in ShiftType.values)
                      s: rosterForDay(roster, day, s)
                  },
                  names: names,
                  stateOf: (e) => shiftStateOf(e, attendance, schedules, now),
                  onAdd: (shift) => _pickGuard(day, shift),
                  onOpen: (entry) => _showEntry(entry, !isPast),
                  onRemove: _remove,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetLabel extends StatelessWidget {
  final String text;
  const _SheetLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2)),
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: AppColors.roster),
            const SizedBox(width: 10),
            SizedBox(
                width: 72,
                child: Text(label,
                    style: const TextStyle(color: AppColors.textMuted))),
            Expanded(
                child:
                    Text(value, style: const TextStyle(color: Colors.white))),
          ],
        ),
      );
}

class _StateBadge extends StatelessWidget {
  final ShiftState state;
  const _StateBadge(this.state);

  @override
  Widget build(BuildContext context) {
    final color = shiftStateColor(state);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color)),
      child: Text(state.label,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Wrap(
        spacing: 12,
        runSpacing: 4,
        children: [
          for (final s in ShiftState.values)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 9, color: shiftStateColor(s)),
                const SizedBox(width: 4),
                Text(s.label,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 11)),
              ],
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
  final ShiftState Function(RosterEntry) stateOf;
  final void Function(ShiftType) onAdd;
  final void Function(RosterEntry) onOpen;
  final void Function(RosterEntry) onRemove;

  const _DayCard(
      {required this.day,
      required this.isToday,
      required this.isPast,
      required this.onLeave,
      required this.shifts,
      required this.names,
      required this.stateOf,
      required this.onAdd,
      required this.onOpen,
      required this.onRemove});

  static const _shiftColors = {
    ShiftType.morning: Colors.amber,
    ShiftType.afternoon: Colors.orangeAccent,
    ShiftType.night: Colors.indigoAccent,
  };

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
              color: isToday ? AppColors.roster : AppColors.border,
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
                        color: isPast ? AppColors.textMuted : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                if (isToday) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                        color: AppColors.roster,
                        borderRadius: BorderRadius.circular(6)),
                    child: const Text('HÔM NAY',
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ],
            ),
            if (onLeave.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Nghỉ phép: ${onLeave.join(', ')}',
                    style:
                        const TextStyle(color: AppColors.leave, fontSize: 12)),
              ),
            const SizedBox(height: 4),
            for (final entry in shifts.entries)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 3,
                      height: 32,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                          color: _shiftColors[entry.key],
                          borderRadius: BorderRadius.circular(2)),
                    ),
                    SizedBox(
                      width: 84,
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
                                  color: AppColors.textMuted, fontSize: 10)),
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
                              avatar: Icon(Icons.circle,
                                  size: 10, color: shiftStateColor(stateOf(e))),
                              label: Text(names[e.personnelId] ?? 'Đã xóa',
                                  style: const TextStyle(fontSize: 12)),
                              visualDensity: VisualDensity.compact,
                              onPressed: () => onOpen(e),
                              onDeleted: isPast ? null : () => onRemove(e),
                            ),
                        ],
                      ),
                    ),
                    if (!isPast)
                      IconButton(
                        tooltip: 'Phân ${entry.key.label}',
                        icon: const Icon(Icons.add_circle_outline,
                            color: AppColors.roster),
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
