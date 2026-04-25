import 'package:educore/src/core/services/app_services.dart';
import 'dart:async';
import 'dart:io';
import 'package:educore/src/core/services/network_service.dart';
import 'package:educore/src/core/ui/widgets/app_dialogs.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Enterprise-grade wrapper for all network operations.
/// Handles connectivity checks, timeouts, and professional error reporting.
class RequestGuard {
  RequestGuard._();

  /// Executes an async network [action] with a forced timeout and connectivity pre-check.
  /// 
  /// [context] - Optional. If null, uses AppServices.globalContext.
  /// [action] - The network operation to perform.
  /// [timeout] - Maximum allowed time (default 10s as per requirement).
  /// [showLoading] - Whether to show the global loading overlay.
  /// [loadingMessage] - Custom text for the loading overlay.
  static Future<({bool success, T? data})> run<T>(
    BuildContext? context,
    Future<T> Function() action, {
    Duration timeout = const Duration(seconds: 10),
    bool showLoading = true,
    String? loadingMessage,
  }) async {
    final ctx = context ?? AppServices.globalContext;
    
    // 1. Connectivity check before starting
    final hasInternet = await NetworkService.hasConnection;
    if (!hasInternet) {
      if (ctx != null && ctx.mounted) {
        AppDialogs.showNoInternet(ctx);
      }
      return (success: false, data: null);
    }

    // 2. Optional Loading Overlay
    if (showLoading && ctx != null && ctx.mounted) {
      AppDialogs.showLoading(ctx, message: loadingMessage ?? 'Processing...');
    }

    try {
      // 3. Execute with forced timeout
      final result = await action().timeout(
        timeout,
        onTimeout: () => throw TimeoutException('Request timed out'),
      );
      
      return (success: true, data: result);
    } on TimeoutException {
      if (ctx != null && ctx.mounted) {
        AppDialogs.hideLoading(ctx);
        AppDialogs.showTimeout(ctx);
      }
      return (success: false, data: null);
    } on FirebaseException catch (e) {
      if (ctx != null && ctx.mounted) {
        AppDialogs.hideLoading(ctx);
        AppDialogs.showError(
          ctx,
          title: 'Database Error',
          message: _mapFirebaseError(e),
        );
      }
      return (success: false, data: null);
    } on SocketException {
      if (ctx != null && ctx.mounted) {
        AppDialogs.hideLoading(ctx);
        AppDialogs.showNoInternet(ctx);
      }
      return (success: false, data: null);
    } on PlatformException catch (e) {
      if (ctx != null && ctx.mounted) {
        AppDialogs.hideLoading(ctx);
        AppDialogs.showError(
          ctx,
          title: 'System Error',
          message: e.message ?? 'A platform error occurred.',
        );
      }
      return (success: false, data: null);
    } catch (e) {
      if (ctx != null && ctx.mounted) {
        AppDialogs.hideLoading(ctx);
        AppDialogs.showError(
          ctx,
          title: 'Unexpected Error',
          message: 'Something went wrong. Please try again later.',
        );
      }
      debugPrint('RequestGuard Error: $e');
      return (success: false, data: null);
    } finally {
      // 4. Always hide loading if it was shown
      if (showLoading && ctx != null && ctx.mounted) {
        AppDialogs.hideLoading(ctx);
      }
    }
  }

  static String _mapFirebaseError(FirebaseException e) {
    return switch (e.code) {
      'permission-denied' => 'You do not have permission to perform this action.',
      'unavailable' => 'The service is currently unavailable. Please check your connection.',
      'network-request-failed' => 'Network error. Please check your internet.',
      'not-found' => 'The requested resource was not found.',
      'already-exists' => 'This record already exists.',
      _ => e.message ?? 'A database error occurred.',
    };
  }
}
