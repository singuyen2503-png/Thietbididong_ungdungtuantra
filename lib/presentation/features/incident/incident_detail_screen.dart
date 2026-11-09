import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/models.dart';
import '../../state/manager_state.dart';
import '../../widgets/incident_audio.dart';
import '../../widgets/incident_photo.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';

class IncidentDetailScreen extends ConsumerStatefulWidget {
  final Incident incident;
  const IncidentDetailScreen({super.key, required this.incident});

  @override
  ConsumerState<IncidentDetailScreen> createState() =>
      _IncidentDetailScreenState();
}

class _IncidentDetailScreenState extends ConsumerState<IncidentDetailScreen> {
  final _noteController = TextEditingController();

  void _showDispatchDialog(BuildContext context, WidgetRef ref) {
    final patrollingIds = ref.read(patrollingGuardIdsProvider);
    final activeGuards = ref
        .read(personnelProvider)
        .where((p) => patrollingIds.contains(p.id))
        .toList();
    List<String> selectedGuards = [];

    showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(builder: (context, setState) {
              return AlertDialog(
                backgroundColor: AppColors.surface,
                title: const Text('ĐIỀU ĐỘNG CHI VIỆN',
                    style: TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.bold)),
                content: SizedBox(
                  width: double.maxFinite,
                  child: activeGuards.isEmpty
                      ? const Text(
                          'Không có nhân sự nào đang đi tuần để chi viện.',
                          style: TextStyle(color: Colors.grey))
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: activeGuards.length,
                          itemBuilder: (context, index) {
                            final g = activeGuards[index];
                            return CheckboxListTile(
                              title: Text(g.name,
                                  style: const TextStyle(color: Colors.white)),
                              subtitle: Text('SĐT: ${g.phone}',
                                  style: const TextStyle(color: Colors.grey)),
                              value: selectedGuards.contains(g.name),
                              activeColor: AppColors.primary,
                              onChanged: (val) {
                                setState(() {
                                  val == true
                                      ? selectedGuards.add(g.name)
                                      : selectedGuards.remove(g.name);
                                });
                              },
                            );
                          },
                        ),
                ),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('HỦY',
                          style: TextStyle(color: Colors.grey))),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary),
                    onPressed: () {
                      if (selectedGuards.isNotEmpty) {
                        ref
                            .read(incidentsProvider.notifier)
                            .assignBackups(widget.incident.id, selectedGuards);
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Đã gửi thông báo điều động!'),
                                backgroundColor: Colors.green));
                      }
                      Navigator.pop(context);
                    },
                    child: const Text('ĐIỀU ĐỘNG',
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold)),
                  )
                ],
              );
            }));
  }

  @override
  Widget build(BuildContext context) {
    final updatedIncident = ref
        .watch(incidentsProvider)
        .firstWhere((i) => i.id == widget.incident.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.red.shade900,
        title:
            const Text('CHI TIẾT SỰ CỐ', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: updatedIncident.isResolved
                          ? Colors.green
                          : Colors.redAccent,
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(
                      updatedIncident.isResolved ? 'ĐÃ ĐÓNG' : 'ĐANG XỬ LÝ',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                Text(
                    '${formatHourMinute(updatedIncident.createdAt)} - ${formatDayMonth(updatedIncident.createdAt)}',
                    style: const TextStyle(
                        color: Colors.grey, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 24),
            Text(updatedIncident.title,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 8),
            Text('Báo cáo bởi: ${updatedIncident.reportedBy}',
                style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white12)),
              child: Text(updatedIncident.description,
                  style: const TextStyle(fontSize: 16, color: Colors.white)),
            ),
            const SizedBox(height: 24),
            if (updatedIncident.imageBase64 != null)
              IncidentPhoto(imageBase64: updatedIncident.imageBase64!),
            if (updatedIncident.audioPath != null)
              IncidentAudio(audioPath: updatedIncident.audioPath!),
            if (updatedIncident.assignedBackupNames.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text('ĐỘI CHI VIỆN ĐÃ ĐIỀU ĐỘNG:',
                  style: TextStyle(
                      color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: updatedIncident.assignedBackupNames
                    .map((name) => Chip(
                          label: Text(name,
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold)),
                          backgroundColor: Colors.orangeAccent,
                        ))
                    .toList(),
              )
            ],
            const SizedBox(height: 40),
            if (!updatedIncident.isResolved) ...[
              const Text('GHI CHÚ CHỈ ĐẠO:',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              TextField(
                controller: _noteController,
                maxLines: 2,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                    hintText: 'Nhập ghi chú (nếu có)...',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                      child: OutlinedButton.icon(
                    onPressed: () => _showDispatchDialog(context, ref),
                    icon: const Icon(Icons.group_add, color: Colors.blueAccent),
                    label: const Text('CHI VIỆN',
                        style: TextStyle(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Colors.blueAccent)),
                  )),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16)),
                      onPressed: () {
                        ref.read(incidentsProvider.notifier).resolveByCommander(
                            updatedIncident.id, _noteController.text);
                        Navigator.pop(context);
                      },
                      child: const Text('ĐÓNG SỰ CỐ',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              )
            ] else ...[
              const Divider(color: Colors.white24),
              const SizedBox(height: 16),
              Text('ĐÃ ĐÓNG BỞI: ${updatedIncident.resolvedBy?.toUpperCase()}',
                  style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              if (updatedIncident.commanderNote != null)
                Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                        'Ghi chú Chỉ huy: ${updatedIncident.commanderNote}',
                        style: const TextStyle(color: Colors.white))),
              if (updatedIncident.resolutionReport != null)
                Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                        'Báo cáo hiện trường: ${updatedIncident.resolutionReport}',
                        style: const TextStyle(color: Colors.white))),
            ]
          ],
        ),
      ),
    );
  }
}
