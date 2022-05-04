import 'dart:isolate';

import 'package:chip8/chip8.dart';

class Chip8IsolatePortAndStreams {
  final SendPort sendPort;
  final Stream<Chip8Display> displayStream;
  final Stream<Chip8SoundEvent> audioStream;

  Chip8IsolatePortAndStreams(this.sendPort, this.displayStream, this.audioStream);
}
