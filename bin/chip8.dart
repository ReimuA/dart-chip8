import 'dart:async';
import 'dart:io' as io;
import 'dart:io';

import 'package:chip8/src/chip8.dart';
import 'package:chip8/src/event.dart';

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

void main(List<String> arguments) async {
  var romPath = arguments.isNotEmpty ? arguments[0] : null;

  if (romPath == null) return;

  var file = File(romPath);
  var rom = file.readAsBytesSync();
  var ports = await RunnableChip8.startInIsolateFromRom(rom);

  ports.displayStream.listen((message) {
    print("\x1B[2J\x1B[0;0H");
    print((message).map((e) => e.map((e) => e == 1 ? '*' : ' ').join('')).join('\n'));
  });

  ports.audioStream.listen((event) {
    if (event is Chip8PlaySoundEvent) {
      // Handle playing sound
    } else if (event is Chip8StopSoundEvent) {
      // Stop sound
    }
  });

  var cliInput = CliInput(
    onKeyPressed: (key) => ports.sendPort.send(KeyPressedEvent(key)),
    onKeyReleased: (key) => ports.sendPort.send(KeyReleasedEvent(key)),
  );

  await Future.delayed(Duration(seconds: 30), () => ports.sendPort.send(StopIsolateEvent()));
  cliInput.cancel();
}
