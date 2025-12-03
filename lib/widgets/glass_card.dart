import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;

  const GlassCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1), // 10% 透明度
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white30, width: 0.5),
      ),
      child: child,
    );
  }
}