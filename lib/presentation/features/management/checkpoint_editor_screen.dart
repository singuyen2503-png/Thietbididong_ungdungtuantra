import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/lat_lng.dart';
import '../../../core/utils/qr_utils.dart';
import '../../../domain/entities/models.dart';
import '../../state/manager_state.dart';
import '../../state/workforce_state.dart';
import '../../widgets/tactical_map.dart';

class CheckpointEditorScreen extends ConsumerStatefulWidget {
  final String routeId;
  final CheckpointConfig? checkpoint;

  const CheckpointEditorScreen(
      {super.key, required this.routeId, this.checkpoint});

  @override
  ConsumerState<CheckpointEditorScreen> createState() =>
      _CheckpointEditorScreenState();
}

class _CheckpointEditorScreenState
    extends ConsumerState<CheckpointEditorScreen> {
  static const _accent = AppColors.setup;

  late final TextEditingController _nameCtrl;
  late final TextEditingController _qrCtrl;
  late bool _qrEdited;
  LatLng? _location;
  double _radius = 15;
  bool _locating = false;

  bool get _isEdit => widget.checkpoint != null;

  @override
  void initState() {
    super.initState();
    final cp = widget.checkpoint;
    _nameCtrl = TextEditingController(text: cp?.name ?? '');
    _qrCtrl = TextEditingController(text: cp?.expectedQrCode ?? '');
    _qrEdited = cp != null;
    _location = cp?.location;
    _radius = cp?.radiusMeters ?? 15;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qrCtrl.dispose();
    super.dispose();
  }

  void _toast(String text, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(text),
        backgroundColor: error ? Colors.red : Colors.green));
  }

  Future<void> _useGps() async {
    setState(() => _locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw 'Hãy bật định vị (GPS) trên điện thoại!';
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw 'Ứng dụng chưa được cấp quyền vị trí!';
      }
      final pos = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.high));
      if (!mounted) return;
      setState(() => _location = LatLng(pos.latitude, pos.longitude));
      HapticFeedback.selectionClick();
    } catch (e) {
      if (mounted) {
        _toast(e is String ? e : 'Không lấy được vị trí GPS!', error: true);
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _save() {
    final location = _location;
    if (location == null) {
      _toast('Chạm vào bản đồ hoặc dùng GPS để chọn vị trí!', error: true);
      return;
    }
    final error = saveCheckpoint(
        ref.read,
        widget.routeId,
        CheckpointConfig(
            id: widget.checkpoint?.id ??
                'cp${DateTime.now().microsecondsSinceEpoch}',
            name: _nameCtrl.text,
            expectedQrCode: _qrCtrl.text,
            location: location,
            radiusMeters: _radius));
    if (error != null) {
      HapticFeedback.heavyImpact();
      _toast(error, error: true);
      return;
    }
    HapticFeedback.mediumImpact();
    _toast(_isEdit ? 'Đã cập nhật địa điểm' : 'Đã thêm địa điểm & mã QR mới');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final route = ref
        .watch(routeConfigsProvider)
        .where((r) => r.id == widget.routeId)
        .firstOrNull;
    final others = [
      for (final c in route?.checkpoints ?? const <CheckpointConfig>[])
        if (c.id != widget.checkpoint?.id)
          Checkpoint(
              id: c.id,
              name: c.name,
              expectedQrCode: c.expectedQrCode,
              location: c.location,
              radiusMeters: c.radiusMeters,
              isScanned: true),
    ];
    final name = _nameCtrl.text.trim();
    final code = normalizeQr(_qrCtrl.text);

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: _accent),
        title: Text(_isEdit ? 'SỬA ĐỊA ĐIỂM' : 'THÊM ĐỊA ĐIỂM',
            style: const TextStyle(color: _accent)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Lộ trình: ${route?.name ?? '—'}',
              style: const TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 10),
          Container(
            height: 280,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _accent.withValues(alpha: 0.5))),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: TacticalMap(
                siteTracks: ref.watch(siteTrackPointsProvider),
                plannedPath: route?.plannedPath ?? const [],
                checkpoints: [
                  ...others,
                  if (_location != null)
                    Checkpoint(
                        id: 'new',
                        name: name.isEmpty ? 'Điểm mới' : name,
                        expectedQrCode: code,
                        location: _location!,
                        radiusMeters: _radius),
                ],
                onTap: (p) {
                  HapticFeedback.selectionClick();
                  setState(() => _location = p);
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                    _location == null
                        ? 'Chạm bản đồ để đặt vị trí (điểm xanh: các điểm sẵn có)'
                        : 'Vị trí: ${_location!.latitude.toStringAsFixed(6)}, '
                            '${_location!.longitude.toStringAsFixed(6)}',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12)),
              ),
              TextButton.icon(
                onPressed: _locating ? null : _useGps,
                icon: _locating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.my_location, size: 18),
                label: const Text('VỊ TRÍ GPS'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('cp-name'),
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
                labelText: 'Tên địa điểm (VD: Cổng sau)',
                prefixIcon: Icon(Icons.place)),
            onChanged: (v) => setState(() {
              if (!_qrEdited) _qrCtrl.text = normalizeQr(v);
            }),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('cp-qr'),
            controller: _qrCtrl,
            decoration: const InputDecoration(
                labelText: 'Nội dung mã QR',
                helperText: 'Không phân biệt hoa thường, không được trùng',
                prefixIcon: Icon(Icons.qr_code)),
            onChanged: (_) => setState(() => _qrEdited = true),
          ),
          const SizedBox(height: 12),
          Text('Bán kính quét: ${_radius.toStringAsFixed(0)} m',
              style: const TextStyle(color: Colors.white)),
          Slider(
            value: _radius,
            min: 5,
            max: 50,
            divisions: 9,
            label: '${_radius.toStringAsFixed(0)} m',
            activeColor: _accent,
            onChanged: (v) => setState(() => _radius = v),
          ),
          const SizedBox(height: 4),
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: code.isEmpty
                  ? const SizedBox(
                      width: 140,
                      height: 140,
                      child: Center(
                          child: Text('Nhập tên để tạo mã QR',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.black54))))
                  : QrImageView(
                      data: code, size: 140, backgroundColor: Colors.white),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: _accent),
              icon: const Icon(Icons.save),
              label: const Text('LƯU ĐỊA ĐIỂM'),
              onPressed: _save,
            ),
          ),
        ],
      ),
    );
  }
}
