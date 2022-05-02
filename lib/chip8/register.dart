import 'package:monke8/extension/iterable.dart';
import 'package:collection/collection.dart';

class Chip8Registers {
  int pc = 0x200;
  int index;
  List<int> v;
  List<int> stack = [];

  Chip8Registers({
    this.index = 0,
    int v0 = 0,
    int v1 = 0,
    int v2 = 0,
    int v3 = 0,
    int v4 = 0,
    int v5 = 0,
    int v6 = 0,
    int v7 = 0,
    int v8 = 0,
    int v9 = 0,
    int vA = 0,
    int vB = 0,
    int vC = 0,
    int vD = 0,
    int vE = 0,
    int vF = 0,
  }) : v = [v0, v1, v2, v3, v4, v5, v6, v7, v8, v9, vA, vB, vC, vD, vE, vF];

  @override
  String toString() {
    var vString = v
        .mapIndexed((index, v) => 'V${index.toRadixString(16).toUpperCase()}: 0x${v.toRadixString(16).toUpperCase()}')
        .join('\n');

    var _index = "Index: 0x${index.toRadixString(16).toUpperCase()}";
    var _pc = "PC: 0x${pc.toRadixString(16).toUpperCase()}";
    var _sp = "SP: 0x${(stack.lastOrNull ?? 0).toRadixString(16).toUpperCase()}";

    return [
      vString,
      _index,
      _pc,
      _sp,
    ].join('\n');
  }
}
