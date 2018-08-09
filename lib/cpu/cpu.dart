library nes.cpu;

import 'dart:typed_data';

import '../ppu/ppu.dart';
import '../gamepad/gamepad.dart';

part "cpu_memory.dart";
part "state.dart";
part "hex_interpreter.dart";

/// different types of interrupt that can occur
enum InterruptType {
  /// happens when V-Blank occurs
  NMI,

  /// generated by memory mappers
  IRQ,

  /// happens during startup and resets
  RESET
}

/// Simulate a 6502 cpu
class CPU {
  /// the CPU memory
  final CPUMemory memory = new CPUMemory();
  final State state = new State();
  Interpreter _interpreter;

  /// access to the PPU
  PPU get ppu => _ppu;
  PPU _ppu = new PPU();

  /// access to the gamepad
  GamePad gamepad;

  CPU() {
    state.load_processor_status(0);
    _interpreter = new Interpreter(state, memory);
    memory._cpu = this;
  }

  void interrupt(InterruptType type) {
    switch (type) {
      case InterruptType.IRQ:
        if (!state.interrupt_disable) {
          // if the interrupt disable flag is not set, set the state pc
          // new location is at $FFFE - $FFFF
          state.pc = _interpreter._read_16bit_addr(0xFFFE);
        }
        break;
      case InterruptType.NMI:
        if ((_ppu.memory.control_register_1 & 0x80) != 0) {
          // if bit 7 of PPU control register 1 is not clear, causes interrupt
          state.pc = _interpreter._read_16bit_addr(0xFFFA);
        }
        break;
      case InterruptType.RESET:
        state.pc = _interpreter._read_16bit_addr(0xFFFC);
        state.interrupt_disable = true;
        if (state.sp < 3) state.sp += 0x100;
        state.sp -= 3;
        break;
    }
  }

  /// make one cpu cycle
  void tick() {
    _interpreter.tick();
  }
}
