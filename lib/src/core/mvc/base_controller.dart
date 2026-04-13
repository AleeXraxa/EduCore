import 'package:flutter/foundation.dart';

abstract class BaseController extends ChangeNotifier {
  bool _busy = false;

  bool get busy => _busy;

  @protected
  void setBusy(bool value) {
    if (_busy == value) return;
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
}
