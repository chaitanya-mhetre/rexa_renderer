class SduiError {
  final String? type;
  final String message;
  final String? nodePath;
  final Map<String, dynamic>? rawNode;
  final StackTrace? stackTrace;

  const SduiError({
    this.type,
    required this.message,
    this.nodePath,
    this.rawNode,
    this.stackTrace,
  });

  @override
  String toString() {
    final t = type == null ? '' : ' [$type]';
    final p = nodePath == null ? '' : ' at $nodePath';
    return 'SduiError$t: $message$p';
  }
}
