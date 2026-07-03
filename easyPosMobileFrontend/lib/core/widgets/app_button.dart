import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum BtnKind { primary, surface, ghost, danger }
enum BtnSize { sm, md, lg }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = BtnKind.primary,
    this.size = BtnSize.lg,
    this.icon,
    this.disabled = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final BtnKind kind;
  final BtnSize size;
  final Widget? icon;
  final bool disabled;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final h = size == BtnSize.sm ? 36.0 : size == BtnSize.md ? 44.0 : 52.0;
    final fs = size == BtnSize.sm ? 13.0 : 15.0;

    Color bg, fg;
    Border? border;

    switch (kind) {
      case BtnKind.primary:
        bg = AppColors.accent;
        fg = AppColors.accentInk;
        break;
      case BtnKind.surface:
        bg = AppColors.surface;
        fg = AppColors.text;
        border = Border.all(color: AppColors.border);
        break;
      case BtnKind.ghost:
        bg = Colors.transparent;
        fg = AppColors.text;
        border = Border.all(color: AppColors.border);
        break;
      case BtnKind.danger:
        bg = Colors.transparent;
        fg = AppColors.danger;
        border = Border.all(color: AppColors.danger.withOpacity(0.2));
        break;
    }

    Widget child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[icon!, const SizedBox(width: 8)],
        Text(label,
            style: TextStyle(
              color: fg,
              fontSize: fs,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
            )),
      ],
    );

    Widget btn = GestureDetector(
      onTap: disabled ? null : onPressed,
      child: AnimatedOpacity(
        opacity: disabled ? 0.45 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          height: h,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: border,
            boxShadow: kind == BtnKind.primary && !disabled
                ? [BoxShadow(color: AppColors.accent.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 6))]
                : null,
          ),
          child: child,
        ),
      ),
    );

    return expand ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}
