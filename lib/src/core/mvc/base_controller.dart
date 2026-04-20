import 'package:flutter/foundation.dart';

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

  @protected
  Future<T?> runBusy<T>(Future<T> Function() action) async {
    _error = null;
    setBusy(true);
    try {
      return await action();
    } catch (e) {
      _error = e.toString();
      debugPrint('Controller Error: $e');
      return null;
    } finally {
      setBusy(false);
    }
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
