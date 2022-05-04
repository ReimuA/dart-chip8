abstract class Chip8IsolateEvent {}

class StopIsolateEvent extends Chip8IsolateEvent {}

class KeyPressedEvent extends Chip8IsolateEvent {
  final int key;
  KeyPressedEvent(this.key) : assert(key >= 0 && key <= 15);
}

class KeyReleasedEvent extends Chip8IsolateEvent {
  final int key;
  KeyReleasedEvent(this.key) : assert(key >= 0 && key <= 15);
}

abstract class Chip8SoundEvent {}

class Chip8PlaySoundEvent extends Chip8SoundEvent {}

class Chip8StopSoundEvent extends Chip8SoundEvent {}
