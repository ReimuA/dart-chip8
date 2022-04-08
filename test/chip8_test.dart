import 'package:monke8/chip8/chip8.dart';
import 'package:test/test.dart';

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

      test('sub - carry generated', () {
        var chip = Chip8(v1: 0x12, v2: 0x19)..sub(0x0120);
        expect(chip.registers.v[0x0F], 0x001);
        expect(chip.registers.v[0x01], 0xF9);
      });

      test('sub - no carry generated', () {
        var chip = Chip8(v1: 0x19, v2: 0x12)..sub(0x0120);
        expect(chip.registers.v[0x0F], 0x0);
        expect(chip.registers.v[0x01], 0x07);
      });

      test('rsub - carry generated', () {
        var chip = Chip8(v1: 0x19, v2: 0x12)..rsub(0x0120);
        expect(chip.registers.v[0x0F], 0x001);
        expect(chip.registers.v[0x01], 0xF9);
      });

      test('rsub - no carry generated', () {
        var chip = Chip8(v1: 0x12, v2: 0x19)..rsub(0x0120);
        expect(chip.registers.v[0x0F], 0x0);
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
  });
}
