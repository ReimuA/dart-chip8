import 'package:monke8/chip8/input.dart';

class Chip8InputTest implements IChip8Input {
  final int keypressed;

  const Chip8InputTest(this.keypressed);

  @override
  Future<int> getNextKeyPressed() async => 0;

  @override
  List<bool> get keysPressedStatus => List.generate(16, (index) => index == keypressed);
}
