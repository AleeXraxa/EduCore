import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:flutter/material.dart';

class AppTextArea extends StatelessWidget {
  const AppTextArea({
    super.key,
    required this.controller,
    required this.label,
    this.hintText,
    this.enabled = true,
    this.minLines = 4,
    this.maxLines = 8,
  });

  final TextEditingController controller;
  final String label;
  final String? hintText;
  final bool enabled;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return TextField(
      controller: controller,
      enabled: enabled,
      minLines: minLines,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        alignLabelWithHint: true,
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.r12,
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.r12,
          borderSide: BorderSide(color: cs.primary, width: 1.2),
        ),
      ),
    );
  }
}

