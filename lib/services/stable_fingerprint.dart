class StableFingerprint {
  static String of(Object? value) {
    final canonical = _canonical(value);
    return _fnv1a32(canonical).toRadixString(16).padLeft(8, '0');
  }

  static String _canonical(Object? value) {
    if (value is Map) {
      final keys = value.keys.map((key) => key.toString()).toList()..sort();
      return '{${keys.map((key) => '"$key":${_canonical(value[key])}').join(',')}}';
    }
    if (value is Iterable && value is! String) {
      return '[${value.map(_canonical).join(',')}]';
    }
    if (value is String) {
      return '"${value.replaceAll('\\', '\\\\').replaceAll('"', '\\"')}"';
    }
    if (value == null) {
      return 'null';
    }
    return value.toString();
  }

  static int _fnv1a32(String input) {
    var hash = 0x811c9dc5;
    const prime = 0x01000193;
    const mask = 0xFFFFFFFF;

    for (final unit in input.codeUnits) {
      hash ^= unit;
      hash = (hash * prime) & mask;
    }

    return hash;
  }
}
