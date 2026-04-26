import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:flutter/material.dart';

class AppMultiDropdown<T> extends StatefulWidget {
  const AppMultiDropdown({
    super.key,
    required this.label,
    required this.items,
    required this.values,
    required this.onChanged,
    required this.itemLabel,
    this.hintText,
    this.prefixIcon,
    this.enabled = true,
    this.compact = false,
    this.showLabel = true,
    this.searchable = false,
  });

  final String label;
  final List<T> items;
  final List<T> values;
  final ValueChanged<List<T>> onChanged;
  final String Function(T item) itemLabel;
  final String? hintText;
  final IconData? prefixIcon;
  final bool enabled;
  final bool compact;
  final bool showLabel;
  final bool searchable;

  @override
  State<AppMultiDropdown<T>> createState() => _AppMultiDropdownState<T>();
}

class _AppMultiDropdownState<T> extends State<AppMultiDropdown<T>> {
  late final MultiSelectController<T> _controller =
      MultiSelectController<T>(widget.values);

  @override
  void didUpdateWidget(covariant AppMultiDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.values != widget.values) {
      // Defer to next frame to avoid "setState during build" exception
      // if the parent clears values after an action.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _controller.value = widget.values;
        }
      });
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

    final decoration = CustomDropdownDecoration(
      closedFillColor: AppColors.surface,
      expandedFillColor: AppColors.surface,
      prefixIcon: widget.prefixIcon == null ? null : Icon(widget.prefixIcon),
      closedSuffixIcon: Icon(
        Icons.expand_more_rounded,
        color: cs.onSurfaceVariant,
        size: 20,
      ),
      expandedSuffixIcon: Icon(
        Icons.expand_less_rounded,
        color: cs.onSurfaceVariant,
        size: 20,
      ),
      closedBorder: Border.all(color: cs.outlineVariant),
      expandedBorder: Border.all(color: cs.primary, width: 1.2),
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
        selectedIconShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      searchFieldDecoration: SearchFieldDecoration(
        hintStyle: hintStyle,
        textStyle: headerStyle,
        fillColor: cs.surface,
        border: OutlineInputBorder(
          borderRadius: AppRadii.r12,
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.r12,
          borderSide: BorderSide(color: cs.primary, width: 1.2),
        ),
      ),
    );

    Widget headerListBuilder(context, List<T> selectedItems, enabled) {
      if (selectedItems.isEmpty) {
        return Text(
          widget.hintText ?? 'Select',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: hintStyle,
        );
      }
      final label = selectedItems.length == 1
          ? widget.itemLabel(selectedItems.first)
          : '${selectedItems.length} selected';
      return Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: headerStyle,
      );
    }

    Widget listItemBuilder(context, item, isSelected, onItemSelect) {
      final fg = isSelected ? cs.primary : cs.onSurface;
      return InkWell(
        onTap: onItemSelect,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.itemLabel(item as T),
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
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showLabel) ...[
          Text(widget.label, style: labelStyle),
          const SizedBox(height: 8),
        ],
        () {
          if (widget.searchable) {
            return CustomDropdown<T>.multiSelectSearch(
              items: widget.items,
              multiSelectController: _controller,
              enabled: widget.enabled,
              hintText: widget.hintText ?? 'Select',
              closedHeaderPadding: closedPad,
              expandedHeaderPadding: closedPad,
              listItemPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              maxlines: 1,
              onListChanged: (values) => widget.onChanged(values),
              decoration: decoration,
              headerListBuilder: headerListBuilder,
              listItemBuilder: listItemBuilder,
            );
          } else {
            return CustomDropdown<T>.multiSelect(
              items: widget.items,
              multiSelectController: _controller,
              enabled: widget.enabled,
              hintText: widget.hintText ?? 'Select',
              closedHeaderPadding: closedPad,
              expandedHeaderPadding: closedPad,
              listItemPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              maxlines: 1,
              onListChanged: (values) => widget.onChanged(values),
              decoration: decoration,
              headerListBuilder: headerListBuilder,
              listItemBuilder: listItemBuilder,
            );
          }
        }(),
      ],
    );
  }
}

