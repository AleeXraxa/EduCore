import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:educore/src/core/ui/widgets/app_primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'dart:ui';

class AppDialogs {
  AppDialogs._();

  static Future<void> showSuccess(
    BuildContext context, {
    required String title,
    required String message,
    String buttonLabel = 'Continue',
    VoidCallback? onConfirm,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withValues(alpha: 0.3),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, _, __) => _BaseDialog(
        type: _DialogType.success,
        title: title,
        message: message,
        buttonLabel: buttonLabel,
        onConfirm: onConfirm,
      ),
      transitionBuilder: (context, animation, secondAnimation, child) {
        final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return ScaleTransition(
          scale: Tween<double>(begin: 0.9, end: 1.0).animate(curve),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }

  static Future<void> showError(
    BuildContext context, {
    required String title,
    required String message,
    String buttonLabel = 'Try Again',
    VoidCallback? onConfirm,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withValues(alpha: 0.3),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, _, __) => _BaseDialog(
        type: _DialogType.error,
        title: title,
        message: message,
        buttonLabel: buttonLabel,
        onConfirm: onConfirm,
      ),
      transitionBuilder: (context, animation, secondAnimation, child) {
        final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return ScaleTransition(
          scale: Tween<double>(begin: 0.9, end: 1.0).animate(curve),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }

  static Future<bool?> showConfirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDanger = false,
  }) {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withValues(alpha: 0.3),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, _, __) {
        return _ConfirmDialog(
          title: title,
          message: message,
          confirmLabel: confirmLabel,
          cancelLabel: cancelLabel,
          isDanger: isDanger,
        );
      },
      transitionBuilder: (context, animation, secondAnimation, child) {
        final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return ScaleTransition(
          scale: Tween<double>(begin: 0.9, end: 1.0).animate(curve),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }

  static bool _isLoadingVisible = false;

  static void showLoading(
    BuildContext context, {
    String message = 'Processing your request...',
  }) {
    if (_isLoadingVisible) return;
    _isLoadingVisible = true;

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.25),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => _LoadingDialog(message: message),
      transitionBuilder: (context, animation, secondAnimation, child) {
        final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return ScaleTransition(
          scale: Tween<double>(begin: 0.9, end: 1.0).animate(curve),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    ).then((_) => _isLoadingVisible = false);
  }

  static Future<void> showLimitReached(
    BuildContext context, {
    required String message,
    VoidCallback? onUpgrade,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withValues(alpha: 0.3),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, _, __) => _BaseDialog(
        type: _DialogType.error,
        title: 'Plan Limit Reached',
        message: '$message\n\nUpgrade your plan to unlock more capacity.',
        buttonLabel: 'Upgrade Now',
        onConfirm: onUpgrade,
      ),
      transitionBuilder: (context, animation, secondAnimation, child) {
        final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return ScaleTransition(
          scale: Tween<double>(begin: 0.9, end: 1.0).animate(curve),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }

  static Future<void> showInfo(
    BuildContext context, {
    required String title,
    required String message,
    String buttonLabel = 'Understood',
    IconData? icon,
    VoidCallback? onConfirm,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withValues(alpha: 0.3),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, _, __) => _BaseDialog(
        type: _DialogType.info,
        title: title,
        message: message,
        buttonLabel: buttonLabel,
        onConfirm: onConfirm,
        customIcon: icon,
      ),
      transitionBuilder: (context, animation, secondAnimation, child) {
        final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return ScaleTransition(
          scale: Tween<double>(begin: 0.9, end: 1.0).animate(curve),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }

  static void hide(BuildContext context) {
    if (_isLoadingVisible) {
      Navigator.pop(context);
    }
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
    this.customIcon,
  });

  final _DialogType type;
  final String title;
  final String message;
  final String buttonLabel;
  final VoidCallback? onConfirm;
  final IconData? customIcon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 380,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadii.r16,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 32),
              _AnimatedIcon(type: type, icon: customIcon),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppColors.text,
                        letterSpacing: -0.5,
                      ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                        height: 1.5,
                      ),
                ),
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.all(24),
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

class _AnimatedIcon extends StatelessWidget {
  const _AnimatedIcon({required this.type, this.icon});
  final _DialogType type;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final isSuccess = type == _DialogType.success;
    final isError = type == _DialogType.error;
    final color = isSuccess 
        ? const Color(0xFF10B981) 
        : (isError ? const Color(0xFFF43F5E) : AppColors.primary);
    
    final displayIcon = icon ?? (isSuccess 
        ? Icons.check_rounded 
        : (isError ? Icons.priority_high_rounded : Icons.info_outline_rounded));

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              displayIcon,
              size: 40 * value,
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
      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            constraints: const BoxConstraints(maxWidth: 320),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.98),
              borderRadius: AppRadii.r20,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SpinKitDoubleBounce(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      size: 64,
                    ),
                    const SpinKitThreeBounce(
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: AppColors.text,
                        height: 1.4,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'SYSTEM WORKING',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textMuted.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
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
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 380,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadii.r16,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: (isDanger ? const Color(0xFFF43F5E) : AppColors.primary).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDanger ? Icons.warning_rounded : Icons.help_outline_rounded,
                  size: 32,
                  color: isDanger ? const Color(0xFFF43F5E) : AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.text,
                      letterSpacing: -0.5,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                      height: 1.5,
                    ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppRadii.r12,
                        ),
                      ),
                      child: Text(
                        cancelLabel,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppPrimaryButton(
                      label: confirmLabel,
                      variant: isDanger ? AppButtonVariant.danger : AppButtonVariant.primary,
                      onPressed: () => Navigator.pop(context, true),
                      width: double.infinity,
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
