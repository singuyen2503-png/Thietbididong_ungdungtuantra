import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../domain/entities/models.dart';
import '../state/manager_state.dart';
import '../state/workforce_state.dart';

final alarmSoundProvider = Provider<bool>((ref) => true);

class FireAlarmButton extends ConsumerWidget {
  const FireAlarmButton({super.key});

  Future<void> _report(BuildContext context, WidgetRef ref) async {
    HapticFeedback.heavyImpact();
    final schedule = ref.read(currentGuardScheduleProvider);
    final places = <String>{
      ...?schedule?.checkpoints.map((c) => c.name),
      ...seedCheckpoints.map((c) => c.name),
      'Khu vực khác',
    }.toList();

    final location = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.alarmBackground,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('CHÁY Ở ĐÂU?',
                  style: TextStyle(
                      color: Colors.orangeAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
            ),
            for (final p in places)
              ListTile(
                leading: const Icon(Icons.local_fire_department,
                    color: Colors.orangeAccent),
                title: Text(p, style: const TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(ctx, p),
              ),
          ],
        ),
      ),
    );
    if (location == null || !context.mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Phát báo cháy?'),
        content: Text(
            'Báo cháy tại "$location" sẽ phát còi cảnh báo tới Chỉ huy và các bảo vệ.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('HỦY')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('BÁO CHÁY',
                  style: TextStyle(
                      color: Colors.redAccent, fontWeight: FontWeight.bold))),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    raiseFireAlarm(
        ref, location, ref.read(currentGuardProvider)?.name ?? 'Bảo vệ');
    HapticFeedback.vibrate();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('ĐÃ PHÁT BÁO CHÁY! Gọi cứu hỏa 114 nếu cần.'),
        backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepOrange.shade800,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28))),
        icon: const Icon(Icons.local_fire_department,
            color: Colors.white, size: 28),
        label: const Text('BÁO CHÁY',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 2)),
        onPressed: () => _report(context, ref),
      ),
    );
  }
}

class FireAlarmBanner extends ConsumerStatefulWidget {
  final void Function(Incident incident) onOpen;
  const FireAlarmBanner({super.key, required this.onOpen});

  @override
  ConsumerState<FireAlarmBanner> createState() => _FireAlarmBannerState();
}

class _FireAlarmBannerState extends ConsumerState<FireAlarmBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blink = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600))
    ..repeat(reverse: true);
  AudioPlayer? _player;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncSiren());
  }

  @override
  void dispose() {
    _blink.dispose();
    _player?.dispose();
    super.dispose();
  }

  List<Incident> _loudAlarms() {
    final silenced = ref.read(silencedAlarmIdsProvider);
    return ref
        .read(activeFireAlarmsProvider)
        .where((i) => !silenced.contains(i.id))
        .toList();
  }

  Future<void> _syncSiren() async {
    if (!mounted) return;
    final shouldPlay = ref.read(alarmSoundProvider) && _loudAlarms().isNotEmpty;
    if (shouldPlay == _playing) return;
    _playing = shouldPlay;
    try {
      if (shouldPlay) {
        final player = _player ??= AudioPlayer();
        await player.setReleaseMode(ReleaseMode.loop);
        await player.play(AssetSource('sounds/fire_alarm.wav'));
        HapticFeedback.vibrate();
      } else {
        await _player?.stop();
      }
    } catch (_) {
      _playing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(activeFireAlarmsProvider, (_, __) => _syncSiren());
    ref.listen(silencedAlarmIdsProvider, (_, __) => _syncSiren());
    final alarms = ref.watch(activeFireAlarmsProvider);
    if (alarms.isEmpty) return const SizedBox.shrink();
    final silenced = ref.watch(silencedAlarmIdsProvider);
    final allSilenced = alarms.every((a) => silenced.contains(a.id));
    final latest = alarms.first;

    return AnimatedBuilder(
      animation: _blink,
      builder: (context, child) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Color.lerp(Colors.red.shade900, Colors.deepOrange,
              allSilenced ? 0 : _blink.value),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orangeAccent, width: 2),
        ),
        child: child,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department,
                  color: Colors.white, size: 36),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(latest.title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18)),
                    Text(
                        '${latest.reportedBy} • ${formatHourMinute(latest.createdAt)}'
                        '${alarms.length > 1 ? ' • ${alarms.length} điểm cháy' : ''}',
                        style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white)),
                  icon: Icon(allSilenced ? Icons.volume_off : Icons.volume_up,
                      color: Colors.white),
                  label: Text(allSilenced ? 'ĐÃ TẮT CÒI' : 'TẮT CÒI',
                      style: const TextStyle(color: Colors.white)),
                  onPressed: allSilenced
                      ? null
                      : () => ref
                          .read(silencedAlarmIdsProvider.notifier)
                          .state = {...silenced, ...alarms.map((a) => a.id)},
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.white),
                  onPressed: () => widget.onOpen(latest),
                  child: const Text('XỬ LÝ',
                      style: TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
