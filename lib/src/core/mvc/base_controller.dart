import 'package:flutter/foundation.dart';

abstract class BaseController extends ChangeNotifier {
  bool _busy = false;
  bool _disposed = false;

  bool get busy => _busy;
  bool get isDisposed => _disposed;

  @protected
  void setBusy(bool value) {
    if (_busy == value || _disposed) return;
    _busy = value;
    notifyListeners();
  }

  @protected
  Future<T> runBusy<T>(Future<T> Function() action) async {
    setBusy(true);
    try {
      return await action();
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
