import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../core/theme/app_text_styles.dart';

class SyncProgress extends StatelessWidget {
  final double progress; // 0.0 .. 1.0
  final Color primary;
  final Color background;

  const SyncProgress({
    super.key,
    required this.progress,
    this.primary = Colors.lightBlue,
    this.background = const Color(0xFFE6EAF0),
  });

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).clamp(0, 100).toInt();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 60.w,
          height: 6, // thin bar
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: background,
              valueColor: AlwaysStoppedAnimation<Color>(primary),
              minHeight: 6,
            ),
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          progress < 1.0 ? 'Syncing $pct%' : 'Finalizing...',
          style: AppTextStyles.label.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }
}
