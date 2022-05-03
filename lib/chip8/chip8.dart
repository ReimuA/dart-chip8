import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:chip8/chip8/isolate_event.dart';
import 'package:chip8/chip8/register.dart';

import 'font.dart';

class Chip8 {
  Uint8List memory;
  int soundTimer = 0;
  int delayTimer = 0;
  Chip8Registers registers;
  List<bool> keysPressedStatus = List.filled(16, false);
  List<List<int>> display = List.generate(32, (_) => List.filled(64, 0));

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
  })  : memory = Uint8List(4096),
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

    memory.setRange(0x00, 16 * 5, fonts.fold<List<int>>([], (previous, e) => previous..addAll(e)));
  }

  int _rxIndex(int opcode) => (opcode & 0x0F00) >> 8;
  int _ryIndex(int opcode) => (opcode & 0x00F0) >> 4;

  void cls() => display = List.generate(32, (_) => List.filled(64, 0));

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

  void skpr(int opcode) {
    var index = registers.v[_rxIndex(opcode)];
    _skip(keysPressedStatus[index]);
  }

  void skup(int opcode) {
    var index = registers.v[_rxIndex(opcode)];
    _skip(keysPressedStatus[index]);
  }

  // TODO: adapt to event based input
  void key(int opcode) async =>
      registers.v[_rxIndex(opcode)] = 0; //await input?.getNextKeyPressed() ?? registers.v[_rxIndex(opcode)];

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
    var rx = _rxIndex(opcode);
    registers.v[rx] += registers.v[_ryIndex(opcode)];
    registers.v[0xF] = registers.v[rx] > 0xFF ? 1 : 0;
    registers.v[rx] &= 0xFF;
  }

  void rsub(int opcode) {
    var rxIdx = (opcode & 0x0F00) >> 8;
    var ryIdx = (opcode & 0x0F0) >> 4;

    registers.v[0xF] = registers.v[rxIdx] < registers.v[ryIdx] ? 1 : 0;
    registers.v[rxIdx] = registers.v[ryIdx] - registers.v[rxIdx];
    registers.v[rxIdx] &= 0xFF;
  }

  void sub(int opcode) {
    var rxIdx = (opcode & 0x0F00) >> 8;
    var ryIdx = (opcode & 0x0F0) >> 4;

    registers.v[0xF] = registers.v[rxIdx] > registers.v[ryIdx] ? 1 : 0;
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
  void jmi(int opcode) => registers.pc = registers.v[0x0] + (opcode & 0x0FFF);
  void rand(int opcode) => registers.v[_rxIndex(opcode)] = Random().nextInt(opcode & 0xFF + 1);

  void sprite(int opcode) {
    var xLocation = registers.v[_rxIndex(opcode)];
    var yLocation = registers.v[_ryIndex(opcode)];
    var height = opcode & 0x000F;

    registers.v[0xF] = 0;

    for (int y = 0; y < height; y++) {
      var pixel = memory[registers.index + y];
      for (int x = 0; x < 8; x++) {
        if ((pixel & (0x80 >> x)) != 0) {
          var xPos = (xLocation + x) % 64;
          var yPos = (yLocation + y) % 32;

          if (display[yPos][xPos] == 1) registers.v[0xF] = 0x1;
          display[yPos][xPos] ^= 1;
        }
      }
    }
  }

  void gdelay(int opcode) => registers.v[_rxIndex(opcode)] = delayTimer;

  void sdelay(int opcode) => delayTimer = registers.v[_rxIndex(opcode)];
  void ssound(int opcode) => soundTimer = registers.v[_rxIndex(opcode)];
  void adi(int opcode) => registers.index += registers.v[_rxIndex(opcode)];
  void font(int opcode) => registers.index = registers.v[_rxIndex(opcode)] * 5;

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

  void tick() {
    var opcode = memory[registers.pc] << 8 | memory[registers.pc + 1];
    registers.pc += 2;

    var firstNibble = (opcode & 0xF000) >> 12;
    switch (firstNibble) {
      case 0x0:
        switch (opcode & 0x00FF) {
          case 0xE0:
            chip8.cls();
            break;
          case 0xEE:
            chip8.rts();
            break;
        }
        break;
      case 0x1:
        chip8.jmp(opcode);
        break;
      case 0x2:
        chip8.jsr(opcode);
        break;
      case 0x3:
        chip8.skeqConst(opcode);
        break;
      case 0x4:
        chip8.skneConst(opcode);
        break;
      case 0x5:
        chip8.skeq(opcode);
        break;
      case 0x6:
        chip8.movConst(opcode);
        break;
      case 0x7:
        chip8.addConst(opcode);
        break;
      case 0x8:
        switch (opcode & 0x000F) {
          case 0x0:
            chip8.mov(opcode);
            break;
          case 0x1:
            chip8.or(opcode);
            break;
          case 0x2:
            chip8.and(opcode);
            break;
          case 0x3:
            chip8.xor(opcode);
            break;
          case 0x4:
            chip8.add(opcode);
            break;
          case 0x5:
            chip8.sub(opcode);
            break;
        }
        break;
      case 0x9:
        chip8.skne(opcode);
        break;
      case 0xA:
        chip8.mvi(opcode);
        break;
      case 0xB:
        chip8.jmi(opcode);
        break;
      case 0xC:
        chip8.rand(opcode);
        break;
      case 0xD:
        chip8.sprite(opcode);
        break;
      case 0xE:
        switch (opcode & 0x0FF) {
          case 0x9E:
            chip8.skpr(opcode);
            break;
          case 0xA1:
            chip8.skup(opcode);
            break;
        }
        break;

      case 0xF:
        switch (opcode & 0x0FF) {
          case 0x07:
            chip8.gdelay(opcode);
            break;
          case 0x0A:
            chip8.key(opcode);
            break;
          case 0x15:
            chip8.sdelay(opcode);
            break;
          case 0x18:
            chip8.ssound(opcode);
            break;
          case 0x1E:
            chip8.adi(opcode);
            break;
          case 0x29:
            chip8.font(opcode);
            break;
          case 0x33:
            chip8.bcd(opcode);
            break;
          case 0x55:
            chip8.str(opcode);
            break;
          case 0x65:
            chip8.ldr(opcode);
            break;
        }
        break;
    }
  }

  void timerCallback(Timer _) {
    if (chip8.soundTimer > 0) chip8.soundTimer--;
    if (chip8.delayTimer > 0) chip8.delayTimer--;

    // Clear the screen
    print("\x1B[2J\x1B[0;0H");

    print(chip8.display.map((e) => e.map((e) => e == 1 ? '*' : ' ').join('')).join('\n'));
  }

  Future<void> dumpMemory() async {
    var file = File('./MemoryDump.txt');
    var dump = memory.map((e) => '0x' + e.toRadixString(16).toUpperCase().padLeft(2, '0')).join('\n');
    await file.writeAsString(dump);
  }

  void dumpAll() {
    var memoryDump = memory.map((e) => '0x' + e.toRadixString(16).toUpperCase().padLeft(2, '0')).join('\n');

    print("Opcode = 0x${(memory[registers.pc] << 8 | memory[registers.pc + 1]).toRadixString(16).toUpperCase()}");
    print("---Register---");
    print("V0: 0x${registers.v[0x0].toRadixString(16).toUpperCase()}");
    print("V1: 0x${registers.v[0x1].toRadixString(16).toUpperCase()}");
    print("V2: 0x${registers.v[0x2].toRadixString(16).toUpperCase()}");
    print("V3: 0x${registers.v[0x3].toRadixString(16).toUpperCase()}");
    print("V4: 0x${registers.v[0x4].toRadixString(16).toUpperCase()}");
    print("V5: 0x${registers.v[0x5].toRadixString(16).toUpperCase()}");
    print("V6: 0x${registers.v[0x6].toRadixString(16).toUpperCase()}");
    print("V7: 0x${registers.v[0x7].toRadixString(16).toUpperCase()}");
    print("V8: 0x${registers.v[0x8].toRadixString(16).toUpperCase()}");
    print("V9: 0x${registers.v[0x9].toRadixString(16).toUpperCase()}");
    print("VA: 0x${registers.v[0xA].toRadixString(16).toUpperCase()}");
    print("VB: 0x${registers.v[0xB].toRadixString(16).toUpperCase()}");
    print("VC: 0x${registers.v[0xC].toRadixString(16).toUpperCase()}");
    print("VD: 0x${registers.v[0xD].toRadixString(16).toUpperCase()}");
    print("VE: 0x${registers.v[0xE].toRadixString(16).toUpperCase()}");
    print("VF: 0x${registers.v[0xF].toRadixString(16).toUpperCase()}");
    print("Index Reg: 0x${registers.index.toRadixString(16).toUpperCase()}");
    print("PC Reg: 0x${registers.pc.toRadixString(16).toUpperCase()}");
    //print("SP Reg: 0x${registers.sp.toRadixString(16).toUpperCase()}");
    print("---Memory---");
    print(memoryDump);
  }

  Future<void> run({int? maxCycle, required ReceivePort receivePort}) async {
    var previousTick = DateTime.now();
    var timer60hz = Timer.periodic(const Duration(milliseconds: 1000 ~/ 30), timerCallback);
    var currentCycle = 0;
    var stopIsolateReceived = false;

    var subscription = receivePort.listen((event) {
      if (stopIsolateReceived) return;
      if (event is String) print(event);
      if (event is KeyPressedEvent) chip8.keysPressedStatus[event.key] = true;
      if (event is KeyReleasedEvent) chip8.keysPressedStatus[event.key] = false;
      if (event is StopIsolateEvent) stopIsolateReceived = true;
    });

    while (!stopIsolateReceived) {
      if (maxCycle == currentCycle++) {
        dumpAll();
        break;
      }

      tick();
      var now = DateTime.now();

      var diff = now.subtract(Duration(milliseconds: previousTick.millisecondsSinceEpoch)).millisecondsSinceEpoch;

      if (diff <= 1000 / 600) {
        await Future.delayed(Duration(milliseconds: (1000 - diff) ~/ 600));
      }

      if (chip8.soundTimer > 0) chip8.soundTimer--;
      if (chip8.delayTimer > 0) chip8.delayTimer--;
      previousTick = now;
    }

    timer60hz.cancel();
    subscription.cancel();
  }

  static void Function(SendPort) _isolateEntrypoint(String romPath) => (SendPort p) {
        final commandPort = ReceivePort();
        p.send(commandPort.sendPort);
        var chip = RunnableChip8.fromFile(romPath);

        chip.run(receivePort: commandPort).then((e) {
          commandPort.close();
          Isolate.exit();
        });
      };

  static Future<SendPort> startInIsolate(String romPath) async {
    final p = ReceivePort();
    final completer = Completer<SendPort>();

    var isolate = await Isolate.spawn<SendPort>(_isolateEntrypoint(romPath), p.sendPort);
    isolate.addOnExitListener(p.sendPort, response: "terminated");

    p.listen((message) {
      if (message is SendPort) completer.complete(message);
      if (message is String && message == "terminated") p.close();
    });

    return completer.future;
  }
}
