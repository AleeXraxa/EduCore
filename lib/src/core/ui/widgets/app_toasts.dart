import 'package:educore/src/app/theme/app_tokens.dart';
import 'package:flutter/material.dart';

class AppToasts {
  AppToasts._();

  static void showSuccess(BuildContext context, {required String message}) {
    _showToast(
      context,
      message: message,
      icon: Icons.check_circle_rounded,
      backgroundColor: const Color(0xFF10B981),
    );
  }

  static void showError(BuildContext context, {required String message}) {
    _showToast(
      context,
      message: message,
      icon: Icons.error_rounded,
      backgroundColor: const Color(0xFFF43F5E),
    );
  }

  static void showWarning(BuildContext context, {required String message}) {
    _showToast(
      context,
      message: message,
      icon: Icons.warning_rounded,
      backgroundColor: const Color(0xFFF59E0B),
    );
  }

  static void showInfo(BuildContext context, {required String message}) {
    _showToast(
      context,
      message: message,
      icon: Icons.info_outline_rounded,
      backgroundColor: const Color(0xFF3B82F6),
    );
  }

  static void _showToast(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color backgroundColor,
  }) {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.hideCurrentSnackBar();

    scaffold.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.r12),
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        duration: const Duration(seconds: 4),
        elevation: 8,
      ),
    );
  }
}
