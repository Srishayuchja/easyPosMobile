import 'package:flutter/material.dart';

class ProdAvatar extends StatelessWidget {
  const ProdAvatar({super.key, required this.name, this.size = 40});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initials = name
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    // Simple hash for hue selection
    int h = 0;
    for (final c in name.codeUnits) {
      h = (h * 31 + c) % 360;
    }

    final bg = HSLColor.fromAHSL(1, h.toDouble(), 0.35, 0.22).toColor();
    final fg = HSLColor.fromAHSL(1, h.toDouble(), 0.60, 0.75).toColor();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: fg,
          fontSize: size * 0.36,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
