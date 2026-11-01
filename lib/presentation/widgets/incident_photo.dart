import 'dart:convert';

import 'package:flutter/material.dart';

class IncidentPhoto extends StatelessWidget {
  final String imageBase64;
  const IncidentPhoto({super.key, required this.imageBase64});

  @override
  Widget build(BuildContext context) {
    final bytes = base64Decode(imageBase64);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ẢNH HIỆN TRƯỜNG:',
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => showDialog(
            context: context,
            builder: (ctx) => Dialog(
              backgroundColor: Colors.black,
              insetPadding: const EdgeInsets.all(12),
              child: InteractiveViewer(child: Image.memory(bytes)),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(bytes,
                height: 220, width: double.infinity, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
