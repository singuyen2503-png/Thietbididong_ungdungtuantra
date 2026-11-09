import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/models.dart';
import '../../state/manager_state.dart';
import '../../widgets/incident_audio.dart';
import '../../widgets/incident_photo.dart';
import '../../../core/theme/app_theme.dart';

class GuardIncidentDetailScreen extends ConsumerStatefulWidget {
  final Incident incident;
  const GuardIncidentDetailScreen({super.key, required this.incident});

  @override
  ConsumerState<GuardIncidentDetailScreen> createState() =>
      _GuardIncidentDetailScreenState();
}

class _GuardIncidentDetailScreenState
    extends ConsumerState<GuardIncidentDetailScreen> {
  final _reportController = TextEditingController();

  @override
  void dispose() {
    _reportController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final updatedIncident = ref
        .watch(incidentsProvider)
        .firstWhere((i) => i.id == widget.incident.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('CHI TIẾT NHIỆM VỤ',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: updatedIncident.isResolved
                          ? Colors.green
                          : Colors.redAccent)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(updatedIncident.title,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 8),
                  Text(updatedIncident.description,
                      style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (updatedIncident.imageBase64 != null)
              IncidentPhoto(imageBase64: updatedIncident.imageBase64!),
            if (updatedIncident.audioPath != null)
              IncidentAudio(audioPath: updatedIncident.audioPath!),
            if (updatedIncident.assignedBackupNames.isNotEmpty) ...[
              const Text('LỰC LƯỢNG HIỆN TRƯỜNG:',
                  style: TextStyle(
                      color: Colors.grey, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  Chip(
                      label: Text('${updatedIncident.reportedBy} (Gốc)',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      backgroundColor: Colors.blueAccent),
                  ...updatedIncident.assignedBackupNames.map((name) => Chip(
                      label: Text(name), backgroundColor: Colors.orangeAccent)),
                ],
              ),
              const SizedBox(height: 24),
            ],
            if (!updatedIncident.isResolved) ...[
              const Text('BÁO CÁO KẾT THÚC (Dành cho hiện trường):',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              TextField(
                controller: _reportController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                    hintText: 'Nhập kết quả xử lý...',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: AppColors.surface),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  icon: const Icon(Icons.check_circle, color: Colors.white),
                  label: const Text('XÁC NHẬN AN TOÀN & ĐÓNG',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    if (_reportController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Vui lòng nhập báo cáo kết thúc')));
                      return;
                    }
                    HapticFeedback.heavyImpact();
                    ref.read(incidentsProvider.notifier).resolveByGuard(
                        updatedIncident.id, _reportController.text);
                    Navigator.pop(context);
                  },
                ),
              )
            ] else ...[
              const Text('TRẠNG THÁI: ĐÃ ĐÓNG',
                  style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
              if (updatedIncident.resolutionReport != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                      'Báo cáo của bạn: ${updatedIncident.resolutionReport}',
                      style: const TextStyle(color: Colors.white70)),
                )
            ]
          ],
        ),
      ),
    );
  }
}
