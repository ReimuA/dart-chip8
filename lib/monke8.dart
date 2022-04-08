import 'chip8/chip8.dart';

void monke8() {
  var cpu = RunnableChip8.fromFile("rom/pong.rom");
  cpu.run();
}
