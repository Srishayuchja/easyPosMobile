import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ActionBar extends StatelessWidget {
  const ActionBar({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(children: children),
    );
  }
}
