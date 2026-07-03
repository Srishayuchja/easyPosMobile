import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.placeholder,
    this.prefix,
    this.suffix,
    this.numeric = false,
    this.obscure = false,
    this.noCorrect = false,
    this.autofocus = false,
    this.trailing,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String? placeholder;
  final String? prefix;
  final String? suffix;
  final bool numeric;
  final bool obscure;
  final bool noCorrect;
  final bool autofocus;
  final Widget? trailing;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                  letterSpacing: 0.2,
                )),
          ),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              if (prefix != null)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(prefix!,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      )),
                ),
              Expanded(
                child: TextField(
                  controller: controller,
                  autofocus: autofocus,
                  obscureText: obscure,
                  onChanged: onChanged,
                  autocorrect: !obscure && !noCorrect,
                  enableSuggestions: !obscure && !noCorrect,
                  textCapitalization: TextCapitalization.none,
                  keyboardType: numeric ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
                  inputFormatters: numeric ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))] : null,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: placeholder,
                    hintStyle: const TextStyle(color: AppColors.textDim),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                ),
              ),
              if (suffix != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Text(suffix!,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                ),
              if (trailing != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: trailing!,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
