import 'dart:async';

class Debouncer {
  final Duration duration;
  bool _cooldown = false;
  Timer? _timer;

  Debouncer({Duration? duration, int? milliseconds})
      : duration = duration ?? Duration(milliseconds: milliseconds ?? 300);

  T? run<T>(T Function() action) {
    if (_cooldown) return null;
    _cooldown = true;
    final result = action();
    _timer?.cancel();
    _timer = Timer(duration, () => _cooldown = false);
    return result;
  }

  Future<T?> runAsync<T>(Future<T> Function() action) async {
    if (_cooldown) return null;
    _cooldown = true;
    try {
      final result = await action();
      return result;
    } finally {
      _timer?.cancel();
      _timer = Timer(duration, () => _cooldown = false);
    }
  }
}
