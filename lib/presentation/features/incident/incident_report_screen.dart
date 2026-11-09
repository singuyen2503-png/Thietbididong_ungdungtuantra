import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/manager_state.dart';
import '../../../domain/entities/models.dart';
import '../../widgets/incident_audio.dart';
import '../../../core/theme/app_theme.dart';

class IncidentReportScreen extends ConsumerStatefulWidget {
  const IncidentReportScreen({super.key});

  @override
  ConsumerState<IncidentReportScreen> createState() =>
      _IncidentReportScreenState();
}

class _IncidentReportScreenState extends ConsumerState<IncidentReportScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  bool _isSubmitting = false;
  IncidentSeverity _selectedSeverity = IncidentSeverity.medium;
  Uint8List? _photo;
  final ImagePicker _picker = ImagePicker();
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;
  String? _audioPath;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _recordTimer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  Future<void> _toggleRecording() async {
    HapticFeedback.selectionClick();
    try {
      if (_isRecording) {
        final path = await _recorder.stop();
        _recordTimer?.cancel();
        if (mounted) {
          setState(() {
            _isRecording = false;
            _audioPath = path;
          });
        }
        return;
      }
      if (!await _recorder.hasPermission()) {
        if (mounted) _showError('Cần cấp quyền Micro để ghi âm hiện trường!');
        return;
      }
      _deleteAudioFile();
      final dir = await getApplicationDocumentsDirectory();
      final path =
          '${dir.path}/incident_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(const RecordConfig(), path: path);
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _recordSeconds++);
      });
      if (mounted) {
        setState(() {
          _isRecording = true;
          _recordSeconds = 0;
          _audioPath = null;
        });
      }
    } catch (e) {
      _recordTimer?.cancel();
      if (mounted) {
        setState(() => _isRecording = false);
        _showError('Không ghi âm được: $e');
      }
    }
  }

  void _deleteAudioFile() {
    final path = _audioPath;
    if (path == null) return;
    final file = File(path);
    if (file.existsSync()) file.deleteSync();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    HapticFeedback.selectionClick();
    try {
      if (!kIsWeb && source == ImageSource.camera) {
        final status = await Permission.camera.request();
        if (!status.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Cần cấp quyền Camera để chụp ảnh hiện trường!'),
                backgroundColor: Colors.red));
          }
          return;
        }
      }
      final file = await _picker.pickImage(
          source: source, maxWidth: 1024, imageQuality: 60);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (mounted) setState(() => _photo = bytes);
    } catch (e) {
      if (mounted) _showError('Không lấy được ảnh: $e');
    }
  }

  void _submitReport() async {
    if (_titleController.text.trim().isEmpty ||
        _descController.text.trim().isEmpty) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('CẢNH BÁO: Vui lòng nhập Tiêu đề và Mô tả!'),
          backgroundColor: Colors.red));
      return;
    }

    if (_selectedSeverity == IncidentSeverity.critical && _photo == null) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('LỖI: Mức độ KHẨN CẤP bắt buộc phải đính kèm hình ảnh!'),
          backgroundColor: Colors.red));
      return;
    }

    if (_isRecording) await _toggleRecording();
    if (!mounted) return;

    setState(() => _isSubmitting = true);
    HapticFeedback.lightImpact();

    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    final newIncident = Incident(
      id: DateTime.now().toString(),
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      reportedBy:
          ref.read(currentGuardProvider)?.name ?? 'Bảo vệ (Ca hiện tại)',
      createdAt: DateTime.now(),
      severity: _selectedSeverity,
      imageBase64: _photo == null ? null : base64Encode(_photo!),
      audioPath: _audioPath,
    );

    ref.read(incidentsProvider.notifier).addIncident(newIncident);

    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('HOÀN TẤT: Đã truyền báo cáo về Trung tâm!'),
        backgroundColor: Colors.green));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('BÁO CÁO SỰ CỐ',
            style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
                fontFamily: 'Roboto',
                letterSpacing: 1)),
        iconTheme: const IconThemeData(color: Colors.redAccent),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('THÔNG TIN SỰ CỐ',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 1)),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                  hintText: 'Tiêu đề ngắn gọn (VD: Đột nhập, Cháy)...',
                  hintStyle: TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(borderSide: BorderSide.none)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                  hintText: 'Mô tả chi tiết...',
                  hintStyle: TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(borderSide: BorderSide.none)),
            ),
            const SizedBox(height: 32),
            const Text('MỨC ĐỘ NGHIÊM TRỌNG',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 1)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: IncidentSeverity.values.map((sev) {
                final isSelected = _selectedSeverity == sev;
                Color color = Colors.grey;
                if (sev == IncidentSeverity.low) color = Colors.blue;
                if (sev == IncidentSeverity.medium) color = Colors.orange;
                if (sev == IncidentSeverity.high) color = Colors.red;
                if (sev == IncidentSeverity.critical) {
                  color = Colors.purpleAccent;
                }

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedSeverity = sev);
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: isSelected
                              ? color.withValues(alpha: 0.2)
                              : Colors.transparent,
                          border: Border.all(
                              color: isSelected ? color : Colors.white12,
                              width: 2),
                          borderRadius: BorderRadius.circular(8)),
                      child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(sev.vietnameseName,
                              style: TextStyle(
                                  color: isSelected ? color : Colors.white54,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Roboto'))),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            const Text('BẰNG CHỨNG HIỆN TRƯỜNG',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 1)),
            const SizedBox(height: 8),
            const Text('* Mức KHẨN CẤP bắt buộc phải có hình ảnh.',
                style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 12,
                    fontStyle: FontStyle.italic)),
            const SizedBox(height: 16),
            if (_photo != null) ...[
              Stack(
                children: [
                  ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(_photo!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover)),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton.filled(
                      style:
                          IconButton.styleFrom(backgroundColor: Colors.black54),
                      icon: const Icon(Icons.close, color: Colors.white),
                      tooltip: 'Bỏ ảnh',
                      onPressed: () => setState(() => _photo = null),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                    child: _photoButton(
                        Icons.camera_alt,
                        _photo == null ? 'CHỤP ẢNH' : 'CHỤP LẠI',
                        () => _pickPhoto(ImageSource.camera))),
                const SizedBox(width: 12),
                Expanded(
                    child: _photoButton(Icons.photo_library, 'THƯ VIỆN',
                        () => _pickPhoto(ImageSource.gallery))),
              ],
            ),
            if (!kIsWeb) ...[
              const SizedBox(height: 24),
              if (_audioPath != null && !_isRecording)
                IncidentAudio(
                  audioPath: _audioPath!,
                  onRemove: () {
                    _deleteAudioFile();
                    setState(() => _audioPath = null);
                  },
                ),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _toggleRecording,
                  icon: Icon(_isRecording ? Icons.stop : Icons.mic,
                      color: _isRecording ? Colors.redAccent : Colors.white70),
                  label: Text(
                      _isRecording
                          ? 'DỪNG GHI ÂM  ${_recordSeconds ~/ 60}:${(_recordSeconds % 60).toString().padLeft(2, '0')}'
                          : (_audioPath == null
                              ? 'GHI ÂM HIỆN TRƯỜNG'
                              : 'GHI ÂM LẠI'),
                      style: TextStyle(
                          color: _isRecording
                              ? Colors.redAccent
                              : Colors.white70)),
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(
                          color: _isRecording
                              ? Colors.redAccent
                              : Colors.white12)),
                ),
              ),
            ],
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade900,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('TRUYỀN TIN CẢNH BÁO',
                        style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Roboto',
                            letterSpacing: 2)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _photoButton(IconData icon, String label, VoidCallback onPressed) {
    final color = _photo != null ? AppColors.primary : Colors.white70;
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: color),
      label: Text(label, style: TextStyle(color: color)),
      style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(
              color: _photo != null ? AppColors.primary : Colors.white12)),
    );
  }
}
