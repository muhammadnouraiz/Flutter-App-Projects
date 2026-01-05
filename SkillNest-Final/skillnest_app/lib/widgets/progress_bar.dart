import 'package:flutter/material.dart';

class ProgressBar extends StatelessWidget {
  final int progress;
  const ProgressBar({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(
        value: progress / 100,
        backgroundColor: Colors.grey[300],
        color: const Color(0xFFFF6B4A),
        minHeight: 8,
      ),
    );
  }
}
