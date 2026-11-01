import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/manager_state.dart';
import 'incident_detail_screen.dart';

class IncidentListScreen extends ConsumerWidget {
  const IncidentListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incidents = ref.watch(incidentsProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red.shade700,
        title: const Text('DANH SÁCH SỰ CỐ',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: incidents.isEmpty
          ? const Center(
              child: Text('Tuyệt vời! Không có sự cố nào.',
                  style: TextStyle(fontSize: 18, color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: incidents.length,
              itemBuilder: (context, index) {
                final incident = incidents[index];
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                      side: BorderSide(
                          color:
                              incident.isResolved ? Colors.green : Colors.red,
                          width: 2),
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Icon(
                        incident.isResolved
                            ? Icons.check_circle
                            : Icons.warning,
                        color: incident.isResolved ? Colors.green : Colors.red,
                        size: 40),
                    title: Text(incident.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    subtitle: Text(
                        'Báo cáo bởi: ${incident.reportedBy}\nLúc: ${incident.createdAt.hour}:${incident.createdAt.minute}'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                IncidentDetailScreen(incident: incident))),
                  ),
                );
              },
            ),
    );
  }
}
