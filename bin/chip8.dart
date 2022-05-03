import 'package:chip8/chip8/chip8.dart';
import 'package:chip8/chip8/cli_input.dart';
import 'package:chip8/chip8/isolate_event.dart';

void main(List<String> arguments) async {
  var maxCycle = arguments.length >= 2 ? int.parse(arguments[1]) : null;
  var romPath = arguments.isNotEmpty ? arguments[0] : null;

  if (romPath == null) return;

  var sendPort = await RunnableChip8.startInIsolate(romPath);
  var cliInput = CliInput(
    onKeyPressed: (key) => sendPort.send(KeyPressedEvent(key)),
    onKeyReleased: (key) => sendPort.send(KeyReleasedEvent(key)),
  );

  await Future.delayed(Duration(minutes: 1));

  cliInput.cancel();
}
