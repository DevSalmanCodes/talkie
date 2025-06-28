// recording_timer_provider.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final recordingTimerProvider =
    StateNotifierProvider<RecordingTimerNotifier, int>((ref) {
  return RecordingTimerNotifier();
});

class RecordingTimerNotifier extends StateNotifier<int> {
  RecordingTimerNotifier() : super(0);

  Timer? _timer;

  void start() {
    _timer?.cancel();
    state = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      state++;
    });
  }

  void stop() {
    _timer?.cancel();
    state = 0;
  }
}



