import 'dart:core';

extension IndexedIterable<E> on Iterable<E> {
  Iterable<T> mapIndexed<T>(T Function(E e, int i) f) {
    var i = 0;
    return map((e) => f(e, i++));
  }
}

extension Chunk<E> on Iterable<E> {
  Iterable<List<E>> chunked(int chunkSize) sync* {
    var i = 0;
    var chunk = <E>[];
    for (var e in this) {
      chunk.add(e);
      if (++i == chunkSize) {
        yield chunk;
        chunk = <E>[];
        i = 0;
      }
    }
    if (chunk.isNotEmpty) {
      yield chunk;
    }
  }
}

extension HexDump on Iterable<int> {
  String hexDump() => map((element) => element.toRadixString(16).padLeft(2, '0'))
      .chunked(16)
      .map((element) => element.join(' '))
      .join('\n');
}
