import 'package:flutter/material.dart';

class MockQrScannerScreen extends StatefulWidget {
  final String expectedQr;
  const MockQrScannerScreen({super.key, required this.expectedQr});

  @override
  State<MockQrScannerScreen> createState() => _MockQrScannerScreenState();
}

class _MockQrScannerScreenState extends State<MockQrScannerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) Navigator.pop(context, true);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          ColorFiltered(
            colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.8), BlendMode.srcOut),
            child: Stack(
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
                  border: Border.all(color: Colors.green, width: 4),
                  borderRadius: BorderRadius.circular(20)),
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Stack(
                    children: [
                      Positioned(
                        top: _animationController.value * 230,
                        left: 0,
                        right: 0,
                        child: Container(
                            height: 3,
                            decoration: const BoxDecoration(
                                color: Colors.redAccent,
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.red,
                                      blurRadius: 10,
                                      spreadRadius: 2)
                                ])),
                      )
                    ],
                  );
                },
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                    icon:
                        const Icon(Icons.close, color: Colors.white, size: 40),
                    onPressed: () => Navigator.pop(context, false)),
                const Text('Đang quét mã QR...',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                IconButton(
                    icon: const Icon(Icons.flash_on,
                        color: Colors.white, size: 40),
                    onPressed: () {}),
              ],
            ),
          )
        ],
      ),
    );
  }
}
