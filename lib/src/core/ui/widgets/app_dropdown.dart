import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:flutter/material.dart';

class AppDropdown<T> extends StatefulWidget {
  const AppDropdown({
    super.key,
    required this.label,
    required this.items,
    required this.value,
    required this.onChanged,
    required this.itemLabel,
    this.hintText,
    this.prefixIcon,
    this.enabled = true,
    this.compact = false,
    this.showLabel = true,
    this.validator,
  });

  final String label;
  final List<T> items;
  final T? value;
  final ValueChanged<T?> onChanged;
  final String Function(T item) itemLabel;
  final String? hintText;
  final IconData? prefixIcon;
  final bool enabled;
  final String? Function(T?)? validator;

  /// When true, uses a slightly tighter vertical rhythm (toolbars/filters).
  final bool compact;

  /// Hide the label row (useful for toolbars where label is implied).
  final bool showLabel;

  @override
  State<AppDropdown<T>> createState() => _AppDropdownState<T>();
}

class _AppDropdownState<T> extends State<AppDropdown<T>> {
  late final SingleSelectController<T?> _controller =
      SingleSelectController<T?>(widget.value);

  @override
  void didUpdateWidget(covariant AppDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.value = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final labelStyle = textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w800,
      color: cs.onSurfaceVariant,
    );

    final headerStyle = textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: -0.1,
      color: cs.onSurface,
    );

    final hintStyle = textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w700,
      color: cs.onSurfaceVariant,
    );

    final listItemStyle = textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w700,
      color: cs.onSurface,
    );

    final closedPad = widget.compact
        ? const EdgeInsets.symmetric(horizontal: 14, vertical: 12)
        : const EdgeInsets.symmetric(horizontal: 14, vertical: 14);

    return FormField<T>(
      initialValue: widget.value,
      validator: widget.validator,
      builder: (FormFieldState<T> state) {
        final hasError = state.hasError;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showLabel) ...[
              Text(
                widget.label,
                style: labelStyle?.copyWith(
                  color: hasError ? cs.error : cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
            ],
            CustomDropdown<T>(
              items: widget.items,
              controller: _controller,
              enabled: widget.enabled,
              hintText: widget.hintText ?? 'Select',
              closedHeaderPadding: closedPad,
              expandedHeaderPadding: closedPad,
              listItemPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              maxlines: 1,
              onChanged: (value) {
                state.didChange(value);
                widget.onChanged(value);
              },
              decoration: CustomDropdownDecoration(
                closedFillColor: AppColors.surface,
                expandedFillColor: AppColors.surface,
                prefixIcon: widget.prefixIcon == null
                    ? null
                    : Icon(widget.prefixIcon),
                closedSuffixIcon: Icon(
                  Icons.expand_more_rounded,
                  color: hasError ? cs.error : cs.onSurfaceVariant,
                  size: 20,
                ),
                expandedSuffixIcon: Icon(
                  Icons.expand_less_rounded,
                  color: hasError ? cs.error : cs.onSurfaceVariant,
                  size: 20,
                ),
                closedBorder: Border.all(
                  color: hasError ? cs.error : cs.outlineVariant,
                  width: hasError ? 1.2 : 1.0,
                ),
                expandedBorder: Border.all(
                  color: hasError ? cs.error : cs.primary,
                  width: 1.2,
                ),
                closedBorderRadius: AppRadii.r12,
                expandedBorderRadius: AppRadii.r12,
                closedShadow: AppShadows.soft(Colors.black),
                expandedShadow: AppShadows.soft(Colors.black),
                hintStyle: hintStyle,
                headerStyle: headerStyle,
                listItemStyle: listItemStyle,
                listItemDecoration: ListItemDecoration(
                  highlightColor: cs.surfaceContainerHighest,
                  selectedColor: cs.primary.withValues(alpha: 0.08),
                  splashColor: cs.primary.withValues(alpha: 0.08),
                  selectedIconColor: cs.primary,
                  selectedIconBorder: BorderSide(color: cs.primary, width: 2),
                  selectedIconShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                searchFieldDecoration: SearchFieldDecoration(
                  hintStyle: hintStyle,
                  textStyle: headerStyle,
                  fillColor: cs.surface,
                  border: OutlineInputBorder(
                    borderRadius: AppRadii.r12,
                    borderSide: BorderSide(
                      color: hasError ? cs.error : cs.outlineVariant,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppRadii.r12,
                    borderSide: BorderSide(
                      color: hasError ? cs.error : cs.primary,
                      width: 1.2,
                    ),
                  ),
                ),
              ),
              headerBuilder: (context, selectedItem, enabled) {
                return Text(
                  widget.itemLabel(selectedItem),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: headerStyle,
                );
              },
              hintBuilder: (context, hint, enabled) {
                return Text(
                  hint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: hintStyle,
                );
              },
              listItemBuilder: (context, item, isSelected, onItemSelect) {
                final fg = isSelected ? cs.primary : cs.onSurface;
                return InkWell(
                  onTap: onItemSelect,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.itemLabel(item),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: listItemStyle?.copyWith(color: fg),
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_rounded,
                            size: 18,
                            color: cs.primary,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            if (hasError) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  state.errorText!,
                  style: textTheme.bodySmall?.copyWith(color: cs.error),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
