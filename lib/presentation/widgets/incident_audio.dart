import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class IncidentAudio extends StatefulWidget {
  final String audioPath;
  final VoidCallback? onRemove;
  const IncidentAudio({super.key, required this.audioPath, this.onRemove});

  @override
  State<IncidentAudio> createState() => _IncidentAudioState();
}

class _IncidentAudioState extends State<IncidentAudio> {
  final AudioPlayer _player = AudioPlayer();
  late final StreamSubscription<void> _completeSub;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _completeSub = _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isPlaying = false);
    });
  }

  @override
  void dispose() {
    _completeSub.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    try {
      if (_isPlaying) {
        await _player.stop();
        if (mounted) setState(() => _isPlaying = false);
      } else {
        await _player.play(DeviceFileSource(widget.audioPath));
        if (mounted) setState(() => _isPlaying = true);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isPlaying = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Không phát được bản ghi âm!'),
          backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
          color: const Color(0xFF151E2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12)),
      child: Row(
        children: [
          const Icon(Icons.graphic_eq, color: Color(0xFF00FF9D)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
                _isPlaying ? 'Đang phát ghi âm...' : 'Ghi âm hiện trường',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          IconButton(
            tooltip: _isPlaying ? 'Dừng' : 'Nghe',
            icon: Icon(_isPlaying ? Icons.stop_circle : Icons.play_circle_fill,
                color: const Color(0xFF00FF9D), size: 36),
            onPressed: _toggle,
          ),
          if (widget.onRemove != null)
            IconButton(
              tooltip: 'Xóa ghi âm',
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () async {
                await _player.stop();
                widget.onRemove!();
              },
            ),
        ],
      ),
    );
  }
}
