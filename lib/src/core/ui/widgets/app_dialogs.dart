import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/ui/widgets/app_primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'dart:ui';

/// Unified Dialog & Feedback System for EduCore ERP.
/// Provides consistent, premium interaction patterns across all modules.
class AppDialogs {
  AppDialogs._();

  static bool _isLoadingVisible = false;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 1. CONFIRMATION DIALOGS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Standard Add Confirmation
  static Future<bool?> showAddConfirmation(
    BuildContext context, {
    String title = 'Confirm Add',
    String message = 'Are you sure you want to add this record?',
    String confirmLabel = 'Add Now',
  }) {
    return _showConfirm(
      context,
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      icon: Icons.add_task_rounded,
      iconColor: AppColors.primary,
    );
  }

  /// Standard Update Confirmation
  static Future<bool?> showEditConfirmation(
    BuildContext context, {
    String title = 'Confirm Update',
    String message = 'Save changes to this record?',
    String confirmLabel = 'Update',
  }) {
    return _showConfirm(
      context,
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      icon: Icons.edit_note_rounded,
      iconColor: Colors.amber[700]!,
    );
  }

  /// Standard Delete Confirmation (Critical Action)
  static Future<bool?> showDeleteConfirmation(
    BuildContext context, {
    String title = 'Delete Record?',
    String message = 'This action cannot be undone. Are you sure?',
    String confirmLabel = 'Delete Forever',
  }) {
    return _showConfirm(
      context,
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      isDanger: true,
      icon: Icons.delete_forever_rounded,
      iconColor: const Color(0xFFF43F5E),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 2. LOADING STATES
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Shows a premium loading overlay
  static void showLoading(
    BuildContext context, {
    String message = 'Processing...',
  }) {
    if (_isLoadingVisible) return;
    _isLoadingVisible = true;

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => _LoadingDialog(message: message),
      transitionBuilder: (context, animation, secondAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            )),
            child: child,
          ),
        );
      },
    ).then((_) => _isLoadingVisible = false);
  }

  /// Hides the active loading overlay
  static void hideLoading(BuildContext context) {
    if (_isLoadingVisible) {
      Navigator.of(context, rootNavigator: true).pop();
      _isLoadingVisible = false;
    }
  }

  /// Alias for [hideLoading] — backward compatible with existing call sites.
  static void hide(BuildContext context) => hideLoading(context);

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 3. ACTION FEEDBACK (FULL DIALOG)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  static Future<void> showSuccess(
    BuildContext context, {
    required String title,
    required String message,
    String buttonLabel = 'Continue',
    VoidCallback? onConfirm,
  }) {
    return _showBaseDialog(
      context,
      type: _DialogType.success,
      title: title,
      message: message,
      buttonLabel: buttonLabel,
      onConfirm: onConfirm,
    );
  }

  static Future<void> showError(
    BuildContext context, {
    required String title,
    required String message,
    String buttonLabel = 'Try Again',
    VoidCallback? onConfirm,
  }) {
    return _showBaseDialog(
      context,
      type: _DialogType.error,
      title: title,
      message: message,
      buttonLabel: buttonLabel,
      onConfirm: onConfirm,
    );
  }

  /// Specialized "No Internet" feedback
  static Future<void> showNoInternet(BuildContext context) {
    return _showBaseDialog(
      context,
      type: _DialogType.error,
      title: 'No Internet Connection',
      message: 'Please check your internet connection and try again.',
      buttonLabel: 'Close',
    );
  }

  /// Specialized "Timeout" feedback
  static Future<void> showTimeout(BuildContext context) {
    return _showBaseDialog(
      context,
      type: _DialogType.error,
      title: 'Request Timed Out',
      message: 'Your internet connection seems slow. Please try again later.',
      buttonLabel: 'Close',
    );
  }

  /// Informational feedback dialog (non-error, non-success).
  static Future<void> showInfo(
    BuildContext context, {
    required String title,
    required String message,
    String buttonLabel = 'Got It',
    VoidCallback? onConfirm,
  }) {
    return _showBaseDialog(
      context,
      type: _DialogType.info,
      title: title,
      message: message,
      buttonLabel: buttonLabel,
      onConfirm: onConfirm,
    );
  }

  /// Generic confirmation dialog — public entry point for ad-hoc confirmations.
  static Future<bool?> showConfirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDanger = false,
  }) {
    return _showConfirm(
      context,
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      icon: isDanger ? Icons.warning_amber_rounded : Icons.help_outline_rounded,
      iconColor: isDanger ? const Color(0xFFF43F5E) : AppColors.primary,
      isDanger: isDanger,
    );
  }

  static Future<void> showLimitReached(
    BuildContext context, {
    required String message,
    VoidCallback? onUpgrade,
  }) {
    return _showBaseDialog(
      context,
      type: _DialogType.error,
      title: 'Plan Limit Reached',
      message: '$message\n\nUpgrade your plan to unlock more capacity.',
      buttonLabel: 'View Pricing',
      onConfirm: onUpgrade,
    );
  }

  /// Unified "Access Denied" feedback for restricted features.
  static void showAccessDenied(BuildContext context) {
    showError(
      context,
      title: 'Access Restricted',
      message:
          'Contact TryUnity Solutions to gain access or upgrade your plan to unlock this feature.',
      buttonLabel: 'Got It',
    );
  }

  /// Unified text input dialog
  static Future<String?> showInput(
    BuildContext context, {
    required String title,
    required String hintText,
    String? initialValue,
    String confirmLabel = 'Submit',
    String cancelLabel = 'Cancel',
    bool multiline = false,
  }) {
    return showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, _, __) {
        return _InputDialog(
          title: title,
          hintText: hintText,
          initialValue: initialValue,
          confirmLabel: confirmLabel,
          cancelLabel: cancelLabel,
          multiline: multiline,
        );
      },
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // PRIVATE HELPERS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  static Future<bool?> _showConfirm(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required IconData icon,
    required Color iconColor,
    bool isDanger = false,
  }) {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, _, __) {
        return _ConfirmDialog(
          title: title,
          message: message,
          confirmLabel: confirmLabel,
          cancelLabel: 'Cancel',
          isDanger: isDanger,
          icon: icon,
          iconColor: iconColor,
        );
      },
      transitionBuilder: (context, animation, secondAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          ),
        );
      },
    );
  }

  static Future<void> _showBaseDialog(
    BuildContext context, {
    required _DialogType type,
    required String title,
    required String message,
    required String buttonLabel,
    VoidCallback? onConfirm,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, _, __) => _BaseDialog(
        type: type,
        title: title,
        message: message,
        buttonLabel: buttonLabel,
        onConfirm: onConfirm,
      ),
      transitionBuilder: (context, animation, secondAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          ),
        );
      },
    );
  }
}

enum _DialogType { success, error, info }

class _BaseDialog extends StatelessWidget {
  const _BaseDialog({
    required this.type,
    required this.title,
    required this.message,
    required this.buttonLabel,
    this.onConfirm,
  });

  final _DialogType type;
  final String title;
  final String message;
  final String buttonLabel;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 400,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadii.r24,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 40),
              _AnimatedStatusIcon(type: type),
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppColors.text,
                        letterSpacing: -0.8,
                      ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                        height: 1.6,
                        fontSize: 15,
                      ),
                ),
              ),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
                child: AppPrimaryButton(
                  label: buttonLabel,
                  variant: type == _DialogType.error
                      ? AppButtonVariant.danger
                      : AppButtonVariant.primary,
                  onPressed: () {
                    Navigator.pop(context);
                    onConfirm?.call();
                  },
                  width: double.infinity,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedStatusIcon extends StatelessWidget {
  const _AnimatedStatusIcon({required this.type});
  final _DialogType type;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (type) {
      _DialogType.success => (const Color(0xFF10B981), Icons.check_rounded),
      _DialogType.error   => (const Color(0xFFF43F5E), Icons.priority_high_rounded),
      _DialogType.info    => (AppColors.primary, Icons.info_outline_rounded),
    };

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 50 * value,
              color: color,
            ),
          ),
        );
      },
    );
  }
}

class _LoadingDialog extends StatelessWidget {
  const _LoadingDialog({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.all(32),
            constraints: const BoxConstraints(maxWidth: 340),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadii.r24,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 50,
                  offset: const Offset(0, 25),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SpinKitFadingCube(
                  color: AppColors.primary,
                  size: 40,
                ),
                const SizedBox(height: 32),
                Text(
                  message.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                        letterSpacing: 2.0,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please wait a moment',
                  style: TextStyle(
                    color: AppColors.textMuted.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.isDanger,
    required this.icon,
    required this.iconColor,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDanger;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 400,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadii.r24,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: AppRadii.r20,
                ),
                child: Icon(icon, size: 36, color: iconColor),
              ),
              const SizedBox(height: 28),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.text,
                      letterSpacing: -0.8,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                      height: 1.6,
                      fontSize: 15,
                    ),
              ),
              const SizedBox(height: 40),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppRadii.r16,
                        ),
                      ),
                      child: Text(
                        cancelLabel,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppPrimaryButton(
                      label: confirmLabel,
                      variant: isDanger
                          ? AppButtonVariant.danger
                          : AppButtonVariant.primary,
                      onPressed: () => Navigator.pop(context, true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InputDialog extends StatefulWidget {
  const _InputDialog({
    required this.title,
    required this.hintText,
    this.initialValue,
    required this.confirmLabel,
    required this.cancelLabel,
    this.multiline = false,
  });

  final String title;
  final String hintText;
  final String? initialValue;
  final String confirmLabel;
  final String cancelLabel;
  final bool multiline;

  @override
  State<_InputDialog> createState() => _InputDialogState();
}

class _InputDialogState extends State<_InputDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 450,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadii.r24,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.title,
                textAlign: TextAlign.left,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.text,
                      letterSpacing: -0.8,
                    ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _controller,
                maxLines: widget.multiline ? 5 : 1,
                minLines: widget.multiline ? 3 : 1,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  filled: true,
                  fillColor: AppColors.surfaceAlt,
                  border: const OutlineInputBorder(
                    borderRadius: AppRadii.r16,
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(20),
                ),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppRadii.r16,
                        ),
                      ),
                      child: Text(
                        widget.cancelLabel,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppPrimaryButton(
                      label: widget.confirmLabel,
                      onPressed: () => Navigator.pop(context, _controller.text),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
