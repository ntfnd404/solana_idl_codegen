/// Failure while acquiring the output lock or recovering an interrupted write.
final class OutputRecoveryException implements Exception {
  /// Creates a recovery failure.
  const OutputRecoveryException(this.message, [this.cause]);

  /// Human-readable failure description.
  final String message;

  /// Optional underlying failure.
  final Object? cause;

  @override
  String toString() => 'Output recovery failed: $message';
}
