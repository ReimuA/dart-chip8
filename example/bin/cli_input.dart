import 'dart:async';
import 'dart:io' as io;

class CliInput {
  late StreamSubscription _subscription;
  final void Function(int key) onKeyPressed;
  final void Function(int key) onKeyReleased;

  void _onInput(List<int> keys) {
    for (var key in keys) {
      if (key >= 97 && key <= 112) {
        onKeyPressed(key - 97);
        Future.delayed(Duration(milliseconds: 100), () => onKeyReleased(key - 97));
      }
    }
  }

  CliInput({
    required this.onKeyPressed,
    required this.onKeyReleased,
  }) {
    io.stdin.lineMode = false;
    io.stdin.echoMode = false;
    _subscription = io.stdin.listen(_onInput);
  }

  void cancel() {
    io.stdin.lineMode = true;
    io.stdin.echoMode = true;
    _subscription.cancel();
  }

  Future<int> getNextKeyPressed() async {
    var key = io.stdin.readByteSync();

    while (key < 97 || key > 112) {
      key = io.stdin.readByteSync();
    }

    return key;
  }
}
