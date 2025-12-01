class Debouncer {
  Debouncer({this.duration = const Duration(milliseconds: 400)});

  final Duration duration;
  DateTime? _lastRun;
  bool _pending = false;

  void run(void Function() action) {
    final now = DateTime.now();
    if (_lastRun == null || now.difference(_lastRun!) > duration) {
      _lastRun = now;
      action();
      _pending = false;
    } else {
      // Ignore rapid consecutive triggers
      _pending = true;
    }
  }

  bool get hasPending => _pending;
}
