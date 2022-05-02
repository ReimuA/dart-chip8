import 'dart:async';
import 'dart:io' as io;

import 'input.dart';

class CliInput implements IChip8Input {
  late StreamSubscription _subscription;
  final List<bool> _keysPressedStatus = List.filled(16, false);

  void _onInput(List<int> keys) {
    for (var key in keys) {
      if (key >= 97 && key <= 112) _keysPressedStatus[key - 97] = true;
    }
  }

  @override
  void resetInput() {
    for (int i = 0; i < _keysPressedStatus.length; i++) {
      _keysPressedStatus[i] = false;
    }
  }

  CliInput() {
    io.stdin.lineMode = false;
    io.stdin.echoMode = false;
    _subscription = io.stdin.listen(_onInput);
  }

  void cancel() {
    io.stdin.lineMode = true;
    io.stdin.echoMode = true;
    _subscription.cancel();
  }

  @override
  Future<int> getNextKeyPressed() async {
    var key = io.stdin.readByteSync();

    while (key < 97 || key > 112) {
      key = io.stdin.readByteSync();
    }

    return key;
  }

  @override
  List<bool> get keysPressedStatus => List.from(_keysPressedStatus);
}
