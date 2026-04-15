import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:flutter/material.dart';

class AppSearchField extends StatefulWidget {
  const AppSearchField({
    super.key,
    this.controller,
    this.hintText = 'Search...',
    this.onChanged,
    this.onSubmitted,
    this.width,
  });

  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final double? width;

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  late final TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _hasText = _controller.text.isNotEmpty;
    _controller.addListener(_handleTextChanged);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    } else {
      _controller.removeListener(_handleTextChanged);
    }
    super.dispose();
  }

  void _handleTextChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
    widget.onChanged?.call(_controller.text);
  }

  void _clear() {
    _controller.clear();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      width: widget.width,
      child: TextField(
        controller: _controller,
        onSubmitted: widget.onSubmitted,
        textAlignVertical: TextAlignVertical.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
              ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Icon(
              Icons.search_rounded,
              color: cs.onSurfaceVariant.withValues(alpha: 0.7),
              size: 20,
            ),
          ),
          suffixIcon: _hasText
              ? IconButton(
                  onPressed: _clear,
                  icon: Icon(
                    Icons.cancel_rounded,
                    size: 18,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  splashRadius: 16,
                )
              : null,
          filled: true,
          fillColor: AppColors.surface,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppRadii.r12,
            borderSide: BorderSide(
              color: cs.outlineVariant.withValues(alpha: 0.8),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppRadii.r12,
            borderSide: BorderSide(
              color: cs.primary,
              width: 1.5,
            ),
          ),
          hoverColor: cs.primary.withValues(alpha: 0.02),
        ),
      ),
    );
  }
}
