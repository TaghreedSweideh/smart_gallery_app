import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class DotsLoader extends StatefulWidget {
  final Color color;
  final double dotSize;
  final int dotCount;
  final Duration duration;

  const DotsLoader({
    super.key,
    this.color = Colors.black54,
    this.dotSize = 8,
    this.dotCount = 3,
    this.duration = const Duration(seconds: 1),
  });

  @override
  State<DotsLoader> createState() => _DotsLoaderState();
}

class _DotsLoaderState extends State<DotsLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.dotCount, (i) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            double progress = (_controller.value + i * 0.2) % 1.0;
            double scale = 1 + (0.5 * (1 - (progress - 0.5).abs() * 2));
            double opacity = 0.5 + 0.5 * (1 - (progress - 0.5).abs() * 2);
            return Opacity(
              opacity: opacity,
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 1.w),
                width: widget.dotSize * scale,
                height: widget.dotSize * scale,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
