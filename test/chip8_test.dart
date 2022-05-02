import 'package:monke8/chip8/chip8.dart';
import 'package:monke8/chip8/font.dart';
import 'package:test/test.dart';

import 'inputtest.dart';

void main() {
  group('single assembly operation', () {
    group('basic', () {
      test('movConst', () => expect((Chip8()..movConst(0x06F2)).registers.v[6], 0xF2));
      test('addConst', () => expect((Chip8()..addConst(0x03F2)).registers.v[3], 0xF2));
      test('mov', () => expect((Chip8(v4: 0x3F)..mov(0x0340)).registers.v[0x3], 0x3F));
      test('and', () => expect((Chip8(vE: 0x30, vF: 0x3F)..and(0x0FE0)).registers.v[0xF], 0x30));
      test('xor', () => expect((Chip8(vE: 0x30, vF: 0x3F)..xor(0x0FE0)).registers.v[0xF], 0x0F));
      test('or', () => expect((Chip8(vE: 0x30, vF: 0x3F)..or(0x0FE0)).registers.v[0xF], 0x3F));

      test('skne - skip', () => expect((Chip8(v1: 0x12, v2: 0x19)..skne(0x0120)).registers.pc, 0x202));
      test('skne - no skip', () => expect((Chip8(v1: 0x12, v2: 0x12)..skne(0x0120)).registers.pc, 0x200));
      test('skeq - skip', () => expect((Chip8(v1: 0x12, v2: 0x12)..skeq(0x0120)).registers.pc, 0x202));
      test('skeq - no skip', () => expect((Chip8(v1: 0x12, v2: 0x19)..skeq(0x0120)).registers.pc, 0x200));

      test('skneConst - skip', () => expect((Chip8(v1: 0x12)..skneConst(0x0113)).registers.pc, 0x202));
      test('skneConst - no skip', () => expect((Chip8(v1: 0x12)..skneConst(0x0112)).registers.pc, 0x200));
      test('skeqConst - skip', () => expect((Chip8(v1: 0x12)..skeqConst(0x0112)).registers.pc, 0x202));
      test('skeqConst - no skip', () => expect((Chip8(v1: 0x12)..skeqConst(0x0113)).registers.pc, 0x200));

      test('jmp', () => expect((Chip8()..jmp(0x0120)).registers.pc, 0x120));
      test('jsr', () {
        var chip = Chip8()..jsr(0x888);
        expect(chip.registers.pc, 0x888);
        expect(chip.registers.stack.last, 0x200);
      });

      test('sub - no borrow', () {
        var chip = Chip8(v1: 0x12, v2: 0x19)..sub(0x0120);
        expect(chip.registers.v[0x0F], 0x0);
        expect(chip.registers.v[0x01], 0xF9);
      });

      test('add - carry generated', () {
        var chip = Chip8(v1: 0xFF, v2: 0x10)..add(0x0120);
        expect(chip.registers.v[0x0F], 0x01);
        expect(chip.registers.v[0x01], 0x0F);
      });

      test('add - no carry generated', () {
        var chip = Chip8(v1: 0x12, v2: 0x19)..add(0x0120);
        expect(chip.registers.v[0x0F], 0x00);
        expect(chip.registers.v[0x01], 0x2B);
      });

      test('sub - borrow generated', () {
        var chip = Chip8(v1: 0x19, v2: 0x12)..sub(0x0120);
        expect(chip.registers.v[0x0F], 0x01);
        expect(chip.registers.v[0x01], 0x07);
      });

      test('rsub - no borrow generated', () {
        var chip = Chip8(v1: 0x19, v2: 0x12)..rsub(0x0120);
        expect(chip.registers.v[0x0F], 0x00);
        expect(chip.registers.v[0x01], 0xF9);
      });

      test('rsub - borrow generated', () {
        var chip = Chip8(v1: 0x12, v2: 0x19)..rsub(0x0120);
        expect(chip.registers.v[0x0F], 0x01);
        expect(chip.registers.v[0x01], 0x07);
      });

      test('shr - carry generated', () {
        var chip = Chip8(v1: 0x1)..shr(0x0100);
        expect(chip.registers.v[0x0F], 0x1);
        expect(chip.registers.v[0x01], 0x0);
      });

      test('shr - no carry generated', () {
        var chip = Chip8(v1: 0x10)..shr(0x0100);
        expect(chip.registers.v[0x0F], 0x0);
        expect(chip.registers.v[0x01], 0x08);
      });

      test('shl - carry generated', () {
        var chip = Chip8(v1: 0x80)..shl(0x0100);
        expect(chip.registers.v[0x0F], 0x1);
        expect(chip.registers.v[0x01], 0x00);
      });

      test('shl - no carry generated', () {
        var chip = Chip8(v1: 0x08)..shl(0x0100);
        expect(chip.registers.v[0x0F], 0x0);
        expect(chip.registers.v[0x01], 0x10);
      });

      test('sdelay', () => expect((Chip8(v4: 0x12)..sdelay(0x0400)).delayTimer, 0x12));
      test('ssound', () => expect((Chip8(v4: 0x12)..ssound(0x0400)).soundTimer, 0x12));

      test('jmi', () => expect((Chip8(v0: 0x123)..jmi(0x0223)).registers.pc, 0x0346));
      test('mvi', () => expect((Chip8()..mvi(0x0F23)).registers.index, 0x0F23));
      test('addi', () => expect((Chip8(index: 0x123, v3: 0x123)..adi(0x0300)).registers.index, 0x0246));

      test('cls', () {
        var chip = Chip8();
        chip.display[1][0x12] = 0xFF;
        chip.cls();
        expect(chip.display[1][0x12], 0x00);
      });

      test('font', () {
        var chip = Chip8(v3: 0xA)..font(0x0300);
        expect(chip.memory[chip.registers.index + 0], fonts[0xA][0]);
        expect(chip.memory[chip.registers.index + 1], fonts[0xA][1]);
        expect(chip.memory[chip.registers.index + 2], fonts[0xA][2]);
        expect(chip.memory[chip.registers.index + 3], fonts[0xA][3]);
      });
    });
  });

  group('Key operation', () {
    test('skpr - skip', () {
      var chip = Chip8(input: Chip8InputTest(0x2))..skpr(0x2222);
      expect(chip.registers.pc, 0x0202);
    });

    test('skpr - no skip', () {
      var chip = Chip8(input: Chip8InputTest(0x0))..skpr(0x2222);
      expect(chip.registers.pc, 0x0200);
    });

    test('skup - skip', () {
      var chip = Chip8(input: Chip8InputTest(0x0))..skup(0x2222);
      expect(chip.registers.pc, 0x0202);
    });

    test('skup - no skip', () {
      var chip = Chip8(input: Chip8InputTest(0x2))..skup(0x2222);
      expect(chip.registers.pc, 0x0200);
    });
  });

  group('Multiple operation', () {
    test(
        'movConst / addConst',
        () => expect(
            (Chip8()
                  ..movConst(0x0211)
                  ..addConst(0x02A2))
                .registers
                .v[2],
            0xB3));

    test('jsr / rts', () {
      var chip = Chip8()..jsr(0x888);
      expect(chip.registers.pc, 0x888);
      expect(chip.registers.stack.last, 0x200);
      chip.rts();
      expect(chip.registers.stack.isEmpty, true);
      expect(chip.registers.pc, 0x200);
    });
  });

  group('Operation with memory', () {
    test('bcd', () {
      var chip = Chip8(index: 0x00FF, v0: 0xFF)..bcd(0x0000);

      expect(chip.memory[chip.registers.index], 2);
      expect(chip.memory[chip.registers.index + 1], 5);
      expect(chip.memory[chip.registers.index + 2], 5);
    });

    test('str', () {
      var chip = Chip8(index: 0x00FF, v0: 0xFF, v1: 0xAA, v2: 0x12)..str(0x0200);

      expect(chip.memory[chip.registers.index - 1], 0x12);
      expect(chip.memory[chip.registers.index - 2], 0xAA);
      expect(chip.memory[chip.registers.index - 3], 0xFF);
    });

    test('ldr', () {
      var chip = Chip8(index: 0x00FF);
      var buffer = [0xFF, 0xAA, 0x12];

      chip.memory.setRange(0x00FF, 0x00FF + buffer.length, buffer);
      chip.ldr(0x0200);

      expect(chip.memory[chip.registers.index - 1], 0x12);
      expect(chip.memory[chip.registers.index - 2], 0xAA);
      expect(chip.memory[chip.registers.index - 3], 0xFF);
    });
  });
}
