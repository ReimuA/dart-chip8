abstract class IChip8Input {
  List<bool> get keysPressedStatus;

  Future<int> getNextKeyPressed();

  void resetInput();
}
