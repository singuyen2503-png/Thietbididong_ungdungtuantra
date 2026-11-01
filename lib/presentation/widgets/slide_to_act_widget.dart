import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SlideToActWidget extends StatefulWidget {
  final VoidCallback onAction;
  final String text;

  const SlideToActWidget(
      {super.key, required this.onAction, required this.text});

  @override
  State<SlideToActWidget> createState() => _SlideToActWidgetState();
}

class _SlideToActWidgetState extends State<SlideToActWidget> {
  double _position = 0;
  bool _isDone = false;
  final double _height = 70;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxDrag = constraints.maxWidth - _height;
        return Container(
          height: _height,
          decoration: BoxDecoration(
            color: Colors.red.shade100,
            borderRadius: BorderRadius.circular(_height / 2),
          ),
          child: Stack(
            children: [
              Center(
                child: Text(
                  _isDone ? 'ĐANG KÍCH HOẠT...' : widget.text,
                  style: TextStyle(
                      color: Colors.red.shade900,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      letterSpacing: 1.2),
                ),
              ),
              Positioned(
                left: _position,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    if (_isDone) return;
                    setState(() {
                      _position += details.delta.dx;
                      if (_position < 0) _position = 0;
                      if (_position > maxDrag) _position = maxDrag;
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    if (_isDone) return;
                    if (_position > maxDrag * 0.8) {
                      setState(() {
                        _position = maxDrag;
                        _isDone = true;
                      });
                      HapticFeedback.heavyImpact();
                      widget.onAction();
                      Future.delayed(const Duration(seconds: 1), () {
                        if (mounted) {
                          setState(() {
                            _position = 0;
                            _isDone = false;
                          });
                        }
                      });
                    } else {
                      setState(() => _position = 0);
                      HapticFeedback.lightImpact();
                    }
                  },
                  child: Container(
                    height: _height,
                    width: _height,
                    decoration: BoxDecoration(
                        color: Colors.red.shade700,
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(2, 0))
                        ]),
                    child: const Icon(Icons.keyboard_double_arrow_right,
                        color: Colors.white, size: 36),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
