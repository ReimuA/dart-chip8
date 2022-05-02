import 'chip8/chip8.dart';

Future<void> monke8(List<String> arguments) async {
  var maxCycle = arguments.length >= 2 ? int.parse(arguments[1]) : null;
  var romPath = arguments.isNotEmpty ? arguments[0] : null;

  if (romPath == null) return;

  var cpu = RunnableChip8.fromFile(romPath);
  await cpu.run(maxCycle: maxCycle);
}
