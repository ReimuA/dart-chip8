import 'dart:async';

import 'package:chip8/chip8.dart';

import 'cli_input.dart';

// Sample chip8 emulator in terminal
void main(List<String> arguments) async {
  var romPath = arguments.isNotEmpty ? arguments[0] : null;

  if (romPath == null) return;

  var portAndStreams = await RunnableChip8.startInIsolate(romPath);

  var cliInput = CliInput(
    onKeyPressed: (key) => portAndStreams.sendPort.send(KeyPressedEvent(key)),
    onKeyReleased: (key) => portAndStreams.sendPort.send(KeyReleasedEvent(key)),
  );

  portAndStreams.audioStream.listen(onAudioEvent);
  portAndStreams.displayStream.listen(onDisplayEvent);

  await Future.delayed(Duration(seconds: 30), () => portAndStreams.sendPort.send(StopIsolateEvent()));

  cliInput.cancel();
}

void onAudioEvent(Chip8SoundEvent event) {
  if (event is Chip8PlaySoundEvent) {
    // Handle playing sound
  } else if (event is Chip8StopSoundEvent) {
    // Stop sound
  }
}

void onDisplayEvent(Chip8Display display) {
  var clearScreenSequences = "\x1B[2J\x1B[0;0H";

  print(clearScreenSequences);
  print(display.map((e) => e.map((e) => e == 1 ? '*' : ' ').join('')).join('\n'));
}
