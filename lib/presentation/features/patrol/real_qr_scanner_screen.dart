import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import '../../../core/utils/qr_utils.dart';
import '../../../core/theme/app_theme.dart';

class RealQrScannerScreen extends StatefulWidget {
  final String expectedQr;
  const RealQrScannerScreen({super.key, required this.expectedQr});

  @override
  State<RealQrScannerScreen> createState() => _RealQrScannerScreenState();
}

class _RealQrScannerScreenState extends State<RealQrScannerScreen> {
  final MobileScannerController cameraController = MobileScannerController();
  StreamSubscription<BarcodeCapture>? _subscription;
  bool _isScanned = false;

  @override
  void initState() {
    super.initState();
    _subscription = cameraController.barcodes.listen(_onDetect);
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isScanned) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String? scannedRawValue = barcode.rawValue ?? barcode.displayValue;
      if (scannedRawValue != null) {
        final String scannedCode = scannedRawValue;

        if (qrMatches(scannedCode, widget.expectedQr)) {
          _isScanned = true;
          HapticFeedback.heavyImpact();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('XÁC NHẬN MỤC TIÊU THÀNH CÔNG! ($scannedCode)'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ));
          Navigator.pop(context, true);
        } else {
          HapticFeedback.heavyImpact();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Sai mã QR!\nQuét được: $scannedCode\nCần quét: ${widget.expectedQr}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ));

          _isScanned = true;
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) setState(() => _isScanned = false);
          });
        }
        break;
      }
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
          ),
          Stack(
            children: [
              ColorFiltered(
                colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.7), BlendMode.srcOut),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                          color: Colors.black,
                          backgroundBlendMode: BlendMode.dstOut),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        height: 250,
                        width: 250,
                        decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: Container(
                  height: 250,
                  width: 250,
                  decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primary, width: 3),
                      borderRadius: BorderRadius.circular(20)),
                  child: const Align(
                    alignment: Alignment.center,
                    child: Icon(Icons.add, color: AppColors.primary, size: 40),
                  ),
                ),
              ),
            ],
          ),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  iconTheme: const IconThemeData(color: Colors.white),
                  title: const Text('CAMERA HỆ THỐNG',
                      style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.bold)),
                  actions: [
                    IconButton(
                      color: Colors.white,
                      icon: const Icon(Icons.flash_on, color: Colors.yellow),
                      onPressed: () => cameraController.toggleTorch(),
                    ),
                    IconButton(
                      color: Colors.white,
                      icon: const Icon(Icons.cameraswitch),
                      onPressed: () => cameraController.switchCamera(),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Text('Đang quét: ${widget.expectedQr}',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 16,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.bold,
                          backgroundColor: Colors.black54)),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
