import 'package:flutter/material.dart';

enum AppButtonVariant { primary, secondary, danger }

class AppPrimaryButton extends StatefulWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.busy = false,
    this.variant = AppButtonVariant.primary,
    this.width,
    this.height = 48,
    this.color,
    this.textColor,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool busy;
  final AppButtonVariant variant;
  final double? width;
  final double height;
  final Color? color;
  final Color? textColor;

  @override
  State<AppPrimaryButton> createState() => _AppPrimaryButtonState();
}

class _AppPrimaryButtonState extends State<AppPrimaryButton>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final primaryColor = widget.color ?? switch (widget.variant) {
      AppButtonVariant.primary => cs.primary,
      AppButtonVariant.secondary => cs.secondary,
      AppButtonVariant.danger => const Color(0xFFDC2626),
    };

    final textColor = widget.textColor ?? switch (widget.variant) {
      AppButtonVariant.primary => Colors.white,
      AppButtonVariant.secondary => cs.onSurface,
      AppButtonVariant.danger => Colors.white,
    };

    if (widget.variant == AppButtonVariant.secondary && widget.color == null) {
      return _buildSecondary(cs, textColor);
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: widget.onPressed == null || widget.busy
          ? SystemMouseCursors.forbidden
          : SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.busy ? null : widget.onPressed,
        child: AnimatedScale(
          scale: _pressed ? 0.96 : (_hovered ? 1.02 : 1.0),
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              gradient: widget.onPressed == null
                  ? null
                  : LinearGradient(
                      colors: [primaryColor, primaryColor.withValues(alpha: 0.85)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              color: widget.onPressed == null ? cs.onSurface.withValues(alpha: 0.12) : null,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                if (_hovered && widget.onPressed != null && !widget.busy)
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.center,
            child: widget.busy
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(textColor),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, color: textColor, size: 20),
                        const SizedBox(width: 10),
                      ],
                      Flexible(
                        child: Text(
                          widget.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondary(ColorScheme cs, Color textColor) {
    return OutlinedButton.icon(
      onPressed: widget.busy ? null : widget.onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: BorderSide(color: cs.outlineVariant),
        backgroundColor: _hovered ? cs.surfaceContainerHighest : Colors.transparent,
      ).copyWith(
        elevation: WidgetStateProperty.resolveWith((states) => 0),
      ),
      icon: widget.busy
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: textColor),
            )
          : (widget.icon != null
              ? Icon(widget.icon, size: 20)
              : const SizedBox.shrink()),
      label: Text(
        widget.label,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}
