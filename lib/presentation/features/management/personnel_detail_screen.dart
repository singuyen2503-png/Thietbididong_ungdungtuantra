import 'package:flutter/material.dart';
import '../../../domain/entities/models.dart';

class PersonnelDetailScreen extends StatelessWidget {
  final Personnel personnel;
  const PersonnelDetailScreen({super.key, required this.personnel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF151E2E),
        title: const Text('HỒ SƠ NHÂN SỰ',
            style: TextStyle(color: Colors.blueAccent)),
        iconTheme: const IconThemeData(color: Colors.blueAccent),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
                radius: 60,
                backgroundColor: Colors.blue.shade900,
                child: const Icon(Icons.person,
                    size: 60, color: Colors.blueAccent)),
            const SizedBox(height: 16),
            Text(personnel.name,
                style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            Text(personnel.role,
                style: const TextStyle(fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 32),
            Card(
              color: const Color(0xFF151E2E),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildInfoRow(
                        Icons.badge, 'Tài khoản (Mã NV)', personnel.username),
                    const Divider(color: Colors.white12),
                    _buildInfoRow(
                        Icons.phone, 'Số điện thoại', personnel.phone),
                    const Divider(color: Colors.white12),
                    _buildInfoRow(Icons.wc, 'Giới tính', personnel.gender),
                    const Divider(color: Colors.white12),
                    _buildInfoRow(Icons.cake, 'Tuổi', '${personnel.age} tuổi'),
                    const Divider(color: Colors.white12),
                    _buildInfoRow(Icons.pin, 'Mã PIN', '••••'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Align(
                alignment: Alignment.centerLeft,
                child: Text('Ghi chú / Kinh nghiệm:',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.grey))),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: const Color(0xFF151E2E),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white12)),
              child: Text(
                  personnel.notes.isEmpty
                      ? 'Không có ghi chú'
                      : personnel.notes,
                  style: const TextStyle(fontSize: 16, color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600),
          const SizedBox(width: 16),
          Text(title,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 16)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white)),
        ],
      ),
    );
  }
}
