import 'package:flutter/material.dart';

class MonthSwitcher extends StatelessWidget {
  final DateTime month;
  final ValueChanged<DateTime> onChanged;
  const MonthSwitcher(
      {super.key, required this.month, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
            tooltip: 'Tháng trước',
            icon: const Icon(Icons.chevron_left, color: Colors.white),
            onPressed: () => onChanged(DateTime(month.year, month.month - 1))),
        Text('Tháng ${month.month}/${month.year}',
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        IconButton(
            tooltip: 'Tháng sau',
            icon: const Icon(Icons.chevron_right, color: Colors.white),
            onPressed: () => onChanged(DateTime(month.year, month.month + 1))),
      ],
    );
  }
}

class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const StatTile(
      {super.key,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
            color: const Color(0xFF151E2E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.4))),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    color: color, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
