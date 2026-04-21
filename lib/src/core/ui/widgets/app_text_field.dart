import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:flutter/material.dart';

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.initialValue,
    required this.label,
    this.hintText,
    this.helperText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.enabled = true,
    this.textInputAction,
    this.keyboardType,
    this.onSubmitted,
    this.onChanged,
    this.validator,
    this.autofillHints,
    this.maxLines = 1,
  });

  final TextEditingController? controller;
  final String? initialValue;
  final String label;
  final String? hintText;
  final String? helperText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final bool enabled;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final List<String>? autofillHints;
  final int? maxLines;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != null && widget.controller != oldWidget.controller) {
      _controller = widget.controller!;
    } else if (widget.initialValue != null && widget.initialValue != oldWidget.initialValue) {
      _controller.text = widget.initialValue!;
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return TextFormField(
      controller: _controller,
      enabled: widget.enabled,
      obscureText: widget.obscureText,
      textInputAction: widget.textInputAction,
      keyboardType: widget.keyboardType,
      onFieldSubmitted: widget.onSubmitted,
      onChanged: widget.onChanged,
      validator: widget.validator,
      autofillHints: widget.autofillHints,
      maxLines: widget.maxLines,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hintText,
        helperText: widget.helperText,
        prefixIcon: widget.prefixIcon == null ? null : Icon(widget.prefixIcon),
        suffixIcon: widget.suffixIcon,
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
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadii.r12,
          borderSide: BorderSide(color: cs.error, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadii.r12,
          borderSide: BorderSide(color: cs.error, width: 1.2),
        ),
        errorStyle: TextStyle(
          color: cs.error,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
