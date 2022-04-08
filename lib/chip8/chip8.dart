import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:monke8/chip8/register.dart';

class Chip8 {
  Uint8List memory;
  Chip8Registers registers;
  int soundTimer = 0;
  int delayTimer = 0;

  Chip8({
    int index = 0,
    Uint8List? rom,
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
  })  : memory = Uint8List(0xFFFF),
        registers = Chip8Registers(
          index: index,
          v0: v0,
          v1: v1,
          v2: v2,
          v3: v3,
          v4: v4,
          v5: v5,
          v6: v6,
          v7: v7,
          v8: v8,
          v9: v9,
          vA: vA,
          vB: vB,
          vC: vC,
          vD: vD,
          vE: vE,
          vF: vF,
        ) {
    if (rom != null) {
      memory.setRange(0x200, 0x200 + rom.length, rom);
    }
  }

  int _rxIndex(int opcode) => (opcode & 0x0F00) >> 8;
  int _ryIndex(int opcode) => (opcode & 0x00F0) >> 4;

  void scdown(int _) => throw UnimplementedError();
  void cls(int _) {}
  void scright(int _) => throw UnimplementedError();
  void scleft(int _) => throw UnimplementedError();
  void low(int _) => throw UnimplementedError();
  void high(int _) => throw UnimplementedError();
  void jmp(int opcode) => registers.pc = opcode & 0x0FFF;

  void rts() => registers.pc = registers.stack.removeLast();

  void jsr(int opcode) {
    registers.stack.add((registers.pc));
    registers.pc = opcode & 0x0FFF;
  }

  void _skip(bool skip) => registers.pc += skip ? 2 : 0;

  void skeqConst(int opcode) => _skip(registers.v[_rxIndex(opcode)] == (opcode & 0x00FF));
  void skneConst(int opcode) => _skip(registers.v[_rxIndex(opcode)] != (opcode & 0x00FF));
  void skeq(int opcode) => _skip(registers.v[_rxIndex(opcode)] == registers.v[_ryIndex(opcode)]);
  void skne(int opcode) => _skip(registers.v[_rxIndex(opcode)] != registers.v[_ryIndex(opcode)]);

  void skpr(int _) {}
  void skup(int _) {}

  void addConst(int opcode) {
    var idx = (opcode & 0x0F00) >> 8;
    registers.v[idx] += (opcode & 0x00FF);
    registers.v[idx] &= 0xFFFF;
  }

  void mov(int opcode) => registers.v[_rxIndex(opcode)] = registers.v[_ryIndex(opcode)];
  void movConst(int opcode) => registers.v[_rxIndex(opcode)] = (opcode & 0x00FF);

  void or(int opcode) => registers.v[_rxIndex(opcode)] |= registers.v[_ryIndex(opcode)];
  void and(int opcode) => registers.v[_rxIndex(opcode)] &= registers.v[_ryIndex(opcode)];
  void xor(int opcode) => registers.v[_rxIndex(opcode)] ^= registers.v[_ryIndex(opcode)];

  void add(int opcode) {
    registers.v[_rxIndex(opcode)] += registers.v[_ryIndex(opcode)];
    registers.v[0xF] = (registers.v[_rxIndex(opcode)] & 0xFF) != 0 ? 1 : 0;
    registers.v[_rxIndex(opcode)] &= 0xFF;
  }

  void rsub(int opcode) {
    var rxIdx = (opcode & 0x0F00) >> 8;
    var ryIdx = (opcode & 0x0F0) >> 4;

    registers.v[0xF] = registers.v[rxIdx] < registers.v[ryIdx] ? 0 : 1;
    registers.v[rxIdx] = registers.v[ryIdx] - registers.v[rxIdx];
    registers.v[rxIdx] &= 0xFF;
  }

  void sub(int opcode) {
    var rxIdx = (opcode & 0x0F00) >> 8;
    var ryIdx = (opcode & 0x0F0) >> 4;

    registers.v[0xF] = registers.v[rxIdx] > registers.v[ryIdx] ? 0 : 1;
    registers.v[rxIdx] -= registers.v[ryIdx];
    registers.v[rxIdx] &= 0xFF;
  }

  void shr(int opcode) {
    registers.v[0xF] = (registers.v[_rxIndex(opcode)] % 2) == 1 ? 1 : 0;
    registers.v[_rxIndex(opcode)] >>= 1;
  }

  void shl(int opcode) {
    registers.v[0xF] = (registers.v[_rxIndex(opcode)] & 0x80) == 0x80 ? 1 : 0;
    registers.v[_rxIndex(opcode)] <<= 1;
    registers.v[_rxIndex(opcode)] &= 0xFF;
  }

  void mvi(int opcode) => registers.index = opcode & 0x0FFF;
  void jmi(int opcode) => registers.pc = registers.v[0x0] + opcode & 0x0FFF;
  void rand(int opcode) => registers.v[_rxIndex(opcode)] = Random().nextInt(opcode & 0xFF + 1);
  void sprite(int _) {}
  void xsprite(int _) {}

  void gdelay(int _) {}
  void key(int _) {}
  void sdelay(int opcode) => delayTimer = registers.v[_rxIndex(opcode)];
  void ssound(int opcode) => soundTimer = registers.v[_rxIndex(opcode)];
  void adi(int opcode) => registers.index += registers.v[_rxIndex(opcode)];
  void font(int _) {}
  void xfont(int _) {}

  void bcd(int opcode) {
    memory[registers.index] = registers.v[_rxIndex(opcode)] ~/ 100;
    memory[registers.index + 1] = (registers.v[_rxIndex(opcode)] ~/ 10) % 10;
    memory[registers.index + 2] = registers.v[_rxIndex(opcode)] % 10;
  }

  void str(int opcode) {
    var end = (opcode & 0x0F00) >> 8;

    for (var i = 0; i <= end; i++) {
      memory[registers.index++] = registers.v[i];
    }
  }

  void ldr(int opcode) {
    var end = (opcode & 0x0F00) >> 8;

    for (var i = 0; i <= end; i++) {
      registers.v[i] = memory[registers.index++];
    }
  }
}

class RunnableChip8 {
  final Chip8 chip8;

  RunnableChip8(this.chip8);

  Uint8List get memory => chip8.memory;

  Chip8Registers get registers => chip8.registers;

  factory RunnableChip8.fromFile(String filePath) {
    var file = File(filePath);
    var rom = file.readAsBytesSync();
    return RunnableChip8(Chip8(rom: rom));
  }

  int get _currentOpCode => memory[registers.pc] << 8 | memory[registers.pc + 1];

  void tick() {
    var opCode = _currentOpCode;

    registers.pc += 2;
    var firstNb = opCode & 0xF000;
  }

  void run() {
    while (true) {
      tick();
    }
  }
}
