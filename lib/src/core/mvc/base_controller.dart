import 'dart:async';
import 'package:educore/src/core/utils/request_guard.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

abstract class BaseController extends ChangeNotifier {
  bool _busy = false;
  bool _disposed = false;
  String? _error;

  bool get busy => _busy;
  bool get isDisposed => _disposed;
  String? get error => _error;
  bool get hasError => _error != null;

  @protected
  void setError(String? value) {
    _error = value;
    notifyListeners();
  }

  @protected
  void setBusy(bool value) {
    if (_busy == value || _disposed) return;
    _busy = value;
    notifyListeners();
  }

  /// Runs an [action] and manages the [busy] state.
  /// Use this for background tasks or shimmers where a full dialog isn't needed.
  @protected
  Future<T?> runBusy<T>(Future<T> Function() action) async {
    _error = null;
    setBusy(true);
    try {
      return await action().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Network request timed out'),
      );
    } catch (e) {
      _error = e.toString();
      debugPrint('Controller Error: $e');
      return null;
    } finally {
      setBusy(false);
    }
  }

  /// High-reliability wrapper for network operations.
  /// Handles internet checks, timeouts (10s), and shows professional error dialogs.
  @protected
  Future<T?> runGuarded<T>(
    Future<T> Function() action, {
    BuildContext? context,
    String? loadingMessage,
    bool showLoading = true,
  }) async {
    _error = null;
    // RequestGuard handles showLoading, hideLoading, internet check, and dialogs.
    final result = await RequestGuard.run(
      context,
      action,
      loadingMessage: loadingMessage,
      showLoading: showLoading,
    );
    
    // If it failed, we can still set the local error for UI if needed.
    if (!result.success) {
      _error = 'Operation failed';
      notifyListeners();
    }
    
    return result.data;
  }

  @override
  void notifyListeners() {
    if (_disposed) return;
    // Guard against "setState() called during build" — defer if we're mid-frame.
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!_disposed) super.notifyListeners();
      });
    } else {
      super.notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
